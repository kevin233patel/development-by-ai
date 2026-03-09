---
name: github-actions
description: Provides GitHub Actions CI/CD patterns for React + TypeScript SaaS applications. Covers pipeline setup, lint/test/build stages, caching, environment secrets, preview deployments, and PR checks. Must use when creating or modifying CI/CD workflows.
---

# GitHub Actions Best Practices

## Core Principle: Fast Feedback, Safe Deployments

CI should catch issues before merge. CD should deploy safely with rollback. **Every PR runs lint → type check → test → build → performance gates. Main branch auto-deploys.**

## Pipeline Architecture

```
PR opened/updated:
  ├── Lint (ESLint + Prettier check)
  ├── Type Check (tsc --noEmit)
  ├── Unit Tests (Vitest + 80% coverage)
  ├── E2E Tests (Playwright)
  ├── Build (vite build)
  ├── Bundle Size Check (< 170KB initial JS)  ← Runtime Performance Matrix
  └── Lighthouse CI (score ≥ 70, blocks if < 70)  ← Runtime Performance Matrix

Merge to main:
  ├── All checks above
  └── Deploy to production
```

## CI Workflow

### .github/workflows/ci.yml

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel previous runs on same PR

jobs:
  lint:
    name: Lint & Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: ESLint
        run: npm run lint

      - name: Prettier Check
        run: npm run format:check

  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: TypeScript
        run: npx tsc --noEmit

  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Run Tests
        run: npm run test:run -- --coverage

      - name: Upload Coverage
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: coverage/

  e2e:
    name: E2E Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Install Playwright Browsers
        run: npx playwright install --with-deps chromium

      - name: Run E2E Tests
        run: npx playwright test --project=chromium

      - name: Upload E2E Report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: e2e/test-results/

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test]  # Only build if checks pass
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npm run build

      - name: Upload Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: build
          path: dist/

  bundle-size:
    name: Bundle Size Check
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npm run build

      # Runtime Performance Matrix: Initial JS < 170KB, Per-route < 100KB, CSS < 60KB
      # Critical thresholds: Initial JS > 350KB, Total transfer > 1MB
      - name: Check Bundle Size
        run: |
          INITIAL_JS=$(find dist/assets -name "*.js" ! -name "*.map" -exec du -sk {} + | sort -k1 -n | tail -1 | awk '{print $1}')
          echo "Largest JS chunk: ${INITIAL_JS}KB"
          if [ "$INITIAL_JS" -gt 350 ]; then
            echo "CRITICAL: JS bundle ${INITIAL_JS}KB exceeds 350KB — must fix before deploy"
            exit 1
          elif [ "$INITIAL_JS" -gt 200 ]; then
            echo "WARNING: JS bundle ${INITIAL_JS}KB exceeds 200KB target of 170KB"
          else
            echo "OK: JS bundle ${INITIAL_JS}KB is within budget"
          fi

  lighthouse:
    name: Lighthouse CI
    runs-on: ubuntu-latest
    needs: [build]
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npm run build

      # Runtime Performance Matrix: Performance ≥ 90 (Good), < 70 (Critical = must fix before deploy)
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v11
        with:
          uploadArtifacts: true
          temporaryPublicStorage: true
          runs: 3
          # lighthouserc.js thresholds (create this file in project root)
          configPath: './lighthouserc.js'
        env:
          LHCI_GITHUB_APP_TOKEN: ${{ secrets.LHCI_GITHUB_APP_TOKEN }}
```

### lighthouserc.js (add to project root)

```js
// lighthouserc.js — Runtime Performance Matrix thresholds
module.exports = {
  ci: {
    collect: {
      staticDistDir: './dist',
      numberOfRuns: 3,
    },
    assert: {
      assertions: {
        // Critical: must fix before deploy (score < 0.7)
        'categories:performance': ['error', { minScore: 0.7 }],
        // Good threshold
        'categories:accessibility': ['warn', { minScore: 0.9 }],
        // Core Web Vitals from Runtime Performance Matrix
        'first-contentful-paint': ['warn', { maxNumericValue: 1800 }],    // Good ≤ 1.8s
        'largest-contentful-paint': ['error', { maxNumericValue: 4000 }], // Critical > 4.0s
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.25 }],  // Critical > 0.25
        'total-blocking-time': ['error', { maxNumericValue: 600 }],       // Critical > 600ms
        'speed-index': ['warn', { maxNumericValue: 5800 }],               // Warning ≤ 5.8s
        // DOM size
        'dom-size': ['warn', { maxNumericValue: 3000 }],                  // Warning ≤ 3,000 nodes
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
};
```

## Deploy Workflow

### .github/workflows/deploy.yml

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest
    environment: production  # Requires approval if configured

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npm run build
        env:
          VITE_API_URL: ${{ secrets.VITE_API_URL }}
          VITE_APP_NAME: ${{ vars.VITE_APP_NAME }}

      # Example: Deploy to Vercel
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          working-directory: ./
```

## PR Preview Deployments

```yaml
# .github/workflows/preview.yml
name: Preview Deploy

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  preview:
    name: Deploy Preview
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'

      - run: npm ci

      - name: Build
        run: npm run build
        env:
          VITE_API_URL: ${{ secrets.STAGING_API_URL }}

      - name: Deploy Preview
        id: deploy
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}

      - name: Comment Preview URL
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `Preview deployed: ${{ steps.deploy.outputs.preview-url }}`
            })
```

## Caching Strategies

```yaml
# Node modules caching (built into setup-node)
- uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'npm'  # Caches ~/.npm

# Playwright browser caching
- name: Cache Playwright Browsers
  uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: playwright-${{ runner.os }}-${{ hashFiles('package-lock.json') }}

# Build cache
- name: Cache Vite Build
  uses: actions/cache@v4
  with:
    path: node_modules/.vite
    key: vite-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
```

## Environment Secrets

```yaml
# Use secrets for sensitive values
env:
  VITE_API_URL: ${{ secrets.VITE_API_URL }}

# Use vars for non-sensitive config
env:
  VITE_APP_NAME: ${{ vars.VITE_APP_NAME }}

# Use environments for deployment stages
jobs:
  deploy-staging:
    environment: staging
  deploy-production:
    environment: production
    needs: deploy-staging
```

### Setting Secrets

```bash
# Via GitHub CLI
gh secret set VITE_API_URL --body "https://api.myapp.com"
gh secret set VERCEL_TOKEN --body "xxx"

# Via GitHub UI
# Settings → Secrets and variables → Actions → New repository secret
```

## Branch Protection Rules

```bash
# Configure via GitHub CLI
gh api repos/{owner}/{repo}/branches/main/protection -X PUT -f \
  required_status_checks='{"strict":true,"contexts":["Lint & Format","Type Check","Unit Tests","Build"]}' \
  enforce_admins=true \
  required_pull_request_reviews='{"required_approving_review_count":1}'
```

Key rules for main branch:
- Require status checks to pass (lint, typecheck, test, build)
- Require at least 1 PR approval
- No direct pushes to main
- Branches must be up to date before merge

## Package.json Scripts

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc --noEmit && vite build",
    "preview": "vite preview",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "format": "prettier --write 'src/**/*.{ts,tsx,json,css,md}'",
    "format:check": "prettier --check 'src/**/*.{ts,tsx,json,css,md}'",
    "test": "vitest",
    "test:run": "vitest run",
    "test:coverage": "vitest run --coverage",
    "e2e": "playwright test",
    "e2e:headed": "playwright test --headed",
    "typecheck": "tsc --noEmit"
  }
}
```

## Anti-Patterns to Avoid

```yaml
# BAD: No concurrency control — duplicate runs
# Without concurrency group, every push queues a new run

# GOOD: Cancel previous runs on same PR
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# BAD: All steps in one giant job
# If lint fails, you still wait for tests and build to fail too

# GOOD: Parallel jobs with dependencies
jobs:
  lint: ...
  test: ...
  build:
    needs: [lint, test]  # Only runs if both pass

# BAD: Hardcoding secrets in workflow files
env:
  API_KEY: "sk-1234567890"  # Exposed in repo!

# GOOD: Use GitHub Secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# BAD: Not caching dependencies
# Every run installs from scratch — slow and wasteful

# GOOD: Cache node_modules via setup-node
```

## Summary: Decision Tree

1. **Setting up CI?** → Parallel jobs: lint → typecheck → test → build → bundle-size + lighthouse
2. **PR checks?** → All must pass before merge (branch protection)
3. **Caching?** → `setup-node` cache + Playwright browser cache
4. **Secrets?** → `gh secret set` or GitHub UI, never in code
5. **Deploy?** → On push to main, with environment protection
6. **PR previews?** → Auto-deploy preview on PR, comment URL
7. **Concurrency?** → Cancel previous runs with `cancel-in-progress: true`
8. **E2E in CI?** → Single browser (Chromium), retry 2x, trace on failure
9. **Build artifacts?** → Upload build + coverage + E2E reports + Lighthouse report
10. **Branch protection?** → Require checks + 1 approval + no direct push
11. **Bundle too big?** → CI fails if initial JS > 350KB; warns at > 200KB (target 170KB)
12. **Lighthouse failing?** → Score < 70 blocks deploy; score < 90 is a warning
