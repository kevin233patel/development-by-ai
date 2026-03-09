---
name: authentication
description: Provides JWT/OAuth authentication patterns for React + TypeScript SaaS applications. Covers login/register flows, token storage, auto-refresh, auth context, protected routes, and social OAuth. Must use when implementing auth flows, login pages, token management, or auth guards.
---

# Authentication Best Practices

## Core Principle: Secure by Default

Store tokens securely, refresh automatically, and guard every protected route. **Never trust the client — always validate on the server.** The frontend auth layer is about UX, not security.

## Auth Architecture

### Auth Flow Overview

```
1. User submits login form
2. API returns { accessToken, user } — server sets refreshToken as httpOnly cookie (Set-Cookie header)
3. Store accessToken in Redux (memory only, ~15min TTL)
4. refreshToken lives in httpOnly cookie — JS cannot read/steal it (XSS-safe)
5. Axios interceptor attaches accessToken to every request (Authorization: Bearer)
6. On 401 → POST /auth/refresh with credentials: 'include' → server reads cookie, returns new accessToken
7. On refresh failure → logout, clear Redux, redirect to /login
```

### Token Storage Decision

- **accessToken** → Redux memory (never localStorage — XSS would steal it)
- **refreshToken** → httpOnly cookie set by server (JS cannot access, XSS-safe)
  - Cross-domain API fallback: localStorage (accept XSS risk, mitigate with strict CSP)

| Storage | XSS Safe | CSRF Safe | Persists |
|---------|----------|-----------|----------|
| Redux memory (accessToken) | ✅ | ✅ | ❌ tab close |
| httpOnly cookie (refreshToken) | ✅ | ✅ SameSite=Strict | ✅ |
| localStorage (refreshToken) | ❌ JS-readable | ✅ | ✅ |

## Auth Hook

### useAuth Hook

```tsx
// src/hooks/useAuth.ts
import { useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAppDispatch, useAppSelector } from '@/stores/hooks';
import {
  setCredentials,
  logout as logoutAction,
  selectCurrentUser,
  selectIsAuthenticated,
} from '@/stores/authSlice';
import { authService } from '@/services/authService';
import { queryClient } from '@/lib/queryClient';

export function useAuth() {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const location = useLocation();
  const user = useAppSelector(selectCurrentUser);
  const isAuthenticated = useAppSelector(selectIsAuthenticated);

  const login = useCallback(
    async (credentials: { email: string; password: string }) => {
      const data = await authService.login(credentials);
      dispatch(setCredentials({ user: data.user, token: data.token }));

      // Redirect to where they came from, or dashboard
      const returnTo = (location.state as { from?: string })?.from ?? '/dashboard';
      navigate(returnTo, { replace: true });
    },
    [dispatch, navigate, location.state]
  );

  const register = useCallback(
    async (input: { name: string; email: string; password: string }) => {
      const data = await authService.register(input);
      dispatch(setCredentials({ user: data.user, token: data.token }));
      navigate('/dashboard', { replace: true });
    },
    [dispatch, navigate]
  );

  const logout = useCallback(() => {
    authService.logout(); // Clear server session if needed
    dispatch(logoutAction());
    queryClient.clear(); // Clear all cached data
    navigate('/login', { replace: true });
  }, [dispatch, navigate]);

  return {
    user,
    isAuthenticated,
    isLoading: false,
    login,
    register,
    logout,
  };
}
```

## Auth Service

```tsx
// src/services/authService.ts
import { apiClient } from '@/lib/apiClient';
import type { User } from '@/types';

interface AuthResponse {
  user: User;
  token: string;
  refreshToken: string;
}

interface LoginInput {
  email: string;
  password: string;
}

interface RegisterInput {
  name: string;
  email: string;
  password: string;
}

export const authService = {
  login: async (input: LoginInput): Promise<AuthResponse> => {
    // Server sets refreshToken as httpOnly cookie via Set-Cookie header automatically
    // withCredentials: true ensures the cookie is sent/received cross-origin if needed
    const { data } = await apiClient.post('/auth/login', input, { withCredentials: true });
    return data;
  },

  register: async (input: RegisterInput): Promise<AuthResponse> => {
    // Server sets refreshToken as httpOnly cookie via Set-Cookie header automatically
    const { data } = await apiClient.post('/auth/register', input, { withCredentials: true });
    return data;
  },

  logout: async () => {
    // Server clears the httpOnly cookie — frontend cannot clear httpOnly cookies directly
    await apiClient.post('/auth/logout', {}, { withCredentials: true });
  },

  refreshToken: async (): Promise<AuthResponse> => {
    // Server reads httpOnly cookie automatically — no need to send token from JS
    const { data } = await apiClient.post('/auth/refresh', {}, { withCredentials: true });
    return data;
  },

  getProfile: async (): Promise<User> => {
    const { data } = await apiClient.get('/auth/me');
    return data;
  },

  forgotPassword: async (email: string): Promise<void> => {
    await apiClient.post('/auth/forgot-password', { email });
  },

  resetPassword: async (token: string, password: string): Promise<void> => {
    await apiClient.post('/auth/reset-password', { token, password });
  },
};
```

## Login Page

```tsx
// src/features/auth/pages/Login.tsx
import { Link } from 'react-router-dom';
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useAuth } from '@/hooks/useAuth';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ApiError } from '@/lib/apiError';

const loginSchema = z.object({
  email: z.string().email('Please enter a valid email'),
  password: z.string().min(1, 'Password is required'),
});

type LoginInput = z.infer<typeof loginSchema>;

export default function Login() {
  const { login } = useAuth();

  const form = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  });

  const handleSubmit = async (data: LoginInput) => {
    try {
      await login(data);
    } catch (error) {
      if (error instanceof ApiError) {
        form.setError('root', { message: error.message });
      } else {
        form.setError('root', { message: 'An unexpected error occurred' });
      }
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Sign In</CardTitle>
        <CardDescription>Enter your credentials to access your account</CardDescription>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
            {form.formState.errors.root && (
              <div className="rounded-md bg-destructive/10 p-3 text-sm text-destructive">
                {form.formState.errors.root.message}
              </div>
            )}

            <FormField
              control={form.control}
              name="email"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl>
                    <Input type="email" placeholder="john@example.com" autoComplete="email" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="password"
              render={({ field }) => (
                <FormItem>
                  <div className="flex items-center justify-between">
                    <FormLabel>Password</FormLabel>
                    <Link to="/forgot-password" className="text-xs text-primary hover:underline">
                      Forgot password?
                    </Link>
                  </div>
                  <FormControl>
                    <Input type="password" autoComplete="current-password" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>
              {form.formState.isSubmitting ? 'Signing in...' : 'Sign In'}
            </Button>

            <p className="text-center text-sm text-muted-foreground">
              Don't have an account?{' '}
              <Link to="/register" className="text-primary hover:underline">
                Sign up
              </Link>
            </p>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
}
```

## App Initialization — Hydrate Auth on Load

```tsx
// src/app/AuthInitializer.tsx
import { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '@/stores/hooks';
import { setCredentials, logout, selectToken } from '@/stores/authSlice';
import { authService } from '@/services/authService';
import { PageSkeleton } from '@/components/common/PageSkeleton';

export function AuthInitializer({ children }: { children: React.ReactNode }) {
  const [isInitializing, setIsInitializing] = useState(true);
  const dispatch = useAppDispatch();
  const token = useAppSelector(selectToken);

  useEffect(() => {
    async function initAuth() {
      if (!token) {
        setIsInitializing(false);
        return;
      }

      try {
        // Validate token by fetching user profile
        const user = await authService.getProfile();
        dispatch(setCredentials({ user, token }));
      } catch {
        // Token is invalid/expired
        dispatch(logout());
      } finally {
        setIsInitializing(false);
      }
    }

    initAuth();
  }, []); // Only on mount

  if (isInitializing) {
    return <PageSkeleton />;
  }

  return <>{children}</>;
}

// Wrap in App
function App() {
  return (
    <Provider store={store}>
      <QueryClientProvider client={queryClient}>
        <AuthInitializer>
          <RouterProvider router={router} />
        </AuthInitializer>
      </QueryClientProvider>
    </Provider>
  );
}
```

## Token Storage Security

```tsx
// ❌ BAD: accessToken in localStorage — readable by any JS (XSS steals it)
localStorage.setItem('accessToken', token);

// ❌ BAD: refreshToken in localStorage — XSS can steal long-lived token
localStorage.setItem('refreshToken', refreshToken);

// ✅ CORRECT: accessToken in Redux memory (short-lived ~15min, cleared on tab close)
dispatch(setCredentials({ user, token }));

// ✅ CORRECT: refreshToken as httpOnly cookie (server-set, JS cannot read it)
// Server sets: Set-Cookie: refreshToken=xxx; HttpOnly; Secure; SameSite=Strict
// Frontend just calls with withCredentials: true — cookie is sent/received automatically
await apiClient.post('/auth/refresh', {}, { withCredentials: true });

// ⚠️ FALLBACK (cross-domain APIs only): refreshToken in localStorage
// Use when your API is on a different domain and you can't set cookies cross-origin.
// Mitigate XSS risk with a strict Content Security Policy (CSP).
localStorage.setItem('refreshToken', refreshToken); // only if httpOnly cookie not possible
```

### Why NOT localStorage for refreshToken?

- XSS attack → malicious script reads `localStorage.getItem('refreshToken')` → attacker gets persistent access
- refreshToken is long-lived (days/weeks) — much higher impact than short-lived accessToken
- httpOnly cookie → JS cannot access it at all, even with full XSS

### Why NOT httpOnly cookie for accessToken?

- accessToken needs to be read by the Axios interceptor to set `Authorization: Bearer` header
- httpOnly cookies are invisible to JavaScript by design
- Solution: accessToken stays in Redux memory, refreshToken in httpOnly cookie

## Social OAuth

```tsx
// src/features/auth/components/SocialLogin.tsx
import { Button } from '@/components/ui/button';
import { env } from '@/lib/env';

export function SocialLogin() {
  const handleOAuthLogin = (provider: 'google' | 'github') => {
    // Redirect to backend OAuth endpoint
    window.location.href = `${env.VITE_API_URL}/auth/${provider}`;
  };

  return (
    <div className="space-y-2">
      <Button variant="outline" className="w-full" onClick={() => handleOAuthLogin('google')}>
        <GoogleIcon className="mr-2 h-4 w-4" />
        Continue with Google
      </Button>
      <Button variant="outline" className="w-full" onClick={() => handleOAuthLogin('github')}>
        <GithubIcon className="mr-2 h-4 w-4" />
        Continue with GitHub
      </Button>
    </div>
  );
}

// OAuth callback page — handles the redirect back from provider
// src/features/auth/pages/OAuthCallback.tsx
export default function OAuthCallback() {
  const [searchParams] = useSearchParams();
  const dispatch = useAppDispatch();
  const navigate = useNavigate();

  useEffect(() => {
    const token = searchParams.get('token');
    if (token) {
      authService.getProfile().then((user) => {
        dispatch(setCredentials({ user, token }));
        navigate('/dashboard', { replace: true });
      });
    } else {
      navigate('/login?error=oauth_failed', { replace: true });
    }
  }, []);

  return <PageSkeleton />;
}
```

## Summary: Decision Tree

1. **Implementing login?** → Zod schema + React Hook Form + useAuth hook
2. **Storing tokens?** → accessToken in Redux memory, refreshToken in httpOnly cookie (server-set)
3. **Attaching auth header?** → Axios request interceptor reads from Redux
4. **Token expired?** → Auto-refresh in response interceptor with queue
5. **Checking auth state?** → `useAuth()` hook everywhere
6. **Guarding routes?** → `<ProtectedRoute />` wraps dashboard routes
7. **Redirect after login?** → Save `location.state.from`, navigate back
8. **App load with token?** → `AuthInitializer` validates token on mount
9. **Social login?** → Redirect to backend OAuth, handle callback page
10. **Logging out?** → Clear Redux + localStorage + queryClient + navigate
