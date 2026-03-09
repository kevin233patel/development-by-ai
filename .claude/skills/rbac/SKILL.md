---
name: rbac
description: Provides role-based access control (RBAC) patterns for React + TypeScript SaaS applications. Covers permission definitions, role hierarchies, UI-level guards, component-level checks, route protection, and API-aware permissions. Must use when implementing roles, permissions, or conditional access in the UI.
---

# RBAC Best Practices

## Core Principle: Permission-Based, Not Role-Based Checks

Check **permissions**, not roles, in your UI code. Roles map to permission sets, but components should only care about "can this user do X?" This makes the system flexible — changing what a role can do doesn't require changing component code.

## Permission Architecture

### Define Permissions

```tsx
// src/lib/permissions.ts

// All possible permissions in the system
export const PERMISSIONS = {
  // Projects
  'project:create': 'project:create',
  'project:read': 'project:read',
  'project:update': 'project:update',
  'project:delete': 'project:delete',

  // Team
  'team:invite': 'team:invite',
  'team:remove': 'team:remove',
  'team:manage-roles': 'team:manage-roles',

  // Billing
  'billing:view': 'billing:view',
  'billing:manage': 'billing:manage',

  // Settings
  'settings:view': 'settings:view',
  'settings:manage': 'settings:manage',

  // Admin
  'admin:access': 'admin:access',
} as const;

export type Permission = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];
```

### Define Roles with Permission Sets

```tsx
// src/lib/permissions.ts (continued)

export const ROLES = {
  owner: 'owner',
  admin: 'admin',
  member: 'member',
  viewer: 'viewer',
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];

// Role → Permissions mapping
const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  owner: Object.values(PERMISSIONS), // Everything

  admin: [
    'project:create', 'project:read', 'project:update', 'project:delete',
    'team:invite', 'team:remove', 'team:manage-roles',
    'billing:view', 'billing:manage',
    'settings:view', 'settings:manage',
  ],

  member: [
    'project:create', 'project:read', 'project:update',
    'team:invite',
    'settings:view',
  ],

  viewer: [
    'project:read',
    'settings:view',
  ],
};

export function getRolePermissions(role: Role): Permission[] {
  return ROLE_PERMISSIONS[role] ?? [];
}

export function hasPermission(role: Role, permission: Permission): boolean {
  return getRolePermissions(role).includes(permission);
}

export function hasAnyPermission(role: Role, permissions: Permission[]): boolean {
  const rolePerms = getRolePermissions(role);
  return permissions.some((p) => rolePerms.includes(p));
}

export function hasAllPermissions(role: Role, permissions: Permission[]): boolean {
  const rolePerms = getRolePermissions(role);
  return permissions.every((p) => rolePerms.includes(p));
}
```

## Permission Hook

```tsx
// src/hooks/usePermission.ts
import { useAppSelector } from '@/stores/hooks';
import { selectCurrentUser } from '@/stores/authSlice';
import { hasPermission, hasAnyPermission, hasAllPermissions, type Permission } from '@/lib/permissions';

export function usePermission() {
  const user = useAppSelector(selectCurrentUser);

  return {
    /** Check if user has a single permission */
    can: (permission: Permission): boolean => {
      if (!user) return false;
      return hasPermission(user.role, permission);
    },

    /** Check if user has ANY of the given permissions */
    canAny: (permissions: Permission[]): boolean => {
      if (!user) return false;
      return hasAnyPermission(user.role, permissions);
    },

    /** Check if user has ALL of the given permissions */
    canAll: (permissions: Permission[]): boolean => {
      if (!user) return false;
      return hasAllPermissions(user.role, permissions);
    },

    /** Current user's role */
    role: user?.role ?? null,
  };
}
```

## Component-Level Guards

### Permission Gate Component

```tsx
// src/components/common/PermissionGate.tsx
import type { Permission } from '@/lib/permissions';
import { usePermission } from '@/hooks/usePermission';

interface PermissionGateProps {
  /** Required permission(s) */
  permission?: Permission;
  permissions?: Permission[];
  /** Require ALL or ANY of the permissions (default: 'any') */
  match?: 'any' | 'all';
  /** What to show if unauthorized */
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export function PermissionGate({
  permission,
  permissions,
  match = 'any',
  fallback = null,
  children,
}: PermissionGateProps) {
  const { can, canAny, canAll } = usePermission();

  let hasAccess = false;

  if (permission) {
    hasAccess = can(permission);
  } else if (permissions) {
    hasAccess = match === 'all' ? canAll(permissions) : canAny(permissions);
  }

  return hasAccess ? <>{children}</> : <>{fallback}</>;
}
```

### Usage in Components

```tsx
// BAD: Checking roles directly in components
function ProjectActions({ project }: Props) {
  const { user } = useAuth();

  return (
    <div>
      {(user?.role === 'admin' || user?.role === 'owner') && (
        <Button onClick={handleDelete}>Delete</Button>
      )}
    </div>
  );
}
// If you add a new role that can delete, you must update every component!

// GOOD: Check permissions, not roles
function ProjectActions({ project }: Props) {
  const { can } = usePermission();

  return (
    <div>
      {can('project:update') && (
        <Button onClick={handleEdit}>Edit</Button>
      )}
      {can('project:delete') && (
        <Button variant="destructive" onClick={handleDelete}>Delete</Button>
      )}
    </div>
  );
}

// GOOD: Using PermissionGate for cleaner JSX
function ProjectActions({ project }: Props) {
  return (
    <div className="flex gap-2">
      <PermissionGate permission="project:update">
        <Button onClick={handleEdit}>Edit</Button>
      </PermissionGate>

      <PermissionGate permission="project:delete">
        <Button variant="destructive" onClick={handleDelete}>Delete</Button>
      </PermissionGate>
    </div>
  );
}
```

### Conditional Navigation

```tsx
// Sidebar that only shows items user can access
function Sidebar() {
  const { can } = usePermission();

  const navItems = [
    { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard, show: true },
    { label: 'Projects', path: '/projects', icon: FolderOpen, show: can('project:read') },
    { label: 'Team', path: '/team', icon: Users, show: can('team:invite') },
    { label: 'Billing', path: '/billing', icon: CreditCard, show: can('billing:view') },
    { label: 'Settings', path: '/settings', icon: Settings, show: can('settings:view') },
    { label: 'Admin', path: '/admin', icon: Shield, show: can('admin:access') },
  ].filter((item) => item.show);

  return (
    <nav>
      {navItems.map((item) => (
        <NavLink key={item.path} to={item.path}>
          <item.icon className="h-4 w-4" />
          {item.label}
        </NavLink>
      ))}
    </nav>
  );
}
```

## Route-Level Guards

```tsx
// src/components/common/PermissionRoute.tsx
import { Navigate, Outlet } from 'react-router-dom';
import { usePermission } from '@/hooks/usePermission';
import type { Permission } from '@/lib/permissions';

interface PermissionRouteProps {
  permission?: Permission;
  permissions?: Permission[];
  match?: 'any' | 'all';
  redirectTo?: string;
}

export function PermissionRoute({
  permission,
  permissions,
  match = 'any',
  redirectTo = '/dashboard',
}: PermissionRouteProps) {
  const { can, canAny, canAll } = usePermission();

  let hasAccess = false;
  if (permission) hasAccess = can(permission);
  else if (permissions) hasAccess = match === 'all' ? canAll(permissions) : canAny(permissions);

  if (!hasAccess) {
    return <Navigate to={redirectTo} replace />;
  }

  return <Outlet />;
}

// Usage in routes
export const router = createBrowserRouter([
  {
    element: <ProtectedRoute />, // Auth guard
    children: [
      {
        element: <DashboardLayout />,
        children: [
          // Anyone authenticated can access
          { path: '/dashboard', element: <Dashboard /> },

          // Need billing:view permission
          {
            element: <PermissionRoute permission="billing:view" />,
            children: [
              { path: '/billing', element: <Billing /> },
            ],
          },

          // Need admin:access permission
          {
            element: <PermissionRoute permission="admin:access" />,
            children: [
              { path: '/admin', element: <AdminPanel /> },
              { path: '/admin/users', element: <UserManagement /> },
            ],
          },
        ],
      },
    ],
  },
]);
```

## Forbidden Page

```tsx
// src/pages/Forbidden.tsx
import { ShieldX } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Link } from 'react-router-dom';

export function Forbidden() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center text-center">
      <ShieldX className="h-16 w-16 text-muted-foreground" />
      <h1 className="mt-4 text-2xl font-bold">Access Denied</h1>
      <p className="mt-2 text-muted-foreground">
        You don't have permission to access this page.
      </p>
      <Button asChild className="mt-6">
        <Link to="/dashboard">Go to Dashboard</Link>
      </Button>
    </div>
  );
}
```

## Multi-Tenancy Aware RBAC

```tsx
// When roles are per-organization, not global
interface OrgMembership {
  orgId: string;
  role: Role;
}

// User might be admin in one org, viewer in another
function useOrgPermission(orgId: string) {
  const user = useAppSelector(selectCurrentUser);
  const membership = user?.memberships?.find((m) => m.orgId === orgId);

  return {
    can: (permission: Permission): boolean => {
      if (!membership) return false;
      return hasPermission(membership.role, permission);
    },
    role: membership?.role ?? null,
  };
}
```

## Anti-Patterns to Avoid

```tsx
// BAD: Checking roles directly
if (user.role === 'admin') { /* show button */ }
// What if you add a 'super-admin' role?

// GOOD: Check permissions
if (can('project:delete')) { /* show button */ }

// BAD: Hiding UI but not protecting the route
<PermissionGate permission="admin:access">
  <Link to="/admin">Admin</Link>
</PermissionGate>
// User can still navigate to /admin manually!

// GOOD: Protect BOTH the UI and the route
// UI: PermissionGate hides the link
// Route: PermissionRoute blocks direct access

// BAD: Relying only on frontend RBAC
// Frontend RBAC is for UX only — server MUST validate permissions too!

// BAD: Hardcoding permission checks in 50 components
if (user.role === 'admin' || user.role === 'owner') { ... }
// Change role names = update 50 files

// GOOD: Centralized permission map, check via usePermission
```

## Summary: Decision Tree

1. **Defining permissions?** → `as const` object in `src/lib/permissions.ts`
2. **Mapping roles to permissions?** → `ROLE_PERMISSIONS` record in same file
3. **Checking in components?** → `usePermission()` hook → `can('permission')`
4. **Wrapping JSX conditionally?** → `<PermissionGate permission="..." />`
5. **Protecting routes?** → `<PermissionRoute permission="..." />` in router
6. **Filtering nav items?** → `.filter()` with `can()` checks
7. **Multi-org roles?** → Per-org membership with `useOrgPermission(orgId)`
8. **Denied access page?** → Dedicated `<Forbidden />` page
9. **Adding new role?** → Update `ROLE_PERMISSIONS` map only — components unchanged
10. **Security?** → Frontend RBAC is UX only — always validate on server
