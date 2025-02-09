import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Plus,
  Edit2,
  Trash2,
  AlertCircle,
  X,
  Save,
  ChevronRight,
  Settings,
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

interface Question {
  id: string;
  question: string;
  image?: File;
  imagePreview?: string;
  type: 'single' | 'multiple';
  difficulty: 'easy' | 'medium' | 'hard';
  answers: Answer[];
}

interface Answer {
  id: string;
  text: string;
  isCorrect: boolean;
}

interface ExamModalProps {
  isOpen: boolean;
  onClose: () => void;
  deviceModelId: string;
  onSave: () => void;
  exam?: {
    id: string;
    title: string;
    description: string;
    passing_score: number;
    time_limit: number;
    allowed_attempts: number;
    questions_per_exam: number;
    easy_questions_percentage: number;
    medium_questions_percentage: number;
    hard_questions_percentage: number;
  } | null;
}

export function ExamModal({ isOpen, onClose, deviceModelId, onSave, exam }: ExamModalProps) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    passing_score: 70,
    time_limit: 60,
    allowed_attempts: 3,
    questions_per_exam: 10,
    easy_questions_percentage: 33,
    medium_questions_percentage: 34,
    hard_questions_percentage: 33
  });
  const [questions, setQuestions] = useState<Question[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (exam) {
      setFormData({
        title: exam.title,
        description: exam.description || '',
        passing_score: exam.passing_score,
        time_limit: exam.time_limit,
        allowed_attempts: exam.allowed_attempts,
        questions_per_exam: exam.questions_per_exam || 10,
        easy_questions_percentage: exam.easy_questions_percentage || 33,
        medium_questions_percentage: exam.medium_questions_percentage || 34,
        hard_questions_percentage: exam.hard_questions_percentage || 33
      });
      loadExamQuestions(exam.id);
    } else {
      setFormData({
        title: '',
        description: '',
        passing_score: 70,
        time_limit: 60,
        allowed_attempts: 3,
        questions_per_exam: 10,
        easy_questions_percentage: 33,
        medium_questions_percentage: 34,
        hard_questions_percentage: 33
      });
      setQuestions([]);
    }
  }, [exam]);

  const loadExamQuestions = async (examId: string) => {
    try {
      setIsLoading(true);
      setError(null);

      const { data: questionsData, error: questionsError } = await supabase
        .from('exam_questions')
        .select(`
          *,
          answers:exam_answers(
            id,
            answer,
            is_correct,
            order_index
          )
        `)
        .eq('exam_id', examId)
        .order('order_index');

      if (questionsError) throw questionsError;

      if (!questionsData) {
        setQuestions([]);
        return;
      }

      const transformedQuestions = await Promise.all(questionsData.map(async (q) => {
        let imagePreview = undefined;
        if (q.image_path) {
          const { data: { publicUrl } } = supabase.storage
            .from('exam-images')
            .getPublicUrl(q.image_path);
          imagePreview = publicUrl;
        }

        return {
          id: q.id,
          question: q.question,
          type: q.question_type,
          difficulty: q.difficulty || 'medium',
          image: undefined,
          imagePreview,
          answers: q.answers.sort((a: any, b: any) => a.order_index - b.order_index).map((a: any) => ({
            id: a.id,
            text: a.answer,
            isCorrect: a.is_correct
          }))
        };
      }));

      setQuestions(transformedQuestions);
    } catch (err) {
      console.error('Error loading exam questions:', err);
      setError('Fehler beim Laden der Prüfungsfragen');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePercentageChange = (field: string, value: number) => {
    // Ensure value is between 0 and 100
    const newValue = Math.max(0, Math.min(100, value));
    
    // Create new form data with updated value
    const newFormData = { ...formData, [field]: newValue };
    
    // Calculate total of all percentages
    const total = (field === 'easy_questions_percentage' ? newValue : newFormData.easy_questions_percentage) +
                 (field === 'medium_questions_percentage' ? newValue : newFormData.medium_questions_percentage) +
                 (field === 'hard_questions_percentage' ? newValue : newFormData.hard_questions_percentage);
    
    // Show error if total is not 100
    if (total !== 100) {
      setError('Die Summe der Prozentsätze muss 100% ergeben.');
    } else {
      setError(null);
    }
    
    setFormData(newFormData);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    
    // Validate percentages sum to 100
    const totalPercentage = formData.easy_questions_percentage + 
                          formData.medium_questions_percentage + 
                          formData.hard_questions_percentage;
                          
    if (totalPercentage !== 100) {
      setError('Die Summe der Prozentsätze muss 100% ergeben.');
      return;
    }

    try {
      setIsSaving(true);

      // Validate questions
      if (questions.length === 0) {
        throw new Error('Bitte fügen Sie mindestens eine Frage hinzu.');
      }

      for (const question of questions) {
        if (!question.question.trim()) {
          throw new Error('Bitte geben Sie für jede Frage einen Text ein.');
        }
        if (question.answers.length < 2) {
          throw new Error('Jede Frage muss mindestens zwei Antworten haben.');
        }
        if (!question.answers.some(a => a.isCorrect)) {
          throw new Error('Jede Frage muss mindestens eine richtige Antwort haben.');
        }
        for (const answer of question.answers) {
          if (!answer.text.trim()) {
            throw new Error('Bitte geben Sie für jede Antwort einen Text ein.');
          }
        }
      }

      let examId: string;

      if (exam) {
        // Update existing exam
        const { error: examError } = await supabase
          .from('module_exams')
          .update({
            title: formData.title,
            description: formData.description,
            passing_score: formData.passing_score,
            time_limit: formData.time_limit,
            allowed_attempts: formData.allowed_attempts,
            questions_per_exam: formData.questions_per_exam,
            easy_questions_percentage: formData.easy_questions_percentage,
            medium_questions_percentage: formData.medium_questions_percentage,
            hard_questions_percentage: formData.hard_questions_percentage
          })
          .eq('id', exam.id);

        if (examError) throw examError;
        examId = exam.id;

        // Delete existing questions and answers
        const { error: deleteError } = await supabase
          .from('exam_questions')
          .delete()
          .eq('exam_id', examId);

        if (deleteError) throw deleteError;
      } else {
        // Create new exam
        const { data: examData, error: examError } = await supabase
          .from('module_exams')
          .insert([{
            device_model_id: deviceModelId,
            title: formData.title,
            description: formData.description,
            passing_score: formData.passing_score,
            time_limit: formData.time_limit,
            allowed_attempts: formData.allowed_attempts,
            questions_per_exam: formData.questions_per_exam,
            easy_questions_percentage: formData.easy_questions_percentage,
            medium_questions_percentage: formData.medium_questions_percentage,
            hard_questions_percentage: formData.hard_questions_percentage
          }])
          .select()
          .single();

        if (examError) throw examError;
        if (!examData) throw new Error('Keine Exam-ID zurückgegeben');
        examId = examData.id;
      }

      // Create questions and answers
      for (const [index, question] of questions.entries()) {
        let imagePath = null;

        if (question.image) {
          const fileExt = question.image.name.split('.').pop();
          const fileName = `${Math.random().toString(36).substring(2)}.${fileExt}`;
          const filePath = `exam-images/${examId}/${fileName}`;

          const { error: uploadError } = await supabase.storage
            .from('exam-images')
            .upload(filePath, question.image);

          if (uploadError) throw uploadError;
          imagePath = filePath;
        }

        // Create question
        const { data: questionData, error: questionError } = await supabase
          .from('exam_questions')
          .insert([{
            exam_id: examId,
            question: question.question,
            image_path: imagePath,
            question_type: question.type,
            difficulty: question.difficulty,
            points: 1,
            order_index: index
          }])
          .select()
          .single();

        if (questionError) throw questionError;
        if (!questionData) throw new Error('Keine Question-ID zurückgegeben');

        // Create answers
        const { error: answersError } = await supabase
          .from('exam_answers')
          .insert(
            question.answers.map((answer, answerIndex) => ({
              question_id: questionData.id,
              answer: answer.text,
              is_correct: answer.isCorrect,
              order_index: answerIndex
            }))
          );

        if (answersError) throw answersError;
      }

      onSave();
      onClose();
    } catch (err: any) {
      console.error('Error saving exam:', err);
      setError(err.message || 'Fehler beim Speichern der Prüfung');
      setIsSaving(false);
    }
  };

  const generateId = () => Math.random().toString(36).substr(2, 9);

  const handleAddQuestion = () => {
    const newQuestion: Question = {
      id: generateId(),
      question: '',
      type: 'single',
      difficulty: 'medium',
      answers: [
        { id: generateId(), text: '', isCorrect: true },
        { id: generateId(), text: '', isCorrect: false }
      ]
    };
    setQuestions([...questions, newQuestion]);
  };

  const handleRemoveQuestion = (questionId: string) => {
    setQuestions(questions.filter(q => q.id !== questionId));
  };

  const handleQuestionChange = (questionId: string, field: keyof Question, value: any) => {
    setQuestions(questions.map(q => {
      if (q.id === questionId) {
        return { ...q, [field]: value };
      }
      return q;
    }));
  };

  const handleAddAnswer = (questionId: string) => {
    setQuestions(questions.map(q => {
      if (q.id === questionId) {
        return {
          ...q,
          answers: [...q.answers, { id: generateId(), text: '', isCorrect: false }]
        };
      }
      return q;
    }));
  };

  const handleRemoveAnswer = (questionId: string, answerId: string) => {
    setQuestions(questions.map(q => {
      if (q.id === questionId) {
        return {
          ...q,
          answers: q.answers.filter(a => a.id !== answerId)
        };
      }
      return q;
    }));
  };

  const handleAnswerChange = (questionId: string, answerId: string, field: keyof Answer, value: any) => {
    setQuestions(questions.map(q => {
      if (q.id === questionId) {
        return {
          ...q,
          answers: q.answers.map(a => {
            if (a.id === answerId) {
              if (field === 'isCorrect' && q.type === 'single') {
                // For single choice, uncheck all other answers
                return { ...a, isCorrect: value };
              }
              return { ...a, [field]: value };
            }
            if (field === 'isCorrect' && q.type === 'single' && value === true) {
              return { ...a, isCorrect: false };
            }
            return a;
          })
        };
      }
      return q;
    }));
  };

  const handleImageUpload = async (questionId: string, file: File) => {
    try {
      const reader = new FileReader();
      reader.onloadend = () => {
        handleQuestionChange(questionId, 'imagePreview', reader.result);
      };
      reader.readAsDataURL(file);
      handleQuestionChange(questionId, 'image', file);
    } catch (err) {
      console.error('Error handling image:', err);
      setError('Fehler beim Verarbeiten des Bildes');
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] flex flex-col"
      >
        <div className="flex justify-between items-center px-6 py-4 border-b">
          <h3 className="text-lg font-medium text-gray-900">
            {exam ? 'Prüfung bearbeiten' : 'Neue Prüfung'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto">
          <div className="p-6 space-y-6">
            {error && (
              <div className="mb-4 p-4 bg-red-50 text-red-700 rounded-lg flex items-center">
                <AlertCircle className="h-5 w-5 mr-2" />
                <span>{error}</span>
              </div>
            )}

            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700">
                Titel<span className="text-red-500">*</span>
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
                Beschreibung
              </label>
              <textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={3}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>

            <div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
              <div>
                <label htmlFor="passing_score" className="block text-sm font-medium text-gray-700">
                  Bestehensgrenze (in %)<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  id="passing_score"
                  min="1"
                  max="100"
                  value={formData.passing_score}
                  onChange={(e) => setFormData({ ...formData, passing_score: parseInt(e.target.value) })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="time_limit" className="block text-sm font-medium text-gray-700">
                  Zeitlimit (in Minuten)<span className="text-red-500">*</span>
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Clock className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    type="number"
                    id="time_limit"
                    min="1"
                    value={formData.time_limit}
                    onChange={(e) => setFormData({ ...formData, time_limit: parseInt(e.target.value) })}
                    className="block w-full pl-10 rounded-md border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>
              </div>

              <div>
                <label htmlFor="allowed_attempts" className="block text-sm font-medium text-gray-700">
                  Maximale Versuche<span className="text-red-500">*</span>
                </label>
                <div className="mt-1 relative rounded-md shadow-sm">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Users className="h-5 w-5 text-gray-400" />
                  </div>
                  <input
                    type="number"
                    id="allowed_attempts"
                    min="1"
                    value={formData.allowed_attempts}
                    onChange={(e) => setFormData({ ...formData, allowed_attempts: parseInt(e.target.value) })}
                    className="block w-full pl-10 rounded-md border-gray-300 focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-6 sm:grid-cols-4">
              <div>
                <label htmlFor="questions_per_exam" className="block text-sm font-medium text-gray-700">
                  Fragen pro Prüfung<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  id="questions_per_exam"
                  min="1"
                  value={formData.questions_per_exam}
                  onChange={(e) => setFormData({ ...formData, questions_per_exam: parseInt(e.target.value) })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="easy_questions_percentage" className="block text-sm font-medium text-gray-700">
                  Leichte Fragen (%)<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  id="easy_questions_percentage"
                  min="0"
                  max="100"
                  value={formData.easy_questions_percentage}
                  onChange={(e) => handlePercentageChange('easy_questions_percentage', parseInt(e.target.value))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="medium_questions_percentage" className="block text-sm font-medium text-gray-700">
                  Mittlere Fragen (%)<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  id="medium_questions_percentage"
                  min="0"
                  max="100"
                  value={formData.medium_questions_percentage}
                  onChange={(e) => handlePercentageChange('medium_questions_percentage', parseInt(e.target.value))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>

              <div>
                <label htmlFor="hard_questions_percentage" className="block text-sm font-medium text-gray-700">
                  Schwere Fragen (%)<span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  id="hard_questions_percentage"
                  min="0"
                  max="100"
                  value={formData.hard_questions_percentage}
                  onChange={(e) => handlePercentageChange('hard_questions_percentage', parseInt(e.target.value))}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-medium text-gray-900">Fragen</h3>
                <button
                  type="button"
                  onClick={handleAddQuestion}
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Frage hinzufügen
                </button>
              </div>

              {questions.map((question, questionIndex) => (
                <div
                  key={question.id}
                  className="bg-gray-50 rounded-lg p-4 space-y-4"
                >
                  <div className="flex justify-between items-start">
                    <h4 className="text-sm font-medium text-gray-900">
                      Frage {questionIndex + 1}
                    </h4>
                    <button
                      type="button"
                      onClick={() => handleRemoveQuestion(question.id)}
                      className="p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>

                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Fragetext<span className="text-red-500">*</span>
                      </label>
                      <input
                        type="text"
                        value={question.question}
                        onChange={(e) => handleQuestionChange(question.id, 'question', e.target.value)}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        required
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700">
                        Bild (optional)
                      </label>
                      <div className="mt-1 flex items-center space-x-4">
                        <label className="cursor-pointer inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                          <Upload className="h-4 w-4 mr-2" />
                          Bild auswählen
                          <input
                            type="file"
                            className="hidden"
                            accept="image/*"
                            onChange={(e) => {
                              const file = e.target.files?.[0];
                              if (file) handleImageUpload(question.id, file);
                            }}
                          />
                        </label>
                        {question.imagePreview && (
                          <div className="relative">
                            <img
                              src={question.imagePreview}
                              alt="Preview"
                              className="h-16 w-16 object-cover rounded-lg"
                            />
                            <button
                              type="button"
                              onClick={() => {
                                handleQuestionChange(question.id, 'image', undefined);
                                handleQuestionChange(question.id, 'imagePreview', undefined);
                              }}
                              className="absolute -top-2 -right-2 p-1 bg-red-100 rounded-full text-red-600 hover:bg-red-200"
                            >
                              <X className="h-4 w-4" />
                            </button>
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                      <div>
                        <label className="block text-sm font-medium text-gray-700">
                          Antworttyp
                        </label>
                        <select
                          value={question.type}
                          onChange={(e) => handleQuestionChange(question.id, 'type', e.target.value)}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        >
                          <option value="single">Einzelauswahl</option>
                          <option value="multiple">Mehrfachauswahl</option>
                        </select>
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-gray-700">
                          Schwierigkeitsgrad
                        </label>
                        <select
                          value={question.difficulty}
                          onChange={(e) => handleQuestionChange(question.id, 'difficulty', e.target.value)}
                          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        >
                          <option value="easy">Leicht</option>
                          <option value="medium">Mittel</option>
                          <option value="hard">Schwer</option>
                        </select>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <label className="block text-sm font-medium text-gray-700">
                        Antworten
                      </label>
                      {question.answers.map((answer, answerIndex) => (
                        <div key={answer.id} className="flex items-center space-x-2">
                          <input
                            type={question.type === 'single' ? 'radio' : 'checkbox'}
                            checked={answer.isCorrect}
                            onChange={(e) => handleAnswerChange(question.id, answer.id, 'isCorrect', e.target.checked)}
                            className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300"
                          />
                          <input
                            type="text"
                            value={answer.text}
                            onChange={(e) => handleAnswerChange(question.id, answer.id, 'text', e.target.value)}
                            placeholder={`Antwort ${answerIndex + 1}`}
                            className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                            required
                          />
                          {question.answers.length > 2 && (
                            <button
                              type="button"
                              onClick={() => handleRemoveAnswer(question.id, answer.id)}
                              className="p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          )}
                        </div>
                      ))}
                      <button
                        type="button"
                        onClick={() => handleAddAnswer(question.id)}
                        className="mt-2 inline-flex items-center px-2 py-1 border border-transparent text-sm font-medium rounded-md text-blue-700 bg-blue-100 hover:bg-blue-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                      >
                        <Plus className="h-4 w-4 mr-1" />
                        Antwort hinzufügen
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="sticky bottom-0 bg-white px -6 py-4 border-t">
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Abbrechen
              </button>
              <button
                type="submit"
                disabled={isLoading || isSaving || questions.length === 0}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {isSaving ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                    Wird gespeichert...
                  </>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    Speichern
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </motion.div>
    </div>
  );
}