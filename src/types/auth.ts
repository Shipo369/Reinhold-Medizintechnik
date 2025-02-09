export interface User {
  id: string;
  email: string;
  role: 'admin' | 'user';
  created_at: string;
}

export interface AuthState {
  user: User | null;
  session: any | null;
}