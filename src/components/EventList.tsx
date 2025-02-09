import React from 'react';
import { Clock, MapPin, Users, Laptop, Trash2, Edit2 } from 'lucide-react';
import type { Event } from '../types/events';

interface EventListProps {
  events: Event[];
  onEventClick: (event: Event) => void;
  onEditClick: (event: Event) => void;
  isAdmin?: boolean;
  onDeleteEvent?: (event: Event) => void;
}

export function EventList({ events, onEventClick, onEditClick, isAdmin, onDeleteEvent }: EventListProps) {
  const sortedEvents = [...events].sort((a, b) => 
    new Date(a.start_time).getTime() - new Date(b.start_time).getTime()
  );

  const isUpcoming = (event: Event) => {
    return new Date(event.end_time) >= new Date();
  };

  const upcomingEvents = sortedEvents.filter(isUpcoming);
  const pastEvents = sortedEvents.filter(event => !isUpcoming(event));

  const handleDelete = async (event: Event, e: React.MouseEvent) => {
    e.stopPropagation();
    if (!onDeleteEvent) return;

    const confirmed = window.confirm(
      'Möchten Sie diese Veranstaltung wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'
    );

    if (confirmed) {
      onDeleteEvent(event);
    }
  };

  return (
    <div className="space-y-8">
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Kommende Veranstaltungen</h3>
        <div className="space-y-4">
          {upcomingEvents.length > 0 ? (
            upcomingEvents.map((event) => (
              <div
                key={event.id}
                className="bg-white border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer relative group"
                onClick={() => onEventClick(event)}
              >
                <h4 className="text-lg font-medium text-gray-900">{event.title}</h4>
                
                <div className="mt-3 space-y-2">
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
                    <span>Max. {event.max_participants} Teilnehmer</span>
                  </div>

                  {event.device_model_id && (
                    <div className="flex items-center text-gray-600">
                      <Laptop className="h-5 w-5 mr-2" />
                      <span>Gerät: {event.device_model?.name || 'Wird geladen...'}</span>
                    </div>
                  )}
                </div>

                {event.description && (
                  <p className="mt-3 text-gray-600 text-sm">{event.description}</p>
                )}

                {isAdmin && (
                  <div className="absolute top-4 right-4 flex space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onEditClick(event);
                      }}
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg"
                      title="Veranstaltung bearbeiten"
                    >
                      <Edit2 className="h-5 w-5" />
                    </button>
                    <button
                      onClick={(e) => handleDelete(event, e)}
                      className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg"
                      title="Veranstaltung löschen"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                )}

                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onEventClick(event);
                  }}
                  className="mt-4 w-full inline-flex justify-center items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  An der Schulung teilnehmen
                </button>
              </div>
            ))
          ) : (
            <p className="text-center text-gray-500 py-8">
              Keine kommenden Veranstaltungen
            </p>
          )}
        </div>
      </div>

      {pastEvents.length > 0 && (
        <div>
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Vergangene Veranstaltungen</h3>
          <div className="space-y-4">
            {pastEvents.map((event) => (
              <div
                key={event.id}
                className="bg-gray-50 border rounded-lg p-4 relative group"
                onClick={() => onEventClick(event)}
              >
                <h4 className="text-lg font-medium text-gray-700">{event.title}</h4>
                
                <div className="mt-3 space-y-2">
                  <div className="flex items-center text-gray-500">
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
                    </span>
                  </div>

                  <div className="flex items-center text-gray-500">
                    <MapPin className="h-5 w-5 mr-2" />
                    <span>{event.location}</span>
                  </div>

                  {event.device_model_id && (
                    <div className="flex items-center text-gray-500">
                      <Laptop className="h-5 w-5 mr-2" />
                      <span>Gerät: {event.device_model?.name || 'Wird geladen...'}</span>
                    </div>
                  )}
                </div>

                {isAdmin && (
                  <div className="absolute top-4 right-4 flex space-x-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onEditClick(event);
                      }}
                      className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg"
                      title="Veranstaltung bearbeiten"
                    >
                      <Edit2 className="h-5 w-5" />
                    </button>
                    <button
                      onClick={(e) => handleDelete(event, e)}
                      className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg"
                      title="Veranstaltung löschen"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}