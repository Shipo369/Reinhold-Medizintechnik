import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  Plus,
  Edit2,
  Trash2,
  AlertCircle,
  X,
  Save,
  ChevronRight,
  Settings,
  ArrowLeft
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';

interface DeviceType {
  id: string;
  name: string;
  description: string;
}

interface DeviceModel {
  id: string;
  type_id: string;
  name: string;
  description: string;
}

export function DeviceManagement() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [deviceTypes, setDeviceTypes] = useState<DeviceType[]>([]);
  const [deviceModels, setDeviceModels] = useState<DeviceModel[]>([]);
  const [selectedType, setSelectedType] = useState<DeviceType | null>(null);
  const [isTypeModalOpen, setIsTypeModalOpen] = useState(false);
  const [isModelModalOpen, setIsModelModalOpen] = useState(false);
  const [editingType, setEditingType] = useState<DeviceType | null>(null);
  const [editingModel, setEditingModel] = useState<DeviceModel | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: ''
  });
  const [error, setError] = useState<string | null>(null);
  const [isEditMode, setIsEditMode] = useState(false);

  useEffect(() => {
    const init = async () => {
      const adminStatus = await checkAdminStatus();
      setIsAdmin(adminStatus);
      if (adminStatus) {
        await loadDeviceTypes();
      }
      setIsLoading(false);
    };
    init();
  }, []);

  const loadDeviceTypes = async () => {
    try {
      const { data: types, error } = await supabase
        .from('device_types')
        .select('*')
        .order('name');
      
      if (error) throw error;
      setDeviceTypes(types || []);
    } catch (err) {
      console.error('Error loading device types:', err);
      setError('Fehler beim Laden der Gerätetypen');
    }
  };

  const loadDeviceModels = async (typeId: string) => {
    try {
      const { data: models, error } = await supabase
        .from('device_models')
        .select('*')
        .eq('type_id', typeId)
        .order('name');
      
      if (error) throw error;
      setDeviceModels(models || []);
    } catch (err) {
      console.error('Error loading device models:', err);
      setError('Fehler beim Laden der Gerätemodelle');
    }
  };

  const handleTypeSelect = async (type: DeviceType) => {
    setSelectedType(type);
    await loadDeviceModels(type.id);
  };

  const handleTypeSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    
    try {
      // Prüfe zuerst, ob ein Typ mit diesem Namen bereits existiert
      const { data: existingType } = await supabase
        .from('device_types')
        .select('id')
        .ilike('name', formData.name)
        .maybeSingle();

      if (existingType && (!editingType || editingType.id !== existingType.id)) {
        throw new Error('Ein Gerätetyp mit diesem Namen existiert bereits.');
      }

      if (editingType) {
        const { error } = await supabase
          .from('device_types')
          .update({
            name: formData.name,
            description: formData.description
          })
          .eq('id', editingType.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('device_types')
          .insert([{
            name: formData.name,
            description: formData.description
          }]);

        if (error) {
          if (error.code === '23505') {
            throw new Error('Ein Gerätetyp mit diesem Namen existiert bereits.');
          }
          throw error;
        }
      }

      await loadDeviceTypes();
      setIsTypeModalOpen(false);
      setEditingType(null);
      setFormData({ name: '', description: '' });
      setError('Gerätetyp wurde erfolgreich gespeichert');
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error submitting device type:', err);
      setError(err.message || 'Fehler beim Speichern des Gerätetyps');
    }
  };

  const handleModelSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    
    if (!selectedType) return;

    try {
      // Prüfe zuerst, ob ein Modell mit diesem Namen bereits existiert
      const { data: existingModel } = await supabase
        .from('device_models')
        .select('id')
        .eq('type_id', selectedType.id)
        .ilike('name', formData.name)
        .maybeSingle();

      if (existingModel && (!editingModel || editingModel.id !== existingModel.id)) {
        throw new Error('Ein Gerätemodell mit diesem Namen existiert bereits für diesen Typ.');
      }

      if (editingModel) {
        const { error } = await supabase
          .from('device_models')
          .update({
            name: formData.name,
            description: formData.description
          })
          .eq('id', editingModel.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('device_models')
          .insert([{
            type_id: selectedType.id,
            name: formData.name,
            description: formData.description
          }]);

        if (error) {
          if (error.code === '23505') {
            throw new Error('Ein Gerätemodell mit diesem Namen existiert bereits für diesen Typ.');
          }
          throw error;
        }
      }

      await loadDeviceModels(selectedType.id);
      setIsModelModalOpen(false);
      setEditingModel(null);
      setFormData({ name: '', description: '' });
      setError('Gerätemodell wurde erfolgreich gespeichert');
      setTimeout(() => setError(null), 3000);
    } catch (err: any) {
      console.error('Error submitting device model:', err);
      setError(err.message || 'Fehler beim Speichern des Gerätemodells');
    }
  };

  const handleDeleteType = async (typeId: string) => {
    if (!window.confirm('Möchten Sie diesen Gerätetyp wirklich löschen? Alle zugehörigen Modelle werden ebenfalls gelöscht.')) return;

    try {
      const { error } = await supabase
        .from('device_types')
        .delete()
        .eq('id', typeId);

      if (error) throw error;

      await loadDeviceTypes();
      if (selectedType?.id === typeId) {
        setSelectedType(null);
        setDeviceModels([]);
      }
    } catch (err) {
      console.error('Error deleting device type:', err);
      setError('Fehler beim Löschen des Gerätetyps');
    }
  };

  const handleDeleteModel = async (modelId: string) => {
    if (!window.confirm('Möchten Sie dieses Gerätemodell wirklich löschen?')) return;

    try {
      const { error } = await supabase
        .from('device_models')
        .delete()
        .eq('id', modelId);

      if (error) throw error;

      if (selectedType) {
        await loadDeviceModels(selectedType.id);
      }
    } catch (err) {
      console.error('Error deleting device model:', err);
      setError('Fehler beim Löschen des Gerätemodells');
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
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
        <div className="bg-white rounded-lg shadow-lg">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex justify-between items-center">
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => navigate(-1)}
                  className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  title="Zurück"
                >
                  <ArrowLeft className="h-5 w-5" />
                </button>
                <h2 className="text-xl font-semibold text-gray-900">Geräteverwaltung</h2>
              </div>
              <div className="flex space-x-2">
                <button
                  onClick={() => setIsEditMode(!isEditMode)}
                  className={`inline-flex items-center px-4 py-2 border rounded-lg shadow-sm text-sm font-medium transition-colors ${
                    isEditMode
                      ? 'border-blue-600 text-blue-600 bg-blue-50 hover:bg-blue-100'
                      : 'border-gray-300 text-gray-700 bg-white hover:bg-gray-50'
                  }`}
                >
                  <Settings className={`h-4 w-4 mr-2 ${isEditMode ? 'text-blue-600' : 'text-gray-500'}`} />
                  {isEditMode ? 'Bearbeitungsmodus beenden' : 'Bearbeitungsmodus'}
                </button>
                <button
                  onClick={() => {
                    setFormData({ name: '', description: '' });
                    setIsTypeModalOpen(true);
                    setError(null);
                  }}
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Neuer Gerätetyp
                </button>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-3 min-h-[600px]">
            {/* Device Types List */}
            <div className="col-span-1 border-r border-gray-200">
              <div className="p-4 space-y-2">
                {deviceTypes.map((type) => (
                  <div
                    key={type.id}
                    className={`flex items-center justify-between p-3 rounded-lg cursor-pointer transition-colors ${
                      selectedType?.id === type.id
                        ? 'bg-blue-50 border-blue-200'
                        : 'hover:bg-gray-50'
                    }`}
                    onClick={() => handleTypeSelect(type)}
                  >
                    <div className="flex-1">
                      <h3 className="font-medium text-gray-900">{type.name}</h3>
                      <p className="text-sm text-gray-500">{type.description}</p>
                    </div>
                    {isEditMode && (
                      <div className="flex items-center space-x-2 ml-4">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setEditingType(type);
                            setFormData({
                              name: type.name,
                              description: type.description
                            });
                            setIsTypeModalOpen(true);
                            setError(null);
                          }}
                          className="p-1 text-gray-400 hover:text-blue-600 rounded-full hover:bg-blue-50"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            handleDeleteType(type.id);
                          }}
                          className="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-red-50"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    )}
                  </div>
                ))}

                {deviceTypes.length === 0 && (
                  <div className="text-center py-8">
                    <p className="text-gray-500">Keine Gerätetypen vorhanden</p>
                  </div>
                )}
              </div>
            </div>

            {/* Device Models List */}
            <div className="col-span-2 p-4">
              {selectedType ? (
                <>
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center">
                      <h3 className="text-lg font-medium text-gray-900">
                        {selectedType.name}
                      </h3>
                      <ChevronRight className="h-5 w-5 text-gray-400 mx-2" />
                      <span className="text-gray-600">Gerätemodelle</span>
                    </div>
                    <button
                      onClick={() => {
                        setFormData({ name: '', description: '' });
                        setIsModelModalOpen(true);
                        setError(null);
                      }}
                      className="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                      <Plus className="h-4 w-4 mr-2" />
                      Neues Modell
                    </button>
                  </div>

                  <div className="space-y-4">
                    {deviceModels.map((model) => (
                      <div
                        key={model.id}
                        className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                      >
                        <div>
                          <h4 className="font-medium text-gray-900">{model.name}</h4>
                          <p className="text-sm text-gray-500">{model.description}</p>
                        </div>
                        {isEditMode && (
                          <div className="flex items-center space-x-2">
                            <button
                              onClick={() => {
                                setEditingModel(model);
                                setFormData({
                                  name: model.name,
                                  description: model.description
                                });
                                setIsModelModalOpen(true);
                                setError(null);
                              }}
                              className="p-1 text-gray-400 hover:text-blue-600 rounded-full hover:bg-blue-50"
                            >
                              <Edit2 className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleDeleteModel(model.id)}
                              className="p-1 text-gray-400 hover:text-red-600 rounded-full hover:bg-red-50"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        )}
                      </div>
                    ))}

                    {deviceModels.length === 0 && (
                      <div className="text-center py-8">
                        <p className="text-gray-500">Keine Modelle für diesen Gerätetyp</p>
                      </div>
                    )}
                  </div>
                </>
              ) : (
                <div className="flex flex-col items-center justify-center h-full text-gray-500">
                  <p>Wählen Sie einen Gerätetyp aus der Liste aus</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Device Type Modal */}
      {isTypeModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-lg shadow-xl max-w-md w-full"
          >
            <div className="flex justify-between items-center px-6 py-4 border-b">
              <h3 className="text-lg font-medium text-gray-900">
                {editingType ? 'Gerätetyp bearbeiten' : 'Neuer Gerätetyp'}
              </h3>
              <button
                onClick={() => {
                  setIsTypeModalOpen(false);
                  setEditingType(null);
                  setFormData({ name: '', description: '' });
                  setError(null);
                }}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={handleTypeSubmit} className="p-6 space-y-4">
              {error && (
                <div className="bg-red-50 border border-red-200 rounded-md p-4">
                  <p className="text-sm text-red-600">{error}</p>
                </div>
              )}

              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Name
                </label>
                <input
                  type="text"
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
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
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setIsTypeModalOpen(false);
                    setEditingType(null);
                    setFormData({ name: '', description: '' });
                    setError(null);
                  }}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Abbrechen
                </button>
                <button
                  type="submit"
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <Save className="h-4 w-4 mr-2" />
                  Speichern
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}

      {/* Device Model Modal */}
      {isModelModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-white rounded-lg shadow-xl max-w-md w-full"
          >
            <div className="flex justify-between items-center px-6 py-4 border-b">
              <h3 className="text-lg font-medium text-gray-900">
                {editingModel ? 'Gerätemodell bearbeiten' : 'Neues Gerätemodell'}
              </h3>
              <button
                onClick={() => {
                  setIsModelModalOpen(false);
                  setEditingModel(null);
                  setFormData({ name: '', description: '' });
                  setError(null);
                }}
                className="text-gray-400 hover:text-gray-500"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <form onSubmit={handleModelSubmit} className="p-6 space-y-4">
              {error && (
                <div className="bg-red-50 border border-red-200 rounded-md p-4">
                  <p className="text-sm text-red-600">{error}</p>
                </div>
              )}

              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Name
                </label>
                <input
                  type="text"
                  id="name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
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
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setIsModelModalOpen(false);
                    setEditingModel(null);
                    setFormData({ name: '', description: '' });
                    setError(null);
                  }}
                  className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Abbrechen
                </button>
                <button
                  type="submit"
                  className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                >
                  <Save className="h-4 w-4 mr-2" />
                  Speichern
                </button>
              </div>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}