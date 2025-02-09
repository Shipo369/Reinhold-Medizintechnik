import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  X,
  Users,
  Clock,
  MapPin,
  Loader2,
  Trash2,
  AlertCircle,
  CheckCircle,
  XCircle,
  Clock4
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import type { Event } from '../types/events';

interface EventDetailsModalProps {
  isOpen: boolean;
  onClose: () => void;
  event: Event;
  isAdmin?: boolean;
  onRegister?: (event: Event) => void;
}

export function EventDetailsModal({ isOpen, onClose, event, isAdmin, onRegister }: EventDetailsModalProps) {
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [userRegistration, setUserRegistration] = useState<Participant | null>(null);
  const [registeredCount, setRegisteredCount] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [hasPassedExam, setHasPassedExam] = useState(false);
  const [isCheckingExam, setIsCheckingExam] = useState(true);

  useEffect(() => {
    if (isOpen) {
      loadParticipants();
      checkUserRegistration();
      checkExamStatus();
    }
  }, [isOpen, event.id]);

  const checkExamStatus = async () => {
    try {
      setIsCheckingExam(true);
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      if (event.device_model_id) {
        const { data: exam, error: examError } = await supabase
          .from('module_exams')
          .select('id')
          .eq('device_model_id', event.device_model_id)
          .single();

        if (examError) {
          console.error('Error finding exam:', examError);
          return;
        }

        if (!exam) {
          setHasPassedExam(true);
          return;
        }

        const { data: examAttempts, error: attemptsError } = await supabase
          .from('exam_attempts')
          .select('passed')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .eq('exam_id', exam.id);

        if (attemptsError) throw attemptsError;

        setHasPassedExam(examAttempts?.some(attempt => attempt.passed) || false);
      } else {
        setHasPassedExam(true);
      }
    } catch (err) {
      console.error('Error checking exam status:', err);
      setError('Fehler beim Prüfen des Prüfungsstatus');
    } finally {
      setIsCheckingExam(false);
    }
  };

  const loadParticipants = async () => {
    try {
      const { data, error } = await supabase
        .from('event_participants')
        .select(`
          *,
          profile:profiles(email, full_name)
        `)
        .eq('event_id', event.id)
        .order('created_at');

      if (error) throw error;

      setParticipants(data as Participant[]);
      setRegisteredCount(data.filter(p => p.status === 'registered').length);
    } catch (err) {
      console.error('Error loading participants:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const checkUserRegistration = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('event_participants')
        .select('*')
        .eq('event_id', event.id)
        .eq('user_id', user.id);

      if (error) throw error;
      
      setUserRegistration(data && data.length > 0 ? data[0] : null);
    } catch (err) {
      console.error('Error checking registration:', err);
    }
  };

  const handleRegistration = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setError('Bitte melden Sie sich an, um sich für die Veranstaltung zu registrieren.');
        return;
      }

      if (event.device_model_id && !hasPassedExam) {
        setError('Sie müssen zuerst die Prüfung für dieses Gerät bestehen, bevor Sie an der Schulung teilnehmen können.');
        return;
      }

      if (userRegistration?.status === 'cancelled') {
        const { error } = await supabase
          .from('event_participants')
          .update({ status: 'registered' })
          .eq('id', userRegistration.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('event_participants')
          .insert([{
            event_id: event.id,
            user_id: user.id,
            status: registeredCount >= event.max_participants ? 'waitlist' : 'registered'
          }]);

        if (error) throw error;
      }

      await loadParticipants();
      await checkUserRegistration();
    } catch (err: any) {
      console.error('Error registering:', err);
      setError(err.message || 'Fehler bei der Registrierung');
    }
  };

  const handleCancellation = async () => {
    if (!userRegistration) return;

    try {
      const { error } = await supabase
        .from('event_participants')
        .update({ status: 'cancelled' })
        .eq('id', userRegistration.id);

      if (error) throw error;

      if (userRegistration.status === 'registered') {
        const waitlistParticipant = participants.find(p => p.status === 'waitlist');
        if (waitlistParticipant) {
          const { error: updateError } = await supabase
            .from('event_participants')
            .update({ status: 'registered' })
            .eq('id', waitlistParticipant.id);

          if (updateError) throw updateError;
        }
      }

      await loadParticipants();
      await checkUserRegistration();
    } catch (err: any) {
      console.error('Error cancelling:', err);
      setError(err.message || 'Fehler bei der Stornierung');
    }
  };

  const handleDeleteEvent = async () => {
    if (!isAdmin) return;

    const confirmed = window.confirm(
      'Möchten Sie diese Veranstaltung wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'
    );

    if (!confirmed) return;

    try {
      setIsLoading(true);
      const { error } = await supabase
        .from('events')
        .delete()
        .eq('id', event.id);

      if (error) throw error;

      onClose();
      window.location.reload();
    } catch (err: any) {
      console.error('Error deleting event:', err);
      setError(err.message || 'Fehler beim Löschen der Veranstaltung');
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'registered':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
            <CheckCircle className="h-3 w-3 mr-1" />
            Angemeldet
          </span>
        );
      case 'waitlist':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
            <Clock4 className="h-3 w-3 mr-1" />
            Warteliste
          </span>
        );
      case 'cancelled':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
            <XCircle className="h-3 w-3 mr-1" />
            Abgemeldet
          </span>
        );
      default:
        return null;
    }
  };

  if (!isOpen) return null;

  const availableSpots = event.max_participants - registeredCount;
  const showRegistrationSection = !userRegistration || userRegistration.status === 'cancelled';
  const isPastEvent = new Date(event.end_time) < new Date();

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full">
        <div className="flex justify-between items-center px-6 py-4 border-b">
          <h3 className="text-lg font-medium text-gray-900">
            {event.title}
          </h3>
          <div className="flex items-center space-x-2">
            {isAdmin && (
              <button
                onClick={handleDeleteEvent}
                disabled={isLoading}
                className="p-2 text-red-600 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors"
                title="Veranstaltung löschen"
              >
                <Trash2 className="h-5 w-5" />
              </button>
            )}
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-500"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        <div className="p-6">
          {error && (
            <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-md">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          <div className="space-y-4">
            <div className="flex items-center text-gray-600">
              <Clock className="h-5 w-5 mr-2" />
              <span>
                {new Date(event.start_time).toLocaleString('de-DE', {
                  weekday: 'long',
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                })}
                {' - '}
                {new Date(event.end_time).toLocaleString('de-DE', {
                  hour: '2-digit',
                  minute: '2-digit'
                })}
              </span>
            </div>

            <div className="flex items-center text-gray-600">
              <MapPin className="h-5 w-5 mr-2" />
              <span>{event.location}</span>
            </div>

            <div className="flex items-center text-gray-600">
              <Users className="h-5 w-5 mr-2" />
              <span>
                {registeredCount} von {event.max_participants} Plätzen belegt
                {availableSpots > 0 && ` (noch ${availableSpots} Plätze frei)`}
              </span>
            </div>

            {event.description && (
              <div className="mt-4 text-gray-600">
                <p>{event.description}</p>
              </div>
            )}

            {!isPastEvent && (
              <div className="mt-6">
                {isCheckingExam ? (
                  <div className="flex justify-center">
                    <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
                  </div>
                ) : showRegistrationSection ? (
                  <div className="space-y-3">
                    {event.device_model_id && !hasPassedExam && (
                      <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-md flex items-start">
                        <AlertCircle className="h-5 w-5 text-yellow-600 mt-0.5 mr-3 flex-shrink-0" />
                        <div>
                          <p className="text-sm font-medium text-yellow-800">
                            Prüfung erforderlich
                          </p>
                          <p className="mt-1 text-sm text-yellow-700">
                            Sie müssen zuerst die Prüfung für dieses Gerät bestehen, bevor Sie an der Schulung teilnehmen können.
                          </p>
                        </div>
                      </div>
                    )}
                    <button
                      onClick={handleRegistration}
                      disabled={isLoading || !hasPassedExam}
                      className="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                    >
                      {isLoading ? (
                        <>
                          <Loader2 className="animate-spin h-5 w-5 mr-2" />
                          Wird verarbeitet...
                        </>
                      ) : !hasPassedExam && event.device_model_id ? (
                        'Prüfung erforderlich'
                      ) : (
                        'An der Schulung teilnehmen'
                      )}
                    </button>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className={`text-center p-2 rounded-md ${
                      userRegistration.status === 'registered'
                        ? 'bg-green-50 text-green-700'
                        : 'bg-yellow-50 text-yellow-700'
                    }`}>
                      {userRegistration.status === 'registered'
                        ? 'Sie sind für diese Veranstaltung angemeldet'
                        : 'Sie sind auf der Warteliste'}
                    </div>
                    <button
                      onClick={handleCancellation}
                      className="w-full px-4 py-2 border border-red-300 rounded-md shadow-sm text-sm font-medium text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                    >
                      Teilnahme stornieren
                    </button>
                  </div>
                )}
              </div>
            )}

            {isAdmin && (
              <div className="mt-6">
                <h4 className="font-medium text-gray-900 mb-4">Teilnehmerliste</h4>
                {isLoading ? (
                  <div className="flex justify-center py-4">
                    <Loader2 className="animate-spin h-6 w-6 text-blue-600" />
                  </div>
                ) : participants.length > 0 ? (
                  <div className="border rounded-lg divide-y">
                    {participants.map((participant) => (
                      <div
                        key={participant.id}
                        className="p-4 flex items-center justify-between"
                      >
                        <div>
                          <p className="font-medium text-gray-900">
                            {participant.profile.full_name || participant.profile.email}
                          </p>
                          <p className="text-sm text-gray-500">
                            {participant.profile.email}
                          </p>
                        </div>
                        {getStatusBadge(participant.status)}
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-center text-gray-500 py-4">
                    Noch keine Teilnehmer
                  </p>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}