import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Please connect to Supabase first.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  },
  global: {
    headers: {
      'x-my-custom-header': 'my-app-name'
    }
  },
  db: {
    schema: 'public'
  },
  storage: {
    retryAttempts: 3,
    retryDelay: 500
  }
});

// Add error handling for failed requests
supabase.handleError = (error: any) => {
  console.error('Supabase error:', error);
  if (error.message === 'Failed to fetch') {
    return new Error('Verbindungsfehler: Bitte überprüfen Sie Ihre Internetverbindung');
  }
  if (error.message.includes('storage/object-not-found')) {
    return new Error('Die angeforderte Datei wurde nicht gefunden');
  }
  if (error.message.includes('storage/permission-denied')) {
    return new Error('Keine Berechtigung zum Zugriff auf diese Datei');
  }
  return error;
};