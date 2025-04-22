import React, { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { getOpenAIKey, saveOpenAIKey } from '../lib/openai';

export function OpenAISettings() {
  const [key, setKey] = useState('');
  const [isLoading, setLoading] = useState(true);
  const [isSaving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    setLoading(true);
    setError(null);
    try {
      const existingKey = await getOpenAIKey();
      if (existingKey) {
        setKey(existingKey);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load OpenAI API key');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setSuccessMessage(null);
    try {
      await saveOpenAIKey(key);
      // Test integration by listing models
      const res = await fetch('https://api.openai.com/v1/models', {
        headers: {
          'Authorization': `Bearer ${key}`,
          'Content-Type': 'application/json'
        }
      });
      if (!res.ok) {
        throw new Error(`OpenAI API error: ${res.status} ${res.statusText}`);
      }
      setSuccessMessage('OpenAI settings saved and validated successfully');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save OpenAI settings');
    } finally {
      setSaving(false);
    }
  };

  if (isLoading) {
    return (
      <div className="bg-gray-800 p-4 border border-gray-700 rounded-md shadow-md flex items-center justify-center">
      <Loader2 className="w-6 h-6 animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <div className="bg-gray-800 p-4 border border-gray-700 rounded-md shadow-md">
      <h3 className="text-lg font-medium mb-2 text-white">OpenAI Settings</h3>
      <form onSubmit={handleSubmit} className="space-y-2">
        <div>
          <label htmlFor="openaiKey" className="block text-sm font-medium text-white">
            API Key
          </label>
          <input
            type="password"
            id="openaiKey"
            value={key}
            onChange={(e) => setKey(e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-600 bg-gray-900 text-white shadow-sm focus:border-orange-500 focus:ring-orange-500"
            placeholder="Enter your OpenAI API key"
          />
        </div>

        {error && <div className="text-red-400 text-sm">{error}</div>}
        {successMessage && <div className="text-green-400 text-sm">{successMessage}</div>}

        <button
          type="submit"
          disabled={isSaving}
          className="mt-2 w-full bg-orange-500 text-white rounded-md py-1 hover:bg-orange-600 transition-colors disabled:opacity-50"
        >
          {isSaving ? 'Saving...' : 'Save OpenAI Settings'}
        </button>
      </form>
    </div>
  );
}