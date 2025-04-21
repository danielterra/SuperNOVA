import type { Session } from '@supabase/supabase-js';

export interface Message {
  id?: string;
  content: string;
  role: 'user' | 'assistant' | 'system' | 'tool';
  created_at: string;
  tool_call_id?: string;
  tool_calls?: any[];
  name?: string;
}

export interface ChatSession {
  id: string;
  title: string;
}

export interface UserSettings {
  thebrain_api_key?: string;
  brain_id?: string;
  openai_api_key?: string;
  developer_mode?: boolean;
  thought_id?: string;
}

export interface Brain {
  id: string;
  name: string;
}

export interface TheBrainThought {
  id: string;
  name: string;
  kind: number;
  label?: string;
  typeId?: string;
  typeName?: string;
}

export interface TheBrainLink {
  id: string;
  thoughtIdA: string;
  thoughtIdB: string;
  name?: string;
  direction: number;
  relation: number;
}

export interface ThoughtType {
  id: string;
  name: string;
  description?: string;
  color?: string;
  icon?: string;
}