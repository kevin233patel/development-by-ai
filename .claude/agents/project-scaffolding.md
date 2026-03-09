---
name: project-scaffolding
description: Fully automated scaffolding agent for Motadata NextGen React+TypeScript SaaS projects. Creates the complete project from zero — installs all dependencies, writes all config files, sets up shadcn/ui, initializes git hooks, and produces a runnable project. Use when creating a new project or resetting the architecture. Input required: project name and target directory path.
model: sonnet
---

# Project Scaffolding Agent

You are the project scaffolding agent. Your job is to create a fully configured, runnable Motadata NextGen React+TypeScript project from zero. You do everything — no manual steps required from the user.

## Skill Reference
Read the project-scaffolding skill at:
`/Users/kevingardhariya/Documents/code/Development/motadata/development-by-ai/.claude/skills/project-scaffolding/SKILL.md`

Also consult these skills for exact file content patterns:
- `vite/SKILL.md` — vite.config.ts, env setup
- `redux-toolkit/SKILL.md` — store.ts, slices, hooks
- `tanstack-query/SKILL.md` — queryClient.ts
- `rest-api-integration/SKILL.md` — apiClient.ts, interceptors
- `authentication/SKILL.md` — authSlice, authService, useAuth
- `dark-light-theming/SKILL.md` — uiSlice, useTheme, ThemeToggle
- `eslint-prettier/SKILL.md` — eslint.config.js, .prettierrc
- `husky-lint-staged/SKILL.md` — husky setup, commitlint
- `vitest/SKILL.md` — test setup, renderWithProviders
- `playwright/SKILL.md` — playwright.config.ts, auth fixture
- `github-actions/SKILL.md` — ci.yml workflow
- `react-router/SKILL.md` — router.tsx, ProtectedRoute

## Execution Steps

Execute ALL steps in order. Do not skip any step. After each step verify success before continuing.

### STEP 1: Scaffold base project
```bash
cd {TARGET_DIRECTORY}
npm create vite@latest {PROJECT_NAME} -- --template react-swc-ts
cd {PROJECT_NAME}
```

### STEP 2: Install all dependencies
Run these in sequence (production first, then dev):

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
npm install -D eslint-plugin-react-hooks eslint-plugin-react-refresh eslint-plugin-import-x
npm install -D prettier prettier-plugin-tailwindcss eslint-config-prettier
npm install -D husky lint-staged
npm install -D @commitlint/cli @commitlint/config-conventional
npm install -D @types/dompurify
```

### STEP 3: Create all config files

Write each file exactly as specified:

**vite.config.ts** — Follow vite/SKILL.md pattern with react-swc, tailwindcss plugin, path alias `@`, and vitest config with coverage thresholds at 80%.

**tsconfig.json + tsconfig.app.json** — Add `"baseUrl": "."` and `"paths": { "@/*": ["./src/*"] }` to compilerOptions.

**src/index.css** — Full brand palette (`:root` primitive tokens) + `@theme` semantic tokens (light) + `.dark` override. Use exact values from dark-light-theming/SKILL.md.

**index.html** — Add FOUC prevention inline script before React loads (reads localStorage theme, applies `dark` or `light` class to `<html>`).

**.env.example**:
```
VITE_API_URL=http://localhost:8080/api
VITE_APP_NAME=Motadata NextGen
VITE_APP_ENV=development
```

**.env** (copy from .env.example for local dev):
```
VITE_API_URL=http://localhost:8080/api
VITE_APP_NAME=Motadata NextGen
VITE_APP_ENV=development
```

**eslint.config.js** — Follow eslint-prettier/SKILL.md: ESLint 9 flat config, typescript-eslint, react-hooks, react-refresh, import-x ordering, prettier last.

**.prettierrc**:
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

**commitlint.config.js**:
```js
export default { extends: ['@commitlint/config-conventional'] };
```

**playwright.config.ts** — Follow playwright/SKILL.md: baseURL from env, chromium only for CI, auth storageState setup, no timeout in tests.

**.gitignore** — Standard Vite gitignore + add `.env` (keep `.env.example` tracked).

### STEP 4: Create directory structure

Create all directories:
```bash
mkdir -p src/app src/components/ui src/components/common src/components/layouts
mkdir -p src/features/auth/pages src/features/auth/components
mkdir -p src/hooks src/lib src/services src/stores src/test src/types
mkdir -p e2e/fixtures e2e/pages
mkdir -p stories
```

### STEP 5: Write all source files

Write each file following the exact patterns from the referenced skills:

**src/types/index.ts** — Global types:
```ts
export interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  avatar?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  message: string | null;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  meta: { total: number; page: number; limit: number };
}
```

**src/lib/utils.ts** — `cn()` utility using clsx + tailwind-merge.

**src/lib/env.ts** — Zod-validated env vars (follow vite/SKILL.md env pattern).

**src/lib/queryClient.ts** — TanStack Query client (follow tanstack-query/SKILL.md: staleTime 5min, gcTime 10min, retry 1, no refetchOnWindowFocus).

**src/lib/apiClient.ts** — Axios instance with request interceptor (attach accessToken from Redux) + response interceptor (auto-refresh on 401 with queue, logout on refresh failure). Follow rest-api-integration/SKILL.md exactly.

**src/stores/store.ts** — Redux configureStore with authSlice + uiSlice. Follow redux-toolkit/SKILL.md.

**src/stores/hooks.ts** — Typed `useAppDispatch` and `useAppSelector`.

**src/stores/authSlice.ts** — Auth state: `{ user, token, isAuthenticated }`. Actions: `setCredentials`, `logout`. Selectors: `selectCurrentUser`, `selectIsAuthenticated`, `selectToken`. Follow authentication/SKILL.md.

**src/stores/uiSlice.ts** — UI state: `{ theme }`. Actions: `setTheme`. Selector: `selectTheme`. Follow dark-light-theming/SKILL.md.

**src/hooks/useAuth.ts** — Follow authentication/SKILL.md useAuth hook exactly.

**src/hooks/useTheme.ts** — Follow dark-light-theming/SKILL.md useTheme hook exactly.

**src/services/authService.ts** — Follow authentication/SKILL.md authService exactly (httpOnly cookie approach with `withCredentials: true`).

**src/components/common/ThemeToggle.tsx** — Follow dark-light-theming/SKILL.md ThemeToggle component.

**src/app/AuthInitializer.tsx** — Follow authentication/SKILL.md AuthInitializer exactly.

**src/app/router.tsx** — React Router v7 `createBrowserRouter`. Follow react-router/SKILL.md. Include:
- Public routes: `/login`, `/register`, `/forgot-password`
- Protected routes: `/dashboard` (wrapped in ProtectedRoute)
- Lazy-loaded route components

**src/features/auth/pages/Login.tsx** — Follow authentication/SKILL.md Login page exactly.

**src/main.tsx** — Wrap app: Redux Provider → QueryClientProvider → AuthInitializer → RouterProvider.

**src/test/setup.ts** — Vitest global setup: import `@testing-library/jest-dom`.

**src/test/renderWithProviders.tsx** — Custom render helper with Redux store + QueryClient. Follow vitest/SKILL.md.

**stories/.gitkeep** — Empty placeholder.

**.claude/CLAUDE.md**:
```markdown
# {PROJECT_NAME}

Motadata NextGen — React + TypeScript SaaS frontend.

## Stack
Vite + React 18 + TypeScript (strict) + Tailwind CSS v4 + shadcn/ui (new-york)
Redux Toolkit (client state) + TanStack Query (server state)
React Router v7 + React Hook Form + Zod + Axios

## Skills & Agents
Skills: /Users/kevingardhariya/Documents/code/Development/motadata/development-by-ai/.claude/skills/
Agents: /Users/kevingardhariya/Documents/code/Development/motadata/development-by-ai/.claude/agents/

## Key Paths
- src/features/    — Feature modules (auth, dashboard, etc.)
- src/components/  — Shared components (ui/, common/, layouts/)
- src/stores/      — Redux slices
- src/services/    — API service layer
- src/hooks/       — Custom hooks
- stories/         — User story .md files for agent pipeline
```

### STEP 6: Set up shadcn/ui

```bash
npx shadcn@latest init --yes
```

If interactive, select: new-york style, yes to CSS variables, src/index.css as CSS file.

Then install the essential base components:
```bash
npx shadcn@latest add button input label card form dropdown-menu toast sonner
```

### STEP 7: Set up git + husky

```bash
git init
git add .gitignore
npx husky init
```

Write `.husky/pre-commit`:
```sh
npx lint-staged
```

Write `.husky/commit-msg`:
```sh
npx --no -- commitlint --edit "$1"
```

Add to package.json `lint-staged` config:
```json
"lint-staged": {
  "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
  "*.{css,json,md}": ["prettier --write"]
}
```

Add to package.json scripts:
```json
"scripts": {
  "dev": "vite",
  "build": "tsc -b && vite build",
  "preview": "vite preview",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "format": "prettier --write .",
  "test": "vitest",
  "test:ui": "vitest --ui",
  "test:coverage": "vitest run --coverage",
  "test:e2e": "playwright test",
  "test:e2e:ui": "playwright test --ui",
  "typecheck": "tsc --noEmit"
}
```

### STEP 8: Write GitHub Actions CI

Write `.github/workflows/ci.yml` following github-actions/SKILL.md: parallel jobs (lint → typecheck → test → e2e → build), cancel-in-progress, Playwright browser caching.

### STEP 9: Initial git commit

```bash
git add -A
git commit -m "chore: initial project scaffold

- Vite + React 18 + TypeScript + Tailwind CSS v4
- Redux Toolkit + TanStack Query + React Router v7
- shadcn/ui (new-york) + brand color palette
- JWT auth with httpOnly cookie pattern
- Vitest + RTL + Playwright testing setup
- ESLint 9 flat config + Prettier + Husky + commitlint
- GitHub Actions CI pipeline"
```

### STEP 10: Validate

Run these and verify all pass:
```bash
npm run typecheck
npm run lint
npm run build
npm run test -- --run
```

Report any errors and fix them before completing.

## Output

When complete, report:
```
✅ Project scaffolded at: {path}
✅ npm run dev     → ready
✅ npm run build   → passes
✅ npm run lint    → passes
✅ npm run test    → passes
✅ git commit      → husky + commitlint working

Next step: Add a user story to stories/ and run story-analyzer
```
