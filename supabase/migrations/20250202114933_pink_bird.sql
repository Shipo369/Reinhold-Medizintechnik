-- Drop existing function first
DROP FUNCTION IF EXISTS get_random_exam_questions(UUID, INTEGER);

-- Create improved function with better distribution logic
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
SET search_path = public
AS $$
DECLARE
  v_total_questions INTEGER;
  v_easy_count INTEGER;
  v_medium_count INTEGER;
  v_hard_count INTEGER;
  v_exam_record module_exams%ROWTYPE;
  v_available_easy INTEGER;
  v_available_medium INTEGER;
  v_available_hard INTEGER;
BEGIN
  -- Get exam details
  SELECT * INTO v_exam_record
  FROM module_exams
  WHERE id = p_exam_id;

  -- Get available questions count per difficulty
  SELECT COUNT(*) INTO v_available_easy
  FROM exam_questions
  WHERE exam_id = p_exam_id AND difficulty = 'easy';

  SELECT COUNT(*) INTO v_available_medium
  FROM exam_questions
  WHERE exam_id = p_exam_id AND difficulty = 'medium';

  SELECT COUNT(*) INTO v_available_hard
  FROM exam_questions
  WHERE exam_id = p_exam_id AND difficulty = 'hard';

  -- Use specified count or exam default
  v_total_questions := COALESCE(p_questions_per_exam, v_exam_record.questions_per_exam);
  
  -- Calculate initial distribution
  v_easy_count := GREATEST(1, ROUND(v_total_questions * v_exam_record.easy_questions_percentage / 100.0));
  v_medium_count := GREATEST(1, ROUND(v_total_questions * v_exam_record.medium_questions_percentage / 100.0));
  v_hard_count := GREATEST(1, ROUND(v_total_questions * v_exam_record.hard_questions_percentage / 100.0));

  -- Adjust for available questions
  v_easy_count := LEAST(v_easy_count, v_available_easy);
  v_medium_count := LEAST(v_medium_count, v_available_medium);
  v_hard_count := LEAST(v_hard_count, v_available_hard);

  -- Adjust total to match requested count
  WHILE (v_easy_count + v_medium_count + v_hard_count) > v_total_questions LOOP
    IF v_hard_count > 1 THEN
      v_hard_count := v_hard_count - 1;
    ELSIF v_medium_count > 1 THEN
      v_medium_count := v_medium_count - 1;
    ELSIF v_easy_count > 1 THEN
      v_easy_count := v_easy_count - 1;
    END IF;
  END LOOP;

  -- If we still need more questions, add them based on availability
  WHILE (v_easy_count + v_medium_count + v_hard_count) < v_total_questions LOOP
    IF v_easy_count < v_available_easy THEN
      v_easy_count := v_easy_count + 1;
    ELSIF v_medium_count < v_available_medium THEN
      v_medium_count := v_medium_count + 1;
    ELSIF v_hard_count < v_available_hard THEN
      v_hard_count := v_hard_count + 1;
    ELSE
      EXIT; -- Cannot add more questions
    END IF;
  END LOOP;

  RETURN QUERY
  WITH all_questions AS (
    (SELECT 
      eq.id,
      eq.question,
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
    GROUP BY eq.id
    ORDER BY random()
    LIMIT v_easy_count)
    
    UNION ALL
    
    (SELECT 
      eq.id,
      eq.question,
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
    GROUP BY eq.id
    ORDER BY random()
    LIMIT v_medium_count)
    
    UNION ALL
    
    (SELECT 
      eq.id,
      eq.question,
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
    GROUP BY eq.id
    ORDER BY random()
    LIMIT v_hard_count)
  )
  SELECT 
    id as question_id,
    question as question_text,
    question_type,
    difficulty,
    image_path,
    answers
  FROM (
    SELECT *, random() as rand
    FROM all_questions
  ) q
  ORDER BY rand;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_random_exam_questions(UUID, INTEGER) TO authenticated;