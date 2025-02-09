import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  LogOut,
  BookOpen,
  Calendar,
  Settings,
  Users,
  GraduationCap,
  FileText,
  Presentation,
  ShieldCheck
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus, checkModuleAccess } from '../lib/auth';

interface DeviceType {
  id: string;
  name: string;
  description: string;
  models: {
    id: string;
    name: string;
  }[];
}

export function Dashboard() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [hasTrainingAccess, setHasTrainingAccess] = useState(false);
  const [hasEventsAccess, setHasEventsAccess] = useState(false);
  const [deviceTypes, setDeviceTypes] = useState<DeviceType[]>([]);

  useEffect(() => {
    const init = async () => {
      const adminStatus = await checkAdminStatus();
      setIsAdmin(adminStatus);

      // Check module access if not admin
      if (!adminStatus) {
        const trainingAccess = await checkModuleAccess('training');
        const eventsAccess = await checkModuleAccess('events');
        setHasTrainingAccess(trainingAccess);
        setHasEventsAccess(eventsAccess);
      } else {
        // Admins have access to everything
        setHasTrainingAccess(true);
        setHasEventsAccess(true);
      }

      await loadDeviceTypes();
    };
    init();
  }, []);

  const loadDeviceTypes = async () => {
    try {
      const { data: types, error: typesError } = await supabase
        .from('device_types')
        .select(`
          id,
          name,
          description,
          models:device_models(id, name)
        `)
        .order('name');

      if (typesError) throw typesError;
      setDeviceTypes(types || []);
    } catch (err) {
      console.error('Error loading device types:', err);
      const error = supabase.handleError(err);
    }
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate('/');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold text-gray-900">
              Mein Dashboard
              {isAdmin && (
                <span className="ml-2 text-sm font-normal text-white bg-blue-600 px-2 py-1 rounded-full">
                  Administrator
                </span>
              )}
            </h1>
            <button
              onClick={handleLogout}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:from-blue-600 hover:via-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <LogOut className="h-4 w-4 mr-2" />
              Abmelden
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {/* Schulungen */}
            {hasTrainingAccess && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4 }}
                className="bg-white overflow-hidden shadow-lg rounded-lg"
              >
                <div className="p-6">
                  <div className="flex items-center">
                    <div className="bg-blue-500 rounded-lg p-3">
                      <BookOpen className="h-6 w-6 text-white" />
                    </div>
                    <div className="ml-4">
                      <h2 className="text-lg font-medium text-gray-900">Meine Schulungen</h2>
                      <p className="mt-1 text-sm text-gray-500">Aktuelle und abgeschlossene Schulungen</p>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 px-6 py-4">
                  <div className="text-sm">
                    <Link to="/schulungen" className="font-medium text-blue-600 hover:text-blue-500">
                      Alle anzeigen
                    </Link>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Termine */}
            {hasEventsAccess && (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.4, delay: 0.1 }}
                className="bg-white overflow-hidden shadow-lg rounded-lg"
              >
                <div className="p-6">
                  <div className="flex items-center">
                    <div className="bg-green-500 rounded-lg p-3">
                      <Calendar className="h-6 w-6 text-white" />
                    </div>
                    <div className="ml-4">
                      <h2 className="text-lg font-medium text-gray-900">Termine</h2>
                      <p className="mt-1 text-sm text-gray-500">Geplante und verfügbare Termine</p>
                    </div>
                  </div>
                </div>
                <div className="bg-gray-50 px-6 py-4">
                  <div className="text-sm">
                    <Link to="/events" className="font-medium text-blue-600 hover:text-blue-500">
                      Kalender öffnen
                    </Link>
                  </div>
                </div>
              </motion.div>
            )}

            {/* Admin Modules */}
            {isAdmin && (
              <>
                {/* Zertifikate */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.2 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-purple-500 rounded-lg p-3">
                        <GraduationCap className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Zertifikate</h2>
                        <p className="mt-1 text-sm text-gray-500">Zertifikatsverwaltung</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/zertifikate" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>

                {/* Dokumente */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.3 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-indigo-500 rounded-lg p-3">
                        <FileText className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Dokumente</h2>
                        <p className="mt-1 text-sm text-gray-500">Technische Dokumentationen und Anleitungen</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/dokumente" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>

                {/* Präsentationen */}
                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.4 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-orange-500 rounded-lg p-3">
                        <Presentation className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Präsentation</h2>
                        <p className="mt-1 text-sm text-gray-500">Verfügbare Gerätetypen und Modelle</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/praesentation" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.5 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-blue-600 rounded-lg p-3">
                        <Settings className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Geräteverwaltung</h2>
                        <p className="mt-1 text-sm text-gray-500">Gerätetypen und Modelle verwalten</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/geraete" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.6 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-yellow-500 rounded-lg p-3">
                        <Users className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Benutzerverwaltung</h2>
                        <p className="mt-1 text-sm text-gray-500">Benutzer verwalten und freigeben</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/users" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.7 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-red-500 rounded-lg p-3">
                        <GraduationCap className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Prüfungsverwaltung</h2>
                        <p className="mt-1 text-sm text-gray-500">Prüfungen erstellen und verwalten</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/pruefungen" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>

                <motion.div
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.4, delay: 0.8 }}
                  className="bg-white overflow-hidden shadow-lg rounded-lg"
                >
                  <div className="p-6">
                    <div className="flex items-center">
                      <div className="bg-emerald-500 rounded-lg p-3">
                        <ShieldCheck className="h-6 w-6 text-white" />
                      </div>
                      <div className="ml-4">
                        <h2 className="text-lg font-medium text-gray-900">Zugriffsberechtigung</h2>
                        <p className="mt-1 text-sm text-gray-500">Benutzerberechtigungen verwalten</p>
                      </div>
                    </div>
                  </div>
                  <div className="bg-gray-50 px-6 py-4">
                    <div className="text-sm">
                      <Link to="/access" className="font-medium text-blue-600 hover:text-blue-500">
                        Verwalten
                      </Link>
                    </div>
                  </div>
                </motion.div>
              </>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}