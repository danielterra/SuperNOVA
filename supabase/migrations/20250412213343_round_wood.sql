-- Add tool_calls column to messages table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' 
    AND column_name = 'tool_calls'
  ) THEN
    ALTER TABLE messages 
    ADD COLUMN tool_calls jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' 
    AND column_name = 'name'
  ) THEN
    ALTER TABLE messages 
    ADD COLUMN name text;
  END IF;
END $$;