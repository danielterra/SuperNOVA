import React, { useEffect, useState } from 'react';
import { MessageSquare, Trash2 } from 'lucide-react';
import { format } from 'date-fns';
import { supabase } from '../lib/supabase';
import type { ChatSession } from '../types';

interface ChatSessionsListProps {
  currentSessionId: string | null;
  onSelectSession: (session: ChatSession) => void;
}

export function ChatSessionsList({ currentSessionId, onSelectSession }: ChatSessionsListProps) {
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleting, setDeleting] = useState<string | null>(null);

  useEffect(() => {
    loadSessions();
    
    // Subscribe to changes in chat_sessions table
    const channel = supabase
      .channel('chat_sessions_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'chat_sessions'
        },
        () => {
          loadSessions();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const loadSessions = async () => {
    try {
      const { data, error } = await supabase
        .from('chat_sessions')
        .select('*')
        .order('updated_at', { ascending: false });

      if (error) throw error;
      setSessions(data || []);
    } catch (error) {
      console.error('Error loading chat sessions:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (sessionId: string, e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent session selection when clicking delete
    
    if (!confirm('Are you sure you want to delete this chat session? This action cannot be undone.')) {
      return;
    }

    setDeleting(sessionId);
    try {
      const { error } = await supabase
        .from('chat_sessions')
        .delete()
        .eq('id', sessionId);

      if (error) throw error;

      // If the deleted session was the current one, clear it
      if (sessionId === currentSessionId) {
        onSelectSession(null as any);
      }

      // Reload sessions to update the list
      loadSessions();
    } catch (error) {
      console.error('Error deleting chat session:', error);
      alert('Failed to delete chat session. Please try again.');
    } finally {
      setDeleting(null);
    }
  };

  if (loading) {
    return (
      <div className="px-4 py-2 text-sm text-gray-500">
        Loading sessions...
      </div>
    );
  }

  if (sessions.length === 0) {
    return (
      <div className="px-4 py-2 text-sm text-gray-500">
        No chat sessions yet
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto">
      {sessions.map((session) => (
        <div
          key={session.id}
          className={`group flex items-center px-4 py-2 hover:bg-gray-800 ${
            session.id === currentSessionId ? 'bg-gray-800' : ''
          }`}
        >
          <button
            onClick={() => onSelectSession(session)}
            className="flex-1 flex items-center gap-2 text-left min-w-0"
          >
            <MessageSquare className="w-4 h-4 text-gray-500 flex-shrink-0" />
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium text-white truncate">
                {session.title}
              </div>
              <div className="text-xs text-gray-400">
                {format(new Date(session.created_at), 'MMM d, yyyy')}
              </div>
            </div>
          </button>
          <button
            onClick={(e) => handleDelete(session.id, e)}
            className={`p-1 rounded-full hover:bg-red-100 ${
              deleting === session.id ? 'opacity-50 cursor-not-allowed' : 'opacity-0 group-hover:opacity-100'
            }`}
            disabled={deleting === session.id}
            title="Delete chat session"
          >
            <Trash2 className="w-4 h-4 text-red-600" />
          </button>
        </div>
      ))}
    </div>
  );
}