import React, { useState, useEffect } from 'react';
import { supabase } from './lib/supabase';
import type { Session } from '@supabase/supabase-js';
import type { Message, ChatSession } from './types';
import { AuthForm } from './components/AuthForm';
import { Sidebar } from './components/Sidebar';
import { ConfigurationRequired } from './components/ConfigurationRequired';
import { ChatInterface } from './components/ChatInterface';
import { Settings } from './components/Settings';
import { sendMessage } from './lib/chat';
import { saveUserThoughtId } from './lib/thebrain';

function App() {
  const [session, setSession] = useState<Session | null>(null);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [isSignup, setIsSignup] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentChatSession, setCurrentChatSession] = useState<ChatSession | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [showSettings, setShowSettings] = useState(false);
  const [openAIKey, setOpenAIKey] = useState<string | null>(null);
  const [theBrainApiKey, setTheBrainApiKey] = useState<string | null>(null);
  const [brainId, setBrainId] = useState<string | null>(null);
  const [settingsLoading, setSettingsLoading] = useState(false);
  const [settingsRetryCount, setSettingsRetryCount] = useState(0);

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

  useEffect(() => {
    if (currentChatSession) {
      loadMessages();
    } else {
      setMessages([]);
    }
  }, [currentChatSession]);

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

  const handleNewChat = async () => {
    const newSession = await createNewChatSession();
    if (newSession) {
      setCurrentChatSession(newSession);
      setError(null);
    }
  };

  const handleSelectSession = (session: ChatSession) => {
    setCurrentChatSession(session);
    setError(null);
  };

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

  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar
        onNewChat={handleNewChat}
        onToggleSettings={() => setShowSettings(!showSettings)}
        onSelectSession={handleSelectSession}
        currentSessionId={currentChatSession?.id || null}
        isDisabled={!theBrainApiKey || !brainId || !openAIKey}
      />

      <div className="flex-1 flex flex-col">
        {showSettings ? (
          <div className="p-4">
            <Settings onClose={() => setShowSettings(false)} />
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
  );
}

export default App;