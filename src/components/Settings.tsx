import React from 'react';
import { SuperNOVASettings } from './SuperNOVASettings';
import { OpenAISettings } from './OpenAISettings';
import { TheBrainSettings } from './TheBrainSettings';

// Settings page: render each settings card with no outer container
export function Settings() {
  // Render individual settings cards with consistent vertical spacing
  return (
    // Stack settings cards vertically with consistent spacing
    <div className="space-y-6">
      <SuperNOVASettings />
      <OpenAISettings />
      <TheBrainSettings />
    </div>
  );
}