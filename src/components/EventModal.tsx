import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { X, Calendar as CalendarIcon, Clock, MapPin, Users } from 'lucide-react';
import type { Event, EventFormData } from '../types/events';
import { supabase } from '../lib/supabase';

interface EventModalProps {
  isOpen: boolean;
  onClose: () => void;
  event?: Event | null;
  onSave: () => void;
}

export function EventModal({ isOpen, onClose, event, onSave }: EventModalProps) {
  const [formData, setFormData] = useState<EventFormData>({
    title: '',
    description: '',
    start_time: '',
    end_time: '',
    location: '',
    max_participants: 10,
    device_model_id: null
  });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [deviceModels, setDeviceModels] = useState<Array<{ id: string; name: string }>>([]);

  useEffect(() => {
    if (event) {
      const startDate = new Date(event.start_time);
      const endDate = new Date(event.end_time);

      setFormData({
        title: event.title,
        description: event.description || '',
        start_time: formatDateTimeForInput(startDate),
        end_time: formatDateTimeForInput(endDate),
        location: event.location,
        max_participants: event.max_participants,
        device_model_id: event.device_model_id
      });
    } else {
      // Set default times for new events
      const now = new Date();
      const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
      
      setFormData({
        title: '',
        description: '',
        start_time: formatDateTimeForInput(now),
        end_time: formatDateTimeForInput(oneHourLater),
        location: '',
        max_participants: 10,
        device_model_id: null
      });
    }

    loadDeviceModels();
  }, [event]);

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
    }
  };

  const formatDateTimeForInput = (date: Date) => {
    return date.toISOString().slice(0, 16);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      const startTime = new Date(formData.start_time);
      const endTime = new Date(formData.end_time);

      if (endTime <= startTime) {
        throw new Error('Die Endzeit muss nach der Startzeit liegen.');
      }

      const eventData = {
        title: formData.title,
        description: formData.description,
        start_time: startTime.toISOString(),
        end_time: endTime.toISOString(),
        location: formData.location,
        max_participants: Math.max(1, Math.min(100, formData.max_participants)), // Ensure valid range
        device_model_id: formData.device_model_id
      };

      if (event) {
        const { error } = await supabase
          .from('events')
          .update(eventData)
          .eq('id', event.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('events')
          .insert([eventData]);

        if (error) throw error;
      }

      onSave();
      onClose();
    } catch (err: any) {
      console.error('Error saving event:', err);
      setError(err.message || 'Fehler beim Speichern der Veranstaltung');
    } finally {
      setIsLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full">
        <div className="flex justify-between items-center px-6 py-4 border-b">
          <h3 className="text-lg font-medium text-gray-900">
            {event ? 'Veranstaltung bearbeiten' : 'Neue Veranstaltung'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-500"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-md p-4">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          <div>
            <label htmlFor="title" className="block text-sm font-medium text-gray-700">
              Titel
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

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <label htmlFor="start_time" className="block text-sm font-medium text-gray-700">
                Startzeit
              </label>
              <div className="mt-1 relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <CalendarIcon className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="datetime-local"
                  id="start_time"
                  value={formData.start_time}
                  onChange={(e) => setFormData({ ...formData, start_time: e.target.value })}
                  className="mt-1 block w-full pl-10 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            <div>
              <label htmlFor="end_time" className="block text-sm font-medium text-gray-700">
                Endzeit
              </label>
              <div className="mt-1 relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Clock className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="datetime-local"
                  id="end_time"
                  value={formData.end_time}
                  onChange={(e) => setFormData({ ...formData, end_time: e.target.value })}
                  className="mt-1 block w-full pl-10 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>
            </div>
          </div>

          <div>
            <label htmlFor="location" className="block text-sm font-medium text-gray-700">
              Ort
            </label>
            <div className="mt-1 relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <MapPin className="h-5 w-5 text-gray-400" />
              </div>
              <input
                type="text"
                id="location"
                value={formData.location}
                onChange={(e) => setFormData({ ...formData, location: e.target.value })}
                className="mt-1 block w-full pl-10 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <label htmlFor="max_participants" className="block text-sm font-medium text-gray-700">
                Maximale Teilnehmerzahl
              </label>
              <div className="mt-1 relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Users className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="number"
                  id="max_participants"
                  min="1"
                  max="100"
                  value={formData.max_participants.toString()}
                  onChange={(e) => {
                    const value = parseInt(e.target.value);
                    if (!isNaN(value)) {
                      setFormData({ ...formData, max_participants: Math.max(1, Math.min(100, value)) });
                    }
                  }}
                  className="mt-1 block w-full pl-10 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            <div>
              <label htmlFor="device_model" className="block text-sm font-medium text-gray-700">
                Gerät (optional)
              </label>
              <select
                id="device_model"
                value={formData.device_model_id || ''}
                onChange={(e) => setFormData({ ...formData, device_model_id: e.target.value || null })}
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              >
                <option value="">Kein Gerät ausgewählt</option>
                {deviceModels.map((model) => (
                  <option key={model.id} value={model.id}>
                    {model.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

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
              disabled={isLoading}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Wird gespeichert...
                </>
              ) : (
                'Speichern'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}