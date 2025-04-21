import React, { useState, useEffect } from 'react';
import { saveTheBrainApiKey, getTheBrainApiKey, getBrains, saveBrainId, getBrainId } from '../lib/thebrain';
import { Loader2 } from 'lucide-react';

interface Brain {
  id: string;
  name: string;
}

export function TheBrainSettings() {
  const [apiKey, setApiKey] = useState('');
  const [brains, setBrains] = useState<Brain[]>([]);
  const [selectedBrainId, setSelectedBrainId] = useState<string>('');
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
      const key = await getTheBrainApiKey();
      const brainId = await getBrainId();
      
      if (key) {
        setApiKey(key);
        try {
          const brainsList = await getBrains(key);
          setBrains(brainsList);
          setSelectedBrainId(brainId || '');
        } catch (err) {
          if (err instanceof Error) {
            if (err instanceof TypeError && err.message === 'Failed to fetch') {
              setError('Unable to connect to TheBrain API. Please check your internet connection and ensure you can access api.thebrain.com. If the problem persists, there might be a firewall or proxy blocking the connection.');
            } else {
              setError(`Error loading brains: ${err.message}`);
            }
          } else {
            setError('Failed to load brains. Please check your API key and try again.');
          }
          setBrains([]);
        }
      }
    } catch (err) {
      console.error('Error loading settings:', err);
      if (err instanceof Error) {
        if (err instanceof TypeError && err.message === 'Failed to fetch') {
          setError('Network error: Unable to connect to our servers. Please check your internet connection and try again.');
        } else {
          setError(`Error loading settings: ${err.message}`);
        }
      } else {
        setError('Failed to load settings. Please try again.');
      }
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
      await saveTheBrainApiKey(apiKey);
      
      // After saving API key, fetch available brains
      const brainsList = await getBrains(apiKey);
      setBrains(brainsList);
      
      // If there's only one brain, select it automatically
      if (brainsList.length === 1) {
        await saveBrainId(brainsList[0].id);
        setSelectedBrainId(brainsList[0].id);
      }
      
      setSuccessMessage('Settings saved successfully');
    } catch (err) {
      console.error('Error saving settings:', err);
      if (err instanceof Error) {
        if (err.message === 'User not authenticated') {
          setError('Please sign in to save your settings');
        } else if (err.message.includes('No brains found')) {
          setError('No brains found in your TheBrain account. Please create a brain first.');
        } else if (err instanceof TypeError && err.message === 'Failed to fetch') {
          setError(
            'Unable to connect to TheBrain API. Please:\n' +
            '1. Check your internet connection\n' +
            '2. Verify you can access api.thebrain.com\n' +
            '3. Check if any firewall or proxy is blocking the connection\n' +
            '4. Try again in a few minutes if the problem persists'
          );
        } else {
          setError(`Failed to save settings: ${err.message}`);
        }
      } else {
        setError('Failed to save settings. Please try again.');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleBrainSelect = async (brainId: string) => {
    setError(null);
    setSuccessMessage(null);
    setSaving(true);
    
    try {
      await saveBrainId(brainId);
      setSelectedBrainId(brainId);
      setSuccessMessage('Brain selection saved successfully');
    } catch (err) {
      console.error('Error saving brain selection:', err);
      if (err instanceof TypeError && err.message === 'Failed to fetch') {
        setError(
          'Network error: Unable to save brain selection. Please check your internet connection and try again.'
        );
      } else {
        setError('Failed to save brain selection. Please try again.');
      }
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
      <h2 className="text-xl font-semibold mb-4">TheBrain Settings</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="apiKey" className="block text-sm font-medium text-gray-700">
            API Key
          </label>
          <input
            type="password"
            id="apiKey"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            placeholder="Enter your TheBrain API key"
            required
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
              value={selectedBrainId}
              onChange={(e) => handleBrainSelect(e.target.value)}
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

        {error && (
          <div className="whitespace-pre-line text-red-600 text-sm">{error}</div>
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