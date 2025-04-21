/*
  # Add brain_id column to user_settings

  1. Changes
    - Add `brain_id` column to `user_settings` table to store the selected brain ID
    - Make the column nullable since users might not have selected a brain yet

  2. Security
    - No changes to RLS policies needed as we're using existing table
*/

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'brain_id'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN brain_id text;
  END IF;
END $$;