---
name: responsive-design
description: Provides responsive design patterns for React + TypeScript SaaS applications. Covers mobile-first approach, breakpoint strategy, adaptive layouts, responsive navigation, touch targets, and container queries. Must use when building responsive layouts or adapting UI for different screen sizes.
---

# Responsive Design Best Practices

## Core Principle: Mobile-First, Content-Out

Start with the smallest screen, then add complexity for larger screens. **Design for content, not devices.** Use Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`) to progressively enhance.

## Breakpoint Strategy

### Tailwind Defaults

```
sm:  640px   — Small tablets / large phones landscape
md:  768px   — Tablets
lg:  1024px  — Small laptops
xl:  1280px  — Desktops
2xl: 1536px  — Large desktops
```

### SaaS App Breakpoint Usage

```tsx
// Mobile (default): Single column, stacked, full-width
// sm (640px+): Minor tweaks, 2-column grids
// md (768px+): Sidebar appears, tables replace cards
// lg (1024px+): Full dashboard layout, expanded sidebar
// xl (1280px+): More columns, larger spacing
```

## Layout Patterns

### SaaS Dashboard — Responsive Shell

```tsx
export function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex h-screen overflow-hidden">
      {/* Mobile overlay sidebar */}
      <div className="md:hidden">
        {sidebarOpen && (
          <>
            <div
              className="fixed inset-0 z-40 bg-black/50"
              onClick={() => setSidebarOpen(false)}
            />
            <aside className="fixed inset-y-0 left-0 z-50 w-64 bg-card">
              <SidebarContent onClose={() => setSidebarOpen(false)} />
            </aside>
          </>
        )}
      </div>

      {/* Desktop fixed sidebar */}
      <aside className="hidden w-64 border-r border-border bg-card md:flex md:flex-col">
        <SidebarContent />
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex h-14 items-center border-b border-border px-4 md:px-6">
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="h-5 w-5" />
          </Button>
          <HeaderContent />
        </header>
        <main className="flex-1 overflow-y-auto p-4 md:p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
```

### Responsive Grid

```tsx
// Cards grid: 1 → 2 → 3 → 4 columns
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
  {items.map((item) => <Card key={item.id} item={item} />)}
</div>

// Dashboard stats: 1 → 2 → 4 columns
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
  <StatCard title="Revenue" value="$12,345" />
  <StatCard title="Users" value="1,234" />
  <StatCard title="Orders" value="567" />
  <StatCard title="Growth" value="+12%" />
</div>

// Form layout: Full width → 2 columns
<div className="grid grid-cols-1 gap-4 md:grid-cols-2">
  <FormField name="firstName" />
  <FormField name="lastName" />
  <FormField name="email" className="md:col-span-2" /> {/* Full width */}
</div>
```

### Responsive Navigation

```tsx
// Bottom navigation on mobile, sidebar on desktop
function AppNavigation() {
  return (
    <>
      {/* Desktop: Sidebar */}
      <nav className="hidden md:flex md:w-64 md:flex-col md:border-r">
        <SidebarNav />
      </nav>

      {/* Mobile: Bottom tab bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 flex border-t bg-card md:hidden">
        {navItems.slice(0, 5).map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              cn(
                'flex flex-1 flex-col items-center gap-1 py-2 text-xs',
                isActive ? 'text-primary' : 'text-muted-foreground'
              )
            }
          >
            <item.icon className="h-5 w-5" />
            {item.label}
          </NavLink>
        ))}
      </nav>

      {/* Add bottom padding on mobile to account for tab bar */}
      <div className="pb-16 md:pb-0">{/* content */}</div>
    </>
  );
}
```

### Responsive Tables

```tsx
// BAD: Horizontal scroll on mobile (poor UX)
<Table>{/* full table on all screens */}</Table>

// GOOD: Cards on mobile, table on desktop
function UserList({ users }: { users: User[] }) {
  return (
    <>
      {/* Mobile: Card layout */}
      <div className="space-y-3 md:hidden">
        {users.map((user) => (
          <div key={user.id} className="rounded-lg border p-4">
            <div className="flex items-center gap-3">
              <Avatar src={user.avatarUrl} />
              <div>
                <p className="font-medium">{user.name}</p>
                <p className="text-sm text-muted-foreground">{user.email}</p>
              </div>
            </div>
            <div className="mt-3 flex items-center justify-between">
              <Badge>{user.role}</Badge>
              <ActionMenu user={user} />
            </div>
          </div>
        ))}
      </div>

      {/* Desktop: Table layout */}
      <div className="hidden md:block">
        <DataTable columns={userColumns} data={users} />
      </div>
    </>
  );
}
```

## Responsive Typography

```tsx
// Scale text with breakpoints
<h1 className="text-2xl font-bold sm:text-3xl lg:text-4xl">
  Dashboard
</h1>

<p className="text-sm sm:text-base">
  Regular paragraph that scales up slightly
</p>

// Truncation — different line clamps per breakpoint
<p className="line-clamp-2 sm:line-clamp-3 lg:line-clamp-none">
  Long description text...
</p>
```

## Touch Targets

```tsx
// WCAG: Minimum touch target size is 44x44px
// BAD: Tiny touch targets on mobile
<button className="p-1 text-xs">X</button>

// GOOD: At least 44px touch target
<button className="min-h-[44px] min-w-[44px] p-2">
  <X className="h-4 w-4" />
</button>

// GOOD: Larger spacing between interactive elements on mobile
<div className="flex flex-col gap-3 sm:flex-row sm:gap-2">
  <Button>Save</Button>
  <Button variant="outline">Cancel</Button>
</div>
```

## Show/Hide Pattern

```tsx
// Show different content per screen size
<MobileHeader className="md:hidden" />
<DesktopHeader className="hidden md:flex" />

// Show more details on larger screens
<div>
  <p className="font-medium">{user.name}</p>
  <p className="hidden text-sm text-muted-foreground sm:block">{user.email}</p>
  <p className="hidden text-sm text-muted-foreground lg:block">{user.department}</p>
</div>
```

## useMediaQuery Hook

```tsx
// src/hooks/useMediaQuery.ts
import { useState, useEffect } from 'react';

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(
    () => window.matchMedia(query).matches
  );

  useEffect(() => {
    const media = window.matchMedia(query);
    const handler = (e: MediaQueryListEvent) => setMatches(e.matches);
    media.addEventListener('change', handler);
    return () => media.removeEventListener('change', handler);
  }, [query]);

  return matches;
}

// Usage
function MyComponent() {
  const isMobile = useMediaQuery('(max-width: 767px)');
  const isDesktop = useMediaQuery('(min-width: 1024px)');

  // Render different components based on screen size
  // (Use CSS show/hide for most cases — only use this for logic differences)
  return isMobile ? <MobileView /> : <DesktopView />;
}
```

## Summary: Decision Tree

1. **Starting a layout?** → Mobile-first: write base styles, add `sm:`, `md:`, `lg:`
2. **Sidebar navigation?** → Hidden + overlay on mobile, fixed on `md:+`
3. **Grid items?** → `grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4`
4. **Data tables?** → Cards on mobile, table on `md:+`
5. **Navigation on mobile?** → Bottom tab bar or hamburger menu
6. **Touch targets?** → Minimum 44x44px on mobile
7. **Show/hide content?** → `hidden md:block` or `md:hidden`
8. **Need JS breakpoint?** → `useMediaQuery` hook (prefer CSS when possible)
9. **Typography?** → Scale with `text-2xl sm:text-3xl lg:text-4xl`
10. **Testing?** → Playwright mobile device projects + manual resize check
