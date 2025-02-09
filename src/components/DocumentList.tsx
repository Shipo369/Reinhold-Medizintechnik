import React from 'react';
import { FileText, ExternalLink } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface Document {
  id: string;
  name: string;
  description: string;
  file_path: string;
  file_type: string;
  created_at: string;
}

interface DocumentListProps {
  documents: Document[];
}

export function DocumentList({ documents }: DocumentListProps) {
  const handleOpenDocument = async (document: Document) => {
    const { data: { publicUrl } } = supabase.storage
      .from('module-documents')
      .getPublicUrl(document.file_path);
    window.open(publicUrl, '_blank', 'noopener,noreferrer');
  };

  if (documents.length === 0) {
    return (
      <div className="text-center py-12">
        <FileText className="mx-auto h-12 w-12 text-gray-400" />
        <h3 className="mt-2 text-sm font-medium text-gray-900">Keine Dokumente verfügbar</h3>
        <p className="mt-1 text-sm text-gray-500">
          Für dieses Gerät wurden noch keine Dokumente hochgeladen.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {documents.map((doc) => (
        <div
          key={doc.id}
          className="bg-white p-4 rounded-lg border border-gray-200 hover:border-blue-300 transition-colors"
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="flex-shrink-0">
                <FileText className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <h4 className="text-sm font-medium text-gray-900">{doc.name}</h4>
                {doc.description && (
                  <p className="text-sm text-gray-500">{doc.description}</p>
                )}
                <p className="text-xs text-gray-400 mt-1">
                  Hochgeladen am: {new Date(doc.created_at).toLocaleDateString('de-DE')}
                </p>
              </div>
            </div>
            <button
              onClick={() => handleOpenDocument(doc)}
              className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Dokument öffnen"
            >
              <ExternalLink className="h-5 w-5" />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}