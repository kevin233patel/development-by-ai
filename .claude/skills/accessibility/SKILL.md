---
name: accessibility
description: Provides accessibility (a11y) patterns for React + TypeScript SaaS applications. Covers semantic HTML, ARIA, keyboard navigation, focus management, screen reader support, color contrast, and automated testing. Must use when building accessible components or auditing a11y compliance.
---

# Accessibility (a11y) Best Practices

## Core Principle: Accessible by Default

Accessibility is not an afterthought or a checklist item. **Build with semantic HTML first, ARIA only when needed, and test with keyboard and screen reader.** WCAG 2.1 AA is the minimum standard.

## Semantic HTML First

```tsx
// BAD: Div soup with ARIA bandaids
<div role="button" onClick={handleClick} tabIndex={0}>Click me</div>
<div role="navigation">
  <div role="link" onClick={() => navigate('/home')}>Home</div>
</div>

// GOOD: Semantic HTML — accessibility built-in
<button onClick={handleClick}>Click me</button>
<nav>
  <a href="/home">Home</a>
</nav>
```

### Semantic Elements to Use

```tsx
// Page structure
<header>       {/* Site header/nav */}
<nav>          {/* Navigation links */}
<main>         {/* Primary content */}
<aside>        {/* Sidebar/secondary */}
<footer>       {/* Footer */}
<section>      {/* Thematic grouping */}
<article>      {/* Self-contained content */}

// Headings — must be hierarchical (h1 → h2 → h3, never skip)
<h1>Page Title</h1>       {/* One per page */}
<h2>Section</h2>
<h3>Subsection</h3>

// Forms
<form>
<label>         {/* Always pair with input */}
<fieldset>      {/* Group related inputs */}
<legend>        {/* Fieldset title */}

// Interactive
<button>        {/* For actions */}
<a href="...">  {/* For navigation */}
<details>       {/* Expandable content */}
<dialog>        {/* Modal/dialog */}
```

## Labels and Forms

```tsx
// BAD: Input without label
<input type="email" placeholder="Email" />

// BAD: Label not connected to input
<label>Email</label>
<input type="email" />

// GOOD: Label with htmlFor
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// GOOD: Wrapping label (implicit association)
<label>
  Email
  <input type="email" />
</label>

// GOOD: With shadcn/ui Form components (handles this automatically)
<FormField
  control={form.control}
  name="email"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Email</FormLabel>
      <FormControl>
        <Input type="email" {...field} />
      </FormControl>
      <FormDescription>We'll never share your email.</FormDescription>
      <FormMessage />
    </FormItem>
  )}
/>
```

### Error Messages

```tsx
// BAD: Error not associated with input
<Input type="email" />
<span className="text-red-500">Invalid email</span>

// GOOD: Error linked via aria-describedby
<Input
  type="email"
  aria-invalid={!!error}
  aria-describedby={error ? 'email-error' : undefined}
/>
{error && <p id="email-error" role="alert" className="text-destructive text-sm">{error}</p>}
```

## Keyboard Navigation

### Focus Management

```tsx
// BAD: Custom component not focusable
<div onClick={handleClick}>Custom button</div>

// GOOD: All interactive elements focusable via keyboard
// Buttons, links, inputs are focusable by default
// Custom elements need tabIndex={0}

// Focus visible indicator — never remove!
// BAD:
<button className="outline-none">Click</button> // Keyboard users can't see focus!

// GOOD: Tailwind's focus-visible (only shows for keyboard nav)
<button className="focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">
  Click
</button>
```

### Keyboard Shortcuts

```tsx
// Dialog: Escape to close
function Dialog({ open, onClose }: DialogProps) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (open) document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [open, onClose]);
}

// Dropdown: Arrow keys to navigate
// shadcn/ui handles this automatically via Radix primitives
```

### Focus Trapping in Modals

```tsx
// shadcn/ui Dialog handles focus trapping automatically
// If building custom: focus must stay inside the modal until closed

// When dialog opens: focus first focusable element
// When dialog closes: return focus to trigger element
// Tab wraps: last focusable → first focusable (and vice versa)
```

## ARIA Attributes

### Use ARIA Only When HTML Can't Express It

```tsx
// BAD: Redundant ARIA
<button role="button">Submit</button>          // button already has role="button"
<nav role="navigation">...</nav>               // nav already has role="navigation"

// GOOD: ARIA for dynamic states
<button aria-expanded={isOpen} aria-controls="menu-content">
  Menu
</button>
<div id="menu-content" role="menu" hidden={!isOpen}>
  <div role="menuitem">Option 1</div>
</div>

// GOOD: ARIA for live regions (dynamic content updates)
<div aria-live="polite" aria-atomic="true">
  {notification && <p>{notification}</p>}
</div>

// GOOD: Loading states
<button aria-busy={isLoading} disabled={isLoading}>
  {isLoading ? 'Saving...' : 'Save'}
</button>

// GOOD: Describing relationships
<input aria-describedby="password-hint" type="password" />
<p id="password-hint">Must be at least 8 characters</p>
```

### Common ARIA Patterns

```tsx
// Tabs
<div role="tablist">
  <button role="tab" aria-selected={active === 'tab1'} aria-controls="panel1">Tab 1</button>
  <button role="tab" aria-selected={active === 'tab2'} aria-controls="panel2">Tab 2</button>
</div>
<div role="tabpanel" id="panel1">Content 1</div>

// Toast notifications
<div role="status" aria-live="polite">
  {toastMessage}
</div>

// Progress
<div role="progressbar" aria-valuenow={75} aria-valuemin={0} aria-valuemax={100}>
  75% complete
</div>

// Breadcrumbs
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/projects">Projects</a></li>
    <li aria-current="page">My Project</li>
  </ol>
</nav>
```

## Color and Contrast

```tsx
// WCAG AA minimum contrast ratios:
// Normal text: 4.5:1
// Large text (18px+ bold or 24px+): 3:1
// UI components and graphics: 3:1

// BAD: Light gray text on white
<p className="text-gray-300">Hard to read</p>  // Fails contrast!

// GOOD: Sufficient contrast
<p className="text-foreground">Primary text</p>           // High contrast
<p className="text-muted-foreground">Secondary text</p>   // Meets 4.5:1

// Never rely on color alone
// BAD: Only color indicates status
<span className="text-red-500">Error</span>
<span className="text-green-500">Success</span>

// GOOD: Color + icon/text
<span className="text-destructive flex items-center gap-1">
  <XCircle className="h-4 w-4" /> Error: Invalid email
</span>
<span className="text-green-600 flex items-center gap-1">
  <CheckCircle className="h-4 w-4" /> Success
</span>
```

## Images and Icons

```tsx
// Decorative images: empty alt
<img src="/decoration.svg" alt="" role="presentation" />

// Informative images: descriptive alt
<img src="/chart.png" alt="Monthly revenue chart showing 20% growth in Q4" />

// Icon buttons: need accessible name
// BAD: Icon-only button with no label
<button><Search className="h-4 w-4" /></button>

// GOOD: Icon button with sr-only label
<button>
  <Search className="h-4 w-4" />
  <span className="sr-only">Search</span>
</button>

// GOOD: aria-label for icon buttons
<button aria-label="Search">
  <Search className="h-4 w-4" />
</button>
```

## Skip Links

```tsx
// Allow keyboard users to skip navigation
function SkipLink() {
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-background focus:px-4 focus:py-2 focus:shadow-lg"
    >
      Skip to main content
    </a>
  );
}

// In layout
<body>
  <SkipLink />
  <Header />
  <Sidebar />
  <main id="main-content" tabIndex={-1}>
    {children}
  </main>
</body>
```

## Automated Testing

```bash
npm install -D @axe-core/react
```

```tsx
// In development only — reports a11y violations to console
// src/main.tsx
if (import.meta.env.DEV) {
  import('@axe-core/react').then((axe) => {
    axe.default(React, ReactDOM, 1000);
  });
}
```

```tsx
// In Playwright E2E tests
import AxeBuilder from '@axe-core/playwright';

test('page has no accessibility violations', async ({ page }) => {
  await page.goto('/dashboard');
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

## Summary: Decision Tree

1. **Building interactive UI?** → Use semantic HTML (`<button>`, `<a>`, `<nav>`) first
2. **Need ARIA?** → Only if HTML alone can't express the pattern
3. **Form input?** → Must have `<label>` + error linked via `aria-describedby`
4. **Custom component?** → Must be keyboard-operable (Tab, Enter, Escape, Arrow)
5. **Modal/dialog?** → Focus trap + Escape to close + return focus to trigger
6. **Icon-only button?** → `aria-label` or `<span className="sr-only">`
7. **Color indicating state?** → Never color alone — add icon or text
8. **Images?** → Decorative: `alt=""` | Informative: descriptive alt text
9. **Testing?** → axe-core in dev + Playwright a11y audit in CI
10. **Keyboard navigation?** → Never `outline-none` — use `focus-visible:ring-2`
