import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  Plus,
  ArrowLeft,
  AlertCircle,
  X,
  Save,
  ChevronRight,
  Settings,
  Download,
  Upload,
  File,
  Activity,
  ChevronDown,
  FileText,
  GraduationCap,
  Clock,
  Play,
  Users
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';
import { ExamModal } from '../components/ExamModal';

interface Exam {
  id: string;
  title: string;
  description: string;
  passing_score: number;
  time_limit: number;
  allowed_attempts: number;
  device_model: {
    id: string;
    name: string;
  };
  created_at: string;
  question_count: number;
  attempt_count: number;
}

export function ExamBoard() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [exams, setExams] = useState<Exam[]>([]);
  const [selectedExam, setSelectedExam] = useState<Exam | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedDeviceModel, setSelectedDeviceModel] = useState<string | null>(null);
  const [deviceModels, setDeviceModels] = useState<Array<{ id: string; name: string }>>([]);

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        if (adminStatus) {
          await Promise.all([
            loadExams(),
            loadDeviceModels()
          ]);
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

  const loadExams = async () => {
    try {
      setError(null);
      
      const { data: examsData, error: examsError } = await supabase
        .from('module_exams')
        .select(`
          *,
          device_model:device_models (
            id,
            name
          ),
          exam_questions (count),
          exam_attempts (count)
        `)
        .order('created_at', { ascending: false });

      if (examsError) throw examsError;

      const transformedData = examsData?.map(exam => ({
        ...exam,
        question_count: exam.exam_questions?.length || 0,
        attempt_count: exam.exam_attempts?.length || 0
      })) || [];

      setExams(transformedData);
    } catch (err) {
      console.error('Error loading exams:', err);
      setError('Fehler beim Laden der Prüfungen');
    }
  };

  const loadDeviceModels = async () => {
    try {
      const { data, error } = await supabase
        .from('device_models')
        .select('id, name')
        .order('name');

      if (error) throw error;
      setDeviceModels(data || []);
    } catch (err) {
      console.error('Error loading device models:', err);
      setError('Fehler beim Laden der Gerätemodelle');
    }
  };

  const handleEditExam = (exam: Exam) => {
    setSelectedDeviceModel(exam.device_model.id);
    setSelectedExam(exam);
    setIsModalOpen(true);
  };

  const handleDeleteExam = async (examId: string) => {
    if (!window.confirm('Möchten Sie diese Prüfung wirklich löschen?')) return;

    try {
      setError(null);
      const { error } = await supabase
        .from('module_exams')
        .delete()
        .eq('id', examId);

      if (error) throw error;

      await loadExams();
      setError('Prüfung wurde erfolgreich gelöscht');
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error deleting exam:', err);
      setError(err.message || 'Fehler beim Löschen der Prüfung');
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
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <button
                onClick={() => navigate(-1)}
                className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                title="Zurück"
              >
                <ArrowLeft className="h-5 w-5" />
              </button>
              <h1 className="text-2xl font-bold text-gray-900">Prüfungsverwaltung</h1>
            </div>
            <div className="flex items-center space-x-4">
              <Link
                to="/pruefungen/teilnahmen"
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <Users className="h-4 w-4 mr-2" />
                Teilnahmen anzeigen
              </Link>
              <select
                value={selectedDeviceModel || ''}
                onChange={(e) => setSelectedDeviceModel(e.target.value || null)}
                className="rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="">Gerät auswählen...</option>
                {deviceModels.map((model) => (
                  <option key={model.id} value={model.id}>
                    {model.name}
                  </option>
                ))}
              </select>
              <button
                onClick={() => {
                  setSelectedExam(null);
                  setIsModalOpen(true);
                }}
                disabled={!selectedDeviceModel}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                <Plus className="h-4 w-4 mr-2" />
                Neue Prüfung
              </button>
            </div>
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

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {exams.map((exam) => (
            <motion.div
              key={exam.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white rounded-lg shadow-sm border p-6 relative group"
            >
              <div className="absolute top-4 right-4 flex space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                <button
                  onClick={() => handleEditExam(exam)}
                  className="p-1 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg"
                  title="Bearbeiten"
                >
                  <Settings className="h-4 w-4" />
                </button>
                <button
                  onClick={() => handleDeleteExam(exam.id)}
                  className="p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg"
                  title="Löschen"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div className="flex items-center mb-4">
                <div className="bg-blue-100 rounded-lg p-2 mr-3">
                  <GraduationCap className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <h3 className="font-medium text-gray-900">{exam.title}</h3>
                  <p className="text-sm text-gray-500">{exam.description}</p>
                </div>
              </div>

              <div className="space-y-3 text-sm">
                <div className="flex items-center text-gray-600">
                  <FileText className="h-4 w-4 mr-2" />
                  <span>{exam.device_model.name}</span>
                </div>

                <div className="flex items-center text-gray-600">
                  <Users className="h-4 w-4 mr-2" />
                  <span>{exam.attempt_count} Teilnahmen</span>
                </div>

                <div className="flex items-center text-gray-600">
                  <Clock className="h-4 w-4 mr-2" />
                  <span>
                    Erstellt am {new Date(exam.created_at).toLocaleDateString('de-DE')}
                  </span>
                </div>
              </div>

              <div className="mt-4 pt-4 border-t">
                <div className="flex justify-between items-center">
                  <div className="text-sm">
                    <span className="text-gray-500">Bestehensgrenze:</span>
                    <span className="ml-1 font-medium text-gray-900">
                      {exam.passing_score}%
                    </span>
                  </div>
                  <div className="text-sm">
                    <span className="text-gray-500">Zeit:</span>
                    <span className="ml-1 font-medium text-gray-900">
                      {exam.time_limit} Min
                    </span>
                  </div>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {exams.length === 0 && (
          <div className="text-center py-12">
            <GraduationCap className="mx-auto h-12 w-12 text-gray-400" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">Keine Prüfungen vorhanden</h3>
            <p className="mt-1 text-sm text-gray-500">
              Erstellen Sie Ihre erste Prüfung, indem Sie auf "Neue Prüfung" klicken.
            </p>
          </div>
        )}
      </div>

      {selectedDeviceModel && (
        <ExamModal
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setSelectedDeviceModel(null);
            setSelectedExam(null);
          }}
          deviceModelId={selectedDeviceModel}
          exam={selectedExam}
          onSave={loadExams}
        />
      )}
    </div>
  );
}