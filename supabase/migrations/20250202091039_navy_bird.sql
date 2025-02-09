-- Add difficulty levels and question pool management

-- Add difficulty to exam questions
ALTER TABLE exam_questions
  ADD COLUMN difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')) NOT NULL DEFAULT 'medium';

-- Add difficulty distribution and question count to exams
ALTER TABLE module_exams
  ADD COLUMN easy_questions_percentage INTEGER CHECK (easy_questions_percentage BETWEEN 0 AND 100) DEFAULT 33,
  ADD COLUMN medium_questions_percentage INTEGER CHECK (medium_questions_percentage BETWEEN 0 AND 100) DEFAULT 34,
  ADD COLUMN hard_questions_percentage INTEGER CHECK (hard_questions_percentage BETWEEN 0 AND 100) DEFAULT 33,
  ADD COLUMN questions_per_exam INTEGER CHECK (questions_per_exam > 0),
  ADD CONSTRAINT percentages_sum_check CHECK (
    easy_questions_percentage + medium_questions_percentage + hard_questions_percentage = 100
  );

-- Create question usage tracking
CREATE TABLE question_usage_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID REFERENCES exam_questions(id) ON DELETE CASCADE,
  exam_attempt_id UUID REFERENCES exam_attempts(id) ON DELETE CASCADE,
  used_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(question_id, exam_attempt_id)
);

-- Enable RLS
ALTER TABLE question_usage_tracking ENABLE ROW LEVEL SECURITY;

-- Create policies for tracking
CREATE POLICY "tracking_insert_policy" 
  ON question_usage_tracking
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "tracking_select_policy"
  ON question_usage_tracking
  FOR SELECT TO authenticated
  USING (true);

-- Create function to select random questions based on difficulty distribution
CREATE OR REPLACE FUNCTION get_random_exam_questions(
  p_exam_id UUID,
  p_questions_per_exam INTEGER DEFAULT NULL
)
RETURNS TABLE (
  question_id UUID,
  question TEXT,
  question_type TEXT,
  difficulty TEXT,
  image_path TEXT,
  answers JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_questions INTEGER;
  v_easy_count INTEGER;
  v_medium_count INTEGER;
  v_hard_count INTEGER;
  v_exam_record module_exams%ROWTYPE;
BEGIN
  -- Get exam details
  SELECT * INTO v_exam_record
  FROM module_exams
  WHERE id = p_exam_id;

  -- Use specified count or all questions if not set
  v_total_questions := COALESCE(p_questions_per_exam, v_exam_record.questions_per_exam);
  IF v_total_questions IS NULL THEN
    SELECT COUNT(*) INTO v_total_questions
    FROM exam_questions
    WHERE exam_id = p_exam_id;
  END IF;

  -- Calculate counts for each difficulty
  v_easy_count := (v_total_questions * v_exam_record.easy_questions_percentage / 100)::INTEGER;
  v_medium_count := (v_total_questions * v_exam_record.medium_questions_percentage / 100)::INTEGER;
  v_hard_count := v_total_questions - v_easy_count - v_medium_count;

  RETURN QUERY
  WITH question_selection AS (
    (SELECT 
      q.id,
      q.question,
      q.question_type,
      q.difficulty,
      q.image_path,
      jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'answer', a.answer,
          'is_correct', a.is_correct
        ) ORDER BY random()
      ) as answers
    FROM exam_questions q
    JOIN exam_answers a ON q.id = a.question_id
    WHERE q.exam_id = p_exam_id
    AND q.difficulty = 'easy'
    GROUP BY q.id
    ORDER BY random()
    LIMIT v_easy_count)
    
    UNION ALL
    
    (SELECT 
      q.id,
      q.question,
      q.question_type,
      q.difficulty,
      q.image_path,
      jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'answer', a.answer,
          'is_correct', a.is_correct
        ) ORDER BY random()
      ) as answers
    FROM exam_questions q
    JOIN exam_answers a ON q.id = a.question_id
    WHERE q.exam_id = p_exam_id
    AND q.difficulty = 'medium'
    GROUP BY q.id
    ORDER BY random()
    LIMIT v_medium_count)
    
    UNION ALL
    
    (SELECT 
      q.id,
      q.question,
      q.question_type,
      q.difficulty,
      q.image_path,
      jsonb_agg(
        jsonb_build_object(
          'id', a.id,
          'answer', a.answer,
          'is_correct', a.is_correct
        ) ORDER BY random()
      ) as answers
    FROM exam_questions q
    JOIN exam_answers a ON q.id = a.question_id
    WHERE q.exam_id = p_exam_id
    AND q.difficulty = 'hard'
    GROUP BY q.id
    ORDER BY random()
    LIMIT v_hard_count)
  )
  SELECT 
    question_id,
    question,
    question_type,
    difficulty,
    image_path,
    answers
  FROM (
    SELECT
      id as question_id,
      question,
      question_type,
      difficulty,
      image_path,
      answers,
      random() as rand
    FROM question_selection
  ) q
  ORDER BY rand;
END;
$$;