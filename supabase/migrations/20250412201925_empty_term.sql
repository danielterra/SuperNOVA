/*
  # Add developer mode to user settings

  1. Changes
    - Add developer_mode column to user_settings table
*/

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_settings' 
    AND column_name = 'developer_mode'
  ) THEN
    ALTER TABLE user_settings ADD COLUMN developer_mode boolean DEFAULT false;
  END IF;
END $$;