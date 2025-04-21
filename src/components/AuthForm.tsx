import React from 'react';
import { Bot } from 'lucide-react';

interface AuthFormProps {
  error: string | null;
  isSignup: boolean;
  onSubmit: (e: React.FormEvent) => Promise<void>;
  onToggleMode: () => void;
}

export function AuthForm({ error, isSignup, onSubmit, onToggleMode }: AuthFormProps) {
  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-md w-96">
        <div className="flex items-center justify-center mb-8">
          <Bot className="w-12 h-12 text-blue-600" />
          <h1 className="text-2xl font-bold ml-2">SuperNOVA</h1>
        </div>
        
        {error && (
          <div className="mb-4 p-3 bg-red-100 border border-red-400 text-red-700 rounded">
            {error}
          </div>
        )}

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              name="email"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              name="password"
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>
          <div className="flex gap-4">
            <button
              type="submit"
              className="w-full bg-blue-600 text-white rounded-md py-2 hover:bg-blue-700 transition-colors"
            >
              {isSignup ? 'Sign Up' : 'Login'}
            </button>
            <button
              type="button"
              onClick={onToggleMode}
              className="w-full bg-gray-200 text-gray-800 rounded-md py-2 hover:bg-gray-300 transition-colors"
            >
              {isSignup ? 'Back to Login' : 'Sign Up'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}