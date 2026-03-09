---
name: tailwind-css
description: Provides Tailwind CSS patterns for React + TypeScript SaaS applications. Covers utility-first styling, responsive design, custom configuration, dark mode, design tokens, and component styling with cn() utility. Must use when writing styles, configuring Tailwind, or creating responsive layouts.
---

# Tailwind CSS Best Practices

## Core Principle: Utility-First, Not Utility-Only

Use Tailwind utilities as the primary styling approach. **Only extract components when you see a clear, repeated pattern** — not preemptively. The `cn()` utility from shadcn/ui is your best friend for conditional classes.

## Installation & Setup

### Install Tailwind CSS v4 with Vite

```bash
npm install tailwindcss @tailwindcss/vite
```

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
```

### CSS Entry Point

```css
/* src/index.css — Tailwind v4 uses CSS-first configuration */
@import 'tailwindcss';

/* Custom theme configuration via CSS */
@theme {
  /* Colors — semantic tokens mapped from brand palette (see dark-light-theming skill for full palette) */
  --color-background: #ffffff;
  --color-foreground: #030b5d;          /* blue-90 */
  --color-card: #ffffff;
  --color-card-foreground: #030b5d;
  --color-primary: #006dfa;             /* blue-55 — brand CTA */
  --color-primary-foreground: #ffffff;
  --color-secondary: #f4f9ff;           /* blue-05 */
  --color-secondary-foreground: #030b5d;
  --color-muted: #ebf4ff;               /* blue-10 */
  --color-muted-foreground: #043cb5;    /* blue-70 */
  --color-accent: #cce4ff;              /* blue-20 */
  --color-accent-foreground: #030b5d;
  --color-destructive: #db132a;         /* red-60 */
  --color-destructive-foreground: #ffffff;
  --color-success: #14b053;             /* green-60 */
  --color-success-foreground: #ffffff;
  --color-warning: #f47c22;             /* orange-60 */
  --color-warning-foreground: #ffffff;
  --color-border: #cce4ff;              /* blue-20 */
  --color-input: #cce4ff;
  --color-ring: #006dfa;                /* blue-55 */

  /* Typography */
  --font-sans: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  /* Border Radius */
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1);

  /* Spacing Scale Overrides (if needed) */
  --spacing-sidebar: 16rem;
  --spacing-header: 4rem;
}
```

## The cn() Utility — Always Use It

### Setup

```ts
// src/lib/utils.ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```bash
npm install clsx tailwind-merge
```

### Usage

```tsx
// BAD: String concatenation for conditional classes
<div className={`p-4 rounded-lg ${isActive ? 'bg-primary text-white' : 'bg-muted'} ${className}`}>

// BAD: Conflicting classes not resolved
<div className={`p-4 px-6 bg-red-500 bg-blue-500`}> // Which bg wins?

// GOOD: cn() handles merging and conflicts
import { cn } from '@/lib/utils';

<div className={cn(
  'p-4 rounded-lg',
  isActive ? 'bg-primary text-primary-foreground' : 'bg-muted',
  className // Allow parent overrides
)}>
```

### Component Pattern with cn()

```tsx
// GOOD: Every component accepts className and uses cn()
interface CardProps extends React.ComponentPropsWithoutRef<'div'> {
  variant?: 'default' | 'outlined';
}

export function Card({ variant = 'default', className, children, ...props }: CardProps) {
  return (
    <div
      className={cn(
        'rounded-lg p-6',
        variant === 'default' && 'bg-card shadow-md',
        variant === 'outlined' && 'border border-border',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

// Usage — parent can override styles
<Card className="p-8 shadow-lg" variant="outlined" />
```

## Responsive Design — Mobile-First

### Breakpoint Strategy

```tsx
// BAD: Desktop-first (hiding things on mobile)
<div className="flex hidden md:flex"> // Confusing logic

// GOOD: Mobile-first (adding complexity at larger breakpoints)
<div className="flex flex-col md:flex-row">
  <aside className="w-full md:w-64 lg:w-80">Sidebar</aside>
  <main className="flex-1">Content</main>
</div>
```

### Common Responsive Patterns

```tsx
// Navigation: Stack on mobile, horizontal on desktop
<nav className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-4">
  <a href="/">Home</a>
  <a href="/about">About</a>
</nav>

// Grid: 1 col → 2 col → 3 col → 4 col
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
  {items.map((item) => <Card key={item.id} />)}
</div>

// Typography: Scale up on larger screens
<h1 className="text-2xl font-bold sm:text-3xl lg:text-4xl">
  Dashboard
</h1>

// Spacing: Tighter on mobile, more room on desktop
<section className="px-4 py-6 sm:px-6 lg:px-8 lg:py-10">
  {content}
</section>

// Show/hide elements
<MobileNav className="sm:hidden" />
<DesktopNav className="hidden sm:flex" />
```

## Dark Mode

### CSS Variables Approach (Recommended for SaaS)

```css
/* src/index.css */
@import 'tailwindcss';

@theme {
  --color-background: #ffffff;
  --color-foreground: #030b5d;          /* blue-90 */
  --color-card: #ffffff;
  --color-card-foreground: #030b5d;
  --color-primary: #006dfa;             /* blue-55 */
  --color-primary-foreground: #ffffff;
  --color-muted: #ebf4ff;               /* blue-10 */
  --color-muted-foreground: #043cb5;    /* blue-70 */
  --color-border: #cce4ff;              /* blue-20 */
}

/* Dark mode overrides via class strategy */
.dark {
  --color-background: #030b5d;          /* blue-90 */
  --color-foreground: #f4f9ff;          /* blue-05 */
  --color-card: #001489;                /* blue-80 */
  --color-card-foreground: #f4f9ff;
  --color-primary: #66b3ff;             /* blue-40 */
  --color-primary-foreground: #030b5d;
  --color-muted: #043cb5;               /* blue-70 */
  --color-muted-foreground: #99cdff;    /* blue-30 */
  --color-border: #043cb5;              /* blue-70 */
}
```

```tsx
// Usage — semantic color names work in both modes
<div className="bg-background text-foreground">
  <div className="bg-card text-card-foreground rounded-lg border border-border p-6">
    <p className="text-muted-foreground">Subtitle text</p>
  </div>
</div>
// No need for dark: prefix — CSS variables handle it automatically!
```

```tsx
// BAD: Manually adding dark: everywhere
<div className="bg-white text-black dark:bg-gray-900 dark:text-white">
  <p className="text-gray-500 dark:text-gray-400">Text</p>
</div>

// GOOD: Semantic tokens — one class, both modes
<div className="bg-background text-foreground">
  <p className="text-muted-foreground">Text</p>
</div>
```

## Layout Patterns

### SaaS Dashboard Layout

```tsx
// Sidebar + Main content layout
export function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen overflow-hidden">
      {/* Sidebar — fixed width */}
      <aside className="hidden w-sidebar border-r border-border bg-card md:flex md:flex-col">
        <div className="flex h-header items-center border-b border-border px-6">
          <Logo />
        </div>
        <nav className="flex-1 overflow-y-auto p-4">
          <SidebarNav />
        </nav>
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex h-header items-center border-b border-border px-6">
          <HeaderContent />
        </header>
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
```

### Page Header Pattern

```tsx
export function PageHeader({ title, description, actions }: PageHeaderProps) {
  return (
    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
        {description && (
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        )}
      </div>
      {actions && <div className="flex gap-2">{actions}</div>}
    </div>
  );
}
```

## Typography

```tsx
// BAD: Inconsistent font sizes and weights throughout app
<h1 className="text-3xl font-bold">Title</h1>      // Here
<h1 className="text-2xl font-semibold">Title</h1>   // And here...

// GOOD: Consistent typography scale
// Headings
<h1 className="text-3xl font-bold tracking-tight">Page Title</h1>
<h2 className="text-2xl font-semibold tracking-tight">Section Title</h2>
<h3 className="text-xl font-semibold">Subsection</h3>
<h4 className="text-lg font-medium">Card Title</h4>

// Body text
<p className="text-base leading-7">Regular paragraph text</p>
<p className="text-sm text-muted-foreground">Secondary/helper text</p>
<p className="text-xs text-muted-foreground">Caption/meta text</p>

// Truncation
<p className="truncate">Very long text that gets cut off...</p>
<p className="line-clamp-2">Text that wraps to max 2 lines then truncates...</p>
```

## Animation & Transitions

```tsx
// BAD: No transitions — jarring UI changes
<button className={isHovered ? 'bg-primary' : 'bg-muted'}>Click</button>

// GOOD: Smooth transitions
<button className="bg-muted transition-colors duration-200 hover:bg-primary">
  Click
</button>

// Common transition patterns
<div className="transition-all duration-200" />         // All properties
<div className="transition-colors duration-150" />       // Color changes
<div className="transition-opacity duration-200" />      // Fade in/out
<div className="transition-transform duration-200" />    // Scale/translate

// Sidebar collapse animation
<aside className={cn(
  'transition-[width] duration-300 ease-in-out',
  isCollapsed ? 'w-16' : 'w-sidebar'
)}>
```

## Anti-Patterns to Avoid

```tsx
// BAD: @apply everywhere — defeats the purpose of utility-first
.btn-primary {
  @apply rounded-lg bg-primary px-4 py-2 text-primary-foreground;
}

// GOOD: Use component abstraction instead
export function Button({ children, ...props }: ButtonProps) {
  return (
    <button className="rounded-lg bg-primary px-4 py-2 text-primary-foreground" {...props}>
      {children}
    </button>
  );
}

// BAD: Arbitrary values when design tokens exist
<div className="p-[13px] text-[#006dfa] rounded-[7px]">

// GOOD: Use the design system
<div className="p-3 text-primary rounded-lg">

// BAD: !important overrides
<div className="!p-0 !m-0">

// GOOD: Use cn() to resolve conflicts properly
<div className={cn('p-4', overrideNeeded && 'p-0')}>

// BAD: Mixing inline styles with Tailwind
<div className="flex" style={{ gap: '12px', padding: '16px' }}>

// GOOD: All Tailwind
<div className="flex gap-3 p-4">
```

## Summary: Decision Tree

1. **Styling a component?** → Use Tailwind utilities directly in JSX with `cn()`
2. **Conditional classes?** → Use `cn()` with ternary or logical AND
3. **Component accepts className?** → Always spread it last in `cn()` for overrides
4. **Responsive?** → Mobile-first: base styles → `sm:` → `md:` → `lg:` → `xl:`
5. **Dark mode?** → Use semantic CSS variable tokens (`bg-background`), not `dark:` prefix
6. **Repeated pattern?** → Extract a React component, not a CSS class with `@apply`
7. **Custom value needed?** → Check if a design token exists first, then use theme config
8. **Animation?** → Use `transition-{property} duration-{ms}` for smooth interactions
9. **Layout?** → Flexbox for 1D, Grid for 2D, use `gap-*` instead of margin hacks
