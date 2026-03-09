---
name: eslint-prettier
description: Provides ESLint + Prettier configuration patterns for React + TypeScript SaaS applications. Covers flat config setup, rule customization, TypeScript-aware linting, import ordering, and Prettier integration. Must use when setting up or modifying linting and formatting rules.
---

# ESLint + Prettier Best Practices

## Core Principle: Automate Code Quality

Linting catches bugs and enforces conventions. Formatting removes style debates. **Set them up once, enforce via CI, and never argue about semicolons again.**

## Installation

```bash
# ESLint 9+ with flat config
npm install -D eslint @eslint/js typescript-eslint eslint-plugin-react-hooks eslint-plugin-react-refresh

# Prettier
npm install -D prettier eslint-config-prettier

# Import sorting
npm install -D eslint-plugin-import-x
```

## ESLint Flat Config

### eslint.config.js

```js
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import reactHooks from 'eslint-plugin-react-hooks';
import reactRefresh from 'eslint-plugin-react-refresh';
import importX from 'eslint-plugin-import-x';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  // Global ignores
  {
    ignores: ['dist/', 'node_modules/', 'coverage/', '*.config.js', '*.config.ts'],
  },

  // Base JS rules
  js.configs.recommended,

  // TypeScript rules
  ...tseslint.configs.recommended,

  // React hooks rules
  {
    plugins: {
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },

  // Import ordering
  {
    plugins: {
      'import-x': importX,
    },
    rules: {
      'import-x/order': [
        'error',
        {
          groups: [
            'builtin',          // Node.js built-ins
            'external',         // npm packages
            'internal',         // @/ aliased imports
            'parent',           // ../
            'sibling',          // ./
            'index',            // ./index
            'type',             // type imports
          ],
          'newlines-between': 'always',
          alphabetize: { order: 'asc', caseInsensitive: true },
          pathGroups: [
            { pattern: 'react', group: 'external', position: 'before' },
            { pattern: '@/**', group: 'internal' },
          ],
          pathGroupsExcludedImportTypes: ['react'],
        },
      ],
      'import-x/no-duplicates': 'error',
    },
  },

  // Custom rules
  {
    rules: {
      // TypeScript
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/consistent-type-imports': [
        'error',
        { prefer: 'type-imports', fixStyle: 'inline-type-imports' },
      ],
      '@typescript-eslint/no-empty-interface': 'off',

      // General
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'prefer-const': 'error',
      'no-var': 'error',
      eqeqeq: ['error', 'always'],
    },
  },

  // Prettier must be last — disables conflicting formatting rules
  prettier
);
```

## Prettier Config

### .prettierrc

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

```bash
# Install Tailwind CSS Prettier plugin (auto-sorts classes)
npm install -D prettier-plugin-tailwindcss
```

### .prettierignore

```
dist/
coverage/
node_modules/
*.min.js
pnpm-lock.yaml
package-lock.json
```

## Import Order Example

```tsx
// BAD: Random import order
import { useState } from 'react';
import { Button } from '@/components/ui/button';
import axios from 'axios';
import { useAuth } from '@/hooks/useAuth';
import { type User } from '@/types';
import { cn } from '@/lib/utils';
import { Link } from 'react-router-dom';

// GOOD: Organized imports (enforced by ESLint)
import { useState } from 'react';                    // 1. React first

import axios from 'axios';                            // 2. External packages
import { Link } from 'react-router-dom';

import { Button } from '@/components/ui/button';      // 3. Internal (@/ aliases)
import { useAuth } from '@/hooks/useAuth';
import { cn } from '@/lib/utils';

import { type User } from '@/types';                  // 4. Type imports last
```

## VS Code Integration

### .vscode/settings.json

```json
{
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.organizeImports": "never"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ]
}
```

### .vscode/extensions.json

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss"
  ]
}
```

## Package.json Scripts

```json
{
  "scripts": {
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "format": "prettier --write 'src/**/*.{ts,tsx,json,css,md}'",
    "format:check": "prettier --check 'src/**/*.{ts,tsx,json,css,md}'"
  }
}
```

## Key Rules Explained

```ts
// @typescript-eslint/consistent-type-imports
// Enforces: import { type User } from './types' (not import { User })
// Why: Helps bundlers tree-shake type-only imports

// @typescript-eslint/no-unused-vars with _ prefix
// Allows: const [_, setCount] = useState(0)
// Disallows: const unusedVar = 'hello'

// no-console (warn level)
// Allows: console.warn(), console.error()
// Warns: console.log() — use proper logging in production

// react-hooks/exhaustive-deps
// Enforces correct dependency arrays in useEffect, useMemo, useCallback

// react-refresh/only-export-components
// Ensures files export only components for proper HMR
```

## Anti-Patterns to Avoid

```ts
// BAD: Disabling rules inline without justification
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const data: any = response;

// GOOD: Fix the code, or add justification if truly needed
const data: unknown = response;

// BAD: Disabling rules project-wide because they're "annoying"
'@typescript-eslint/no-explicit-any': 'off' // Defeats the purpose!

// BAD: Prettier and ESLint conflicts
// If you see formatting fights, ensure eslint-config-prettier is LAST in config

// BAD: Different settings per developer
// Without .vscode/settings.json and .prettierrc, everyone formats differently

// GOOD: Committed config files + pre-commit hooks = consistency
```

## Summary: Decision Tree

1. **Setting up ESLint?** → Flat config (eslint.config.js) with typescript-eslint
2. **Formatting?** → Prettier handles it — ESLint only for logic/bugs
3. **Conflicts?** → `eslint-config-prettier` must be last in ESLint config
4. **Import order?** → `eslint-plugin-import-x` with group ordering
5. **Tailwind class sorting?** → `prettier-plugin-tailwindcss`
6. **Type imports?** → `consistent-type-imports` rule for tree-shaking
7. **Running?** → `npm run lint` for check, `npm run lint:fix` for auto-fix
8. **VS Code?** → Format on save + ESLint fix on save via settings.json
9. **CI?** → `npm run lint && npm run format:check` in pipeline
10. **Disabling rules?** → Fix the code first, disable only with justification
