import React, { useState, useEffect } from 'react';
import { Loader2 } from 'lucide-react';
import { supabase } from '../lib/supabase';

export function SuperNOVASettings() {
  const [devMode, setDevMode] = useState(false);
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
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');
      const { data, error } = await supabase
        .from('user_settings')
        .select('developer_mode')
        .eq('user_id', user.id)
        .single();
      if (error && (error as any).code !== 'PGRST116') throw error;
      if (data && data.developer_mode !== undefined) {
        setDevMode(data.developer_mode);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load SuperNOVA settings');
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
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('User not authenticated');
      const { error } = await supabase
        .from('user_settings')
        .upsert({
          user_id: user.id,
          developer_mode: devMode,
          updated_at: new Date().toISOString()
        }, { onConflict: 'user_id' });
      if (error) throw error;
      setSuccessMessage('SuperNOVA settings saved successfully');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save SuperNOVA settings');
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
      <h3 className="text-lg font-medium mb-2 text-white">SuperNOVA Settings</h3>
      <form onSubmit={handleSubmit} className="space-y-2">
        <div className="flex items-center space-x-2">
          <input
            type="checkbox"
            id="developerMode"
            checked={devMode}
            onChange={(e) => setDevMode(e.target.checked)}
            className="rounded border-gray-600 text-orange-500 focus:ring-orange-500"
          />
          <label htmlFor="developerMode" className="text-sm font-medium text-white">
            Developer Mode
          </label>
        </div>

        {error && <div className="text-red-400 text-sm">{error}</div>}
        {successMessage && <div className="text-green-400 text-sm">{successMessage}</div>}

        <button
          type="submit"
          disabled={isSaving}
          className="mt-2 w-full bg-orange-500 text-white rounded-md py-1 hover:bg-orange-600 transition-colors disabled:opacity-50"
        >
          {isSaving ? 'Saving...' : 'Save SuperNOVA Settings'}
        </button>
      </form>
    </div>
  );
}