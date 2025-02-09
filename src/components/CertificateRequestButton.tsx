import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Award, Lock, Loader2, CheckCircle, Clock, Download } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface CertificateRequestButtonProps {
  examId: string;
  deviceModelId: string;
}

interface CertificateRequest {
  id: string;
  status: 'pending' | 'processing' | 'completed';
  created_at: string;
  file_path: string | null;
}

export function CertificateRequestButton({ examId, deviceModelId }: CertificateRequestButtonProps) {
  const [hasPassed, setHasPassed] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [request, setRequest] = useState<CertificateRequest | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const init = async () => {
      try {
        await Promise.all([
          checkExamStatus(),
          checkRequestStatus()
        ]);
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, [examId]);

  const checkExamStatus = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: attempts, error } = await supabase
        .from('exam_attempts')
        .select('passed')
        .eq('exam_id', examId)
        .eq('user_id', user.id)
        .eq('status', 'active');

      if (error) throw error;

      setHasPassed(attempts?.some(attempt => attempt.passed) || false);
    } catch (err) {
      console.error('Error checking exam status:', err);
    }
  };

  const checkRequestStatus = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Nur die neueste Anfrage laden
      const { data, error } = await supabase
        .from('certificate_requests')
        .select()
        .eq('exam_id', examId)
        .eq('user_id', user.id)
        .eq('device_model_id', deviceModelId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) throw error;
      setRequest(data);
    } catch (err) {
      console.error('Error checking request status:', err);
    }
  };

  const handleRequest = async () => {
    try {
      setIsSubmitting(true);
      setError(null);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Prüfe zuerst, ob bereits eine aktive Anfrage existiert
      const { data: existingRequest, error: checkError } = await supabase
        .from('certificate_requests')
        .select('id')
        .eq('exam_id', examId)
        .eq('user_id', user.id)
        .eq('device_model_id', deviceModelId)
        .not('status', 'eq', 'completed') // Ignoriere abgeschlossene Anfragen
        .maybeSingle();

      if (checkError) throw checkError;

      // Nur eine neue Anfrage erstellen, wenn keine aktive existiert
      if (!existingRequest) {
        const { error: insertError } = await supabase
          .from('certificate_requests')
          .insert([{
            user_id: user.id,
            exam_id: examId,
            device_model_id: deviceModelId,
            status: 'pending'
          }])
          .select()
          .single();

        if (insertError) throw insertError;
      }

      await checkRequestStatus();
    } catch (err) {
      console.error('Error requesting certificate:', err);
      setError('Fehler bei der Zertifikatsanforderung');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDownload = async () => {
    if (!request?.file_path) return;

    try {
      setIsLoading(true);
      setError(null);

      const { data, error: downloadError } = await supabase.storage
        .from('certificates')
        .download(request.file_path);

      if (downloadError) throw downloadError;

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
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-4">
        <Loader2 className="h-5 w-5 animate-spin text-gray-400" />
      </div>
    );
  }

  if (!hasPassed) {
    return (
      <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-200">
        <div className="flex items-center text-gray-500">
          <Lock className="h-5 w-5 mr-2" />
          <span>Bestehen Sie zuerst die Prüfung, um ein Zertifikat anzufordern</span>
        </div>
      </div>
    );
  }

  if (request) {
    let statusColor = '';
    let StatusIcon = CheckCircle;
    let statusText = '';

    switch (request.status) {
      case 'pending':
        statusColor = 'bg-yellow-50 border-yellow-200 text-yellow-700';
        StatusIcon = Clock;
        statusText = 'Zertifikat wurde angefordert - Warten auf Bearbeitung';
        break;
      case 'processing':
        statusColor = 'bg-blue-50 border-blue-200 text-blue-700';
        StatusIcon = Loader2;
        statusText = 'Zertifikat wird bearbeitet';
        break;
      case 'completed':
        statusColor = 'bg-green-50 border-green-200 text-green-700';
        StatusIcon = CheckCircle;
        statusText = 'Zertifikat steht zum Download bereit';
        break;
    }

    return (
      <div className={`p-4 rounded-lg border ${statusColor}`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            {StatusIcon === Loader2 ? (
              <Loader2 className="h-5 w-5 mr-2 animate-spin" />
            ) : (
              <StatusIcon className="h-5 w-5 mr-2" />
            )}
            <div>
              <span>{statusText}</span>
              <p className="text-sm mt-1 opacity-75">
                Angefordert am: {new Date(request.created_at).toLocaleDateString('de-DE')}
              </p>
            </div>
          </div>
          {request.status === 'completed' && request.file_path && (
            <button
              onClick={handleDownload}
              className="ml-4 inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <Download className="h-4 w-4 mr-1" />
              Herunterladen
            </button>
          )}
        </div>
        {error && (
          <p className="mt-2 text-sm text-red-600">{error}</p>
        )}
      </div>
    );
  }

  return (
    <motion.button
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      onClick={handleRequest}
      disabled={isSubmitting}
      className="w-full flex items-center justify-center p-4 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
    >
      {isSubmitting ? (
        <Loader2 className="h-5 w-5 animate-spin mr-2" />
      ) : (
        <Award className="h-5 w-5 mr-2" />
      )}
      Zertifikat anfordern
    </motion.button>
  );
}