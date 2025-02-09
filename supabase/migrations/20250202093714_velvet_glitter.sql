-- Drop existing function first
DROP FUNCTION IF EXISTS get_random_exam_questions(UUID, INTEGER);

-- Recreate function with updated return type
CREATE OR REPLACE FUNCTION get_random_exam_questions(
  p_exam_id UUID,
  p_questions_per_exam INTEGER DEFAULT NULL
)
RETURNS TABLE (
  question_id UUID,
  question_text TEXT,
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
      eq.id,
      eq.question as question_text,
      eq.question_type,
      eq.difficulty,
      eq.image_path,
      jsonb_agg(
        jsonb_build_object(
          'id', ea.id,
          'answer', ea.answer,
          'is_correct', ea.is_correct
        ) ORDER BY random()
      ) as answers
    FROM exam_questions eq
    JOIN exam_answers ea ON eq.id = ea.question_id
    WHERE eq.exam_id = p_exam_id
    AND eq.difficulty = 'easy'
    GROUP BY eq.id, eq.question, eq.question_type, eq.difficulty, eq.image_path
    ORDER BY random()
    LIMIT v_easy_count)
    
    UNION ALL
    
    (SELECT 
      eq.id,
      eq.question as question_text,
      eq.question_type,
      eq.difficulty,
      eq.image_path,
      jsonb_agg(
        jsonb_build_object(
          'id', ea.id,
          'answer', ea.answer,
          'is_correct', ea.is_correct
        ) ORDER BY random()
      ) as answers
    FROM exam_questions eq
    JOIN exam_answers ea ON eq.id = ea.question_id
    WHERE eq.exam_id = p_exam_id
    AND eq.difficulty = 'medium'
    GROUP BY eq.id, eq.question, eq.question_type, eq.difficulty, eq.image_path
    ORDER BY random()
    LIMIT v_medium_count)
    
    UNION ALL
    
    (SELECT 
      eq.id,
      eq.question as question_text,
      eq.question_type,
      eq.difficulty,
      eq.image_path,
      jsonb_agg(
        jsonb_build_object(
          'id', ea.id,
          'answer', ea.answer,
          'is_correct', ea.is_correct
        ) ORDER BY random()
      ) as answers
    FROM exam_questions eq
    JOIN exam_answers ea ON eq.id = ea.question_id
    WHERE eq.exam_id = p_exam_id
    AND eq.difficulty = 'hard'
    GROUP BY eq.id, eq.question, eq.question_type, eq.difficulty, eq.image_path
    ORDER BY random()
    LIMIT v_hard_count)
  )
  SELECT 
    question_id,
    question_text,
    question_type,
    difficulty,
    image_path,
    answers
  FROM (
    SELECT
      id as question_id,
      question_text,
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