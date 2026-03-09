---
name: vitest
description: Provides Vitest unit and integration testing patterns for React + TypeScript SaaS applications. Covers test setup, mocking, async testing, custom render utilities, snapshot testing, coverage, and CI integration. Must use when writing or running unit/integration tests.
---

# Vitest Best Practices

## Core Principle: Test Behavior, Not Implementation

Tests should verify **what** the code does, not **how** it does it. If you refactor internals without changing behavior, tests should still pass. Write tests from the user's perspective.

## Installation & Setup

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom
```

### Vitest Config (in vite.config.ts)

```ts
/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  test: {
    globals: true,                              // No need to import describe, it, expect
    environment: 'jsdom',                       // Browser-like environment
    setupFiles: ['./src/test/setup.ts'],        // Global setup
    include: ['src/**/*.{test,spec}.{ts,tsx}'], // Test file patterns
    css: true,                                  // Process CSS imports
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/**/*.test.{ts,tsx}',
        'src/**/*.spec.{ts,tsx}',
        'src/test/**',
        'src/types/**',
        'src/main.tsx',
        'src/vite-env.d.ts',
      ],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
  },
});
```

### Test Setup File

```ts
// src/test/setup.ts
import '@testing-library/jest-dom/vitest';

// Mock window.matchMedia for components that use it
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver
class MockIntersectionObserver {
  observe = vi.fn();
  unobserve = vi.fn();
  disconnect = vi.fn();
}
Object.defineProperty(window, 'IntersectionObserver', {
  writable: true,
  value: MockIntersectionObserver,
});

// Clean up after each test
afterEach(() => {
  vi.restoreAllMocks();
});
```

## Test File Structure

### Naming & Organization

```
src/
├── components/common/Button/
│   ├── Button.tsx
│   └── Button.test.tsx        # Co-located with component
├── hooks/
│   ├── useAuth.ts
│   └── useAuth.test.ts        # Co-located with hook
├── lib/
│   ├── utils.ts
│   └── utils.test.ts          # Co-located with utility
└── test/
    ├── setup.ts               # Global test setup
    ├── helpers.tsx             # Custom render, mock providers
    └── mocks/
        ├── handlers.ts        # MSW handlers (if using MSW)
        └── data.ts            # Shared test fixtures
```

### Test Structure Pattern

```tsx
// BAD: Unclear test names, testing implementation
describe('UserList', () => {
  it('should work', () => { ... });
  it('test 1', () => { ... });
  it('calls setState with correct value', () => { ... }); // Implementation detail!
});

// GOOD: Descriptive tests organized by behavior
describe('UserList', () => {
  describe('when loading', () => {
    it('renders skeleton placeholders', () => { ... });
  });

  describe('when data is loaded', () => {
    it('renders a list of user cards', () => { ... });
    it('displays user name and email for each user', () => { ... });
  });

  describe('when empty', () => {
    it('renders empty state with create action', () => { ... });
  });

  describe('when error occurs', () => {
    it('renders error message with retry button', () => { ... });
  });
});
```

## Custom Test Render

### Wrap with All Providers

```tsx
// src/test/helpers.tsx
import { render, type RenderOptions } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Provider } from 'react-redux';
import { QueryClientProvider, QueryClient } from '@tanstack/react-query';
import { MemoryRouter } from 'react-router-dom';
import { configureStore } from '@reduxjs/toolkit';
import { authSlice } from '@/stores/authSlice';
import { uiSlice } from '@/stores/uiSlice';
import type { RootState } from '@/stores/store';

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  preloadedState?: Partial<RootState>;
  route?: string;
}

export function renderWithProviders(
  ui: React.ReactElement,
  {
    preloadedState = {},
    route = '/',
    ...renderOptions
  }: CustomRenderOptions = {}
) {
  const store = configureStore({
    reducer: {
      auth: authSlice.reducer,
      ui: uiSlice.reducer,
    },
    preloadedState,
  });

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false },
    },
  });

  function Wrapper({ children }: { children: React.ReactNode }) {
    return (
      <Provider store={store}>
        <QueryClientProvider client={queryClient}>
          <MemoryRouter initialEntries={[route]}>
            {children}
          </MemoryRouter>
        </QueryClientProvider>
      </Provider>
    );
  }

  return {
    ...render(ui, { wrapper: Wrapper, ...renderOptions }),
    store,
    queryClient,
    user: userEvent.setup(),
  };
}
```

### Usage

```tsx
import { renderWithProviders } from '@/test/helpers';

describe('Dashboard', () => {
  it('shows welcome message for authenticated user', () => {
    const { getByText } = renderWithProviders(<Dashboard />, {
      preloadedState: {
        auth: {
          user: { id: '1', name: 'John', email: 'john@test.com', role: 'admin' },
          token: 'fake-token',
          isAuthenticated: true,
        },
      },
    });

    expect(getByText('Welcome, John')).toBeInTheDocument();
  });
});
```

## Mocking Patterns

### Mock API Calls

```tsx
// BAD: Mocking implementation details
vi.mock('@/stores/hooks', () => ({
  useAppSelector: vi.fn().mockReturnValue({ name: 'John' }),
}));

// GOOD: Mock at the service/API layer
import { projectService } from '@/services/projectService';

vi.mock('@/services/projectService');
const mockProjectService = vi.mocked(projectService);

describe('ProjectList', () => {
  it('renders projects from API', async () => {
    mockProjectService.getAll.mockResolvedValue({
      data: [
        { id: '1', name: 'Project A', slug: 'project-a', status: 'active' },
        { id: '2', name: 'Project B', slug: 'project-b', status: 'active' },
      ],
      total: 2,
      page: 1,
      pageSize: 10,
      totalPages: 1,
    });

    const { getByText } = renderWithProviders(<ProjectList />);

    expect(await screen.findByText('Project A')).toBeInTheDocument();
    expect(getByText('Project B')).toBeInTheDocument();
  });
});
```

### Mock Navigation

```tsx
const mockNavigate = vi.fn();
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return { ...actual, useNavigate: () => mockNavigate };
});

it('navigates to project detail on click', async () => {
  const { user, getByText } = renderWithProviders(<ProjectCard project={mockProject} />);

  await user.click(getByText('View Details'));

  expect(mockNavigate).toHaveBeenCalledWith('/projects/123');
});
```

### Mock Timers

```tsx
describe('useDebounce', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('debounces value changes', () => {
    const { result, rerender } = renderHook(
      ({ value }) => useDebounce(value, 500),
      { initialProps: { value: 'initial' } }
    );

    expect(result.current).toBe('initial');

    rerender({ value: 'updated' });
    expect(result.current).toBe('initial'); // Not yet

    vi.advanceTimersByTime(500);
    expect(result.current).toBe('updated'); // Now debounced
  });
});
```

## Testing Utilities & Hooks

### Testing Custom Hooks

```tsx
import { renderHook, act } from '@testing-library/react';

describe('useCounter', () => {
  it('increments counter', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });
});
```

### Testing Utility Functions

```tsx
// Pure functions — simplest tests
import { formatCurrency, truncateText } from '@/lib/utils';

describe('formatCurrency', () => {
  it('formats USD amount correctly', () => {
    expect(formatCurrency(1234.56, 'USD')).toBe('$1,234.56');
  });

  it('handles zero', () => {
    expect(formatCurrency(0, 'USD')).toBe('$0.00');
  });

  it('handles negative amounts', () => {
    expect(formatCurrency(-50, 'USD')).toBe('-$50.00');
  });
});

describe('truncateText', () => {
  it('returns full text if under limit', () => {
    expect(truncateText('hello', 10)).toBe('hello');
  });

  it('truncates and adds ellipsis', () => {
    expect(truncateText('hello world', 8)).toBe('hello...');
  });
});
```

## Running Tests

```bash
# Run all tests
npx vitest

# Run in watch mode (default in dev)
npx vitest --watch

# Run specific file
npx vitest src/components/Button/Button.test.tsx

# Run with coverage
npx vitest --coverage

# Run once (CI mode)
npx vitest run

# Run with UI
npx vitest --ui
```

### Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "test:coverage": "vitest run --coverage",
    "test:ui": "vitest --ui"
  }
}
```

## Anti-Patterns to Avoid

```tsx
// BAD: Testing implementation details
it('calls setState with correct value', () => {
  const setState = vi.fn();
  vi.spyOn(React, 'useState').mockReturnValue(['', setState]);
  // Testing React internals!
});

// GOOD: Test the result, not the mechanism
it('updates displayed text when typing', async () => {
  const { user, getByRole } = render(<SearchInput />);
  await user.type(getByRole('textbox'), 'hello');
  expect(getByRole('textbox')).toHaveValue('hello');
});

// BAD: Snapshot testing everything
it('matches snapshot', () => {
  const { container } = render(<ComplexComponent />);
  expect(container).toMatchSnapshot(); // Brittle, breaks on any change
});

// GOOD: Assert specific, meaningful things
it('renders the correct heading and description', () => {
  render(<ComplexComponent title="Hello" description="World" />);
  expect(screen.getByRole('heading')).toHaveTextContent('Hello');
  expect(screen.getByText('World')).toBeInTheDocument();
});

// BAD: No cleanup between tests
let globalState = {};
it('test 1', () => { globalState.key = 'value'; });
it('test 2', () => { /* globalState leaks! */ });

// GOOD: Each test is independent
it('test 1', () => {
  const state = { key: 'value' };
  expect(state.key).toBe('value');
});
```

## Summary: Decision Tree

1. **Setting up tests?** → Vitest in `vite.config.ts` + setup file + custom render
2. **Testing a component?** → `renderWithProviders` + query by role/text + assert
3. **Testing a hook?** → `renderHook` + `act` for state changes
4. **Testing a utility?** → Direct function call + `expect`
5. **Mocking API calls?** → `vi.mock` at service layer, not hook layer
6. **Mocking navigation?** → Mock `useNavigate`, assert `mockNavigate` calls
7. **Testing async?** → `await screen.findByText()` or `waitFor()`
8. **Need timers?** → `vi.useFakeTimers()` + `vi.advanceTimersByTime()`
9. **Running in CI?** → `vitest run --coverage` with thresholds
10. **File location?** → Co-locate `*.test.tsx` next to source file
