import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Mail, Lock, Loader2 } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface EmailVerificationProps {
  email: string;
  onVerified: () => void;
  onCancel: () => void;
}

export function EmailVerification({ email, onVerified, onCancel }: EmailVerificationProps) {
  const [code, setCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isResending, setIsResending] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      const { data, error: verifyError } = await supabase
        .rpc('verify_code', {
          p_email: email,
          p_code: code
        });

      if (verifyError) throw verifyError;

      if (data) {
        onVerified();
      } else {
        throw new Error('Ungültiger Code. Bitte versuchen Sie es erneut.');
      }
    } catch (err: any) {
      console.error('Verification error:', err);
      setError(err.message || 'Fehler bei der Verifizierung');
    } finally {
      setIsLoading(false);
    }
  };

  const handleResendCode = async () => {
    setIsResending(true);
    setError(null);

    try {
      // First generate a new code
      const { data: verificationCode, error: codeError } = await supabase
        .rpc('generate_verification_code', {
          p_email: email
        });

      if (codeError) throw codeError;

      // For now, just show the code to the user since email sending is not working
      setError(`Ein neuer Code wurde generiert: ${verificationCode}`);
    } catch (err: any) {
      console.error('Error resending code:', err);
      setError(err.message || 'Fehler beim Senden des Codes');
    } finally {
      setIsResending(false);
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-white/80 backdrop-blur-sm py-8 px-4 shadow-xl rounded-xl sm:px-10"
    >
      <div className="text-center mb-6">
        <Mail className="mx-auto h-12 w-12 text-blue-600" />
        <h2 className="mt-4 text-2xl font-bold text-gray-900">
          E-Mail bestätigen
        </h2>
        <p className="mt-2 text-sm text-gray-600">
          Wir haben einen 6-stelligen Code an {email} gesendet.
          <br />
          Bitte geben Sie den Code ein, um fortzufahren.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="code" className="block text-sm font-medium text-gray-700">
            Verifizierungscode
          </label>
          <div className="mt-1 relative">
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <Lock className="h-5 w-5 text-gray-400" />
            </div>
            <input
              type="text"
              id="code"
              value={code}
              onChange={(e) => {
                const value = e.target.value.replace(/\D/g, '').slice(0, 6);
                setCode(value);
                setError(null);
              }}
              className="appearance-none block w-full pl-10 px-3 py-2 border border-gray-300 rounded-lg shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
              placeholder="123456"
              maxLength={6}
              required
            />
          </div>
        </div>

        {error && (
          <div className={`rounded-lg ${error.includes('generiert') ? 'bg-green-50' : 'bg-red-50'} p-4`}>
            <div className="flex">
              <div className="ml-3">
                <h3 className={`text-sm font-medium ${error.includes('generiert') ? 'text-green-800' : 'text-red-800'}`}>
                  {error}
                </h3>
              </div>
            </div>
          </div>
        )}

        <div className="flex flex-col space-y-3">
          <button
            type="submit"
            disabled={isLoading || code.length !== 6}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:from-blue-600 hover:via-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? (
              <Loader2 className="h-5 w-5 animate-spin" />
            ) : (
              'Code bestätigen'
            )}
          </button>

          <div className="flex justify-between items-center">
            <button
              type="button"
              onClick={handleResendCode}
              disabled={isResending}
              className="text-sm text-blue-600 hover:text-blue-700"
            >
              {isResending ? (
                <span className="flex items-center">
                  <Loader2 className="h-4 w-4 animate-spin mr-2" />
                  Code wird generiert...
                </span>
              ) : (
                'Neuen Code generieren'
              )}
            </button>

            <button
              type="button"
              onClick={onCancel}
              className="text-sm text-gray-600 hover:text-gray-700"
            >
              Abbrechen
            </button>
          </div>
        </div>
      </form>
    </motion.div>
  );
}