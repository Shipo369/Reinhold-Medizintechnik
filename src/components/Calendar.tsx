import React from 'react';
import { ChevronLeft, ChevronRight, Clock, MapPin, Users } from 'lucide-react';
import type { Event, CalendarView } from '../types/events';

interface CalendarProps {
  events: Event[];
  view: CalendarView;
  currentDate: Date;
  onDateChange: (date: Date) => void;
  onEventClick: (event: Event) => void;
  onRegister?: (event: Event) => void;
  isAdmin?: boolean;
}

export function Calendar({ events, view, currentDate, onDateChange, onEventClick, onRegister, isAdmin }: CalendarProps) {
  const formatDate = (date: Date) => {
    const options: Intl.DateTimeFormatOptions = {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    };
    return date.toLocaleDateString('de-DE', options);
  };

  const getEventsForDate = (date: Date) => {
    return events.filter(event => {
      const eventStart = new Date(event.start_time);
      const eventEnd = new Date(event.end_time);
      const currentDay = new Date(date.getFullYear(), date.getMonth(), date.getDate());
      const nextDay = new Date(currentDay);
      nextDay.setDate(nextDay.getDate() + 1);

      return currentDay >= new Date(eventStart.setHours(0,0,0,0)) && 
             currentDay < new Date(eventEnd.setHours(0,0,0,0));
    });
  };

  const isEventContinuation = (date: Date, event: Event) => {
    const eventStart = new Date(event.start_time);
    const dateStart = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    return dateStart > new Date(eventStart.setHours(0,0,0,0));
  };

  const isEventEnd = (date: Date, event: Event) => {
    const eventEnd = new Date(event.end_time);
    const dateEnd = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
    return dateEnd.getTime() === new Date(eventEnd.setHours(23,59,59,999)).getTime();
  };

  const renderMonthView = () => {
    const firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
    const lastDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0);
    
    // Adjust for Monday as first day of week
    let firstDayOfCalendar = new Date(firstDayOfMonth);
    const dayOfWeek = firstDayOfMonth.getDay();
    const diff = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
    firstDayOfCalendar.setDate(firstDayOfMonth.getDate() - diff);

    const weeks: Date[][] = [];
    let currentWeek: Date[] = [];
    let date = new Date(firstDayOfCalendar);

    while (date <= lastDayOfMonth || currentWeek.length > 0) {
      if (currentWeek.length === 7) {
        weeks.push(currentWeek);
        currentWeek = [];
      }

      currentWeek.push(new Date(date));
      date.setDate(date.getDate() + 1);

      if (date > lastDayOfMonth && currentWeek.length < 7) {
        while (currentWeek.length < 7) {
          currentWeek.push(new Date(date));
          date.setDate(date.getDate() + 1);
        }
        weeks.push(currentWeek);
        break;
      }
    }

    return (
      <div className="grid grid-cols-7 gap-px bg-gray-200">
        {weeks.map((week, weekIndex) =>
          week.map((date, dayIndex) => {
            const isCurrentMonth = date.getMonth() === currentDate.getMonth();
            const isToday = date.toDateString() === new Date().toDateString();
            const dayEvents = getEventsForDate(date);

            return (
              <div
                key={`${weekIndex}-${dayIndex}`}
                className={`min-h-[120px] bg-white ${
                  !isCurrentMonth ? 'bg-gray-50' : ''
                }`}
              >
                <div className={`p-2 ${isToday ? 'bg-blue-50' : ''}`}>
                  <span className={`text-sm ${
                    isCurrentMonth
                      ? isToday
                        ? 'text-blue-600 font-semibold'
                        : 'text-gray-900'
                      : 'text-gray-400'
                  }`}>
                    {date.getDate()}
                  </span>
                </div>
                <div className="p-1">
                  {dayEvents.map((event) => {
                    const isContinuation = isEventContinuation(date, event);
                    const isEnd = isEventEnd(date, event);
                    const eventStart = new Date(event.start_time);
                    const eventEnd = new Date(event.end_time);
                    const isMultiDay = eventStart.toDateString() !== eventEnd.toDateString();

                    return (
                      <div
                        key={event.id}
                        onClick={() => onEventClick(event)}
                        className={`mb-1 px-2 py-1 text-xs rounded-md cursor-pointer transition-colors
                          ${isMultiDay 
                            ? `bg-blue-100 text-blue-800 hover:bg-blue-200 
                               ${!isContinuation ? 'rounded-l-md' : 'rounded-l-none'} 
                               ${isEnd ? 'rounded-r-md' : 'rounded-r-none'}`
                            : 'bg-blue-100 text-blue-800 hover:bg-blue-200'
                          }`}
                      >
                        <div className="font-medium truncate">
                          {event.title}
                        </div>
                        <div className="text-blue-600 flex items-center mt-1">
                          <Clock className="h-3 w-3 mr-1" />
                          {new Date(event.start_time).toLocaleTimeString('de-DE', {
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                          {' - '}
                          {new Date(event.end_time).toLocaleTimeString('de-DE', {
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })
        )}
      </div>
    );
  };

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="flex items-center justify-between p-4 border-b">
        <h2 className="text-lg font-semibold text-gray-900">
          {formatDate(currentDate)}
        </h2>
        <div className="flex space-x-2">
          <button
            onClick={() => {
              const newDate = new Date(currentDate);
              newDate.setMonth(newDate.getMonth() - 1);
              onDateChange(newDate);
            }}
            className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <button
            onClick={() => onDateChange(new Date())}
            className="px-3 py-1 text-sm text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            Heute
          </button>
          <button
            onClick={() => {
              const newDate = new Date(currentDate);
              newDate.setMonth(newDate.getMonth() + 1);
              onDateChange(newDate);
            }}
            className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-7 gap-px bg-gray-200">
        {['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].map((day) => (
          <div
            key={day}
            className="bg-gray-50 py-2 text-center text-sm font-medium text-gray-500"
          >
            {day}
          </div>
        ))}
      </div>
      {renderMonthView()}
    </div>
  );
}