---
name: react-router
description: Provides React Router v7 patterns for SaaS applications. Covers route configuration, nested layouts, protected routes, lazy loading, navigation, breadcrumbs, and route-based code splitting. Must use when creating routes, layouts, navigation, or route guards.
---

# React Router Best Practices

## Core Principle: Routes Are the App Skeleton

Define all routes in a single, centralized configuration. **Routes should be declarative, lazy-loaded, and protected by auth guards.** Every SaaS app has two route trees: public (auth) and private (dashboard).

## Installation

```bash
npm install react-router-dom
```

## Route Configuration

### Centralized Route Definition

```tsx
// BAD: Routes scattered across components
function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      {/* 50 more routes inline... */}
    </Routes>
  );
}

// GOOD: Centralized route config with lazy loading
// src/app/routes.tsx
import { lazy } from 'react';
import { createBrowserRouter, Navigate } from 'react-router-dom';
import { AuthLayout } from '@/components/layouts/AuthLayout';
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
import { ProtectedRoute } from '@/components/common/ProtectedRoute';

// Lazy load all pages
const Login = lazy(() => import('@/features/auth/pages/Login'));
const Register = lazy(() => import('@/features/auth/pages/Register'));
const ForgotPassword = lazy(() => import('@/features/auth/pages/ForgotPassword'));
const Dashboard = lazy(() => import('@/features/dashboard/pages/Dashboard'));
const Projects = lazy(() => import('@/features/projects/pages/Projects'));
const ProjectDetail = lazy(() => import('@/features/projects/pages/ProjectDetail'));
const Settings = lazy(() => import('@/features/settings/pages/Settings'));
const ProfileSettings = lazy(() => import('@/features/settings/pages/ProfileSettings'));
const TeamSettings = lazy(() => import('@/features/settings/pages/TeamSettings'));
const BillingSettings = lazy(() => import('@/features/settings/pages/BillingSettings'));
const NotFound = lazy(() => import('@/pages/NotFound'));

export const router = createBrowserRouter([
  // Public routes (auth)
  {
    element: <AuthLayout />,
    children: [
      { path: '/login', element: <Login /> },
      { path: '/register', element: <Register /> },
      { path: '/forgot-password', element: <ForgotPassword /> },
    ],
  },

  // Protected routes (dashboard)
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <DashboardLayout />,
        children: [
          { path: '/', element: <Navigate to="/dashboard" replace /> },
          { path: '/dashboard', element: <Dashboard /> },
          { path: '/projects', element: <Projects /> },
          { path: '/projects/:projectId', element: <ProjectDetail /> },
          {
            path: '/settings',
            element: <Settings />,
            children: [
              { index: true, element: <Navigate to="profile" replace /> },
              { path: 'profile', element: <ProfileSettings /> },
              { path: 'team', element: <TeamSettings /> },
              { path: 'billing', element: <BillingSettings /> },
            ],
          },
        ],
      },
    ],
  },

  // Catch-all
  { path: '*', element: <NotFound /> },
]);
```

### App Entry with Router

```tsx
// src/main.tsx
import { StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';
import { RouterProvider } from 'react-router-dom';
import { router } from '@/app/routes';
import { PageSkeleton } from '@/components/common/PageSkeleton';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Suspense fallback={<PageSkeleton />}>
      <RouterProvider router={router} />
    </Suspense>
  </StrictMode>
);
```

## Layouts with Outlet

### Auth Layout

```tsx
// src/components/layouts/AuthLayout.tsx
import { Outlet, Navigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';

export function AuthLayout() {
  const { isAuthenticated } = useAuth();

  // Redirect to dashboard if already logged in
  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted">
      <div className="w-full max-w-md p-6">
        <Outlet />
      </div>
    </div>
  );
}
```

### Dashboard Layout

```tsx
// src/components/layouts/DashboardLayout.tsx
import { Outlet } from 'react-router-dom';
import { Sidebar } from '@/components/layouts/Sidebar';
import { Header } from '@/components/layouts/Header';
import { Suspense } from 'react';
import { PageSkeleton } from '@/components/common/PageSkeleton';

export function DashboardLayout() {
  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          <Suspense fallback={<PageSkeleton />}>
            <Outlet />
          </Suspense>
        </main>
      </div>
    </div>
  );
}
```

### Settings Layout with Nested Tabs

```tsx
// src/features/settings/pages/Settings.tsx
import { Outlet, NavLink } from 'react-router-dom';
import { cn } from '@/lib/utils';

const settingsNav = [
  { label: 'Profile', path: 'profile' },
  { label: 'Team', path: 'team' },
  { label: 'Billing', path: 'billing' },
];

export default function Settings() {
  return (
    <div>
      <h1 className="text-2xl font-bold tracking-tight">Settings</h1>
      <nav className="mt-4 flex gap-2 border-b">
        {settingsNav.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              cn(
                'border-b-2 px-4 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground'
              )
            }
          >
            {item.label}
          </NavLink>
        ))}
      </nav>
      <div className="mt-6">
        <Outlet />
      </div>
    </div>
  );
}
```

## Protected Routes

### Auth Guard Component

```tsx
// src/components/common/ProtectedRoute.tsx
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { PageSkeleton } from '@/components/common/PageSkeleton';

export function ProtectedRoute() {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  // Show loading while checking auth state
  if (isLoading) {
    return <PageSkeleton />;
  }

  // Redirect to login with return URL
  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }

  return <Outlet />;
}
```

### Role-Based Route Guard

```tsx
// src/components/common/RoleGuard.tsx
import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import type { UserRole } from '@/types';

interface RoleGuardProps {
  allowedRoles: UserRole[];
  fallback?: string;
}

export function RoleGuard({ allowedRoles, fallback = '/dashboard' }: RoleGuardProps) {
  const { user } = useAuth();

  if (!user || !allowedRoles.includes(user.role)) {
    return <Navigate to={fallback} replace />;
  }

  return <Outlet />;
}

// Usage in routes
{
  element: <RoleGuard allowedRoles={['admin', 'owner']} />,
  children: [
    { path: '/admin', element: <AdminPanel /> },
    { path: '/admin/users', element: <UserManagement /> },
  ],
}
```

## Navigation Patterns

### Sidebar Navigation with Active State

```tsx
// src/components/layouts/Sidebar.tsx
import { NavLink, useLocation } from 'react-router-dom';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  FolderOpen,
  Settings,
  Users,
  type LucideIcon,
} from 'lucide-react';

interface NavItem {
  label: string;
  path: string;
  icon: LucideIcon;
}

const navItems: NavItem[] = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { label: 'Projects', path: '/projects', icon: FolderOpen },
  { label: 'Team', path: '/team', icon: Users },
  { label: 'Settings', path: '/settings', icon: Settings },
];

export function Sidebar() {
  return (
    <aside className="hidden w-64 border-r border-border bg-card md:flex md:flex-col">
      <div className="flex h-16 items-center border-b border-border px-6">
        <span className="text-lg font-bold">MyApp</span>
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-primary/10 text-primary'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground'
              )
            }
          >
            <item.icon className="h-4 w-4" />
            {item.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
```

### Programmatic Navigation

```tsx
// BAD: Using window.location
window.location.href = '/dashboard'; // Full page reload

// BAD: Using navigate in render
function MyComponent() {
  const navigate = useNavigate();
  if (condition) navigate('/other'); // Side effect during render!
  return <div />;
}

// GOOD: Navigate in event handlers
import { useNavigate } from 'react-router-dom';

function LoginForm() {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogin = async (data: LoginFormValues) => {
    await login(data);
    // Redirect to where they came from, or dashboard
    const returnTo = (location.state as { from?: string })?.from ?? '/dashboard';
    navigate(returnTo, { replace: true });
  };

  return <form onSubmit={handleSubmit(handleLogin)}>...</form>;
}

// GOOD: Navigate component for redirects in JSX
import { Navigate } from 'react-router-dom';

function OldPage() {
  return <Navigate to="/new-page" replace />;
}
```

## Route Parameters & Search Params

### Type-Safe Route Parameters

```tsx
// BAD: Untyped params
function ProjectDetail() {
  const { projectId } = useParams(); // string | undefined
  // projectId could be undefined!
}

// GOOD: Validated params
import { useParams, Navigate } from 'react-router-dom';

function ProjectDetail() {
  const { projectId } = useParams<{ projectId: string }>();

  if (!projectId) {
    return <Navigate to="/projects" replace />;
  }

  // Now projectId is guaranteed to be a string
  const { data: project } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => fetchProject(projectId),
  });

  return <div>{project?.name}</div>;
}
```

### Search Params for Filters

```tsx
// src/hooks/useSearchParamsState.ts
import { useSearchParams } from 'react-router-dom';
import { useCallback } from 'react';

export function useSearchParamsState<T extends string>(
  key: string,
  defaultValue: T
): [T, (value: T) => void] {
  const [searchParams, setSearchParams] = useSearchParams();
  const value = (searchParams.get(key) as T) ?? defaultValue;

  const setValue = useCallback(
    (newValue: T) => {
      setSearchParams((prev) => {
        if (newValue === defaultValue) {
          prev.delete(key);
        } else {
          prev.set(key, newValue);
        }
        return prev;
      });
    },
    [key, defaultValue, setSearchParams]
  );

  return [value, setValue];
}

// Usage — URL stays in sync: /projects?status=active&sort=name
function ProjectsPage() {
  const [status, setStatus] = useSearchParamsState('status', 'all');
  const [sort, setSort] = useSearchParamsState('sort', 'created');

  return (
    <>
      <Select value={status} onValueChange={setStatus}>
        <SelectItem value="all">All</SelectItem>
        <SelectItem value="active">Active</SelectItem>
        <SelectItem value="archived">Archived</SelectItem>
      </Select>
    </>
  );
}
```

## Breadcrumbs

```tsx
// src/components/common/Breadcrumbs.tsx
import { Link, useMatches } from 'react-router-dom';
import { ChevronRight } from 'lucide-react';

interface RouteHandle {
  breadcrumb: string | ((params: Record<string, string>) => string);
}

export function Breadcrumbs() {
  const matches = useMatches();

  const crumbs = matches
    .filter((match) => (match.handle as RouteHandle)?.breadcrumb)
    .map((match) => {
      const handle = match.handle as RouteHandle;
      const label =
        typeof handle.breadcrumb === 'function'
          ? handle.breadcrumb(match.params as Record<string, string>)
          : handle.breadcrumb;

      return { label, path: match.pathname };
    });

  if (crumbs.length <= 1) return null;

  return (
    <nav className="flex items-center gap-1 text-sm text-muted-foreground">
      {crumbs.map((crumb, index) => (
        <span key={crumb.path} className="flex items-center gap-1">
          {index > 0 && <ChevronRight className="h-3 w-3" />}
          {index === crumbs.length - 1 ? (
            <span className="font-medium text-foreground">{crumb.label}</span>
          ) : (
            <Link to={crumb.path} className="hover:text-foreground">
              {crumb.label}
            </Link>
          )}
        </span>
      ))}
    </nav>
  );
}

// Add handle to routes
{
  path: '/projects',
  element: <Projects />,
  handle: { breadcrumb: 'Projects' },
},
{
  path: '/projects/:projectId',
  element: <ProjectDetail />,
  handle: { breadcrumb: (params: Record<string, string>) => `Project ${params.projectId}` },
},
```

## Error Handling

### Route Error Boundary

```tsx
// src/pages/RouteError.tsx
import { useRouteError, isRouteErrorResponse, Link } from 'react-router-dom';
import { Button } from '@/components/ui/button';

export function RouteError() {
  const error = useRouteError();

  if (isRouteErrorResponse(error)) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center">
        <h1 className="text-4xl font-bold">{error.status}</h1>
        <p className="mt-2 text-muted-foreground">{error.statusText}</p>
        <Button asChild className="mt-4">
          <Link to="/">Go Home</Link>
        </Button>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center">
      <h1 className="text-4xl font-bold">Something went wrong</h1>
      <p className="mt-2 text-muted-foreground">An unexpected error occurred.</p>
      <Button onClick={() => window.location.reload()} className="mt-4">
        Reload Page
      </Button>
    </div>
  );
}

// Add to router
export const router = createBrowserRouter([
  {
    errorElement: <RouteError />,
    children: [
      // ... all routes
    ],
  },
]);
```

## Summary: Decision Tree

1. **Defining routes?** → Single `createBrowserRouter` config in `src/app/routes.tsx`
2. **Need layouts?** → Use `<Outlet />` in layout components with nested routes
3. **Page-level code splitting?** → `lazy(() => import(...))` for every page
4. **Need auth protection?** → Wrap with `<ProtectedRoute />` using `<Outlet />`
5. **Need role-based access?** → Use `<RoleGuard allowedRoles={[...]} />`
6. **Active nav styling?** → Use `<NavLink>` with `isActive` callback
7. **Programmatic navigation?** → `useNavigate()` in event handlers only
8. **URL-synced filters?** → `useSearchParams()` or custom `useSearchParamsState`
9. **Need breadcrumbs?** → Use route `handle` with `useMatches()`
10. **Route errors?** → `errorElement` on root route with `useRouteError()`
