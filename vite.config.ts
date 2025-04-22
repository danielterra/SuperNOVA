import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Enable polling so Tailwind JIT picks up class changes reliably
    watch: {
      usePolling: true,
    },
  },
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
});
