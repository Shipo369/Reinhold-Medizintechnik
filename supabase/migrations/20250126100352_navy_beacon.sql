-- Drop tables in correct order (respecting dependencies)
DROP TABLE IF EXISTS exam_attempts CASCADE;
DROP TABLE IF EXISTS exam_answers CASCADE;
DROP TABLE IF EXISTS exam_questions CASCADE;
DROP TABLE IF EXISTS module_exams CASCADE;

-- Create module_exams table
CREATE TABLE module_exams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  passing_score INTEGER NOT NULL DEFAULT 70,
  time_limit INTEGER NOT NULL DEFAULT 60,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create exam_questions table
CREATE TABLE exam_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID REFERENCES module_exams(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  image_path TEXT,
  question_type TEXT NOT NULL CHECK (question_type IN ('single', 'multiple')),
  points INTEGER NOT NULL DEFAULT 1,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create exam_answers table
CREATE TABLE exam_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES exam_questions(id) ON DELETE CASCADE,
  answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL DEFAULT false,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create exam_attempts table
CREATE TABLE exam_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id UUID REFERENCES module_exams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  passed BOOLEAN NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  answers JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE module_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;

-- Create storage bucket for exam images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('exam-images', 'exam-images', false)
ON CONFLICT DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view exams" ON module_exams;
DROP POLICY IF EXISTS "Admins can manage exams" ON module_exams;
DROP POLICY IF EXISTS "Users can view exam questions" ON exam_questions;
DROP POLICY IF EXISTS "Admins can manage exam questions" ON exam_questions;
DROP POLICY IF EXISTS "Users can view exam answers" ON exam_answers;
DROP POLICY IF EXISTS "Admins can manage exam answers" ON exam_answers;
DROP POLICY IF EXISTS "Users can view and manage their own exam attempts" ON exam_attempts;
DROP POLICY IF EXISTS "Admins can view all exam attempts" ON exam_attempts;

-- Policies for module_exams
CREATE POLICY "Users can view exams"
  ON module_exams
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage exams"
  ON module_exams
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for exam_questions
CREATE POLICY "Users can view exam questions"
  ON exam_questions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage exam questions"
  ON exam_questions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for exam_answers
CREATE POLICY "Users can view exam answers"
  ON exam_answers
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage exam answers"
  ON exam_answers
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Policies for exam_attempts
CREATE POLICY "Users can view and manage their own exam attempts"
  ON exam_attempts
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view all exam attempts"
  ON exam_attempts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Update triggers
CREATE TRIGGER update_module_exams_updated_at
  BEFORE UPDATE ON module_exams
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exam_questions_updated_at
  BEFORE UPDATE ON exam_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();