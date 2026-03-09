---
name: project-scaffolding
description: Blueprint for scaffolding a new Motadata NextGen React+TypeScript SaaS project from zero. Covers project structure, all dependencies, config files, initial source files, and tooling setup. Used by the project-scaffolding agent to automate full project creation.
---

# Project Scaffolding Blueprint

## Core Principle: One Command, Full Setup

Running the project-scaffolding agent on a new directory produces a fully configured, runnable project — with all tooling, brand tokens, and initial architecture in place. Zero manual steps.

## Stack

| Layer | Tool |
|-------|------|
| Build | Vite + `@vitejs/plugin-react-swc` |
| Language | TypeScript (strict) |
| Styling | Tailwind CSS v4 (`@tailwindcss/vite`) |
| Components | shadcn/ui (new-york style) |
| Routing | React Router v7 |
| Global state | Redux Toolkit |
| Server state | TanStack Query v5 |
| Forms | React Hook Form + Zod |
| HTTP | Axios |
| Auth | JWT + httpOnly cookie (see authentication skill) |
| Icons | lucide-react |
| Security | DOMPurify |
| Unit tests | Vitest + React Testing Library |
| E2E tests | Playwright |
| Linting | ESLint 9 (flat config) + Prettier |
| Git hooks | Husky + lint-staged + commitlint |
| CI/CD | GitHub Actions |

## All Dependencies

```bash
# Production
npm install react-router-dom @reduxjs/toolkit react-redux
npm install @tanstack/react-query axios
npm install react-hook-form @hookform/resolvers zod
npm install clsx tailwind-merge lucide-react
npm install dompurify

# Dev
npm install -D tailwindcss @tailwindcss/vite
npm install -D vitest @vitest/coverage-v8
npm install -D @testing-library/react @testing-library/user-event @testing-library/jest-dom
npm install -D jsdom @types/jsdom
npm install -D @playwright/test
npm install -D eslint @eslint/js typescript-eslint
npm install -D eslint-plugin-react-hooks eslint-plugin-react-refresh
npm install -D eslint-plugin-import-x
npm install -D prettier prettier-plugin-tailwindcss eslint-config-prettier
npm install -D husky lint-staged
npm install -D @commitlint/cli @commitlint/config-conventional
npm install -D @types/dompurify
```

## Directory Structure

```
{project-name}/
├── .claude/
│   └── CLAUDE.md                    # Points to skills + agents
├── .github/
│   └── workflows/
│       └── ci.yml                   # Lint + test + build pipeline
├── .husky/
│   ├── commit-msg                   # commitlint
│   └── pre-commit                   # lint-staged
├── e2e/
│   ├── fixtures/
│   │   └── auth.setup.ts            # Auth state reuse
│   └── pages/
│       └── login.page.ts            # Page Object Model
├── public/
│   └── favicon.ico
├── src/
│   ├── app/
│   │   ├── AuthInitializer.tsx      # Hydrate auth on load
│   │   └── router.tsx               # createBrowserRouter
│   ├── components/
│   │   ├── common/
│   │   │   └── ThemeToggle.tsx
│   │   ├── layouts/
│   │   │   └── DashboardLayout.tsx
│   │   └── ui/                      # shadcn/ui components (auto-generated)
│   ├── features/
│   │   └── auth/
│   │       ├── pages/
│   │       │   └── Login.tsx
│   │       └── components/
│   │           └── SocialLogin.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   └── useTheme.ts
│   ├── lib/
│   │   ├── apiClient.ts             # Axios instance + interceptors
│   │   ├── queryClient.ts           # TanStack Query client
│   │   ├── utils.ts                 # cn() utility
│   │   └── env.ts                   # Zod-validated env vars
│   ├── services/
│   │   └── authService.ts
│   ├── stores/
│   │   ├── store.ts
│   │   ├── hooks.ts                 # useAppDispatch, useAppSelector
│   │   ├── authSlice.ts
│   │   └── uiSlice.ts               # theme state
│   ├── test/
│   │   └── setup.ts                 # Vitest global setup
│   │   └── renderWithProviders.tsx  # Test helper
│   ├── types/
│   │   └── index.ts                 # Global types (User, ApiResponse, etc.)
│   ├── index.css                    # Tailwind + brand tokens
│   └── main.tsx                     # App entry point
├── stories/                         # User story .md files
│   └── .gitkeep
├── .commitlintrc.json
├── .env.example
├── .eslintrc.js (eslint.config.js)
├── .gitignore
├── .prettierrc
├── commitlint.config.js
├── index.html                       # FOUC prevention script
├── package.json
├── playwright.config.ts
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
└── vite.config.ts
```

## Key Config File Contents

### vite.config.ts
```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import tailwindcss from '@tailwindcss/vite';
import path from 'path';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      include: ['src/**/*.{ts,tsx}'],
      exclude: ['src/**/*.test.{ts,tsx}', 'src/test/**', 'src/types/**', 'src/main.tsx'],
      thresholds: { branches: 80, functions: 80, lines: 80, statements: 80 },
    },
  },
});
```

### tsconfig.json (path aliases)
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["./src/*"] },
    "strict": true
  }
}
```

### src/index.css (brand palette + semantic tokens)
```css
@import 'tailwindcss';

:root {
  --red-05: #fef5f5; --red-10: #feecec; --red-20: #fccfcf; --red-30: #f6b1b1;
  --red-40: #f58a8a; --red-50: #ec5b5b; --red-60: #db132a; --red-65: #c72323;
  --red-70: #ad1111; --red-80: #750c0c; --red-90: #4a0b0b; --red-100: #310c0c;
  --orange-05: #fdf7f4; --orange-10: #fef5ee; --orange-20: #fddcc4; --orange-30: #fac2a0;
  --orange-40: #ffb37a; --orange-50: #fa9950; --orange-60: #f47c22; --orange-65: #e56b19;
  --orange-70: #c35323; --orange-80: #8d3118; --orange-90: #541914; --orange-100: #40130f;
  --yellow-05: #fffdf4; --yellow-10: #fffbea; --yellow-20: #fff1b3; --yellow-30: #ffe980;
  --yellow-40: #ffdd35; --yellow-50: #fad100; --yellow-60: #e8b407; --yellow-70: #c28e00;
  --yellow-80: #855c15; --yellow-90: #543308; --yellow-100: #3d2106;
  --green-05: #f5fdf8; --green-10: #edfdf3; --green-20: #d1fae0; --green-30: #a2f6c3;
  --green-40: #7beaa5; --green-50: #36d576; --green-60: #14b053; --green-70: #0e7c3a;
  --green-80: #0b602d; --green-90: #0d3a1f; --green-100: #052912;
  --blue-05: #f4f9ff; --blue-10: #ebf4ff; --blue-20: #cce4ff; --blue-30: #99cdff;
  --blue-40: #66b3ff; --blue-50: #008cff; --blue-55: #006dfa; --blue-60: #0263e0;
  --blue-70: #043cb5; --blue-80: #001489; --blue-90: #030b5d; --blue-100: #06033a;
  --purple-05: #faf7fd; --purple-10: #f5f0fc; --purple-20: #e7dcfa; --purple-30: #c8aff0;
  --purple-40: #a67fe3; --purple-50: #8c5bd8; --purple-60: #6d2ed1; --purple-70: #5817bd;
  --purple-80: #380e78; --purple-90: #22094a; --purple-100: #160433;
}

@theme {
  --color-background: #ffffff;
  --color-foreground: #030b5d;
  --color-card: #ffffff;
  --color-card-foreground: #030b5d;
  --color-primary: #006dfa;
  --color-primary-foreground: #ffffff;
  --color-secondary: #f4f9ff;
  --color-secondary-foreground: #030b5d;
  --color-muted: #ebf4ff;
  --color-muted-foreground: #043cb5;
  --color-accent: #cce4ff;
  --color-accent-foreground: #030b5d;
  --color-destructive: #db132a;
  --color-destructive-foreground: #ffffff;
  --color-success: #14b053;
  --color-success-foreground: #ffffff;
  --color-warning: #f47c22;
  --color-warning-foreground: #ffffff;
  --color-border: #cce4ff;
  --color-input: #cce4ff;
  --color-ring: #006dfa;
  --font-sans: 'Inter', system-ui, sans-serif;
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --spacing-sidebar: 16rem;
  --spacing-header: 4rem;
}

.dark {
  --color-background: #030b5d;
  --color-foreground: #f4f9ff;
  --color-card: #001489;
  --color-card-foreground: #f4f9ff;
  --color-primary: #66b3ff;
  --color-primary-foreground: #030b5d;
  --color-secondary: #001489;
  --color-secondary-foreground: #f4f9ff;
  --color-muted: #043cb5;
  --color-muted-foreground: #99cdff;
  --color-accent: #043cb5;
  --color-accent-foreground: #f4f9ff;
  --color-destructive: #f58a8a;
  --color-destructive-foreground: #310c0c;
  --color-success: #36d576;
  --color-success-foreground: #052912;
  --color-warning: #fa9950;
  --color-warning-foreground: #40130f;
  --color-border: #043cb5;
  --color-input: #043cb5;
  --color-ring: #66b3ff;
}
```

### index.html (FOUC prevention)
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Motadata NextGen</title>
    <script>
      (function() {
        const theme = localStorage.getItem('theme') || 'system';
        const isDark = theme === 'dark' ||
          (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
        document.documentElement.classList.add(isDark ? 'dark' : 'light');
      })();
    </script>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### .env.example
```
VITE_API_URL=http://localhost:8080/api
VITE_APP_NAME=Motadata NextGen
VITE_APP_ENV=development
```

### shadcn/ui components.json
```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "blue",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
```

## Validation Checklist

After scaffolding, verify:
- [ ] `npm run dev` starts without errors
- [ ] `npm run build` compiles successfully
- [ ] `npm run lint` passes
- [ ] `npm run test` runs (even with 0 tests)
- [ ] `npm run test:e2e` runs Playwright
- [ ] shadcn/ui components install with `npx shadcn@latest add button`
- [ ] Theme toggle changes `<html>` class
- [ ] `git commit` triggers husky + commitlint
