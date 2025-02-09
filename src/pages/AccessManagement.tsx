import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  AlertCircle,
  X,
  Loader2,
  Check,
  Users,
  BookOpen,
  Calendar,
  Shield,
  Laptop
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';

interface User {
  id: string;
  email: string;
  full_name: string | null;
  organization: string | null;
  role: 'admin' | 'user';
  created_at: string;
  device_access: string[];
  module_access: {
    training: boolean;
    events: boolean;
  };
}

interface DeviceModel {
  id: string;
  name: string;
  type_id: string;
  type_name: string;
}

export function AccessManagement() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [users, setUsers] = useState<User[]>([]);
  const [deviceModels, setDeviceModels] = useState<DeviceModel[]>([]);
  const [updatingAccess, setUpdatingAccess] = useState<{
    userId: string;
    type: 'device' | 'module';
    id?: string;
    module?: string;
  } | null>(null);

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        if (adminStatus) {
          await Promise.all([
            loadUsers(),
            loadDeviceModels()
          ]);
        }
      } catch (err) {
        console.error('Error initializing:', err);
        setError('Fehler beim Laden der Daten');
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  const loadUsers = async () => {
    try {
      // Get all users
      const { data: usersData, error: usersError } = await supabase
        .from('profiles')
        .select('*')
        .neq('email', 'juan_jano@hotmail.de')
        .order('created_at', { ascending: false });

      if (usersError) throw usersError;

      // Get device access data
      const { data: deviceAccessData, error: deviceError } = await supabase
        .from('user_device_access')
        .select('*');

      if (deviceError) throw deviceError;

      // Get module access data
      const { data: moduleAccessData, error: moduleError } = await supabase
        .from('user_module_access')
        .select('*');

      if (moduleError) throw moduleError;

      // Combine the data
      const usersWithAccess = usersData.map(user => ({
        ...user,
        device_access: deviceAccessData
          .filter(access => access.user_id === user.id)
          .map(access => access.device_model_id),
        module_access: {
          training: moduleAccessData.some(access => 
            access.user_id === user.id && access.module_type === 'training'
          ),
          events: moduleAccessData.some(access => 
            access.user_id === user.id && access.module_type === 'events'
          )
        }
      }));

      setUsers(usersWithAccess);
    } catch (err) {
      console.error('Error loading users:', err);
      setError('Fehler beim Laden der Benutzer');
    }
  };

  const loadDeviceModels = async () => {
    try {
      const { data, error } = await supabase
        .from('device_models')
        .select(`
          id,
          name,
          type_id,
          device_types (
            name
          )
        `)
        .order('name');

      if (error) throw error;

      setDeviceModels(data?.map(model => ({
        id: model.id,
        name: model.name,
        type_id: model.type_id,
        type_name: model.device_types.name
      })) || []);
    } catch (err) {
      console.error('Error loading device models:', err);
      setError('Fehler beim Laden der Gerätemodelle');
    }
  };

  const toggleDeviceAccess = async (userId: string, deviceModelId: string) => {
    try {
      setUpdatingAccess({ userId, type: 'device', id: deviceModelId });
      const user = users.find(u => u.id === userId);
      if (!user) return;

      const hasAccess = user.device_access.includes(deviceModelId);

      if (hasAccess) {
        // Remove access
        const { error } = await supabase
          .from('user_device_access')
          .delete()
          .eq('user_id', userId)
          .eq('device_model_id', deviceModelId);

        if (error) throw error;
      } else {
        // Grant access
        const { error } = await supabase
          .from('user_device_access')
          .insert([{
            user_id: userId,
            device_model_id: deviceModelId
          }]);

        if (error) throw error;
      }

      await loadUsers();
      setError(`Gerätezugriff wurde erfolgreich ${hasAccess ? 'entzogen' : 'gewährt'}`);
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error toggling device access:', err);
      setError(err.message || 'Fehler beim Ändern der Gerätezugriffsrechte');
    } finally {
      setUpdatingAccess(null);
    }
  };

  const toggleModuleAccess = async (userId: string, moduleType: 'training' | 'events') => {
    try {
      setUpdatingAccess({ userId, type: 'module', module: moduleType });
      const user = users.find(u => u.id === userId);
      if (!user) return;

      const hasAccess = moduleType === 'training' 
        ? user.module_access.training 
        : user.module_access.events;

      if (hasAccess) {
        // Remove access
        const { error } = await supabase
          .from('user_module_access')
          .delete()
          .eq('user_id', userId)
          .eq('module_type', moduleType);

        if (error) throw error;
      } else {
        // Grant access
        const { error } = await supabase
          .from('user_module_access')
          .insert([{
            user_id: userId,
            module_type: moduleType
          }]);

        if (error) throw error;
      }

      await loadUsers();
      setError(`${moduleType === 'training' ? 'Schulungs' : 'Termin'}-Zugriff wurde erfolgreich ${hasAccess ? 'entzogen' : 'gewährt'}`);
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error toggling module access:', err);
      setError(err.message || 'Fehler beim Ändern der Modulzugriffsrechte');
    } finally {
      setUpdatingAccess(null);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-lg max-w-md w-full">
          <div className="flex items-center justify-center text-red-500 mb-4">
            <AlertCircle className="h-12 w-12" />
          </div>
          <h2 className="text-2xl font-bold text-center text-gray-900 mb-4">
            Zugriff verweigert
          </h2>
          <p className="text-gray-600 text-center mb-6">
            Sie benötigen Administrator-Rechte, um auf diesen Bereich zugreifen zu können.
          </p>
          <button
            onClick={() => navigate('/')}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Zurück zur Startseite
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Zurück"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <h1 className="text-2xl font-bold text-gray-900">Zugriffsberechtigung</h1>
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

        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            {users.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Benutzer
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Organisation
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Modulzugriff
                      </th>
                      <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Gerätezugriff
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {users.map((user) => (
                      <tr key={user.id}>
                        <td className="px-6 py-4">
                          <div className="text-sm font-medium text-gray-900">
                            {user.full_name || user.email}
                          </div>
                          <div className="text-sm text-gray-500">{user.email}</div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-900">
                            {user.organization || '-'}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col space-y-2">
                            <button
                              onClick={() => toggleModuleAccess(user.id, 'training')}
                              disabled={updatingAccess?.userId === user.id}
                              className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                                user.module_access.training
                                  ? 'bg-green-100 text-green-800 hover:bg-green-200'
                                  : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                              }`}
                            >
                              {updatingAccess?.userId === user.id && updatingAccess?.module === 'training' ? (
                                <Loader2 className="h-4 w-4 animate-spin mr-2" />
                              ) : (
                                <BookOpen className="h-4 w-4 mr-2" />
                              )}
                              Schulungen: {user.module_access.training ? 'Aktiv' : 'Inaktiv'}
                            </button>
                            <button
                              onClick={() => toggleModuleAccess(user.id, 'events')}
                              disabled={updatingAccess?.userId === user.id}
                              className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                                user.module_access.events
                                  ? 'bg-green-100 text-green-800 hover:bg-green-200'
                                  : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                              }`}
                            >
                              {updatingAccess?.userId === user.id && updatingAccess?.module === 'events' ? (
                                <Loader2 className="h-4 w-4 animate-spin mr-2" />
                              ) : (
                                <Calendar className="h-4 w-4 mr-2" />
                              )}
                              Termine: {user.module_access.events ? 'Aktiv' : 'Inaktiv'}
                            </button>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col space-y-2">
                            {deviceModels.map((model) => (
                              <button
                                key={model.id}
                                onClick={() => toggleDeviceAccess(user.id, model.id)}
                                disabled={updatingAccess?.userId === user.id}
                                className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
                                  user.device_access.includes(model.id)
                                    ? 'bg-green-100 text-green-800 hover:bg-green-200'
                                    : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                                }`}
                              >
                                {updatingAccess?.userId === user.id && updatingAccess?.id === model.id ? (
                                  <Loader2 className="h-4 w-4 animate-spin mr-2" />
                                ) : (
                                  <Laptop className="h-4 w-4 mr-2" />
                                )}
                                {model.name}
                                <span className="ml-1 text-xs text-gray-500">
                                  ({model.type_name})
                                </span>
                              </button>
                            ))}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="text-center py-12">
                <Users className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-2 text-sm font-medium text-gray-900">
                  Keine Benutzer
                </h3>
                <p className="mt-1 text-sm text-gray-500">
                  Es sind noch keine Benutzer vorhanden.
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}