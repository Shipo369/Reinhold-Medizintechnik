import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  Activity,
  FileText,
  GraduationCap,
  Clock,
  Users,
  ChevronRight,
  ChevronDown,
  CheckCircle,
  XCircle,
  Play,
  Presentation,
  BookOpen,
  Plus,
  Award,
  AlertCircle
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus, checkDeviceAccess } from '../lib/auth';
import { ExamSession } from '../components/ExamSession';
import { DocumentList } from '../components/DocumentList';
import { PresentationViewer } from '../components/PresentationViewer';
import { DocumentUploadModal } from '../components/DocumentUploadModal';
import { CertificateRequestButton } from '../components/CertificateRequestButton';

interface DeviceType {
  id: string;
  name: string;
  description: string;
}

interface DeviceModel {
  id: string;
  name: string;
  description: string;
  type_id: string;
}

interface Module {
  id: string;
  title: string;
  description: string;
  content: string;
  order_index: number;
}

interface Document {
  id: string;
  name: string;
  description: string;
  file_path: string;
  created_at: string;
}

interface Exam {
  id: string;
  title: string;
  description: string;
  passing_score: number;
  time_limit: number;
  allowed_attempts: number;
  question_count: number;
  attempts?: ExamAttempt[];
}

interface ExamAttempt {
  id: string;
  score: number;
  passed: boolean;
  created_at: string;
  status: 'active' | 'reset';
}

export function TrainingArea() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deviceTypes, setDeviceTypes] = useState<DeviceType[]>([]);
  const [deviceModels, setDeviceModels] = useState<Record<string, DeviceModel[]>>({});
  const [selectedType, setSelectedType] = useState<DeviceType | null>(null);
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
  const [expandedTypes, setExpandedTypes] = useState<Record<string, boolean>>({});
  const [modules, setModules] = useState<Module[]>([]);
  const [documents, setDocuments] = useState<Document[]>([]);
  const [exams, setExams] = useState<Exam[]>([]);
  const [activeTab, setActiveTab] = useState<'module' | 'documents' | 'exam' | 'certificates'>('documents');
  const [selectedExam, setSelectedExam] = useState<string | null>(null);
  const [isExamSessionActive, setIsExamSessionActive] = useState(false);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [selectedPresentation, setSelectedPresentation] = useState<any>(null);
  const [presentations, setPresentations] = useState<Record<string, any>>({});

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        await Promise.all([
          loadDeviceTypes(),
          loadPresentations()
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

  const loadPresentations = async () => {
    try {
      const { data, error } = await supabase
        .from('device_presentations')
        .select('*');

      if (error) throw error;

      const presentationsMap: Record<string, any> = {};
      data?.forEach(presentation => {
        presentationsMap[presentation.device_model_id] = presentation;
      });
      setPresentations(presentationsMap);
    } catch (err) {
      console.error('Error loading presentations:', err);
      setError('Fehler beim Laden der Präsentationen');
    }
  };

  const loadModelData = async (modelId: string) => {
    try {
      setError(null);

      const { data: documentData, error: documentError } = await supabase
        .from('module_documents')
        .select('*')
        .eq('device_model_id', modelId)
        .order('created_at', { ascending: false });

      if (documentError) throw documentError;
      setDocuments(documentData || []);

      const { data: moduleData, error: moduleError } = await supabase
        .from('learning_modules')
        .select('*')
        .eq('device_model_id', modelId)
        .order('order_index');

      if (moduleError) throw moduleError;
      setModules(moduleData || []);

      const { data: examData, error: examError } = await supabase
        .from('module_exams')
        .select(`
          *,
          exam_questions (count),
          exam_attempts (
            id,
            score,
            passed,
            created_at,
            status
          )
        `)
        .eq('device_model_id', modelId);

      if (examError) throw examError;

      const transformedExams = examData?.map(exam => ({
        ...exam,
        question_count: exam.exam_questions?.length || 0,
        attempts: exam.exam_attempts?.filter(a => a.status === 'active') || []
      })) || [];

      setExams(transformedExams);
    } catch (err) {
      console.error('Error loading model data:', err);
      setError('Fehler beim Laden der Daten');
    }
  };

  const handleTypeSelect = async (type: DeviceType) => {
    setSelectedType(type);
    setSelectedModel(null);
    setExpandedTypes(prev => ({ ...prev, [type.id]: true }));
  };

  const handleModelSelect = async (model: DeviceModel) => {
    const hasAccess = await checkDeviceAccess(model.id);
    if (!hasAccess) {
      setError('Sie haben keine Berechtigung für dieses Gerät');
      return;
    }

    setSelectedModel(model);
    await loadModelData(model.id);
  };

  const toggleTypeExpansion = (typeId: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setExpandedTypes(prev => ({ ...prev, [typeId]: !prev[typeId] }));
  };

  const handleStartExam = async (examId: string) => {
    try {
      const exam = exams.find(e => e.id === examId);
      if (!exam) {
        setError('Prüfung nicht gefunden');
        return;
      }

      const passedAttempt = exam.attempts?.find(a => a.passed && a.status === 'active');
      if (passedAttempt) {
        setError('Sie haben diese Prüfung bereits bestanden und können sie nicht erneut durchführen.');
        setTimeout(() => setError(null), 5000);
        return;
      }

      const activeAttempts = exam.attempts?.filter(a => a.status === 'active')?.length || 0;
      if (activeAttempts >= exam.allowed_attempts) {
        setError('Sie haben die maximale Anzahl an Versuchen für diese Prüfung erreicht.');
        setTimeout(() => setError(null), 5000);
        return;
      }

      setSelectedExam(examId);
      setIsExamSessionActive(true);
      setError(null);
    } catch (err: any) {
      console.error('Error starting exam:', err);
      setError(err.message || 'Fehler beim Starten der Prüfung');
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
    <div className="min-h-screen bg-gray-50 flex">
      {/* Sidebar */}
      <div className="w-64 bg-white shadow-lg">
        <div className="p-4 border-b">
          <div className="flex items-center space-x-2">
            <button
              onClick={() => navigate(-1)}
              className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Zurück"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <h2 className="text-lg font-semibold text-gray-900">Geräte</h2>
          </div>
        </div>
        <nav className="p-4">
          <div className="space-y-2">
            {deviceTypes.map((type) => (
              <div key={type.id} className="group">
                <div
                  className={`flex items-center p-2 rounded-lg cursor-pointer ${
                    selectedType?.id === type.id
                      ? 'bg-blue-50 text-blue-700'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                  onClick={() => handleTypeSelect(type)}
                >
                  <span className="flex-1">{type.name}</span>
                  <button
                    onClick={(e) => toggleTypeExpansion(type.id, e)}
                    className="p-1 hover:bg-gray-100 rounded-lg"
                  >
                    {expandedTypes[type.id] ? (
                      <ChevronDown className="h-4 w-4 text-gray-400" />
                    ) : (
                      <ChevronRight className="h-4 w-4 text-gray-400" />
                    )}
                  </button>
                </div>
                {expandedTypes[type.id] && deviceModels[type.id]?.length > 0 && (
                  <div className="ml-4 mt-1 space-y-1">
                    {deviceModels[type.id].map((model) => (
                      <div
                        key={model.id}
                        onClick={() => handleModelSelect(model)}
                        className={`flex items-center p-2 rounded-lg cursor-pointer ${
                          selectedModel?.id === model.id
                            ? 'bg-blue-50 text-blue-700'
                            : 'text-gray-600 hover:bg-gray-50'
                        }`}
                      >
                        <Activity className={`h-4 w-4 mr-2 ${
                          selectedModel?.id === model.id ? 'text-blue-600' : 'text-gray-400'
                        }`} />
                        <span className="text-sm">{model.name}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 p-8">
        {error && (
          <div className="mb-4 p-4 bg-red-50 text-red-800 rounded-lg flex items-center">
            <AlertCircle className="h-5 w-5 mr-2" />
            {error}
          </div>
        )}

        {selectedModel ? (
          <>
            <div className="flex items-center justify-between mb-6">
              <h1 className="text-2xl font-bold text-gray-900">{selectedModel.name}</h1>
              {isAdmin && activeTab === 'documents' && (
                <button
                  onClick={() => setIsUploadModalOpen(true)}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Dokument hochladen
                </button>
              )}
            </div>

            <div className="bg-white rounded-lg shadow">
              <div className="border-b px-4 py-3">
                <div className="flex space-x-4">
                  <button
                    onClick={() => setActiveTab('module')}
                    className={`px-4 py-2 rounded-lg flex items-center space-x-2 ${
                      activeTab === 'module'
                        ? 'bg-blue-50 text-blue-700'
                        : 'text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    <BookOpen className="h-5 w-5" />
                    <span>Lernmodule</span>
                  </button>
                  <button
                    onClick={() => setActiveTab('documents')}
                    className={`px-4 py-2 rounded-lg flex items-center space-x-2 ${
                      activeTab === 'documents'
                        ? 'bg-blue-50 text-blue-700'
                        : 'text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    <FileText className="h-5 w-5" />
                    <span>Dokumente</span>
                  </button>
                  <button
                    onClick={() => setActiveTab('exam')}
                    className={`px-4 py-2 rounded-lg flex items-center space-x-2 ${
                      activeTab === 'exam'
                        ? 'bg-blue-50 text-blue-700'
                        : 'text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    <GraduationCap className="h-5 w-5" />
                    <span>Prüfung</span>
                  </button>
                  <button
                    onClick={() => setActiveTab('certificates')}
                    className={`px-4 py-2 rounded-lg flex items-center space-x-2 ${
                      activeTab === 'certificates'
                        ? 'bg-blue-50 text-blue-700'
                        : 'text-gray-600 hover:bg-gray-50'
                    }`}
                  >
                    <Award className="h-5 w-5" />
                    <span>Zertifikate</span>
                  </button>
                </div>
              </div>

              <div className="p-6">
                {activeTab === 'module' && (
                  <div className="space-y-6">
                    {/* PowerPoint Presentation Section */}
                    {selectedModel && presentations[selectedModel.id] && (
                      <div className="p-4 border rounded-lg hover:border-blue-300 transition-colors">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center">
                            <div className="bg-orange-100 rounded-lg p-2 mr-3">
                              <Presentation className="h-5 w-5 text-orange-600" />
                            </div>
                            <div>
                              <h3 className="text-lg font-medium text-gray-900">
                                {presentations[selectedModel.id].title || selectedModel.name}
                              </h3>
                            </div>
                          </div>
                          <button
                            onClick={() => setSelectedPresentation(presentations[selectedModel.id])}
                            className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                          >
                            <Play className="h-4 w-4 mr-1" />
                            Anzeigen
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Existing modules */}
                    {modules.map((module) => (
                      <div
                        key={module.id}
                        className="p-4 border rounded-lg hover:border-blue-300 transition-colors"
                      >
                        <h3 className="text-lg font-semibold text-gray-900">{module.title}</h3>
                        <p className="text-gray-600 mt-1">{module.description}</p>
                      </div>
                    ))}
                    {modules.length === 0 && !presentations[selectedModel.id] && (
                      <div className="text-center py-8">
                        <p className="text-gray-500">Keine Module verfügbar</p>
                      </div>
                    )}
                  </div>
                )}

                {activeTab === 'documents' && (
                  <DocumentList
                    documents={documents}
                    isAdmin={isAdmin}
                  />
                )}

                {activeTab === 'exam' && (
                  <div className="space-y-6">
                    {exams.length > 0 ? (
                      exams.map(exam => (
                        <div
                          key={exam.id}
                          className="bg-white border rounded-lg p-6 space-y-4"
                        >
                          <div className="flex justify-between items-start">
                            <div className="flex-1">
                              <div className="flex items-center space-x-3">
                                <h3 className="text-lg font-medium text-gray-900">
                                  {exam.title}
                                </h3>
                                {exam.attempts?.find(a => a.passed) ? (
                                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                    <CheckCircle className="h-3 w-3 mr-1" />
                                    Bestanden
                                  </span>
                                ) : exam.attempts?.length ? (
                                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                                    <XCircle className="h-3 w-3 mr-1" />
                                    Nicht bestanden
                                  </span>
                                ) : null}
                              </div>
                              {exam.description && (
                                <p className="mt-1 text-gray-500">{exam.description}</p>
                              )}
                              {exam.attempts?.length > 0 && (
                                <p className="mt-2 text-sm text-gray-500">
                                  Letzter Versuch: {new Date(exam.attempts[0].created_at).toLocaleDateString('de-DE')} - 
                                  Ergebnis: {exam.attempts[0].score}%
                                </p>
                              )}
                              {!exam.attempts?.find(a => a.passed) && (
                                <p className="mt-2 text-sm font-medium text-gray-700">
                                  Verbleibende Versuche: {exam.allowed_attempts - (exam.attempts?.length || 0)} von {exam.allowed_attempts}
                                </p>
                              )}
                            </div>
                            <button
                              onClick={() => handleStartExam(exam.id)}
                              disabled={
                                exam.attempts?.find(a => a.passed) ||
                                (exam.attempts?.length || 0) >= exam.allowed_attempts
                              }
                              className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                            >
                              <Play className="h-4 w-4 mr-2" />
                              Prüfung starten
                            </button>
                          </div>

                          <div className="grid grid-cols-2 gap-4">
                            <div className="flex items-center text-gray-600">
                              <Clock className="h-5 w-5 mr-2" />
                              <span>Zeitlimit: {exam.time_limit} Minuten</span>
                            </div>
                            <div className="flex items-center text-gray-600">
                              <GraduationCap className="h-5 w-5 mr-2" />
                              <span>Bestehensgrenze: {exam.passing_score}%</span>
                            </div>
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className="text-center py-12">
                        <GraduationCap className="h-12 w-12 mx-auto text-gray-400" />
                        <h3 className="mt-4 text-lg font-medium text-gray-900">
                          Keine Prüfungen verfügbar
                        </h3>
                        <p className="mt-2 text-gray-500">
                          Für dieses Gerät wurden noch keine Prüfungen erstellt.
                        </p>
                      </div>
                    )}
                  </div>
                )}

                {activeTab === 'certificates' && (
                  <div className="space-y-6">
                    {exams.map(exam => (
                      <div key={exam.id} className="bg-white border rounded-lg p-6">
                        <h3 className="text-lg font-medium text-gray-900 mb-4">
                          Zertifikat für {exam.title}
                        </h3>
                        <CertificateRequestButton
                          examId={exam.id}
                          deviceModelId={selectedModel!.id}
                        />
                      </div>
                    ))}
                    {exams.length === 0 && (
                      <div className="text-center py-12">
                        <Award className="h-12 w-12 mx-auto text-gray-400" />
                        <h3 className="mt-4 text-lg font-medium text-gray-900">
                          Keine Zertifikate verfügbar
                        </h3>
                        <p className="mt-2 text-gray-500">
                          Für dieses Gerät wurden noch keine Prüfungen erstellt.
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          </>
        ) : (
          <div className="text-center py-12">
            <Activity className="h-12 w-12 mx-auto text-gray-400" />
            <h3 className="mt-4 text-lg font-medium text-gray-900">
              Wählen Sie ein Gerät aus
            </h3>
            <p className="mt-2 text-gray-500">
              Bitte wählen Sie ein Gerät aus der linken Navigation aus.
            </p>
          </div>
        )}
      </div>

      {selectedExam && isExamSessionActive && (
        <ExamSession
          examId={selectedExam}
          onClose={() => {
            setSelectedExam(null);
            setIsExamSessionActive(false);
            loadModelData(selectedModel!.id);
          }}
        />
      )}

      {isUploadModalOpen && selectedModel && (
        <DocumentUploadModal
          isOpen={isUploadModalOpen}
          onClose={() => setIsUploadModalOpen(false)}
          deviceModelId={selectedModel.id}
          onUploadComplete={() => loadModelData(selectedModel.id)}
        />
      )}

      {selectedPresentation && (
        <PresentationViewer
          presentation={{
            id: selectedPresentation.id,
            content: selectedPresentation.content,
            title: selectedPresentation.title || selectedModel?.name
          }}
          onClose={() => setSelectedPresentation(null)}
        />
      )}
    </div>
  );
}