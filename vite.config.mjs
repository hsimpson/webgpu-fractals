import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import process from 'node:process';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  root: 'src',
  publicDir: '../public',
  build: { minify: true, outDir: '../dist' },
  resolve: { alias: { '/src': path.resolve(process.cwd(), 'src') } },
  base: '',
});
