import { User } from '../types/auth';
import { supabase } from './supabase';

export async function checkAdminStatus(): Promise<boolean> {
  try {
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    if (sessionError) {
      console.error('Session error:', sessionError);
      await handleAuthError(sessionError);
      return false;
    }
    
    if (!session) {
      console.log('No active session');
      return false;
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError) {
      console.error('Auth error:', authError);
      await handleAuthError(authError);
      return false;
    }
    
    if (!user) {
      console.log('No authenticated user');
      return false;
    }
    
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();
      
    if (profileError) {
      console.error('Error fetching profile:', profileError);
      return false;
    }
      
    return profile?.role === 'admin';
  } catch (err) {
    console.error('Error checking admin status:', err);
    return false;
  }
}

// New function to check device access
export async function checkDeviceAccess(deviceModelId: string): Promise<boolean> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    // First check if user is admin
    const isAdmin = await checkAdminStatus();
    if (isAdmin) return true;

    // Check if user has explicit access to this device
    const { data, error } = await supabase
      .from('user_device_access')
      .select('id')
      .eq('user_id', user.id)
      .eq('device_model_id', deviceModelId)
      .maybeSingle();

    if (error) {
      console.error('Error checking device access:', error);
      return false;
    }

    return !!data;
  } catch (err) {
    console.error('Error checking device access:', err);
    return false;
  }
}

// Add new function to check module access
export async function checkModuleAccess(moduleType: 'training' | 'events'): Promise<boolean> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return false;

    // First check if user is admin
    const isAdmin = await checkAdminStatus();
    if (isAdmin) return true;

    // Check if user has explicit access to this module
    const { data, error } = await supabase
      .from('user_module_access')
      .select('id')
      .eq('user_id', user.id)
      .eq('module_type', moduleType)
      .maybeSingle();

    if (error) {
      console.error('Error checking module access:', error);
      return false;
    }

    return !!data;
  } catch (err) {
    console.error('Error checking module access:', err);
    return false;
  }
}

export async function getCurrentUser(): Promise<User | null> {
  try {
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    if (sessionError) {
      await handleAuthError(sessionError);
      return null;
    }
    
    if (!session) {
      return null;
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError) {
      await handleAuthError(authError);
      return null;
    }
    
    if (!user) {
      return null;
    }
    
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();
      
    if (profileError) {
      console.error('Error fetching profile:', profileError);
      return null;
    }
      
    return profile;
  } catch (err) {
    console.error('Error getting current user:', err);
    // Try to recover the session
    try {
      const { error: refreshError } = await supabase.auth.refreshSession();
      if (refreshError) {
        await handleAuthError(refreshError);
        return null;
      }
      
      // Retry profile fetch after refresh
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;
      
      const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();
        
      return profile;
    } catch (refreshErr) {
      console.error('Error refreshing session:', refreshErr);
      await handleAuthError(refreshErr);
      return null;
    }
  }
}

export async function isUserApproved(): Promise<boolean> {
  try {
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    if (sessionError) {
      await handleAuthError(sessionError);
      return false;
    }
    
    if (!session) {
      return false;
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError) {
      await handleAuthError(authError);
      return false;
    }
    
    if (!user) {
      return false;
    }
    
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('status')
      .eq('id', user.id)
      .single();
      
    if (profileError) {
      console.error('Error fetching profile:', profileError);
      return false;
    }
      
    return profile?.status === 'approved';
  } catch (err) {
    console.error('Error checking user approval:', err);
    return false;
  }
}

// Helper function to check if session is valid
export async function checkSession(): Promise<boolean> {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error) {
      console.error('Session check error:', error);
      await handleAuthError(error);
      return false;
    }
    return !!session;
  } catch (err) {
    console.error('Error checking session:', err);
    return false;
  }
}

// Helper to handle auth errors
export async function handleAuthError(error: any): Promise<void> {
  if (error?.message?.includes('JWT')) {
    // For JWT/token errors, sign out and redirect to login
    await supabase.auth.signOut();
    window.location.href = '/login';
  } else if (error?.message?.includes('refresh_token_not_found')) {
    // For refresh token errors, try to get a new session
    try {
      const { error: refreshError } = await supabase.auth.refreshSession();
      if (refreshError) {
        // If refresh fails, sign out and redirect
        await supabase.auth.signOut();
        window.location.href = '/login';
      }
    } catch (refreshErr) {
      console.error('Error refreshing session:', refreshErr);
      await supabase.auth.signOut();
      window.location.href = '/login';
    }
  } else {
    console.error('Authentication error:', error);
  }
}