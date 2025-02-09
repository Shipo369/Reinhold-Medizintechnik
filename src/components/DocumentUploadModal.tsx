import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { X, Upload, FileText, Loader2, AlertCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface DocumentUploadModalProps {
  isOpen: boolean;
  onClose: () => void;
  deviceModelId: string;
  onUploadComplete: () => void;
}

export function DocumentUploadModal({ isOpen, onClose, deviceModelId, onUploadComplete }: DocumentUploadModalProps) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    file: null as File | null
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getFileType = (fileName: string): string => {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.file) return;

    setIsLoading(true);
    setError(null);

    try {
      // 1. Upload file to storage
      const fileExt = formData.file.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
      const filePath = `${deviceModelId}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('module-documents')
        .upload(filePath, formData.file);

      if (uploadError) throw uploadError;

      // 2. Create database record
      const { error: dbError } = await supabase
        .from('module_documents')
        .insert([{
          device_model_id: deviceModelId,
          title: formData.title,
          description: formData.description,
          file_path: filePath,
          name: formData.file.name,
          file_type: getFileType(formData.file.name)
        }]);

      if (dbError) throw dbError;

      // 3. Reset form and close modal
      setFormData({ title: '', description: '', file: null });
      onUploadComplete();
      onClose();
    } catch (err: any) {
      console.error('Error uploading document:', err);
      setError(err.message || 'Fehler beim Hochladen des Dokuments');
    } finally {
      setIsLoading(false);
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
            Dokument hochladen
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-md p-4 flex items-center">
              <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700">
              Name<span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              id="title"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              Beschreibung (optional)
            </label>
            <textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              rows={3}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Datei<span className="text-red-500">*</span>
            </label>
            <div className="mt-1">
              <label className="cursor-pointer inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                <Upload className="h-4 w-4 mr-2" />
                {formData.file ? formData.file.name : 'Datei auswählen'}
                <input
                  type="file"
                  className="hidden"
                  accept=".pdf,.doc,.docx,.xls,.xlsx"
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) {
                      setFormData({ ...formData, file });
                    }
                  }}
                  required
                />
              </label>
            </div>
            <p className="mt-2 text-xs text-gray-500">
              Erlaubte Dateitypen: PDF, DOC, DOCX, XLS, XLSX
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
              disabled={isLoading || !formData.file || !formData.title}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isLoading ? (
                <>
                  <Loader2 className="animate-spin h-4 w-4 mr-2" />
                  Wird hochgeladen...
                </>
              ) : (
                <>
                  <FileText className="h-4 w-4 mr-2" />
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