import React from 'react';
import { MessageCircle, Settings } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { ChatSessionsList } from './ChatSessionsList';
import type { ChatSession } from '../types';

interface SidebarProps {
  onNewChat: () => void;
  onToggleSettings: () => void;
  onSelectSession: (session: ChatSession) => void;
  currentSessionId: string | null;
  isDisabled: boolean;
}

export function Sidebar({ 
  onNewChat, 
  onToggleSettings, 
  onSelectSession,
  currentSessionId,
  isDisabled 
}: SidebarProps) {
  return (
  <div className="w-64 bg-gray-900 border-r border-gray-700 text-white flex flex-col h-full">
      <div className="p-4">
        <button
          onClick={onNewChat}
        className="w-full flex items-center justify-center gap-2 bg-orange-500 text-white rounded-md py-2 hover:bg-orange-600 transition-colors disabled:opacity-50"
          disabled={isDisabled}
        >
          <MessageCircle className="w-4 h-4" />
          New Chat
        </button>
      </div>

      <ChatSessionsList
        currentSessionId={currentSessionId}
        onSelectSession={onSelectSession}
      />

      <div className="mt-auto border-t p-4 space-y-2">
        <button
          onClick={onToggleSettings}
          className="w-full flex items-center gap-2 text-white text-sm hover:text-orange-500"
        >
          <Settings className="w-4 h-4" />
          Settings
        </button>
        <button
          onClick={() => supabase.auth.signOut()}
          className="w-full text-white text-sm hover:text-orange-500"
        >
          Sign Out
        </button>
      </div>
    </div>
  );
}