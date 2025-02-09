import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, ArrowLeft, AlertCircle, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { EventList } from '../components/EventList';
import { EventModal } from '../components/EventModal';
import { EventDetailsModal } from '../components/EventDetailsModal';
import { checkAdminStatus } from '../lib/auth';
import type { Event } from '../types/events';

export function EventManagement() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [events, setEvents] = useState<Event[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        await loadEvents();
      } catch (err) {
        console.error('Error initializing:', err);
        setError('Fehler beim Laden der Daten');
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  const loadEvents = async () => {
    try {
      const { data, error } = await supabase
        .from('events')
        .select(`
          *,
          device_model:device_models(
            id,
            name
          )
        `)
        .order('start_time', { ascending: true });

      if (error) throw error;
      setEvents(data || []);
    } catch (err) {
      console.error('Error loading events:', err);
      setError('Fehler beim Laden der Veranstaltungen');
    }
  };

  const handleEventClick = (event: Event, mode: 'edit' | 'details' = 'details') => {
    setSelectedEvent(event);
    if (isAdmin && mode === 'edit') {
      setIsModalOpen(true);
    } else {
      setIsDetailsModalOpen(true);
    }
  };

  const handleDeleteEvent = async (event: Event) => {
    try {
      setIsLoading(true);
      const { error } = await supabase
        .from('events')
        .delete()
        .eq('id', event.id);

      if (error) throw error;

      await loadEvents();
      setError('Veranstaltung wurde erfolgreich gelöscht');
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error deleting event:', err);
      setError(err.message || 'Fehler beim Löschen der Veranstaltung');
    } finally {
      setIsLoading(false);
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
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
              <h1 className="text-2xl font-bold text-gray-900">Veranstaltungen</h1>
            </div>
            {isAdmin && (
              <button
                onClick={() => {
                  setSelectedEvent(null);
                  setIsModalOpen(true);
                }}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <Plus className="h-4 w-4 mr-2" />
                Neue Veranstaltung
              </button>
            )}
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

        <EventList
          events={events}
          onEventClick={(event) => handleEventClick(event, 'details')}
          onEditClick={(event) => handleEventClick(event, 'edit')}
          isAdmin={isAdmin}
          onDeleteEvent={handleDeleteEvent}
        />

        <EventModal
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setSelectedEvent(null);
          }}
          event={selectedEvent}
          onSave={loadEvents}
        />

        {selectedEvent && (
          <EventDetailsModal
            isOpen={isDetailsModalOpen}
            onClose={() => {
              setIsDetailsModalOpen(false);
              setSelectedEvent(null);
              loadEvents();
            }}
            event={selectedEvent}
            isAdmin={isAdmin}
          />
        )}
      </div>
    </div>
  );
}