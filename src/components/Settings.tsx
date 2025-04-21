import React, { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { getBrains, TheBrainAPI } from '../lib/thebrain';
import type { Brain, UserSettings } from '../types';

interface SettingsProps {
  onClose: () => void;
}

export function Settings({ onClose }: SettingsProps) {
  const [settings, setSettings] = useState<UserSettings>({});
  const [brains, setBrains] = useState<Brain[]>([]);
  const [userName, setUserName] = useState('');
  const [isSaving, setSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      const { data, error } = await supabase
        .from('user_settings')
        .select('thebrain_api_key, brain_id, openai_api_key, developer_mode, thought_id')
        .eq('user_id', user.id)
        .single();

      if (error && error.code !== 'PGRST116') {
        throw error;
      }

      if (data) {
        setSettings(data);
        if (data.thebrain_api_key) {
          try {
            const brainsList = await getBrains(data.thebrain_api_key);
            setBrains(brainsList);
          } catch (err) {
            if (err instanceof Error) {
              if (err.message.includes('401')) {
                setError('Invalid TheBrain API key. Please check your API key and try again.');
              } else if (err.message.includes('403')) {
                setError('Access denied. Please check your TheBrain API key permissions.');
              } else {
                setError(`Error loading brains: ${err.message}`);
              }
            } else {
              setError('An unexpected error occurred while loading brains.');
            }
            setBrains([]);
          }
        }
      }
    } catch (err) {
      console.error('Error loading settings:', err);
      setError(err instanceof Error ? err.message : 'Failed to load settings');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        throw new Error('User not authenticated');
      }

      // Only create/find user thought if we have all required data and no thought_id yet
      if (!settings.thought_id && settings.brain_id && settings.thebrain_api_key && userName) {
        const theBrain = new TheBrainAPI(settings.thebrain_api_key, settings.brain_id);
        const thoughtId = await theBrain.findOrCreateUserThought(userName);
        settings.thought_id = thoughtId;
      }

      const { error } = await supabase
        .from('user_settings')
        .upsert({
          user_id: user.id,
          ...settings
        })
        .select();

      if (error) throw error;

      if (settings.thebrain_api_key) {
        try {
          const brainsList = await getBrains(settings.thebrain_api_key);
          setBrains(brainsList);
        } catch (err) {
          if (err instanceof Error) {
            if (err.message.includes('401')) {
              throw new Error('Invalid TheBrain API key. Please check your API key and try again.');
            } else if (err.message.includes('403')) {
              throw new Error('Access denied. Please check your TheBrain API key permissions.');
            } else {
              throw new Error(`Error loading brains: ${err.message}`);
            }
          } else {
            throw new Error('An unexpected error occurred while loading brains.');
          }
        }
      }

      setSuccessMessage('Settings saved successfully');
      
      // Reload the page to refresh the settings state
      window.location.reload();
    } catch (err) {
      console.error('Error saving settings:', err);
      setError(err instanceof Error ? err.message : 'Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-8">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="bg-white p-6 rounded-lg shadow-md">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Settings</h2>
        <button
          onClick={onClose}
          className="text-gray-500 hover:text-gray-700"
        >
          ×
        </button>
      </div>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        {!settings.thought_id && (
          <div>
            <label htmlFor="userName" className="block text-sm font-medium text-gray-700">
              Your Name
            </label>
            <input
              type="text"
              id="userName"
              value={userName}
              onChange={(e) => setUserName(e.target.value)}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              placeholder="Enter your name"
              required
            />
            <p className="mt-1 text-sm text-gray-500">
              This will be used to identify you in TheBrain
            </p>
          </div>
        )}

        <div>
          <label htmlFor="openaiKey" className="block text-sm font-medium text-gray-700">
            OpenAI API Key
          </label>
          <input
            type="password"
            id="openaiKey"
            value={settings.openai_api_key || ''}
            onChange={(e) => setSettings(prev => ({ ...prev, openai_api_key: e.target.value }))}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="Enter your OpenAI API key"
          />
          <p className="mt-1 text-sm text-gray-500">
            Get your API key from{' '}
            <a 
              href="https://platform.openai.com/api-keys"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-800"
            >
              OpenAI Dashboard
            </a>
          </p>
        </div>

        <div>
          <label htmlFor="theBrainKey" className="block text-sm font-medium text-gray-700">
            TheBrain API Key
          </label>
          <input
            type="password"
            id="theBrainKey"
            value={settings.thebrain_api_key || ''}
            onChange={(e) => setSettings(prev => ({ ...prev, thebrain_api_key: e.target.value }))}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="Enter your TheBrain API key"
          />
          <p className="mt-1 text-sm text-gray-500">
            Get your API key from{' '}
            <a 
              href="https://app.thebrain.com/api-keys"
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-800"
            >
              TheBrain Dashboard
            </a>
          </p>
        </div>

        {brains.length > 0 && (
          <div>
            <label htmlFor="brainSelect" className="block text-sm font-medium text-gray-700">
              Select Brain
            </label>
            <select
              id="brainSelect"
              value={settings.brain_id || ''}
              onChange={(e) => setSettings(prev => ({ ...prev, brain_id: e.target.value }))}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            >
              <option value="">Select a brain</option>
              {brains.map((brain) => (
                <option key={brain.id} value={brain.id}>
                  {brain.name}
                </option>
              ))}
            </select>
          </div>
        )}

        <div className="flex items-center space-x-2">
          <input
            type="checkbox"
            id="developerMode"
            checked={settings.developer_mode || false}
            onChange={(e) => setSettings(prev => ({ ...prev, developer_mode: e.target.checked }))}
            className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
          />
          <label htmlFor="developerMode" className="text-sm font-medium text-gray-700">
            Developer Mode
          </label>
        </div>

        {error && (
          <div className="text-red-600 text-sm">{error}</div>
        )}

        {successMessage && (
          <div className="text-green-600 text-sm">{successMessage}</div>
        )}

        <button
          type="submit"
          disabled={isSaving}
          className="w-full bg-blue-600 text-white rounded-md py-2 hover:bg-blue-700 transition-colors disabled:opacity-50"
        >
          {isSaving ? 'Saving...' : 'Save Settings'}
        </button>
      </form>
    </div>
  );
}