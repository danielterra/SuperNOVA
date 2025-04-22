import React, { useRef, useEffect } from 'react';

interface ChatInputProps {
  input: string;
  loading: boolean;
  onInputChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => Promise<void>;
  // sessionId triggers refocus when chat session changes
  sessionId?: string | null;
}

export function ChatInput({ input, loading, onInputChange, onSubmit, sessionId }: ChatInputProps) {
  const inputRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    // Focus input on component mount
    inputRef.current?.focus();
  }, []);

  // Add effect to refocus when input is cleared
  useEffect(() => {
    if (input === '') {
      inputRef.current?.focus();
    }
  }, [input]);

  // Refocus input when chat session changes
  useEffect(() => {
    inputRef.current?.focus();
  }, [sessionId]);
  // Global slash keypress focuses input when not already focused
  useEffect(() => {
    const handleSlash = (e: KeyboardEvent) => {
      if (e.key === '/' && document.activeElement !== inputRef.current) {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    window.addEventListener('keydown', handleSlash);
    return () => window.removeEventListener('keydown', handleSlash);
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSubmit(e);
    // Re-focus the input after sending
    inputRef.current?.focus();
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="flex gap-4">
        <textarea
          id="chat-input"
          ref={inputRef}
          value={input}
          onChange={(e) => onInputChange(e.target.value)}
          placeholder="Type your message..."
          className="flex-1 resize-none outline-none text-white bg-transparent border-b-2 border-orange-600 focus:border-orange-500 focus:ring-orange-500"
          disabled={loading}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              handleSubmit(e as unknown as React.FormEvent);
            }
          }}
        />
      </div>
    </form>
  );
}