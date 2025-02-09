export interface Event {
  id: string;
  title: string;
  description: string;
  start_time: string;
  end_time: string;
  location: string;
  max_participants: number;
  device_model_id: string | null;
  created_at: string;
  updated_at: string;
}

export interface EventParticipant {
  id: string;
  event_id: string;
  user_id: string;
  status: 'registered' | 'waitlist' | 'cancelled';
  created_at: string;
  updated_at: string;
}

export type CalendarView = 'day' | 'week' | 'month';

export interface EventFormData {
  title: string;
  description: string;
  start_time: string;
  end_time: string;
  location: string;
  max_participants: number;
  device_model_id: string | null;
}