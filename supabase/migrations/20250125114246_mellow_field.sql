-- Update module_documents to link directly to device_models
ALTER TABLE module_documents
  DROP CONSTRAINT module_documents_module_id_fkey,
  ADD COLUMN device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  ALTER COLUMN module_id DROP NOT NULL;

-- Update module_exams to link directly to device_models
ALTER TABLE module_exams
  DROP CONSTRAINT module_exams_module_id_fkey,
  ADD COLUMN device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  ALTER COLUMN module_id DROP NOT NULL;

-- Add indexes for better query performance
CREATE INDEX idx_module_documents_device_model_id ON module_documents(device_model_id);
CREATE INDEX idx_module_exams_device_model_id ON module_exams(device_model_id);

-- Update existing records if any
UPDATE module_documents
SET device_model_id = (
  SELECT device_model_id 
  FROM learning_modules 
  WHERE learning_modules.id = module_documents.module_id
)
WHERE module_id IS NOT NULL;

UPDATE module_exams
SET device_model_id = (
  SELECT device_model_id 
  FROM learning_modules 
  WHERE learning_modules.id = module_exams.module_id
)
WHERE module_id IS NOT NULL;