import React, { useState } from 'react';
import { Terminal, ChevronDown, ChevronRight } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { format } from 'date-fns';
import type { Message } from '../types';

interface ChatMessageProps {
  message: Message;
}

export function ChatMessage({ message }: ChatMessageProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const isToolMessage = message.tool_call_id || message.tool_calls;
  let toolData = null;

  if (isToolMessage) {
    if (message.tool_calls) {
      toolData = {
        name: 'Tool Calls',
        calls: message.tool_calls.map(call => ({
          name: call.function.name,
          arguments: JSON.parse(call.function.arguments)
        }))
      };
    } else if (message.tool_call_id) {
      try {
        toolData = {
          name: message.name,
          result: JSON.parse(message.content)
        };
      } catch (e) {
        console.error('Failed to parse tool message content:', e);
      }
    }
  }

  return (
    <div
      className={`flex ${
        message.role === 'user' ? 'justify-end' : 'justify-start'
      }`}
    >
        <div
          className={`max-w-2xl rounded-lg p-4 ${
            message.role === 'user'
              ? 'bg-gray-700 text-white'
              : isToolMessage && toolData
              ? 'bg-gray-900 text-gray-100 font-mono'
              : 'bg-gray-900 text-white'
          } ${isToolMessage ? 'shadow-lg' : 'shadow-md'}`}
        >
        {isToolMessage && toolData ? (
          <div className="space-y-3">
            <button
              onClick={() => setIsExpanded(!isExpanded)}
              className="w-full flex items-center justify-between gap-2 border-b border-gray-700 pb-2"
            >
              <div className="flex items-center gap-2">
                <Terminal className="w-4 h-4 text-green-400" />
                <span className="font-semibold text-green-400">
                  {toolData.name}
                </span>
              </div>
              {isExpanded ? (
                <ChevronDown className="w-4 h-4 text-gray-400" />
              ) : (
                <ChevronRight className="w-4 h-4 text-gray-400" />
              )}
            </button>
            {isExpanded && (
              <div className="space-y-3 text-sm">
                {toolData.calls ? (
                  toolData.calls.map((call, index) => (
                    <div key={index} className="space-y-2">
                      <div className="text-gray-400 font-semibold">{call.name}</div>
                      <pre className="bg-gray-800 rounded p-2 overflow-x-auto">
                        {JSON.stringify(call.arguments, null, 2)}
                      </pre>
                    </div>
                  ))
                ) : (
                  <pre className="bg-gray-800 rounded p-2 overflow-x-auto">
                    {JSON.stringify(toolData.result, null, 2)}
                  </pre>
                )}
              </div>
            )}
          </div>
        ) : (
          <ReactMarkdown
            className="prose prose-invert max-w-none"
          >
            {message.content}
          </ReactMarkdown>
        )}
        <div className={`text-xs mt-2 ${
          message.role === 'user' || isToolMessage
            ? 'text-gray-300'
            : 'text-gray-300'
        }`}>
          {format(new Date(message.created_at), 'HH:mm')}
        </div>
      </div>
    </div>
  );
}