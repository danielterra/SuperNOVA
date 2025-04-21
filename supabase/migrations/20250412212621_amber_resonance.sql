/*
  # Update messages role check constraint

  1. Changes
    - Drop existing role check constraint
    - Add new role check constraint that includes 'tool' and 'function' roles
    - Add index on tool_call_id for better query performance

  2. Security
    - Maintains existing RLS policies
*/

-- Drop existing role check constraint
ALTER TABLE messages
DROP CONSTRAINT IF EXISTS messages_role_check;

-- Add new role check constraint with additional roles
ALTER TABLE messages
ADD CONSTRAINT messages_role_check
CHECK (role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text, 'tool'::text, 'function'::text]));

-- Add index on tool_call_id for better performance
CREATE INDEX IF NOT EXISTS messages_tool_call_id_idx ON messages (tool_call_id);