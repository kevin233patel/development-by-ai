---
name: playwright
description: Provides Playwright end-to-end testing patterns for React + TypeScript SaaS applications. Covers test setup, page object model, auth handling, fixtures, visual testing, and CI configuration. Must use when writing or running E2E tests for critical user flows.
---

# Playwright Best Practices

## Core Principle: Test Critical User Journeys

E2E tests are expensive to write and maintain. **Only test critical user flows** — login, sign up, core feature workflows, checkout. Use unit/integration tests for everything else.

## Installation & Setup

```bash
npm init playwright@latest
# Installs: @playwright/test, browsers
```

### playwright.config.ts

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  outputDir: './e2e/test-results',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,          // Fail CI if .only is left in
  retries: process.env.CI ? 2 : 0,       // Retry in CI
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI
    ? [['html', { open: 'never' }], ['github']]
    : [['html', { open: 'on-failure' }]],

  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',              // Capture trace on retry
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 12'] } },
  ],

  // Start dev server before tests
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## Project Structure

```
e2e/
├── fixtures/
│   ├── auth.fixture.ts        # Auth setup fixture
│   └── test-data.ts           # Shared test data
├── pages/
│   ├── LoginPage.ts           # Page object
│   ├── DashboardPage.ts
│   ├── ProjectPage.ts
│   └── SettingsPage.ts
├── tests/
│   ├── auth.spec.ts           # Auth flow tests
│   ├── projects.spec.ts       # Project CRUD tests
│   └── settings.spec.ts       # Settings tests
├── .auth/                     # Stored auth state (gitignored)
└── test-results/              # Test output (gitignored)
```

## Page Object Model

### Page Object Pattern

```ts
// e2e/pages/LoginPage.ts
import { type Page, type Locator, expect } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;
  readonly forgotPasswordLink: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Password');
    this.submitButton = page.getByRole('button', { name: 'Sign In' });
    this.errorMessage = page.locator('[role="alert"]');
    this.forgotPasswordLink = page.getByRole('link', { name: 'Forgot password?' });
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async expectError(message: string) {
    await expect(this.errorMessage).toContainText(message);
  }

  async expectRedirectToDashboard() {
    await expect(this.page).toHaveURL('/dashboard');
  }
}
```

```ts
// e2e/pages/DashboardPage.ts
import { type Page, type Locator, expect } from '@playwright/test';

export class DashboardPage {
  readonly page: Page;
  readonly heading: Locator;
  readonly createProjectButton: Locator;
  readonly projectList: Locator;

  constructor(page: Page) {
    this.page = page;
    this.heading = page.getByRole('heading', { name: /dashboard/i });
    this.createProjectButton = page.getByRole('button', { name: 'Create Project' });
    this.projectList = page.getByRole('list');
  }

  async goto() {
    await this.page.goto('/dashboard');
  }

  async expectLoaded() {
    await expect(this.heading).toBeVisible();
  }

  async createProject(name: string) {
    await this.createProjectButton.click();
    const dialog = this.page.getByRole('dialog');
    await dialog.getByLabel('Project Name').fill(name);
    await dialog.getByRole('button', { name: 'Create' }).click();
    await expect(dialog).not.toBeVisible();
  }
}
```

## Authentication Setup

### Shared Auth State (Login Once, Reuse)

```ts
// e2e/fixtures/auth.fixture.ts
import { test as base, expect } from '@playwright/test';
import path from 'path';

const authFile = path.join(__dirname, '../.auth/user.json');

// Setup: login once and save storage state
export const setup = base.extend({});

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').fill('password123');
  await page.getByRole('button', { name: 'Sign In' }).click();
  await expect(page).toHaveURL('/dashboard');

  // Save auth state (cookies, localStorage)
  await page.context().storageState({ path: authFile });
});

// Test fixture that reuses auth state
export const test = base.extend({});

// In playwright.config.ts, add auth setup project
// projects: [
//   { name: 'setup', testMatch: /auth\.fixture\.ts/ },
//   {
//     name: 'chromium',
//     use: { ...devices['Desktop Chrome'], storageState: authFile },
//     dependencies: ['setup'],
//   },
// ],
```

### Using Auth in Tests

```ts
// e2e/tests/projects.spec.ts
import { test, expect } from '@playwright/test';
import { DashboardPage } from '../pages/DashboardPage';

// These tests run with authenticated state (storageState from config)
test.describe('Projects', () => {
  test('user can create a project', async ({ page }) => {
    const dashboard = new DashboardPage(page);
    await dashboard.goto();
    await dashboard.expectLoaded();

    await dashboard.createProject('My New Project');

    await expect(page.getByText('My New Project')).toBeVisible();
  });

  test('user can delete a project', async ({ page }) => {
    await page.goto('/projects');

    // Open actions menu
    await page.getByRole('button', { name: 'More actions' }).first().click();
    await page.getByRole('menuitem', { name: 'Delete' }).click();

    // Confirm deletion
    const dialog = page.getByRole('alertdialog');
    await expect(dialog).toContainText('permanently delete');
    await dialog.getByRole('button', { name: 'Delete' }).click();

    await expect(dialog).not.toBeVisible();
  });
});
```

## Test Patterns

### Auth Flow Tests

```ts
// e2e/tests/auth.spec.ts
import { test, expect } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

// Auth tests DON'T use stored auth state
test.use({ storageState: { cookies: [], origins: [] } });

test.describe('Authentication', () => {
  test('user can login with valid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('test@example.com', 'password123');
    await loginPage.expectRedirectToDashboard();
  });

  test('shows error for invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('test@example.com', 'wrongpassword');
    await loginPage.expectError('Invalid credentials');
  });

  test('redirects to login when unauthenticated', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL('/login');
  });

  test('redirects back after login', async ({ page }) => {
    // Try to access protected page
    await page.goto('/settings');
    await expect(page).toHaveURL(/\/login/);

    // Login
    await page.getByLabel('Email').fill('test@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: 'Sign In' }).click();

    // Should redirect back to settings
    await expect(page).toHaveURL('/settings');
  });
});
```

### Navigation Tests

```ts
test.describe('Navigation', () => {
  test('sidebar links navigate correctly', async ({ page }) => {
    await page.goto('/dashboard');

    await page.getByRole('link', { name: 'Projects' }).click();
    await expect(page).toHaveURL('/projects');

    await page.getByRole('link', { name: 'Settings' }).click();
    await expect(page).toHaveURL('/settings');
  });

  test('active nav item is highlighted', async ({ page }) => {
    await page.goto('/projects');

    const projectsLink = page.getByRole('link', { name: 'Projects' });
    await expect(projectsLink).toHaveAttribute('aria-current', 'page');
  });
});
```

### Form Submission Tests

```ts
test('settings form saves successfully', async ({ page }) => {
  await page.goto('/settings/profile');

  await page.getByLabel('Display Name').clear();
  await page.getByLabel('Display Name').fill('Updated Name');
  await page.getByLabel('Bio').fill('Updated bio text');

  await page.getByRole('button', { name: 'Save Changes' }).click();

  // Toast notification
  await expect(page.getByText('Settings saved')).toBeVisible();

  // Reload and verify persistence
  await page.reload();
  await expect(page.getByLabel('Display Name')).toHaveValue('Updated Name');
});
```

## Locator Strategies

```ts
// GOOD: Accessible locators (prefer these)
page.getByRole('button', { name: 'Submit' });
page.getByLabel('Email');
page.getByPlaceholder('Search...');
page.getByText('Welcome');
page.getByRole('heading', { level: 1 });

// GOOD: For components without accessible names
page.getByTestId('project-card');

// GOOD: Chaining for specificity
page.getByRole('dialog').getByRole('button', { name: 'Confirm' });

// GOOD: nth for lists
page.getByRole('listitem').nth(0);
page.getByRole('listitem').first();
page.getByRole('listitem').last();

// BAD: CSS selectors (fragile)
page.locator('.btn-primary');
page.locator('#submit');

// BAD: XPath
page.locator('//div[@class="container"]//button');
```

## Running Tests

```bash
# Run all E2E tests
npx playwright test

# Run specific test file
npx playwright test e2e/tests/auth.spec.ts

# Run in headed mode (see browser)
npx playwright test --headed

# Run specific browser
npx playwright test --project=chromium

# Debug mode (step through)
npx playwright test --debug

# Show HTML report
npx playwright show-report

# Update snapshots
npx playwright test --update-snapshots

# Run with UI mode
npx playwright test --ui
```

### Package.json Scripts

```json
{
  "scripts": {
    "e2e": "playwright test",
    "e2e:headed": "playwright test --headed",
    "e2e:debug": "playwright test --debug",
    "e2e:ui": "playwright test --ui",
    "e2e:report": "playwright show-report"
  }
}
```

## Anti-Patterns to Avoid

```ts
// BAD: Hard-coded waits
await page.waitForTimeout(3000); // Flaky!

// GOOD: Wait for specific conditions
await expect(page.getByText('Loaded')).toBeVisible();
await page.waitForResponse('**/api/projects');

// BAD: Testing everything E2E
test('button has correct font size', ...); // Unit test territory

// GOOD: Only test critical user journeys E2E
test('user can complete checkout flow', ...);

// BAD: Tests depend on each other
test('create project', async () => { /* creates data */ });
test('edit project', async () => { /* assumes data from above */ });

// GOOD: Each test is independent
test('edit project', async () => {
  // Setup its own data
  await api.createProject({ name: 'Test' });
  // Then test editing
});

// BAD: Assertions only at the end
test('complex flow', async () => {
  await step1();
  await step2();
  await step3();
  expect(result).toBe('done'); // Only fails at end — hard to debug
});

// GOOD: Assert at each step
test('complex flow', async () => {
  await step1();
  await expect(page.getByText('Step 1 complete')).toBeVisible();
  await step2();
  await expect(page.getByText('Step 2 complete')).toBeVisible();
});
```

## Summary: Decision Tree

1. **What to E2E test?** → Login, signup, core CRUD flows, checkout — critical paths only
2. **Page structure?** → Page Object Model in `e2e/pages/`
3. **Auth in tests?** → Store auth state, reuse via `storageState`
4. **Locating elements?** → `getByRole` > `getByLabel` > `getByText` > `getByTestId`
5. **Waiting?** → Never `waitForTimeout` — use `expect().toBeVisible()` or `waitForResponse`
6. **Test independence?** → Each test sets up its own data, no shared mutable state
7. **Running in CI?** → Single worker, retry 2x, trace on first retry
8. **Debugging?** → `--debug` for step-through, `--ui` for interactive mode
9. **Cross-browser?** → Test Chromium + Firefox + WebKit in CI
10. **Mobile testing?** → Add mobile device projects in config
