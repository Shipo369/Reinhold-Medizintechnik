/*
  # Add learning content tables

  1. New Tables
    - `learning_modules` - For module content per device model
    - `module_sections` - For organizing content into sections
    - `module_documents` - For storing document metadata
    - `module_exams` - For exam configuration
    - `exam_questions` - For storing questions
    - `exam_answers` - For storing answer options
    - `user_progress` - For tracking user progress
    - `exam_attempts` - For tracking user exam attempts

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users and admins
*/

-- Learning Modules
CREATE TABLE learning_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  content TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Module Sections
CREATE TABLE module_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID REFERENCES learning_modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Module Documents
CREATE TABLE module_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID REFERENCES learning_modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Module Exams
CREATE TABLE module_exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID REFERENCES learning_modules(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  passing_score INTEGER NOT NULL DEFAULT 70,
  time_limit INTEGER, -- in minutes, NULL for no limit
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Exam Questions
CREATE TABLE exam_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID REFERENCES module_exams(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  question_type TEXT NOT NULL CHECK (question_type IN ('single', 'multiple')),
  order_index INTEGER NOT NULL DEFAULT 0,
  points INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Exam Answers
CREATE TABLE exam_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES exam_questions(id) ON DELETE CASCADE,
  answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT false,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- User Progress
CREATE TABLE user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id UUID REFERENCES learning_modules(id) ON DELETE CASCADE,
  section_id UUID REFERENCES module_sections(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, module_id, section_id)
);

-- Exam Attempts
CREATE TABLE exam_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  exam_id UUID REFERENCES module_exams(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  passed BOOLEAN NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  answers JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE learning_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE module_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;

-- Policies for learning_modules
CREATE POLICY "Users can view learning modules"
  ON learning_modules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage learning modules"
  ON learning_modules
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for module_sections
CREATE POLICY "Users can view module sections"
  ON module_sections FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage module sections"
  ON module_sections
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for module_documents
CREATE POLICY "Users can view module documents"
  ON module_documents FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage module documents"
  ON module_documents
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for module_exams
CREATE POLICY "Users can view module exams"
  ON module_exams FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage module exams"
  ON module_exams
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for exam_questions
CREATE POLICY "Users can view exam questions"
  ON exam_questions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage exam questions"
  ON exam_questions
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for exam_answers
CREATE POLICY "Users can view exam answers"
  ON exam_answers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage exam answers"
  ON exam_answers
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for user_progress
CREATE POLICY "Users can view and manage their own progress"
  ON user_progress
  USING (auth.uid() = user_id);

-- Policies for exam_attempts
CREATE POLICY "Users can view and manage their own exam attempts"
  ON exam_attempts
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all exam attempts"
  ON exam_attempts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create storage bucket for module documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('module-documents', 'module-documents', false)
ON CONFLICT DO NOTHING;

-- Storage policies for module documents
CREATE POLICY "Users can read module documents"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'module-documents');

CREATE POLICY "Admins can manage module documents"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (
    bucket_id = 'module-documents' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Update triggers
CREATE TRIGGER update_learning_modules_updated_at
  BEFORE UPDATE ON learning_modules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_module_sections_updated_at
  BEFORE UPDATE ON module_sections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_module_documents_updated_at
  BEFORE UPDATE ON module_documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_module_exams_updated_at
  BEFORE UPDATE ON module_exams
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_questions_updated_at
  BEFORE UPDATE ON exam_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();