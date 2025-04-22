import React from 'react';

// A bottom command bar showing keyboard shortcuts for common actions
export type Command = {
  keys: string;
  description: string;
  visible: 'inputFocused' | 'notInputFocused' | 'always';
};
export function CommandBar({ commands }: { commands: Command[] }) {
  const [isInputFocused, setIsInputFocused] = React.useState(false);
  
  React.useEffect(() => {
    const handleFocusIn = (e: FocusEvent) => {
      if ((e.target as Element).id === 'chat-input') {
        setIsInputFocused(true);
      } else {
        setIsInputFocused(false);
      }
    };
    const handleFocusOut = (e: FocusEvent) => {
      if ((e.target as Element).id === 'chat-input') {
        setIsInputFocused(false);
      }
    };
    window.addEventListener('focusin', handleFocusIn);
    window.addEventListener('focusout', handleFocusOut);
    return () => {
      window.removeEventListener('focusin', handleFocusIn);
      window.removeEventListener('focusout', handleFocusOut);
    };
  }, []);

  const visibleCommands = commands.filter(cmd => {
    if (isInputFocused) return cmd.visible === 'inputFocused' || cmd.visible === 'always';
    return cmd.visible === 'notInputFocused' || cmd.visible === 'always';
  });
  return (
    <div className="text-gray-400 m-5">
      <div className="flex justify-center space-x-8 text-sm">
        {visibleCommands.map((cmd) => (
          <div key={cmd.keys} className="flex items-center gap-1">
            <kbd className="px-1.5 py-0.5 border border-gray-600 rounded text-xs text-white">{cmd.keys}</kbd>
            <span>{cmd.description}</span>
          </div>
        ))}
      </div>
    </div>
  );
}