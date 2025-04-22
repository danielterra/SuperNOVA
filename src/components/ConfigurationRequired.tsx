import React from 'react';
import { AlertCircle } from 'lucide-react';

interface ConfigurationRequiredProps {
  onOpenSettings: () => void;
}

export function ConfigurationRequired({ onOpenSettings }: ConfigurationRequiredProps) {
  return (
    <div className="flex-1 flex items-center justify-center">
      <div className="text-center p-8 max-w-md">
        <AlertCircle className="w-12 h-12 text-orange-500 mx-auto mb-4" />
        <h2 className="text-2xl font-bold text-white mb-4">Configuration Required</h2>
        <p className="text-gray-400 mb-6">
          To start chatting, you need to configure your API keys and select a brain in the settings.
        </p>
        <button
          onClick={onOpenSettings}
          className="bg-orange-500 text-white px-6 py-2 rounded-md hover:bg-orange-600 transition-colors"
        >
          Open Settings
        </button>
      </div>
    </div>
  );
}