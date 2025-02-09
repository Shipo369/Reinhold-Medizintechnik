-- First, delete duplicate requests keeping only the latest one
WITH duplicates AS (
  SELECT user_id, exam_id, device_model_id, 
         ROW_NUMBER() OVER (
           PARTITION BY user_id, exam_id, device_model_id 
           ORDER BY created_at DESC
         ) as rn
  FROM certificate_requests
)
DELETE FROM certificate_requests
WHERE id IN (
  SELECT cr.id
  FROM certificate_requests cr
  JOIN duplicates d ON 
    cr.user_id = d.user_id AND 
    cr.exam_id = d.exam_id AND 
    cr.device_model_id = d.device_model_id
  WHERE d.rn > 1
);

-- Now we can safely add the unique constraint
ALTER TABLE certificate_requests
  ADD CONSTRAINT certificate_requests_unique_request 
  UNIQUE (user_id, exam_id, device_model_id);