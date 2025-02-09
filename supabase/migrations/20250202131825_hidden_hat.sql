-- Create certificate_requests table
CREATE TABLE certificate_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  exam_id UUID REFERENCES module_exams(id) ON DELETE CASCADE,
  device_model_id UUID REFERENCES device_models(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE certificate_requests ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_certificate_requests_user_id ON certificate_requests(user_id);
CREATE INDEX idx_certificate_requests_exam_id ON certificate_requests(exam_id);
CREATE INDEX idx_certificate_requests_status ON certificate_requests(status);

-- Create policies
CREATE POLICY "Users can view their own certificate requests"
  ON certificate_requests
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can create their own certificate requests"
  ON certificate_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all certificate requests"
  ON certificate_requests
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can update certificate requests"
  ON certificate_requests
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- Create trigger for updated_at
CREATE TRIGGER update_certificate_requests_updated_at
  BEFORE UPDATE ON certificate_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();