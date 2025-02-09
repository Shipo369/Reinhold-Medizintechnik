import React from 'react';
import { Clock, Loader2, Upload, Download } from 'lucide-react';

interface CertificateRequestCardProps {
  email: string;
  examTitle: string;
  deviceName: string;
  requestDate: string;
  uploadDate?: string | null;
  status: 'pending' | 'processing' | 'completed';
  score: number;
  passingScore: number;
  onProcess?: () => void;
  onUpload?: () => void;
  onDownload?: () => void;
  isProcessing?: boolean;
  filePath?: string | null;
}

export function CertificateRequestCard({
  email,
  examTitle,
  deviceName,
  requestDate,
  uploadDate,
  status,
  score,
  passingScore,
  onProcess,
  onUpload,
  onDownload,
  isProcessing,
  filePath
}: CertificateRequestCardProps) {
  return (
    <div className="bg-white rounded-lg shadow-sm p-6">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-lg font-medium text-gray-900">{email}</h3>
          <p className="text-sm text-gray-500 mt-1">
            Bestanden mit {score}% (Mindestens {passingScore}% erforderlich)
          </p>
        </div>
        <span className={`px-2.5 py-1 text-xs font-medium rounded-full ${
          status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
          status === 'processing' ? 'bg-blue-100 text-blue-800' :
          'bg-green-100 text-green-800'
        }`}>
          {status === 'pending' ? 'Ausstehend' :
           status === 'processing' ? 'In Bearbeitung' :
           'Zertifikat steht zum Download bereit'}
        </span>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <h4 className="text-sm font-medium text-gray-700">Prüfung</h4>
          <p className="text-gray-900">{examTitle}</p>
        </div>
        <div>
          <h4 className="text-sm font-medium text-gray-700">Gerät</h4>
          <p className="text-gray-900">{deviceName}</p>
        </div>
      </div>

      <div className="flex items-center justify-between mt-4 pt-4 border-t">
        <div className="space-y-1">
          <div className="flex items-center text-sm text-gray-500">
            <Clock className="h-4 w-4 mr-1" />
            Angefordert am: {requestDate}
          </div>
          {status === 'completed' && uploadDate && (
            <div className="flex items-center text-sm text-gray-500">
              <Upload className="h-4 w-4 mr-1" />
              Hochgeladen am: {uploadDate}
            </div>
          )}
        </div>
        <div className="flex space-x-2">
          {status === 'pending' && onProcess && (
            <button
              onClick={onProcess}
              disabled={isProcessing}
              className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isProcessing ? (
                <>
                  <Loader2 className="h-4 w-4 mr-1 animate-spin" />
                  Wird verarbeitet...
                </>
              ) : (
                'In Bearbeitung setzen'
              )}
            </button>
          )}
          {onUpload && (
            <button
              onClick={onUpload}
              className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <Upload className="h-4 w-4 mr-1" />
              {status === 'completed' ? 'Neues Zertifikat hochladen' : 'Zertifikat hochladen'}
            </button>
          )}
          {status === 'completed' && filePath && onDownload && (
            <button
              onClick={onDownload}
              className="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <Download className="h-4 w-4 mr-1" />
              Zertifikat herunterladen
            </button>
          )}
        </div>
      </div>
    </div>
  );
}