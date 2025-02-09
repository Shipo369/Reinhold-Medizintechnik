import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  AlertCircle,
  X,
  Save,
  ChevronRight,
  Settings,
  Presentation,
  ChevronDown
} from 'lucide-react';
import { supabase } from '../lib/supabase';
import { checkAdminStatus } from '../lib/auth';
import { PresentationViewer } from '../components/PresentationViewer';
import { Editor } from '../components/Editor';

interface DeviceType {
  id: string;
  name: string;
  description: string;
}

interface DeviceModel {
  id: string;
  name: string;
  type_id: string;
  description: string;
}

interface Presentation {
  id: string;
  device_model_id: string;
  content: string;
  title: string;
  created_at: string;
}

export function PresentationPage() {
  const navigate = useNavigate();
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deviceTypes, setDeviceTypes] = useState<DeviceType[]>([]);
  const [deviceModels, setDeviceModels] = useState<Record<string, DeviceModel[]>>({});
  const [presentations, setPresentations] = useState<Record<string, Presentation>>({});
  const [selectedModel, setSelectedModel] = useState<DeviceModel | null>(null);
  const [editContent, setEditContent] = useState('');
  const [editTitle, setEditTitle] = useState('');
  const [selectedPresentation, setSelectedPresentation] = useState<Presentation | null>(null);
  const [expandedTypes, setExpandedTypes] = useState<Record<string, boolean>>({});

  useEffect(() => {
    const init = async () => {
      try {
        const adminStatus = await checkAdminStatus();
        setIsAdmin(adminStatus);
        await Promise.all([
          loadDeviceTypes(),
          loadPresentations()
        ]);
      } catch (err) {
        console.error('Error initializing:', err);
        setError('Fehler beim Laden der Daten');
      } finally {
        setIsLoading(false);
      }
    };
    init();
  }, []);

  const loadDeviceTypes = async () => {
    try {
      const { data: types, error: typesError } = await supabase
        .from('device_types')
        .select('*')
        .order('name');

      if (typesError) throw typesError;
      setDeviceTypes(types || []);

      // Load models for each type
      const modelsByType: Record<string, DeviceModel[]> = {};
      for (const type of types || []) {
        const { data: models, error: modelsError } = await supabase
          .from('device_models')
          .select('*')
          .eq('type_id', type.id)
          .order('name');

        if (modelsError) throw modelsError;
        modelsByType[type.id] = models || [];
      }
      setDeviceModels(modelsByType);
    } catch (err) {
      console.error('Error loading device types:', err);
      setError('Fehler beim Laden der Gerätetypen');
    }
  };

  const loadPresentations = async () => {
    try {
      const { data, error } = await supabase
        .from('device_presentations')
        .select('*');

      if (error) throw error;

      const presentationsMap: Record<string, Presentation> = {};
      data?.forEach(presentation => {
        presentationsMap[presentation.device_model_id] = presentation;
      });
      setPresentations(presentationsMap);
    } catch (err) {
      console.error('Error loading presentations:', err);
      setError('Fehler beim Laden der Präsentationen');
    }
  };

  const handleSave = async () => {
    if (!selectedModel) return;

    try {
      setError(null);
      setIsLoading(true);

      // Convert content to slide format
      const content = editContent.split('<hr class="slide-divider">').map(slide => 
        `<div class="slide">${slide.trim()}</div>`
      ).join('\n');

      const presentation = presentations[selectedModel.id];

      if (presentation) {
        // Update existing presentation
        const { error: updateError } = await supabase
          .from('device_presentations')
          .update({
            content,
            title: editTitle
          })
          .eq('id', presentation.id);

        if (updateError) throw updateError;
      } else {
        // Create new presentation
        const { error: insertError } = await supabase
          .from('device_presentations')
          .insert([{
            device_model_id: selectedModel.id,
            content,
            title: editTitle
          }]);

        if (insertError) throw insertError;
      }

      await loadPresentations();
      setSelectedModel(null);
      setEditContent('');
      setEditTitle('');
      setError('Präsentation wurde erfolgreich gespeichert');
      setTimeout(() => setError(null), 3000);
    } catch (err) {
      console.error('Error saving presentation:', err);
      setError('Fehler beim Speichern der Präsentation');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async (modelId: string) => {
    try {
      const presentation = presentations[modelId];
      if (!presentation) return;

      const confirmed = window.confirm('Möchten Sie diese Präsentation wirklich löschen?');
      if (!confirmed) return;

      setError(null);

      const { error: dbError } = await supabase
        .from('device_presentations')
        .delete()
        .eq('id', presentation.id);

      if (dbError) throw dbError;

      await loadPresentations();
      setError('Präsentation wurde erfolgreich gelöscht');
      setTimeout(() => setError(null), 3000);
    } catch (err) {
      console.error('Error deleting presentation:', err);
      setError('Fehler beim Löschen der Präsentation');
    }
  };

  const handlePreview = () => {
    if (!editContent || !selectedModel) return;

    // Convert content to slide format for preview
    const content = editContent.split('<hr class="slide-divider">').map(slide => 
      `<div class="slide">${slide.trim()}</div>`
    ).join('\n');

    setSelectedPresentation({
      id: 'preview',
      device_model_id: selectedModel.id,
      content,
      title: editTitle || selectedModel.name,
      created_at: new Date().toISOString()
    });
  };

  const toggleTypeExpansion = (typeId: string) => {
    setExpandedTypes(prev => ({ ...prev, [typeId]: !prev[typeId] }));
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (selectedModel) {
    return (
      <div className="min-h-screen bg-gray-50">
        <div className="max-w-[1920px] mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="mb-8">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => {
                    setSelectedModel(null);
                    setEditContent('');
                    setEditTitle('');
                  }}
                  className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                  title="Zurück"
                >
                  <ArrowLeft className="h-5 w-5" />
                </button>
                <h1 className="text-2xl font-bold text-gray-900">
                  {selectedModel.name}
                </h1>
              </div>
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

          <div className="space-y-4">
            <Editor
              value={editContent}
              onChange={setEditContent}
              title={editTitle}
              onTitleChange={setEditTitle}
              placeholder="Fügen Sie hier Ihren Präsentationsinhalt ein. Verwenden Sie den Divider-Button, um neue Folien zu erstellen..."
            />
            <div className="flex justify-end space-x-2">
              <button
                onClick={() => {
                  setSelectedModel(null);
                  setEditContent('');
                  setEditTitle('');
                }}
                className="px-4 py-2 text-sm text-gray-600 hover:text-gray-900"
              >
                Abbrechen
              </button>
              <button
                onClick={handlePreview}
                className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <ChevronRight className="h-4 w-4 mr-1" />
                Vorschau
              </button>
              <button
                onClick={handleSave}
                disabled={isLoading}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                {isLoading ? (
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                ) : (
                  <Save className="h-4 w-4" />
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-[1920px] mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigate(-1)}
              className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
              title="Zurück"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <h1 className="text-2xl font-bold text-gray-900">Präsentationen</h1>
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

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {deviceTypes.map((type) => (
            <div key={type.id} className="bg-white rounded-lg shadow-sm border">
              {/* Type Header */}
              <div 
                className="p-4 border-b cursor-pointer hover:bg-gray-50 transition-colors"
                onClick={() => toggleTypeExpansion(type.id)}
              >
                <div className="flex items-center justify-between">
                  <h3 className="font-medium text-gray-900">{type.name}</h3>
                  <ChevronDown 
                    className={`h-5 w-5 text-gray-400 transform transition-transform ${
                      expandedTypes[type.id] ? 'rotate-180' : ''
                    }`}
                  />
                </div>
                {type.description && (
                  <p className="text-sm text-gray-500 mt-1">{type.description}</p>
                )}
              </div>

              {/* Models List */}
              {expandedTypes[type.id] && deviceModels[type.id]?.map((model) => (
                <div
                  key={model.id}
                  className="border-b last:border-b-0"
                >
                  <div className="p-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-medium text-gray-800">{model.name}</h4>
                        {model.description && (
                          <p className="text-sm text-gray-500">{model.description}</p>
                        )}
                      </div>
                    </div>

                    <div className="mt-3 flex items-center justify-between">
                      {presentations[model.id] ? (
                        <>
                          <button
                            onClick={() => setSelectedPresentation(presentations[model.id])}
                            className="text-sm text-blue-600 hover:text-blue-800"
                          >
                            {presentations[model.id].title || model.name}
                          </button>
                          {isAdmin && (
                            <div className="flex space-x-2">
                              <button
                                onClick={() => {
                                  setSelectedModel(model);
                                  setEditContent(presentations[model.id].content.replace(/<div class="slide">/g, '').replace(/<\/div>/g, '<hr class="slide-divider">'));
                                  setEditTitle(presentations[model.id].title);
                                }}
                                className="p-1 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                title="Bearbeiten"
                              >
                                <Settings className="h-4 w-4" />
                              </button>
                              <button
                                onClick={() => handleDelete(model.id)}
                                className="p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                title="Löschen"
                              >
                                <X className="h-4 w-4" />
                              </button>
                            </div>
                          )}
                        </>
                      ) : isAdmin && (
                        <button
                          onClick={() => {
                            setSelectedModel(model);
                            setEditContent('');
                            setEditTitle('');
                          }}
                          className="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm text-gray-600 hover:bg-gray-50 transition-colors"
                        >
                          Präsentation erstellen
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ))}
        </div>
      </div>

      {selectedPresentation && (
        <PresentationViewer
          presentation={selectedPresentation}
          onClose={() => setSelectedPresentation(null)}
        />
      )}
    </div>
  );
}