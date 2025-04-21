import React from 'react';
import { AlertCircle } from 'lucide-react';

interface ConfigurationRequiredProps {
  onOpenSettings: () => void;
}

export function ConfigurationRequired({ onOpenSettings }: ConfigurationRequiredProps) {
  return (
    <div className="flex-1 flex items-center justify-center">
      <div className="text-center p-8 max-w-md">
        <AlertCircle className="w-12 h-12 text-yellow-500 mx-auto mb-4" />
        <h2 className="text-2xl font-bold text-gray-800 mb-4">Configuration Required</h2>
        <p className="text-gray-600 mb-6">
          To start chatting, you need to configure your API keys and select a brain in the settings.
        </p>
        <button
          onClick={onOpenSettings}
          className="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition-colors"
        >
          Open Settings
        </button>
      </div>
    </div>
  );
}