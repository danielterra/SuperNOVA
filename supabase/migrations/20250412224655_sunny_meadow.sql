/*
  # Add user thought ID tracking

  1. Changes
    - Add `thought_id` column to `user_settings` table to store the ID of the thought that represents the user in TheBrain

  2. Security
    - Maintain existing RLS policies
*/

ALTER TABLE user_settings 
ADD COLUMN thought_id text;