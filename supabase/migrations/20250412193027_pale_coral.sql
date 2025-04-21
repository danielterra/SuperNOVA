/*
  # Add OpenAI API key to user settings

  1. Changes
    - Add `openai_api_key` column to `user_settings` table
*/

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_settings' AND column_name = 'openai_api_key'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN openai_api_key text;
  END IF;
END $$;