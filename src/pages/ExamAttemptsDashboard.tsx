import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  AlertCircle,
  X,
  CheckCircle,
  XCircle,
  Clock,
  Users,
  RotateCcw,
  Loader2
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';

interface Attempt {
  attempt_id: string;
  user_id: string;
  exam_id: string;
  score: number;
  passed: boolean;
  started_at: string;
  completed_at: string | null;
  created_at: string;
  email: string;
  full_name: string | null;
  exam_title: string;
  passing_score: number;
  allowed_attempts: number;
}

interface ResetConfirmationProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  userName: string;
  examTitle: string;
}

function ResetConfirmationDialog({ isOpen, onClose, onConfirm, userName, examTitle }: ResetConfirmationProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-lg shadow-xl max-w-md w-full p-6"
      >
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          Prüfungsversuche zurücksetzen
        </h3>
        <p className="text-gray-600 mb-6">
          Sind Sie sicher, dass Sie die Prüfungsversuche für <span className="font-medium">{userName}</span> für die Prüfung <span className="font-medium">{examTitle}</span> zurücksetzen möchten? Diese Aktion kann nicht rückgängig gemacht werden.
        </p>
        <div className="flex justify-end space-x-3">
          <button
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Abbrechen
          </button>
          <button
            onClick={onConfirm}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
          >
            <RotateCcw className="h-4 w-4 mr-2" />
            Zurücksetzen bestätigen
          </button>
        </div>
      </motion.div>
    </div>
  );
}

export function ExamAttemptsDashboard() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [attempts, setAttempts] = useState<Attempt[]>([]);
  const [isResetting, setIsResetting] = useState(false);
  const [resetConfirmation, setResetConfirmation] = useState<{
    isOpen: boolean;
    userId: string;
    examId: string;
    userName: string;
    examTitle: string;
  }>({
    isOpen: false,
    userId: '',
    examId: '',
    userName: '',
    examTitle: ''
  });

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        if (adminStatus) {
          await loadAttempts();
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

  const loadAttempts = async () => {
    try {
      const { data, error } = await supabase
        .rpc('get_exam_attempts_with_details');

      if (error) throw error;
      setAttempts(data || []);
    } catch (err) {
      console.error('Error loading attempts:', err);
      setError('Fehler beim Laden der Prüfungsversuche');
    }
  };

  const handleResetAttempts = async () => {
    try {
      setIsResetting(true);
      const { data, error } = await supabase
        .rpc('reset_exam_attempts', {
          p_user_id: resetConfirmation.userId,
          p_exam_id: resetConfirmation.examId
        });

      if (error) throw error;

      if (data) {
        await loadAttempts();
        setError('Prüfungsversuche wurden erfolgreich zurückgesetzt');
        setTimeout(() => setError(null), 3000);
      }
    } catch (err: any) {
      console.error('Error resetting attempts:', err);
      setError(err.message || 'Fehler beim Zurücksetzen der Prüfungsversuche');
    } finally {
      setIsResetting(false);
      setResetConfirmation(prev => ({ ...prev, isOpen: false }));
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
            <h1 className="text-2xl font-bold text-gray-900">Prüfungsteilnahmen</h1>
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

        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            {attempts.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Teilnehmer
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Prüfung
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Status
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Ergebnis
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Datum
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Aktionen
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {attempts.map((attempt) => (
                      <tr key={attempt.attempt_id}>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">
                            {attempt.full_name || attempt.email}
                          </div>
                          <div className="text-sm text-gray-500">{attempt.email}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">{attempt.exam_title}</div>
                          <div className="text-xs text-gray-500">
                            Bestehensgrenze: {attempt.passing_score}%
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {attempt.completed_at ? (
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              attempt.passed
                                ? 'bg-green-100 text-green-800'
                                : 'bg-red-100 text-red-800'
                            }`}>
                              {attempt.passed ? (
                                <>
                                  <CheckCircle className="h-4 w-4 mr-1" />
                                  Bestanden
                                </>
                              ) : (
                                <>
                                  <XCircle className="h-4 w-4 mr-1" />
                                  Nicht bestanden
                                </>
                              )}
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                              <Clock className="h-4 w-4 mr-1" />
                              In Bearbeitung
                            </span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-900">
                            {attempt.score}%
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(attempt.created_at).toLocaleString('de-DE')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <button
                            onClick={() => setResetConfirmation({
                              isOpen: true,
                              userId: attempt.user_id,
                              examId: attempt.exam_id,
                              userName: attempt.full_name || attempt.email,
                              examTitle: attempt.exam_title
                            })}
                            disabled={isResetting}
                            className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                          >
                            {isResetting ? (
                              <>
                                <Loader2 className="animate-spin h-3 w-3 mr-1" />
                                Wird zurückgesetzt...
                              </>
                            ) : (
                              <>
                                <RotateCcw className="h-3 w-3 mr-1" />
                                Zurücksetzen
                              </>
                            )}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="text-center py-12">
                <Users className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-2 text-sm font-medium text-gray-900">
                  Keine Prüfungsteilnahmen
                </h3>
                <p className="mt-1 text-sm text-gray-500">
                  Es wurden noch keine Prüfungen durchgeführt.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      <ResetConfirmationDialog
        isOpen={resetConfirmation.isOpen}
        onClose={() => setResetConfirmation(prev => ({ ...prev, isOpen: false }))}
        onConfirm={handleResetAttempts}
        userName={resetConfirmation.userName}
        examTitle={resetConfirmation.examTitle}
      />
    </div>
  );
}