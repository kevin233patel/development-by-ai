---
name: husky-lint-staged
description: Provides Husky + lint-staged configuration for React + TypeScript SaaS applications. Covers pre-commit hooks, staged file linting, commit message validation, and CI bypass prevention. Must use when setting up or modifying git hooks and pre-commit quality gates.
---

# Husky + lint-staged Best Practices

## Core Principle: Catch Issues Before They Enter the Repo

Pre-commit hooks enforce quality gates at commit time. **Every commit should be linted, formatted, and type-checked** before it reaches the remote. No broken code in the repo, ever.

## Installation & Setup

```bash
npm install -D husky lint-staged

# Initialize Husky
npx husky init
```

This creates a `.husky/` directory with a `pre-commit` hook.

### Configure Pre-Commit Hook

```bash
# .husky/pre-commit
npx lint-staged
```

### Configure lint-staged

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{json,css,md}": [
      "prettier --write"
    ]
  }
}
```

## What Happens on Commit

```
git commit -m "feat: add user profile"
     │
     ▼
.husky/pre-commit runs
     │
     ▼
lint-staged runs on staged files only
     │
     ├── *.ts, *.tsx → ESLint --fix → Prettier --write
     ├── *.json, *.css, *.md → Prettier --write
     │
     ▼
If all pass → commit succeeds
If any fail → commit blocked, errors shown
```

## Commit Message Validation

### Using commitlint

```bash
npm install -D @commitlint/cli @commitlint/config-conventional
```

```js
// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Formatting (no code change)
        'refactor', // Code restructuring
        'perf',     // Performance improvement
        'test',     // Tests
        'build',    // Build system / dependencies
        'ci',       // CI configuration
        'chore',    // Maintenance
        'revert',   // Revert commit
      ],
    ],
    'subject-case': [2, 'never', ['start-case', 'pascal-case', 'upper-case']],
    'subject-max-length': [2, 'always', 72],
  },
};
```

```bash
# .husky/commit-msg
npx --no -- commitlint --edit "$1"
```

### Conventional Commit Examples

```bash
# GOOD: Follows convention
git commit -m "feat: add user profile page"
git commit -m "fix: resolve login redirect loop"
git commit -m "refactor: extract auth logic into custom hook"
git commit -m "test: add unit tests for permission checks"

# BAD: Rejected by commitlint
git commit -m "added stuff"             # No type prefix
git commit -m "feat: Add User Profile"  # Wrong case
git commit -m "fix: this is a very long commit message that exceeds seventy two characters limit"
```

## Advanced lint-staged Configuration

### With Type Checking

```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "bash -c 'npx tsc --noEmit'"
    ],
    "*.{json,css,md}": [
      "prettier --write"
    ]
  }
}
```

> **Note:** `tsc --noEmit` runs on the entire project (not just staged files) because TypeScript needs full context. This is slower but catches type errors that ESLint misses.

### Run Tests on Related Files

```json
{
  "lint-staged": {
    "*.{ts,tsx}": [
      "eslint --fix",
      "prettier --write",
      "vitest related --run"
    ]
  }
}
```

## Anti-Patterns to Avoid

```bash
# BAD: Skipping hooks
git commit --no-verify -m "quick fix"
# This defeats the entire purpose! Fix the issue instead.

# BAD: Running lint on ALL files, not just staged
"lint-staged": {
  "*.ts": "eslint src/"  # Lints everything, very slow
}
# GOOD: lint-staged only passes staged files to the command

# BAD: No hooks at all — relying on CI only
# CI catches issues too late — developer already moved on

# BAD: Too many slow checks in pre-commit
"lint-staged": {
  "*.ts": ["eslint", "prettier", "tsc", "vitest", "playwright"]
  # Pre-commit takes 2 minutes — developers will skip it
}

# GOOD: Fast checks in pre-commit, slow checks in CI
# Pre-commit: lint + format (< 10 seconds)
# CI: lint + format + typecheck + test + build
```

## File Structure

```
project/
├── .husky/
│   ├── pre-commit              # Runs lint-staged
│   └── commit-msg              # Runs commitlint
├── commitlint.config.js        # Commit message rules
└── package.json                # lint-staged config
```

## Summary: Decision Tree

1. **Setting up hooks?** → `npx husky init` + lint-staged in package.json
2. **What to run pre-commit?** → ESLint + Prettier on staged files only
3. **Commit messages?** → commitlint with conventional commits
4. **Type checking?** → Add `tsc --noEmit` if fast enough (< 10s)
5. **Running tests?** → `vitest related --run` for affected files only
6. **Hook too slow?** → Move slow checks (build, E2E) to CI
7. **Skipping hooks?** → Never use `--no-verify` — fix the issue
8. **CI also lint?** → Yes — hooks are local, CI is the safety net
