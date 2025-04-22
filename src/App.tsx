import React, { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import type { Session } from '@supabase/supabase-js';
import type { Message, ChatSession } from './types';
import { AuthForm } from './components/AuthForm';
// Sidebar removed: chat session selection is automatic
import { ConfigurationRequired } from './components/ConfigurationRequired';
import { ChatInterface } from './components/ChatInterface';
import { CommandBar } from './components/CommandBar';
import type { Command } from './components/CommandBar';
import { Settings } from './components/Settings';
import { sendMessage } from './lib/chat';
import { Plex } from './components/Plex';
import { getUserThoughtId } from './lib/thebrain';

function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [isSignup, setIsSignup] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentChatSession, setCurrentChatSession] = useState<ChatSession | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [showSettings, setShowSettings] = useState(false);
  // Close settings on ESC key
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        setShowSettings(false);
      }
    };
    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, []);
  // Open settings on Ctrl+S (or Cmd+S)
  useEffect(() => {
    const handleSaveShortcut = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
        e.preventDefault();
        setShowSettings(true);
      }
    };
    window.addEventListener('keydown', handleSaveShortcut);
    return () => window.removeEventListener('keydown', handleSaveShortcut);
  }, []);
  // Create new chat session on Ctrl+N (or Cmd+N)
  useEffect(() => {
    const handleNewChatShortcut = async (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'n') {
        e.preventDefault();
        try {
          const newSession = await createNewChatSession();
          if (newSession) {
            setCurrentChatSession(newSession);
            setMessages([]);
          }
        } catch (err) {
          console.error('Error creating new chat session via shortcut:', err);
        }
      }
    };
    window.addEventListener('keydown', handleNewChatShortcut);
    return () => window.removeEventListener('keydown', handleNewChatShortcut);
  }, [session]);
  // Open settings on '?' key when input not focused
  useEffect(() => {
    const handleQuestionShortcut = (e: KeyboardEvent) => {
      if (e.key === '?' && document.activeElement?.id !== 'chat-input') {
        e.preventDefault();
        setShowSettings(true);
      }
    };
    window.addEventListener('keydown', handleQuestionShortcut);
    return () => window.removeEventListener('keydown', handleQuestionShortcut);
  }, []);
  const [openAIKey, setOpenAIKey] = useState<string | null>(null);
  const [theBrainApiKey, setTheBrainApiKey] = useState<string | null>(null);
  const [brainId, setBrainId] = useState<string | null>(null);
  const [settingsLoading, setSettingsLoading] = useState(false);
  const [settingsRetryCount, setSettingsRetryCount] = useState(0);
  // Selected thought for PLEX view
  const [selectedThoughtId, setSelectedThoughtId] = useState<string | null>(null);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (session?.user) {
      loadUserSettings();
    }
  }, [session]);

  // On initial load, automatically select the latest chat session if none selected
  useEffect(() => {
    const fetchLatestSession = async () => {
      if (session?.user && !currentChatSession) {
        try {
          const { data, error } = await supabase
            .from('chat_sessions')
            .select('*')
            .eq('user_id', session.user.id)
            .order('updated_at', { ascending: false })
            .limit(1);
          if (!error && data) {
            if (data.length > 0) {
              setCurrentChatSession(data[0]);
            } else {
              // No existing session, create a new one
              const newSession = await createNewChatSession();
              if (newSession) setCurrentChatSession(newSession);
            }
          }
        } catch (err) {
          console.error('Error loading latest chat session:', err);
        }
      }
    };
    fetchLatestSession();
  }, [session, currentChatSession]);

  useEffect(() => {
    if (currentChatSession) {
      loadMessages();
    } else {
      setMessages([]);
    }
  }, [currentChatSession]);
  // Load initial selected thought for PLEX when settings are available
  useEffect(() => {
    if (theBrainApiKey && brainId) {
      getUserThoughtId()
        .then((id) => {
          if (id) setSelectedThoughtId(id);
        })
        .catch((err) => console.error('Error loading user thought ID:', err));
    }
  }, [theBrainApiKey, brainId]);

  const loadMessages = async () => {
    if (!currentChatSession) return;

    try {
      const { data, error } = await supabase
        .from('messages')
        .select('*')
        .eq('session_id', currentChatSession.id)
        .order('created_at', { ascending: true });

      if (error) throw error;
      setMessages(data || []);
    } catch (error) {
      console.error('Error loading messages:', error);
      setError('Failed to load messages');
    }
  };

  const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

  const loadUserSettings = async (retryCount = 0) => {
    if (settingsLoading) return;
    setSettingsLoading(true);
    setSettingsRetryCount(retryCount);

    try {
      // Check network connectivity
      if (!navigator.onLine) {
        throw new Error('No internet connection. Please check your network and try again.');
      }

      const { data, error } = await supabase
        .from('user_settings')
        .select('openai_api_key, thebrain_api_key, brain_id')
        .eq('user_id', session?.user?.id)
        .single();

      if (error) throw error;
      
      setOpenAIKey(data?.openai_api_key || null);
      setTheBrainApiKey(data?.thebrain_api_key || null);
      setBrainId(data?.brain_id || null);
      setError(null);
    } catch (error) {
      console.error('Error loading user settings:', error);
      
      // Handle specific error types
      if (!navigator.onLine) {
        setError('No internet connection. Please check your network and try again.');
      } else if (error instanceof Error && error.message.includes('Failed to fetch')) {
        setError('Unable to connect to the server. Please check your connection and try again.');
      } else {
        setError('Failed to load settings. Please try again later.');
      }

      // Implement retry mechanism with exponential backoff
      if (retryCount < 3) {
        const retryDelay = Math.min(1000 * Math.pow(2, retryCount), 5000);
        await delay(retryDelay);
        setSettingsLoading(false);
        loadUserSettings(retryCount + 1);
        return;
      }
    } finally {
      setSettingsLoading(false);
    }
  };

  const createNewChatSession = async () => {
    if (!session?.user) return null;
    
    try {
      const { data, error } = await supabase
        .from('chat_sessions')
        .insert({
          user_id: session.user.id,
          title: 'New Chat'
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error creating chat session:', error);
      setError('Failed to create chat session');
      return null;
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const formData = new FormData(e.target as HTMLFormElement);
    const email = formData.get('email') as string;
    const password = formData.get('password') as string;

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error('Login error:', error.message);
      setError(error.message);
    }
  };

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const formData = new FormData(e.target as HTMLFormElement);
    const email = formData.get('email') as string;
    const password = formData.get('password') as string;

    const { error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      console.error('Signup error:', error.message);
      setError(error.message);
    } else {
      console.log('Signup successful. Check your email for confirmation.');
      setIsSignup(false);
    }
  };

  // Removed manual new chat; new session auto-created

  // Removed manual session selection

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !session?.user || !theBrainApiKey || !brainId || !openAIKey) return;

    setLoading(true);
    setError(null);

    try {
      let chatSession = currentChatSession;
      
      // If there's no current chat session, create a new one
      if (!chatSession) {
        const newSession = await createNewChatSession();
        if (!newSession) {
          throw new Error('Failed to create chat session');
        }
        chatSession = newSession;
        setCurrentChatSession(newSession);
      }

      // Add explicit validation for chatSession and its id
      if (!chatSession || !chatSession.id) {
        console.error('Invalid chat session:', chatSession);
        throw new Error('Invalid chat session. Please try starting a new chat.');
      }

      const currentInput = input;
      setInput('');

      await sendMessage({
        input: currentInput,
        chatSession: chatSession,
        theBrainApiKey,
        brainId,
        openAIKey,
        onUpdate: setMessages,
        onToolCall: ({ name, args, result }) => {
          if (args?.thoughtId) {
            setSelectedThoughtId(args.thoughtId);
          } else if (result && typeof result === 'object' && 'id' in result) {
            setSelectedThoughtId((result as any).id);
          }
        },
      });
    } catch (error) {
      console.error('Error sending message:', error);
      setError(error instanceof Error ? error.message : 'An error occurred while sending the message');
      setInput(input); // Restore the input if sending failed
    } finally {
      setLoading(false);
    }
  };

  if (!session) {
    return (
      <AuthForm
        error={error}
        isSignup={isSignup}
        onSubmit={isSignup ? handleSignup : handleLogin}
        onToggleMode={() => setIsSignup(!isSignup)}
      />
    );
  }
  
  // Command definitions for CommandBar
  const commands: Command[] = [
    { keys: 'Enter', description: 'Send Message', visible: 'inputFocused' },
    { keys: 'Ctrl + S', description: 'Show Settings', visible: 'inputFocused' },
    { keys: 'Ctrl + N', description: 'New Chat', visible: 'always' },
    { keys: '/', description: 'Focus Input', visible: 'notInputFocused' },
    { keys: 'Esc', description: 'Close Settings', visible: 'notInputFocused' },
    { keys: '?', description: 'Open Settings', visible: 'notInputFocused' },
  ];

  return (
    <div className="flex flex-col h-screen bg-black text-white">
      <div className="flex-1 flex overflow-hidden">
        <div className="flex-1 flex flex-col overflow-y-auto m-5 rounded-[20px]">
          <Plex
            apiKey={theBrainApiKey}
            brainId={brainId}
            thoughtId={selectedThoughtId}
            onSelect={setSelectedThoughtId}
          />
        </div>

        <div className="flex-none w-full max-w-[600px] flex flex-col overflow-y-auto">
          {showSettings ? (
            <div className="p-4">
              <Settings />
            </div>
          ) : !theBrainApiKey || !brainId || !openAIKey ? (
            <ConfigurationRequired
              onOpenSettings={() => setShowSettings(true)}
              error={error}
              isLoading={settingsLoading}
              onRetry={() => {
                setError(null);
                loadUserSettings(0);
              }}
            />
          ) : (
            <ChatInterface
              messages={messages}
              currentChatSession={currentChatSession}
              input={input}
              loading={loading}
              error={error}
              onInputChange={setInput}
              onSubmit={handleSendMessage}
            />
          )}
        </div>
      </div>
      <CommandBar commands={commands} />
    </div>
  );
}

export default App;