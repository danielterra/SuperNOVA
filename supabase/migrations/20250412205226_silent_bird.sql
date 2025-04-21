/*
  # Add tool_call_id column to messages table

  1. Changes
    - Add `tool_call_id` column to `messages` table
      - Type: TEXT
      - Nullable: true
      - Purpose: Store tool call IDs for messages that involve tool interactions

  2. Security
    - No additional security changes needed
    - Existing RLS policies will cover the new column
*/

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' 
    AND column_name = 'tool_call_id'
  ) THEN
    ALTER TABLE messages 
    ADD COLUMN tool_call_id text;
  END IF;
END $$;