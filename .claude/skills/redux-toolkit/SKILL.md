---
name: redux-toolkit
description: Provides Redux Toolkit patterns for React + TypeScript SaaS applications. Covers store setup, typed hooks, slices, async thunks, RTK Query, selectors, persistence, and testing. Must use when creating or modifying Redux stores, slices, or global client-side state.
---

# Redux Toolkit Best Practices

## Core Principle: Redux for Client State, Not Server State

Use Redux Toolkit for **global client-side state** — auth, theme, sidebar, UI preferences, multi-step wizards. **Do NOT use Redux for server/API data** — use TanStack Query for that. This separation keeps Redux lean and avoids cache invalidation headaches.

## Installation

```bash
npm install @reduxjs/toolkit react-redux
```

## Store Setup

### Typed Store Configuration

```tsx
// src/stores/store.ts
import { configureStore } from '@reduxjs/toolkit';
import { authSlice } from './authSlice';
import { uiSlice } from './uiSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice.reducer,
    ui: uiSlice.reducer,
  },
});

// Infer types from the store itself
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

### Typed Hooks (Use These Everywhere)

```tsx
// src/stores/hooks.ts
import { useDispatch, useSelector } from 'react-redux';
import type { RootState, AppDispatch } from './store';

// BAD: Using untyped hooks
const dispatch = useDispatch(); // Dispatch type is unknown
const user = useSelector((state) => state.auth.user); // state is unknown

// GOOD: Create typed hooks once, use everywhere
export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
export const useAppSelector = useSelector.withTypes<RootState>();
```

```tsx
// Usage in components
import { useAppDispatch, useAppSelector } from '@/stores/hooks';

function Header() {
  const user = useAppSelector((state) => state.auth.user); // Fully typed
  const dispatch = useAppDispatch(); // Correctly typed dispatch
}
```

### Provider Setup

```tsx
// src/main.tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { Provider } from 'react-redux';
import { store } from '@/stores/store';
import { App } from '@/app/App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Provider store={store}>
      <App />
    </Provider>
  </StrictMode>
);
```

## Slice Patterns

### Auth Slice

```tsx
// src/stores/authSlice.ts
import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'member' | 'viewer';
  avatarUrl?: string;
}

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

const initialState: AuthState = {
  user: null,
  token: null,
  isAuthenticated: false,
};

export const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    setCredentials: (state, action: PayloadAction<{ user: User; token: string }>) => {
      state.user = action.payload.user;
      state.token = action.payload.token;
      state.isAuthenticated = true;
    },
    updateUser: (state, action: PayloadAction<Partial<User>>) => {
      if (state.user) {
        state.user = { ...state.user, ...action.payload };
      }
    },
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
    },
  },
});

export const { setCredentials, updateUser, logout } = authSlice.actions;

// Selectors — always co-locate with the slice
export const selectCurrentUser = (state: { auth: AuthState }) => state.auth.user;
export const selectIsAuthenticated = (state: { auth: AuthState }) => state.auth.isAuthenticated;
export const selectToken = (state: { auth: AuthState }) => state.auth.token;
export const selectUserRole = (state: { auth: AuthState }) => state.auth.user?.role;
```

### UI Slice

```tsx
// src/stores/uiSlice.ts
import { createSlice, type PayloadAction } from '@reduxjs/toolkit';

type Theme = 'light' | 'dark' | 'system';

interface UIState {
  theme: Theme;
  sidebarOpen: boolean;
  sidebarCollapsed: boolean;
}

const initialState: UIState = {
  theme: 'system',
  sidebarOpen: true,
  sidebarCollapsed: false,
};

export const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    setTheme: (state, action: PayloadAction<Theme>) => {
      state.theme = action.payload;
    },
    toggleSidebar: (state) => {
      state.sidebarOpen = !state.sidebarOpen;
    },
    toggleSidebarCollapse: (state) => {
      state.sidebarCollapsed = !state.sidebarCollapsed;
    },
    setSidebarOpen: (state, action: PayloadAction<boolean>) => {
      state.sidebarOpen = action.payload;
    },
  },
});

export const { setTheme, toggleSidebar, toggleSidebarCollapse, setSidebarOpen } = uiSlice.actions;

export const selectTheme = (state: { ui: UIState }) => state.ui.theme;
export const selectSidebarOpen = (state: { ui: UIState }) => state.ui.sidebarOpen;
export const selectSidebarCollapsed = (state: { ui: UIState }) => state.ui.sidebarCollapsed;
```

## Async Thunks

### When to Use Thunks vs TanStack Query

```tsx
// Use TanStack Query for:
// - GET requests (fetching data)
// - Caching, background refetch, stale-while-revalidate
// - Paginated/infinite queries

// Use Async Thunks for:
// - Side effects that update Redux state (login, logout)
// - Multi-step operations that need Redux
// - Operations that don't fit request/response pattern
```

### Typed Async Thunk

```tsx
// src/stores/authSlice.ts
import { createSlice, createAsyncThunk, type PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from './store';
import { authService } from '@/services/authService';

interface LoginPayload {
  email: string;
  password: string;
}

// BAD: Untyped thunk
export const login = createAsyncThunk('auth/login', async (credentials) => {
  const data = await authService.login(credentials);
  return data;
});

// GOOD: Fully typed thunk with error handling
export const login = createAsyncThunk<
  { user: User; token: string },  // Return type
  LoginPayload,                    // Argument type
  { state: RootState; rejectValue: string }  // ThunkAPI config
>(
  'auth/login',
  async (credentials, { rejectWithValue }) => {
    try {
      const data = await authService.login(credentials);
      localStorage.setItem('token', data.token);
      return data;
    } catch (error) {
      localStorage.removeItem('token');
      if (error instanceof Error) {
        return rejectWithValue(error.message);
      }
      return rejectWithValue('Login failed');
    }
  }
);

export const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    logout: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
      state.loginError = null;
      localStorage.removeItem('token');
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(login.pending, (state) => {
        state.loginError = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.user = action.payload.user;
        state.token = action.payload.token;
        state.isAuthenticated = true;
        state.loginError = null;
      })
      .addCase(login.rejected, (state, action) => {
        state.loginError = action.payload ?? 'Login failed';
        state.isAuthenticated = false;
      });
  },
});
```

### Using Thunks in Components

```tsx
// BAD: Dispatching without handling loading/error
function LoginForm() {
  const dispatch = useAppDispatch();
  const handleLogin = (data: LoginFormValues) => {
    dispatch(login(data)); // Fire and forget!
  };
}

// GOOD: Handle all states
function LoginForm() {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogin = async (data: LoginFormValues) => {
    setIsSubmitting(true);
    try {
      await dispatch(login(data)).unwrap(); // unwrap() throws on rejection
      navigate('/dashboard');
    } catch (error) {
      // Error is already in Redux state via rejectWithValue
      // UI can read it from selectLoginError
    } finally {
      setIsSubmitting(false);
    }
  };

  return <form onSubmit={handleSubmit(handleLogin)}>...</form>;
}
```

## Selectors

### Memoized Selectors with createSelector

```tsx
// BAD: Selector that creates new reference every call
const selectActiveProjects = (state: RootState) =>
  state.projects.items.filter((p) => p.status === 'active'); // New array every time!

// GOOD: Memoized selector with createSelector
import { createSelector } from '@reduxjs/toolkit';

const selectProjectItems = (state: RootState) => state.projects.items;

export const selectActiveProjects = createSelector(
  [selectProjectItems],
  (items) => items.filter((p) => p.status === 'active')
);

// GOOD: Parameterized selector
export const selectProjectsByStatus = createSelector(
  [selectProjectItems, (_state: RootState, status: string) => status],
  (items, status) => items.filter((p) => p.status === status)
);

// Usage
const activeProjects = useAppSelector(selectActiveProjects);
const archivedProjects = useAppSelector((state) => selectProjectsByStatus(state, 'archived'));
```

## State Persistence

### Persist Auth Token

```tsx
// src/stores/middleware/persistMiddleware.ts
import type { Middleware } from '@reduxjs/toolkit';

export const persistAuthMiddleware: Middleware = (store) => (next) => (action) => {
  const result = next(action);

  // Persist token on auth changes
  const state = store.getState();
  if (state.auth.token) {
    localStorage.setItem('token', state.auth.token);
  } else {
    localStorage.removeItem('token');
  }

  return result;
};

// Or use redux-persist for complex persistence needs
// npm install redux-persist
```

### Hydrate State on App Load

```tsx
// src/stores/store.ts
import { configureStore } from '@reduxjs/toolkit';

function getPreloadedState() {
  const token = localStorage.getItem('token');
  const theme = localStorage.getItem('theme') as 'light' | 'dark' | 'system' | null;

  return {
    auth: {
      user: null, // Will be fetched via API on mount
      token,
      isAuthenticated: !!token,
    },
    ui: {
      theme: theme ?? 'system',
      sidebarOpen: true,
      sidebarCollapsed: false,
    },
  };
}

export const store = configureStore({
  reducer: {
    auth: authSlice.reducer,
    ui: uiSlice.reducer,
  },
  preloadedState: getPreloadedState(),
});
```

## File Structure

```
src/stores/
├── store.ts           # Store configuration (configureStore)
├── hooks.ts           # Typed useAppDispatch & useAppSelector
├── authSlice.ts       # Auth state + selectors + thunks
├── uiSlice.ts         # UI state (theme, sidebar, etc.)
└── middleware/
    └── persistMiddleware.ts  # Custom middleware (if needed)
```

```tsx
// BAD: One giant slice file with everything
// stores/rootSlice.ts — 500 lines of mixed concerns

// BAD: Over-splitting into tiny files
// stores/auth/actions.ts
// stores/auth/reducers.ts
// stores/auth/selectors.ts
// stores/auth/types.ts
// stores/auth/thunks.ts

// GOOD: One file per slice, co-locate everything
// stores/authSlice.ts — types, slice, actions, selectors, thunks all together
```

## Anti-Patterns to Avoid

```tsx
// BAD: Putting API data in Redux
const projectsSlice = createSlice({
  name: 'projects',
  initialState: { items: [], isLoading: false, error: null },
  // ... managing fetch states manually
});
// Use TanStack Query instead!

// BAD: Duplicating server state in Redux
dispatch(setUsers(apiResponse.users));
// TanStack Query handles caching automatically

// BAD: useSelector with inline transform (creates new ref each render)
const user = useAppSelector((state) => ({
  name: state.auth.user?.name,
  role: state.auth.user?.role,
})); // New object every render!

// GOOD: Select specific primitives or use createSelector
const userName = useAppSelector((state) => state.auth.user?.name);
const userRole = useAppSelector((state) => state.auth.user?.role);

// BAD: Dispatching in useEffect on every render
useEffect(() => {
  dispatch(setTheme(theme)); // If theme changes, this loops
}, [theme, dispatch]);

// GOOD: Dispatch in event handlers
const handleThemeChange = (newTheme: Theme) => {
  dispatch(setTheme(newTheme));
};

// BAD: Storing form state in Redux
dispatch(setFormField({ name: 'email', value: 'john@example.com' }));
// Use React Hook Form for form state!

// BAD: Storing component-local state in Redux
dispatch(setModalOpen(true));
// Use useState for UI-only state that doesn't need sharing!
```

## Summary: Decision Tree

1. **Setting up store?** → `configureStore` + typed hooks in separate file
2. **New global state?** → Create a new slice with `createSlice`
3. **Selectors?** → Co-locate with slice, use `createSelector` for derived data
4. **Async operation that updates Redux?** → `createAsyncThunk` with typed generics
5. **Fetching API data?** → Use TanStack Query, NOT Redux
6. **Form state?** → Use React Hook Form, NOT Redux
7. **Component-local UI state?** → Use `useState`, NOT Redux
8. **Need persistence?** → Use `preloadedState` + middleware for simple cases
9. **Accessing state in components?** → Always use `useAppSelector` + `useAppDispatch`
10. **Creating new objects in selectors?** → Use `createSelector` to memoize
