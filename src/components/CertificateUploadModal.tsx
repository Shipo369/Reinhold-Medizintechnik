import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { X, Upload, Loader2, AlertCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface CertificateUploadModalProps {
  isOpen: boolean;
  onClose: () => void;
  requestId: string;
  onUploadComplete: () => void;
}

export function CertificateUploadModal({ isOpen, onClose, requestId, onUploadComplete }: CertificateUploadModalProps) {
  const [file, setFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [requestDetails, setRequestDetails] = useState<{
    user_email: string;
    exam_title: string;
    device_name: string;
  } | null>(null);

  useEffect(() => {
    if (isOpen && requestId) {
      loadRequestDetails();
    }
  }, [isOpen, requestId]);

  const loadRequestDetails = async () => {
    try {
      const { data, error } = await supabase
        .from('certificate_requests')
        .select(`
          profile:profiles(email),
          exam:module_exams(title),
          device_model:device_models(name)
        `)
        .eq('id', requestId)
        .single();

      if (error) throw error;

      if (data) {
        setRequestDetails({
          user_email: data.profile.email,
          exam_title: data.exam.title,
          device_name: data.device_model.name
        });
      }
    } catch (err) {
      console.error('Error loading request details:', err);
      setError('Fehler beim Laden der Details');
    }
  };

  const generateFileName = () => {
    if (!requestDetails) return null;

    const date = new Date().toISOString().split('T')[0];
    const time = new Date().toISOString().split('T')[1].split('.')[0].replace(/:/g, '-');
    const userName = requestDetails.user_email.split('@')[0];
    const examName = requestDetails.exam_title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');
    const deviceName = requestDetails.device_name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');

    return `${date}_${time}_${examName}_${deviceName}_${userName}.pdf`;
  };

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;

    try {
      setIsUploading(true);
      setError(null);

      // 1. Generiere neuen Dateinamen
      const fileName = generateFileName();
      if (!fileName) {
        throw new Error('Fehler beim Generieren des Dateinamens');
      }

      const filePath = `certificates/${fileName}`;

      // 2. Hole aktuelle Request-Daten
      const { data: currentRequest } = await supabase
        .from('certificate_requests')
        .select('file_path')
        .eq('id', requestId)
        .single();

      // 3. Lösche alte Datei falls vorhanden
      if (currentRequest?.file_path) {
        try {
          const { error: removeError } = await supabase.storage
            .from('certificates')
            .remove([currentRequest.file_path]);

          if (removeError) {
            console.warn('Warning: Could not remove old file:', removeError);
          }
        } catch (removeErr) {
          console.warn('Warning: Error during file removal:', removeErr);
        }

        // Warte einen Moment, um sicherzustellen, dass die Löschung verarbeitet wurde
        await new Promise(resolve => setTimeout(resolve, 1500));
      }

      // 4. Aktualisiere Request mit neuem Dateipfad (vor dem Upload)
      const { error: updateError } = await supabase
        .from('certificate_requests')
        .update({
          file_path: filePath,
          status: 'completed'
        })
        .eq('id', requestId);

      if (updateError) throw updateError;

      // 5. Lade neue Datei hoch
      const { error: uploadError } = await supabase.storage
        .from('certificates')
        .upload(filePath, file, {
          cacheControl: '0',
          upsert: false // Kein upsert, da wir die alte Datei bereits gelöscht haben
        });

      if (uploadError) {
        // Wenn der Upload fehlschlägt, setze den Request zurück
        await supabase
          .from('certificate_requests')
          .update({
            file_path: null,
            status: 'processing'
          })
          .eq('id', requestId);

        throw uploadError;
      }

      onUploadComplete();
      onClose();
    } catch (err: any) {
      console.error('Error uploading certificate:', err);
      setError(err.message || 'Fehler beim Hochladen des Zertifikats');
    } finally {
      setIsUploading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-lg shadow-xl max-w-md w-full"
      >
        <div className="flex justify-between items-center px-6 py-4 border-b">
          <h3 className="text-lg font-medium text-gray-900">
            Zertifikat hochladen
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleUpload} className="p-6 space-y-4">
          {error && (
            <div className="mb-4 p-4 bg-red-50 text-red-700 rounded-lg flex items-center">
              <AlertCircle className="h-5 w-5 mr-2" />
              <span>{error}</span>
            </div>
          )}

          {requestDetails && (
            <div className="bg-gray-50 rounded-lg p-4 text-sm">
              <p><strong>Teilnehmer:</strong> {requestDetails.user_email}</p>
              <p><strong>Prüfung:</strong> {requestDetails.exam_title}</p>
              <p><strong>Gerät:</strong> {requestDetails.device_name}</p>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700">
              PDF-Datei auswählen
            </label>
            <input
              type="file"
              accept=".pdf"
              onChange={(e) => setFile(e.target.files?.[0] || null)}
              className="mt-1 block w-full text-sm text-gray-500
                file:mr-4 file:py-2 file:px-4
                file:rounded-md file:border-0
                file:text-sm file:font-medium
                file:bg-blue-50 file:text-blue-700
                hover:file:bg-blue-100"
              required
            />
            <p className="mt-2 text-xs text-gray-500">
              Die Datei wird automatisch mit einem aussagekräftigen Namen gespeichert.
              {requestDetails?.file_path && (
                <span className="block mt-1 text-yellow-600">
                  Hinweis: Eine vorhandene Datei wird automatisch ersetzt.
                </span>
              )}
            </p>
          </div>

          <div className="flex justify-end space-x-3 mt-6">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Abbrechen
            </button>
            <button
              type="submit"
              disabled={isUploading || !file}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isUploading ? (
                <>
                  <Loader2 className="animate-spin h-4 w-4 mr-2" />
                  Wird hochgeladen...
                </>
              ) : (
                <>
                  <Upload className="h-4 w-4 mr-2" />
                  Hochladen
                </>
              )}
            </button>
          </div>
        </form>
      </motion.div>
    </div>
  );
}