import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Award, AlertCircle, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';
import { CertificateUploadModal } from '../components/CertificateUploadModal';
import { CertificateRequestCard } from '../components/CertificateRequestCard';

interface CertificateRequest {
  id: string;
  user_id: string;
  exam_id: string;
  device_model_id: string;
  status: 'pending' | 'processing' | 'completed';
  created_at: string;
  updated_at: string;
  file_path: string | null;
  profile: {
    email: string;
    full_name: string | null;
  };
  exam: {
    title: string;
    passing_score: number;
  };
  device_model: {
    name: string;
  };
}

export function CertificateManagement() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [requests, setRequests] = useState<CertificateRequest[]>([]);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [uploadModalOpen, setUploadModalOpen] = useState(false);
  const [selectedRequestId, setSelectedRequestId] = useState<string | null>(null);
  const [examScores, setExamScores] = useState<Record<string, number>>({});

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        if (adminStatus) {
          await loadRequests();
        }
      } catch (err) {
        console.error('Error initializing:', err);
        setError('Fehler beim Laden der Daten');
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  const loadRequests = async () => {
    try {
      const { data, error } = await supabase
        .from('certificate_requests')
        .select(`
          *,
          profile:profiles(email, full_name),
          exam:module_exams(title, passing_score),
          device_model:device_models(name)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setRequests(data || []);

      // Load exam scores for each request
      const scores: Record<string, number> = {};
      for (const request of data || []) {
        const { data: attempts } = await supabase
          .from('exam_attempts')
          .select('score')
          .eq('user_id', request.user_id)
          .eq('exam_id', request.exam_id)
          .eq('passed', true)
          .eq('status', 'active')
          .order('created_at', { ascending: false });

        if (attempts && attempts.length > 0) {
          scores[request.id] = attempts[0].score;
        }
      }
      setExamScores(scores);
    } catch (err) {
      console.error('Error loading requests:', err);
      setError('Fehler beim Laden der Zertifikatsanfragen');
    }
  };

  const handleUpdateStatus = async (requestId: string, status: 'processing' | 'completed') => {
    try {
      setProcessingId(requestId);
      const { error } = await supabase
        .from('certificate_requests')
        .update({ status })
        .eq('id', requestId);

      if (error) throw error;

      await loadRequests();
      setError(`Status wurde erfolgreich auf "${status}" geändert`);
      setTimeout(() => setError(null), 3000);
    } catch (err) {
      console.error('Error updating status:', err);
      setError('Fehler beim Aktualisieren des Status');
    } finally {
      setProcessingId(null);
    }
  };

  const handleDownload = async (request: CertificateRequest) => {
    try {
      if (!request.file_path) {
        throw new Error('Keine Datei verfügbar');
      }

      const { data, error: downloadError } = await supabase.storage
        .from('certificates')
        .download(request.file_path);

      if (downloadError) throw downloadError;

      // Create download link
      const url = URL.createObjectURL(data);
      const a = document.createElement('a');
      a.href = url;
      a.download = request.file_path.split('/').pop() || 'zertifikat.pdf';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Error downloading certificate:', err);
      setError('Fehler beim Herunterladen des Zertifikats');
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-lg max-w-md w-full">
          <div className="flex items-center justify-center text-red-500 mb-4">
            <AlertCircle className="h-12 w-12" />
          </div>
          <h2 className="text-2xl font-bold text-center text-gray-900 mb-4">
            Zugriff verweigert
          </h2>
          <p className="text-gray-600 text-center mb-6">
            Sie benötigen Administrator-Rechte, um auf diesen Bereich zugreifen zu können.
          </p>
          <button
            onClick={() => navigate('/')}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Zurück zur Startseite
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Zurück"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <h1 className="text-2xl font-bold text-gray-900">Zertifikatsverwaltung</h1>
          </div>
        </div>

        {error && (
          <div className={`mb-4 p-4 rounded-lg flex items-center ${
            error.includes('erfolgreich')
              ? 'bg-green-50 text-green-800'
              : 'bg-red-50 text-red-800'
          }`}>
            <AlertCircle className="h-5 w-5 mr-2" />
            {error}
            <button
              onClick={() => setError(null)}
              className="ml-auto p-1 hover:bg-red-100 rounded-full"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        )}

        <div className="space-y-6">
          {requests.length > 0 ? (
            requests.map((request) => (
              <CertificateRequestCard
                key={request.id}
                email={request.profile.email}
                examTitle={request.exam.title}
                deviceName={request.device_model.name}
                requestDate={new Date(request.created_at).toLocaleDateString('de-DE')}
                uploadDate={request.status === 'completed' ? new Date(request.updated_at).toLocaleDateString('de-DE') : null}
                status={request.status}
                score={examScores[request.id] || 0}
                passingScore={request.exam.passing_score}
                onProcess={() => handleUpdateStatus(request.id, 'processing')}
                onUpload={() => {
                  setSelectedRequestId(request.id);
                  setUploadModalOpen(true);
                }}
                onDownload={() => handleDownload(request)}
                isProcessing={processingId === request.id}
                filePath={request.file_path}
              />
            ))
          ) : (
            <div className="text-center py-12">
              <Award className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">
                Keine Zertifikatsanfragen
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                Es liegen aktuell keine Anfragen vor.
              </p>
            </div>
          )}
        </div>
      </div>

      {uploadModalOpen && selectedRequestId && (
        <CertificateUploadModal
          isOpen={uploadModalOpen}
          onClose={() => {
            setUploadModalOpen(false);
            setSelectedRequestId(null);
          }}
          requestId={selectedRequestId}
          onUploadComplete={loadRequests}
        />
      )}
    </div>
  );
}