-- Drop existing storage policies for presentations bucket
DROP POLICY IF EXISTS "Allow read access to all authenticated users for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow upload access to admins for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow delete access to admins for presentations storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access for presentations storage" ON storage.objects;

-- Make presentations bucket public if not already
UPDATE storage.buckets
SET public = true
WHERE id = 'presentations'
AND NOT public;

-- Create new storage policies with public access for reading
DO $$ 
BEGIN
  -- Only create policy if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow public read access for presentations storage'
  ) THEN
    CREATE POLICY "Allow public read access for presentations storage"
      ON storage.objects
      FOR SELECT
      USING (bucket_id = 'presentations');
  END IF;

  -- Create upload policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow upload access to admins for presentations storage'
  ) THEN
    CREATE POLICY "Allow upload access to admins for presentations storage"
      ON storage.objects
      FOR INSERT
      TO authenticated
      WITH CHECK (
        bucket_id = 'presentations' AND
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'
        ) AND
        (LOWER(RIGHT(name, 4)) = '.pdf')
      );
  END IF;

  -- Create delete policy
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'storage' 
    AND tablename = 'objects' 
    AND policyname = 'Allow delete access to admins for presentations storage'
  ) THEN
    CREATE POLICY "Allow delete access to admins for presentations storage"
      ON storage.objects
      FOR DELETE
      TO authenticated
      USING (
        bucket_id = 'presentations' AND
        EXISTS (
          SELECT 1 FROM public.profiles
          WHERE profiles.id = auth.uid()
          AND profiles.role = 'admin'
        )
      );
  END IF;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';