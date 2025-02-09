import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  Award,
  AlertCircle,
  X,
  FileText,
  Download,
  Clock,
  CheckCircle,
  Loader2,
  Settings
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';

interface CertificateRequest {
  id: string;
  user_id: string;
  exam_id: string;
  device_model_id: string;
  status: 'pending' | 'processing' | 'completed';
  created_at: string;
  profile: {
    email: string;
    full_name: string | null;
  };
  exam: {
    title: string;
  };
}

export function CertificatesPage() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [requests, setRequests] = useState<CertificateRequest[]>([]);
  const [processingId, setProcessingId] = useState<string | null>(null);

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
          exam:module_exams(title)
        `)
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setRequests(data || []);
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

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate(-1)}
                className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                title="Zurück"
              >
                <ArrowLeft className="h-5 w-5" />
              </button>
              <h1 className="text-2xl font-bold text-gray-900">Zertifikate</h1>
            </div>
            {isAdmin && (
              <Link
                to="/zertifikate/verwaltung"
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <Settings className="h-4 w-4 mr-2" />
                Zertifikatsverwaltung
              </Link>
            )}
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

        <div className="bg-white shadow rounded-lg divide-y divide-gray-200">
          {requests.length > 0 ? (
            requests.map((request) => (
              <div key={request.id} className="p-6">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-medium text-gray-900">
                      {request.profile.full_name || request.profile.email}
                    </h3>
                    <p className="text-sm text-gray-500">{request.profile.email}</p>
                  </div>
                  <div className="flex items-center space-x-2">
                    {request.status === 'pending' && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                        <Clock className="h-3 w-3 mr-1" />
                        Ausstehend
                      </span>
                    )}
                    {request.status === 'processing' && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                        In Bearbeitung
                      </span>
                    )}
                    {request.status === 'completed' && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        <CheckCircle className="h-3 w-3 mr-1" />
                        Abgeschlossen
                      </span>
                    )}
                  </div>
                </div>

                <div className="mt-4">
                  <p className="text-sm font-medium text-gray-500">Prüfung</p>
                  <p className="mt-1">{request.exam.title}</p>
                </div>

                <div className="mt-4 flex justify-between items-center">
                  <p className="text-sm text-gray-500">
                    Angefordert am: {new Date(request.created_at).toLocaleDateString('de-DE')}
                  </p>
                  <div className="flex space-x-2">
                    {request.status === 'pending' && (
                      <button
                        onClick={() => handleUpdateStatus(request.id, 'processing')}
                        disabled={!!processingId}
                        className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                      >
                        {processingId === request.id ? (
                          <Loader2 className="h-4 w-4 animate-spin mr-1" />
                        ) : (
                          <Clock className="h-4 w-4 mr-1" />
                        )}
                        In Bearbeitung setzen
                      </button>
                    )}
                    {request.status === 'processing' && (
                      <button
                        onClick={() => handleUpdateStatus(request.id, 'completed')}
                        disabled={!!processingId}
                        className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
                      >
                        {processingId === request.id ? (
                          <Loader2 className="h-4 w-4 animate-spin mr-1" />
                        ) : (
                          <CheckCircle className="h-4 w-4 mr-1" />
                        )}
                        Als abgeschlossen markieren
                      </button>
                    )}
                    {request.status === 'completed' && (
                      <button
                        onClick={() => {/* TODO: Implement certificate download */}}
                        className="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                      >
                        <Download className="h-4 w-4 mr-1" />
                        Zertifikat herunterladen
                      </button>
                    )}
                  </div>
                </div>
              </div>
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
    </div>
  );
}