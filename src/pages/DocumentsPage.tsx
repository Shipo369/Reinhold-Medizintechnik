import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  AlertCircle,
  X,
  ChevronDown,
  FileText,
  Upload,
  Loader2,
  Download,
  Trash2,
  Save
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';

interface DeviceType {
  id: string;
  name: string;
  description: string;
}

interface DeviceModel {
  id: string;
  name: string;
  type_id: string;
  description: string;
}

interface Document {
  id: string;
  device_model_id: string;
  title: string;
  name: string;
  description: string;
  file_path: string;
  file_type: string;
  created_at: string;
}

interface UploadModalProps {
  isOpen: boolean;
  onClose: () => void;
  onUpload: (file: File, title: string, description: string) => Promise<void>;
  isUploading: boolean;
}

function UploadModal({ isOpen, onClose, onUpload, isUploading }: UploadModalProps) {
  const [file, setFile] = useState<File | null>(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;
    await onUpload(file, title, description);
    setFile(null);
    setTitle('');
    setDescription('');
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
          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700">
              Titel<span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              id="title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              Beschreibung
            </label>
            <textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Datei<span className="text-red-500">*</span>
            </label>
            <input
              type="file"
              onChange={(e) => setFile(e.target.files?.[0] || null)}
              accept=".pdf,.doc,.docx,.xls,.xlsx"
              className="mt-1 block w-full text-sm text-gray-500
                file:mr-4 file:py-2 file:px-4
                file:rounded-md file:border-0
                file:text-sm file:font-medium
                file:bg-blue-50 file:text-blue-700
                hover:file:bg-blue-100"
              required
            />
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
              disabled={isUploading || !file || !title}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isUploading ? (
                <>
                  <Loader2 className="animate-spin h-4 w-4 mr-2" />
                  Wird hochgeladen...
                </>
              ) : (
                <>
                  <Save className="h-4 w-4 mr-2" />
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

export function DocumentsPage() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deviceTypes, setDeviceTypes] = useState<DeviceType[]>([]);
  const [deviceModels, setDeviceModels] = useState<Record<string, DeviceModel[]>>({});
  const [documents, setDocuments] = useState<Record<string, Document[]>>({});
  const [expandedTypes, setExpandedTypes] = useState<Record<string, boolean>>({});
  const [selectedModelId, setSelectedModelId] = useState<string | null>(null);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [isUploading, setIsUploading] = useState(false);

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        await Promise.all([
          loadDeviceTypes(),
          loadDocuments()
        ]);
      } catch (err) {
        console.error('Error initializing:', err);
        setError('Fehler beim Laden der Daten');
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  const loadDeviceTypes = async () => {
    try {
      const { data: types, error: typesError } = await supabase
        .from('device_types')
        .select('*')
        .order('name');

      if (typesError) throw typesError;
      setDeviceTypes(types || []);

      // Load models for each type
      const modelsByType: Record<string, DeviceModel[]> = {};
      for (const type of types || []) {
        const { data: models, error: modelsError } = await supabase
          .from('device_models')
          .select('*')
          .eq('type_id', type.id)
          .order('name');

        if (modelsError) throw modelsError;
        modelsByType[type.id] = models || [];
      }
      setDeviceModels(modelsByType);
    } catch (err) {
      console.error('Error loading device types:', err);
      setError('Fehler beim Laden der Gerätetypen');
    }
  };

  const loadDocuments = async () => {
    try {
      const { data, error } = await supabase
        .from('module_documents')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Group documents by device model
      const documentsMap: Record<string, Document[]> = {};
      data?.forEach(doc => {
        if (!documentsMap[doc.device_model_id]) {
          documentsMap[doc.device_model_id] = [];
        }
        documentsMap[doc.device_model_id].push(doc);
      });
      setDocuments(documentsMap);
    } catch (err) {
      console.error('Error loading documents:', err);
      setError('Fehler beim Laden der Dokumente');
    }
  };

  const handleFileUpload = async (file: File, title: string, description: string) => {
    if (!selectedModelId) return;

    try {
      setIsUploading(true);
      setError(null);

      // Upload file to storage
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
      const filePath = `${selectedModelId}/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('module-documents')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      // Create database record
      const { error: dbError } = await supabase
        .from('module_documents')
        .insert([{
          device_model_id: selectedModelId,
          title,
          name: file.name,
          description,
          file_path: filePath,
          file_type: file.type
        }]);

      if (dbError) throw dbError;

      await loadDocuments();
      setIsUploadModalOpen(false);
      setError('Dokument wurde erfolgreich hochgeladen');
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error uploading document:', err);
      setError(err.message || 'Fehler beim Hochladen des Dokuments');
    } finally {
      setIsUploading(false);
    }
  };

  const handleDownload = async (document: Document) => {
    try {
      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('module-documents')
        .getPublicUrl(document.file_path);

      // Open in new tab
      window.open(publicUrl, '_blank', 'noopener,noreferrer');
    } catch (err) {
      console.error('Error opening document:', err);
      setError('Fehler beim Öffnen des Dokuments');
    }
  };

  const handleDelete = async (doc: Document) => {
    try {
      const confirmed = window.confirm('Möchten Sie dieses Dokument wirklich löschen?');
      if (!confirmed) return;

      setError(null);

      // Delete file from storage
      const { error: storageError } = await supabase.storage
        .from('module-documents')
        .remove([doc.file_path]);

      if (storageError) throw storageError;

      // Delete database record
      const { error: dbError } = await supabase
        .from('module_documents')
        .delete()
        .eq('id', doc.id);

      if (dbError) throw dbError;

      await loadDocuments();
      setError('Dokument wurde erfolgreich gelöscht');
      setTimeout(() => setError(null), 3000);
    } catch (err) {
      console.error('Error deleting document:', err);
      setError('Fehler beim Löschen des Dokuments');
    }
  };

  const toggleTypeExpansion = (typeId: string) => {
    setExpandedTypes(prev => ({ ...prev, [typeId]: !prev[typeId] }));
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
      <div className="max-w-[1920px] mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Zurück"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <h1 className="text-2xl font-bold text-gray-900">Dokumente</h1>
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

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {deviceTypes.map((type) => (
            <div key={type.id} className="bg-white rounded-lg shadow-sm border">
              {/* Type Header */}
              <div 
                className="p-4 border-b cursor-pointer hover:bg-gray-50 transition-colors"
                onClick={() => toggleTypeExpansion(type.id)}
              >
                <div className="flex items-center justify-between">
                  <h3 className="font-medium text-gray-900">{type.name}</h3>
                  <ChevronDown 
                    className={`h-5 w-5 text-gray-400 transform transition-transform ${
                      expandedTypes[type.id] ? 'rotate-180' : ''
                    }`}
                  />
                </div>
                {type.description && (
                  <p className="text-sm text-gray-500 mt-1">{type.description}</p>
                )}
              </div>

              {/* Models List */}
              {expandedTypes[type.id] && deviceModels[type.id]?.map((model) => (
                <div
                  key={model.id}
                  className="border-b last:border-b-0"
                >
                  <div className="p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium text-gray-800">{model.name}</h4>
                        {model.description && (
                          <p className="text-sm text-gray-500">{model.description}</p>
                        )}
                      </div>
                    </div>

                    {/* Documents List */}
                    <div className="mt-4 space-y-3">
                      {documents[model.id]?.map((doc) => (
                        <div
                          key={doc.id}
                          className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                        >
                          <div className="flex items-center">
                            <FileText className="h-5 w-5 text-gray-400 mr-3" />
                            <div>
                              <h5 className="text-sm font-medium text-gray-900">
                                {doc.title}
                              </h5>
                              {doc.description && (
                                <p className="text-xs text-gray-500">
                                  {doc.description}
                                </p>
                              )}
                              <p className="text-xs text-gray-400 mt-1">
                                {doc.name}
                              </p>
                            </div>
                          </div>
                          <div className="flex space-x-2">
                            <button
                              onClick={() => handleDownload(doc)}
                              className="p-1 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                              title="Herunterladen"
                            >
                              <Download className="h-4 w-4" />
                            </button>
                            {isAdmin && (
                              <button
                                onClick={() => handleDelete(doc)}
                                className="p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                title="Löschen"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            )}
                          </div>
                        </div>
                      ))}

                      {/* Upload Button */}
                      {isAdmin && (
                        <div className="mt-3">
                          <button
                            onClick={() => {
                              setSelectedModelId(model.id);
                              setIsUploadModalOpen(true);
                            }}
                            className="w-full flex items-center justify-center px-4 py-2 border border-gray-300 rounded-lg text-sm text-gray-600 hover:bg-gray-50 transition-colors"
                          >
                            <Upload className="h-4 w-4 mr-2" />
                            Dokument hochladen
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>

      <UploadModal
        isOpen={isUploadModalOpen}
        onClose={() => {
          setIsUploadModalOpen(false);
          setSelectedModelId(null);
        }}
        onUpload={handleFileUpload}
        isUploading={isUploading}
      />
    </div>
  );
}