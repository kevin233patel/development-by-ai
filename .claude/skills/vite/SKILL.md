---
name: vite
description: Provides Vite build tool patterns for React + TypeScript projects. Covers configuration, plugins, environment variables, path aliases, build optimization, and dev server setup. Must use when creating or modifying vite.config.ts, tsconfig.json paths, or build-related files.
---

# Vite Best Practices

## Core Principle: Convention Over Configuration

Vite works out of the box for most cases. **Only add configuration when you have a specific need.** Don't copy boilerplate configs blindly — understand what each option does.

## Project Initialization

### Scaffold with React + TypeScript + SWC

```bash
# Use SWC for faster compilation than Babel
npm create vite@latest my-app -- --template react-swc-ts
cd my-app
npm install
```

### Recommended Directory Structure After Scaffold

```
my-app/
├── public/                  # Static assets (copied as-is)
│   └── favicon.svg
├── src/
│   ├── app/                 # App entry, providers, router
│   │   ├── App.tsx
│   │   └── Providers.tsx
│   ├── assets/              # Imported assets (processed by Vite)
│   │   └── logo.svg
│   ├── components/          # Shared components
│   ├── features/            # Feature modules
│   ├── hooks/               # Shared custom hooks
│   ├── lib/                 # Utilities, API client, constants
│   ├── services/            # API service layers
│   ├── stores/              # Redux stores/slices
│   ├── types/               # Shared TypeScript types
│   └── main.tsx             # Entry point
├── index.html               # HTML template (Vite entry)
├── vite.config.ts           # Vite configuration
├── tsconfig.json            # TypeScript config
├── tsconfig.app.json        # App-specific TS config
└── tsconfig.node.json       # Node/Vite TS config
```

## Configuration

### Base vite.config.ts

```ts
// BAD: Bloated config with unnecessary options
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';
import { visualizer } from 'rollup-plugin-visualizer';
import compression from 'vite-plugin-compression';
import svgr from 'vite-plugin-svgr';
// ... 10 more plugins you don't need yet

// GOOD: Minimal config — add plugins only when needed
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

### TypeScript Path Aliases

Configure both `vite.config.ts` and `tsconfig.json` — they must stay in sync:

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@features': path.resolve(__dirname, './src/features'),
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@lib': path.resolve(__dirname, './src/lib'),
      '@stores': path.resolve(__dirname, './src/stores'),
      '@types': path.resolve(__dirname, './src/types'),
    },
  },
});
```

```json
// tsconfig.app.json — compilerOptions.paths must mirror vite aliases
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@features/*": ["./src/features/*"],
      "@hooks/*": ["./src/hooks/*"],
      "@lib/*": ["./src/lib/*"],
      "@stores/*": ["./src/stores/*"],
      "@types/*": ["./src/types/*"]
    }
  }
}
```

```tsx
// BAD: Relative path hell
import { Button } from '../../../components/ui/Button';
import { useAuth } from '../../../../hooks/useAuth';

// GOOD: Clean alias imports
import { Button } from '@components/ui/Button';
import { useAuth } from '@hooks/useAuth';
```

## Environment Variables

### Naming Convention

```bash
# .env — shared defaults (committed to git)
VITE_APP_NAME=MySaaSApp
VITE_API_TIMEOUT=30000

# .env.local — local overrides (gitignored)
VITE_API_URL=http://localhost:3001/api

# .env.development — dev-specific
VITE_API_URL=http://localhost:3001/api
VITE_ENABLE_MOCK=true

# .env.production — production
VITE_API_URL=https://api.myapp.com
VITE_ENABLE_MOCK=false

# .env.staging — custom mode (use with --mode staging)
VITE_API_URL=https://staging-api.myapp.com
```

### Type-Safe Environment Variables

```ts
// BAD: Accessing env vars without validation
const apiUrl = import.meta.env.VITE_API_URL; // string | undefined — no safety

// GOOD: Typed env with validation in src/lib/env.ts
import { z } from 'zod';

const envSchema = z.object({
  VITE_API_URL: z.string().url(),
  VITE_APP_NAME: z.string().min(1),
  VITE_API_TIMEOUT: z.coerce.number().default(30000),
  VITE_ENABLE_MOCK: z.coerce.boolean().default(false),
});

function validateEnv() {
  const parsed = envSchema.safeParse(import.meta.env);

  if (!parsed.success) {
    console.error('Invalid environment variables:', parsed.error.flatten().fieldErrors);
    throw new Error('Invalid environment variables');
  }

  return parsed.data;
}

export const env = validateEnv();
```

```ts
// src/vite-env.d.ts — Augment ImportMeta for autocompletion
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_NAME: string;
  readonly VITE_API_TIMEOUT: string;
  readonly VITE_ENABLE_MOCK: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

```tsx
// Usage — always import from env.ts, never access import.meta.env directly
import { env } from '@lib/env';

const apiClient = createApiClient({
  baseURL: env.VITE_API_URL,
  timeout: env.VITE_API_TIMEOUT,
});
```

### .gitignore Rules

```gitignore
# BAD: Committing secrets
.env.local  # This should be gitignored!

# GOOD: Git-track shared, ignore local/secrets
.env.local
.env.*.local
```

## Dev Server Configuration

### Proxy API Requests

```ts
// BAD: Hardcoding API URL in code, dealing with CORS manually
fetch('http://localhost:3001/api/users');

// GOOD: Proxy through Vite dev server
// vite.config.ts
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        // Optional: rewrite path
        // rewrite: (path) => path.replace(/^\/api/, ''),
      },
      '/ws': {
        target: 'ws://localhost:3001',
        ws: true,
      },
    },
  },
});
```

```tsx
// In your code — just use relative paths
fetch('/api/users'); // Proxied to http://localhost:3001/api/users
```

### HTTPS in Development

```ts
// vite.config.ts — when you need HTTPS locally
import basicSsl from '@vitejs/plugin-basic-ssl';

export default defineConfig({
  plugins: [react(), basicSsl()],
  server: {
    https: true,
    port: 3000,
  },
});
```

## Build Optimization

### Code Splitting Strategy

```ts
// vite.config.ts — manual chunk splitting for optimal caching
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // Vendor chunks — change less frequently, cached longer
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-redux': ['@reduxjs/toolkit', 'react-redux'],
          'vendor-query': ['@tanstack/react-query'],
          'vendor-ui': ['class-variance-authority', 'clsx', 'tailwind-merge'],
        },
      },
    },
    // Generate sourcemaps for production debugging
    sourcemap: true,
    // Runtime Performance Matrix bundle budgets (gzip targets):
    //   Initial JS: < 170KB  |  Per-route chunk: < 40KB  |  CSS: < 25KB
    // Warn early at 170KB so we stay well under the 350KB critical threshold
    chunkSizeWarningLimit: 170,
  },
});
```

### Asset Handling

```ts
// vite.config.ts — asset configuration
export default defineConfig({
  build: {
    assetsInlineLimit: 4096, // Inline assets < 4KB as base64
    assetsDir: 'assets',     // Output directory for assets
  },
});
```

```tsx
// Importing assets in components
// Small images (< 4KB) → inlined as base64
import smallIcon from '@/assets/icon-small.svg'; // data:image/svg+xml;base64,...

// Large images → copied to /assets/ with hash
import heroImage from '@/assets/hero.png'; // /assets/hero-a1b2c3d4.png

// CSS url() works the same way
.hero { background-image: url('@/assets/hero.png'); }
```

### Bundle Analysis

```ts
// vite.config.ts — add visualizer only when analyzing
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig(({ mode }) => ({
  plugins: [
    react(),
    mode === 'analyze' &&
      visualizer({
        open: true,
        filename: 'dist/stats.html',
        gzipSize: true,
      }),
  ].filter(Boolean),
}));

// Usage: npm run build -- --mode analyze
```

## Common Plugins (Add Only When Needed)

```ts
// SVG as React components
import svgr from 'vite-plugin-svgr';
// Usage: import { ReactComponent as Logo } from './logo.svg';

// Gzip/Brotli compression
import compression from 'vite-plugin-compression';
// Only add for self-hosted deployments (Vercel/Netlify handle this)

// PWA support
import { VitePWA } from 'vite-plugin-pwa';
// Only add if building a Progressive Web App

// Legacy browser support
import legacy from '@vitejs/plugin-legacy';
// Only add if you must support IE11 or old browsers
```

## Testing Configuration

### Vitest Setup in vite.config.ts

```ts
/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.test.{ts,tsx}', 'src/test/**', 'src/types/**'],
    },
  },
});
```

## Bundle Size Budgets (Runtime Performance Matrix)

These are enforced targets — **Critical = must fix before deploy.**

| Asset | Target | Good | Critical |
|---|---|---|---|
| Initial JS Bundle (gzip) | **< 170KB** | ≤ 200KB | > 350KB |
| Per-Route Chunk (gzip) | **< 40KB** | ≤ 50KB | > 100KB |
| Total CSS (gzip) | **< 25KB** | ≤ 30KB | > 60KB |
| Total Transfer Size | **< 400KB** | ≤ 500KB | > 1MB |

```bash
# Check current bundle size (gzip-aware)
npm run build -- --mode analyze
# Opens dist/stats.html — inspect each chunk size
```

```ts
// vite.config.ts — enforce budgets in build output
export default defineConfig({
  build: {
    // Fail loudly at 170KB so we fix before hitting 350KB critical
    chunkSizeWarningLimit: 170,
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-redux': ['@reduxjs/toolkit', 'react-redux'],
          'vendor-query': ['@tanstack/react-query'],
          'vendor-ui': ['class-variance-authority', 'clsx', 'tailwind-merge'],
        },
      },
    },
  },
});
```

## Summary: Decision Tree

1. **Starting a new project?** → `npm create vite@latest -- --template react-swc-ts`
2. **Need path aliases?** → Configure both `vite.config.ts` alias AND `tsconfig.json` paths
3. **Accessing env vars?** → Create typed `env.ts` with Zod validation, never use `import.meta.env` directly
4. **API calls in dev?** → Use Vite proxy, not hardcoded URLs
5. **Bundle too large?** → Add `manualChunks` for vendor splitting — target < 170KB initial JS
6. **Need to analyze bundle?** → Add `rollup-plugin-visualizer` behind a mode flag
7. **Adding a plugin?** → Ask "Do I need this now?" — if no, don't add it
8. **Configuring tests?** → Use Vitest in `vite.config.ts` with `test` block
