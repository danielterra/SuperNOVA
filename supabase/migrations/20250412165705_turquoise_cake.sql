/*
  # Add service role policy for messages table

  1. Changes
    - Add policy to allow service role to insert messages
    - This allows the edge function (which uses service role) to insert messages

  2. Security
    - Enable service role access for message insertion
    - Maintains existing RLS policies
*/

CREATE POLICY "Service role can insert messages"
  ON messages
  FOR INSERT
  TO service_role
  WITH CHECK (true);