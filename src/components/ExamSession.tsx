import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Clock, ChevronLeft, ChevronRight, X, AlertCircle, CheckCircle, XCircle, Trophy } from 'lucide-react';
import Confetti from 'react-confetti';
import { supabase } from '../lib/supabase';

interface ExamSessionProps {
  examId: string;
  onClose: () => void;
}

interface Question {
  id: string;
  question: string;
  question_type: 'single' | 'multiple';
  difficulty: 'easy' | 'medium' | 'hard';
  image_path: string | null;
  answers: Answer[];
}

interface Answer {
  id: string;
  answer: string;
  is_correct: boolean;
}

interface ExamDetails {
  title: string;
  description: string;
  time_limit: number;
  passing_score: number;
  device_model_id: string;
}

export function ExamSession({ examId, onClose }: ExamSessionProps) {
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [examDetails, setExamDetails] = useState<ExamDetails | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [selectedAnswers, setSelectedAnswers] = useState<Record<string, string[]>>({});
  const [timeRemaining, setTimeRemaining] = useState<number | null>(null);
  const [attemptId, setAttemptId] = useState<string | null>(null);
  const [examCompleted, setExamCompleted] = useState(false);
  const [questionResults, setQuestionResults] = useState<Record<string, boolean>>({});
  const [showConfetti, setShowConfetti] = useState(false);
  const [score, setScore] = useState(0);

  useEffect(() => {
    loadExam();
    
    // Cleanup function for early termination
    return () => {
      if (attemptId && !examCompleted) {
        handleEarlyTermination();
      }
    };
  }, [examId]);

  useEffect(() => {
    if (timeRemaining === null || timeRemaining <= 0) return;

    const timer = setInterval(() => {
      setTimeRemaining(prev => {
        if (prev === null || prev <= 0) {
          clearInterval(timer);
          handleSubmit();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [timeRemaining]);

  const loadExam = async () => {
    try {
      setError(null);
      
      // Get user ID
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Nicht eingeloggt');

      // Load exam details
      const { data: examData, error: examError } = await supabase
        .from('module_exams')
        .select('*')
        .eq('id', examId)
        .single();

      if (examError) throw examError;
      setExamDetails(examData);
      setTimeRemaining(examData.time_limit * 60);

      // Create exam attempt first
      const { data: attemptData, error: attemptError } = await supabase
        .from('exam_attempts')
        .insert([{
          exam_id: examId,
          user_id: user.id,
          score: 0,
          passed: false,
          status: 'active'
        }])
        .select()
        .single();

      if (attemptError) throw attemptError;
      setAttemptId(attemptData.id);

      // Get random questions for this exam
      const { data: questionsData, error: questionsError } = await supabase
        .rpc('get_random_exam_questions', { 
          p_exam_id: examId
        });

      if (questionsError) throw questionsError;

      // Transform questions data
      const transformedQuestions = questionsData.map(q => ({
        id: q.question_id,
        question: q.question_text,
        question_type: q.question_type,
        difficulty: q.difficulty,
        image_path: q.image_path,
        answers: q.answers
      }));

      setQuestions(transformedQuestions);
      setCurrentQuestionIndex(0);
    } catch (err: any) {
      console.error('Error loading exam:', err);
      setError(err.message || 'Fehler beim Laden der Prüfung');
    } finally {
      setIsLoading(false);
    }
  };

  const handleEarlyTermination = async () => {
    if (!attemptId) return;

    try {
      const { error: updateError } = await supabase
        .from('exam_attempts')
        .update({
          score: 0,
          passed: false,
          completed_at: new Date().toISOString(),
          answers: selectedAnswers,
          status: 'active'
        })
        .eq('id', attemptId);

      if (updateError) throw updateError;
    } catch (err) {
      console.error('Error handling early termination:', err);
    }
  };

  const handleAnswerSelect = (answerId: string) => {
    const currentQuestion = questions[currentQuestionIndex];
    if (!currentQuestion) return;

    setSelectedAnswers(prev => {
      const questionId = currentQuestion.id;
      const currentAnswers = prev[questionId] || [];

      if (currentQuestion.question_type === 'single') {
        return {
          ...prev,
          [questionId]: [answerId]
        };
      } else {
        const newAnswers = currentAnswers.includes(answerId)
          ? currentAnswers.filter(id => id !== answerId)
          : [...currentAnswers, answerId];
        return {
          ...prev,
          [questionId]: newAnswers
        };
      }
    });
  };

  const handleSubmit = async () => {
    if (!attemptId || !examDetails) return;

    try {
      setError(null);
      setIsLoading(true);

      // Calculate score and track correct/incorrect answers
      let correctCount = 0;
      const results: Record<string, boolean> = {};

      questions.forEach(question => {
        const userAnswers = selectedAnswers[question.id] || [];
        const correctAnswers = question.answers.filter(a => a.is_correct);

        let isCorrect = false;
        if (question.question_type === 'single') {
          isCorrect = userAnswers.length === 1 && 
                     correctAnswers.some(a => a.id === userAnswers[0]);
        } else {
          const correctIds = new Set(correctAnswers.map(a => a.id));
          const userIds = new Set(userAnswers);
          isCorrect = correctIds.size === userIds.size && 
                     [...correctIds].every(id => userIds.has(id));
        }

        results[question.id] = isCorrect;
        if (isCorrect) correctCount++;
      });

      setQuestionResults(results);

      // Calculate final score as percentage
      const finalScore = questions.length > 0 
        ? Math.round((correctCount / questions.length) * 100) 
        : 0;
        
      setScore(finalScore);
      const passed = finalScore >= examDetails.passing_score;

      // Update attempt
      const { error: updateError } = await supabase
        .from('exam_attempts')
        .update({
          score: finalScore,
          passed,
          completed_at: new Date().toISOString(),
          answers: selectedAnswers,
          status: 'active'
        })
        .eq('id', attemptId);

      if (updateError) throw updateError;

      // Show results and confetti if passed
      setExamCompleted(true);
      if (passed) {
        setShowConfetti(true);
        setTimeout(() => setShowConfetti(false), 15000);

        // Automatisch Zertifikat anfordern wenn bestanden
        const { data: { user } } = await supabase.auth.getUser();
        if (user && examDetails.device_model_id) {
          // Atomare Einfügung mit ON CONFLICT DO NOTHING
          const { error: insertError } = await supabase
            .from('certificate_requests')
            .insert([{
              user_id: user.id,
              exam_id: examId,
              device_model_id: examDetails.device_model_id,
              status: 'pending'
            }], {
              onConflict: 'user_id,exam_id,device_model_id',
              ignoreDuplicates: true
            });

          if (insertError) {
            console.error('Error requesting certificate:', insertError);
          }
        }
      }
    } catch (err: any) {
      console.error('Error submitting exam:', err);
      setError(err.message || 'Fehler beim Speichern der Prüfung');
    } finally {
      setIsLoading(false);
    }
  };

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  if (isLoading) {
    return (
      <div className="fixed inset-0 bg-white z-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const currentQuestion = questions[currentQuestionIndex];

  return (
    <div className="fixed inset-0 bg-white z-50 flex flex-col">
      <div className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <h2 className="text-lg font-medium text-gray-900">
          {examDetails?.title}
        </h2>
        {timeRemaining !== null && (
          <div className={`flex items-center ${
            timeRemaining < 300 ? 'text-red-600' : 'text-gray-600'
          }`}>
            <Clock className="h-5 w-5 mr-1" />
            <span className="font-medium">{formatTime(timeRemaining)}</span>
          </div>
        )}
        <button
          onClick={() => {
            if (window.confirm('Möchten Sie die Prüfung wirklich abbrechen? Dies wird als nicht bestandener Versuch gewertet.')) {
              handleSubmit();
              onClose();
            }
          }}
          className="text-gray-400 hover:text-gray-500"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-6">
        {error && (
          <div className="mb-6 p-4 bg-red-50 text-red-700 rounded-lg flex items-center">
            <AlertCircle className="h-5 w-5 mr-2" />
            {error}
          </div>
        )}

        <div className="max-w-3xl mx-auto">
          <div className="mb-6">
            <div className="flex justify-between items-center mb-2">
              <span className="text-sm text-gray-500">
                Frage {currentQuestionIndex + 1} von {questions.length} ({questions.length} Fragen insgesamt)
              </span>
              <span className="text-sm text-gray-500">
                {currentQuestion?.question_type === 'multiple' ? 'Mehrfachauswahl' : 'Einzelauswahl'}
              </span>
            </div>
            <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
              <div
                className="h-full bg-blue-600 transition-all duration-300"
                style={{ width: `${((currentQuestionIndex + 1) / questions.length) * 100}%` }}
              />
            </div>
          </div>

          {currentQuestion && (
            <div className="space-y-6">
              <h3 className="text-lg font-medium text-gray-900">
                {currentQuestion.question}
              </h3>

              {currentQuestion.image_path && (
                <img
                  src={supabase.storage.from('exam-images').getPublicUrl(currentQuestion.image_path).data.publicUrl}
                  alt="Question"
                  className="max-w-full h-auto rounded-lg shadow-sm"
                />
              )}

              <div className="space-y-3">
                {currentQuestion.answers.map((answer) => {
                  const isSelected = (selectedAnswers[currentQuestion.id] || []).includes(answer.id);
                  return (
                    <button
                      key={answer.id}
                      onClick={() => handleAnswerSelect(answer.id)}
                      className={`w-full p-4 text-left rounded-lg border-2 transition-colors ${
                        isSelected
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="flex items-center">
                        <div className={`flex-shrink-0 w-5 h-5 border-2 rounded-${
                          currentQuestion.question_type === 'single' ? 'full' : 'md'
                        } mr-3 ${
                          isSelected
                            ? 'border-blue-500 bg-blue-500'
                            : 'border-gray-300'
                        }`}>
                          {isSelected && (
                            <svg className="w-full h-full text-white" viewBox="0 0 16 16">
                              <path
                                fill="currentColor"
                                d="M13.854 3.646a.5.5 0 0 1 0 .708l-7 7a.5.5 0 0 1-.708 0l-3.5-3.5a.5.5 0 1 1 .708-.708L6.5 10.293l6.646-6.647a.5.5 0 0 1 .708 0z"
                              />
                            </svg>
                          )}
                        </div>
                        <span className="text-gray-900">{answer.answer}</span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="bg-white border-t px-6 py-4 flex justify-between">
        <button
          onClick={() => setCurrentQuestionIndex(prev => Math.max(0, prev - 1))}
          disabled={currentQuestionIndex === 0}
          className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
        >
          <ChevronLeft className="h-5 w-5 mr-2" />
          Zurück
        </button>

        {currentQuestionIndex === questions.length - 1 ? (
          <button
            onClick={handleSubmit}
            disabled={isLoading}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
          >
            {isLoading ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Wird ausgewertet...
              </div>
            ) : (
              'Prüfung abschließen'
            )}
          </button>
        ) : (
          <button
            onClick={() => setCurrentQuestionIndex(prev => Math.min(questions.length - 1, prev + 1))}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            Weiter
            <ChevronRight className="h-5 w-5 ml-2" />
          </button>
        )}
      </div>

      {examCompleted && (
        <div className="fixed inset-0 bg-white z-50 flex flex-col">
          {showConfetti && <Confetti />}
          
          <div className="bg-white border-b px-6 py-4 flex items-center justify-between">
            <h2 className="text-lg font-medium text-gray-900">Prüfungsergebnis</h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-500"
            >
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto">
            <div className="max-w-3xl mx-auto p-6">
              {/* Result Header */}
              <div className={`p-8 rounded-lg text-center mb-8 ${
                score >= (examDetails?.passing_score || 0) ? 'bg-green-50' : 'bg-red-50'
              }`}>
                <div className={`inline-flex items-center justify-center w-16 h-16 rounded-full mb-4 ${
                  score >= (examDetails?.passing_score || 0) ? 'bg-yellow-100' : 'bg-red-100'
                }`}>
                  {score >= (examDetails?.passing_score || 0) ? (
                    <Trophy className="h-8 w-8 text-yellow-600" />
                  ) : (
                    <XCircle className="h-8 w-8 text-red-600" />
                  )}
                </div>
                
                <h3 className={`text-2xl font-bold mb-2 ${
                  score >= (examDetails?.passing_score || 0) ? 'text-green-800' : 'text-red-800'
                }`}>
                  {score >= (examDetails?.passing_score || 0) ? 'Herzlichen Glückwunsch!' : 'Nicht bestanden'}
                </h3>
                
                <div className="text-4xl font-bold mb-4">
                  {score}%
                </div>
                
                <p className={`text-lg ${score >= (examDetails?.passing_score || 0) ? 'text-green-700' : 'text-red-700'}`}>
                  {score >= (examDetails?.passing_score || 0)
                    ? 'Sie haben die Prüfung bestanden!'
                    : `Die Mindestpunktzahl von ${examDetails?.passing_score}% wurde nicht erreicht.`
                  }
                </p>
              </div>

              {/* Question Results */}
              <div className="space-y-6">
                <h4 className="text-lg font-medium text-gray-900 mb-4">Ergebnisübersicht</h4>
                {questions.map((question, index) => (
                  <div
                    key={question.id}
                    className={`p-4 rounded-lg border ${
                      questionResults[question.id]
                        ? 'bg-green-50 border-green-200'
                        : 'bg-red-50 border-red-200'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <span className="text-sm font-medium mr-2">Frage {index + 1}</span>
                        {questionResults[question.id] ? (
                          <CheckCircle className="h-5 w-5 text-green-600" />
                        ) : (
                          <XCircle className="h-5 w-5 text-red-600" />
                        )}
                      </div>
                      <span className={`text-sm font-medium ${
                        questionResults[question.id] ? 'text-green-600' : 'text-red-600'
                      }`}>
                        {questionResults[question.id] ? 'Richtig' : 'Falsch'}
                      </span>
                    </div>
                  </div>
                ))}
              </div>

              {/* Action Buttons */}
              <div className="mt-8 flex justify-end space-x-4">
                <button
                  onClick={onClose}
                  className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  Schließen
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}