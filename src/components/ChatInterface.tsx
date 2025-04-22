import React from 'react';
import { MessageList } from './MessageList';
import { ChatInput } from './ChatInput';
import type { Message, ChatSession } from '../types';

interface ChatInterfaceProps {
  messages: Message[];
  currentChatSession: ChatSession | null;
  input: string;
  loading: boolean;
  error: string | null;
  onInputChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => Promise<void>;
}

export function ChatInterface({
  messages,
  currentChatSession,
  input,
  loading,
  error,
  onInputChange,
  onSubmit
}: ChatInterfaceProps) {
  return (
    <>
      {error && (
        <div className="p-4 bg-red-800 border-b border-red-600">
          <p className="text-red-400">{error}</p>
        </div>
      )}
      
      <MessageList messages={messages} />

      <ChatInput
        input={input}
        loading={loading}
        onInputChange={onInputChange}
        onSubmit={onSubmit}
        sessionId={currentChatSession?.id}
      />
    </>
  );
}