---
name: spacing-guide
description: Provides SaaS dashboard spacing conventions for React + TypeScript applications. Covers page padding, card gaps, section spacing, header heights, form fields, table layouts, and responsive spacing adjustments. Must use when building dashboard pages, forms, or data views.
---

# SaaS Dashboard Spacing Guide

## Core Principle: Consistent Spacing = Professional UI

Use standard spacing patterns across all pages. Agents MUST reference this skill when generating layout code.

## Page-Level Spacing

```
+---------------------------------------------+
| Sidebar |        Main Content               |
|  w-64   |  p-6                              |
|         |  +- Page Header ----------------+ |
|         |  | h-auto  (title + description)| |
|         |  +------------------------------+ |
|         |         ^ gap-6                    |
|         |  +- Content Section ------------+ |
|         |  |                              | |
|         |  +------------------------------+ |
|         |         ^ gap-6                    |
|         |  +- Content Section ------------+ |
|         |  |                              | |
|         |  +------------------------------+ |
+---------------------------------------------+
```

### Key Values
| Element | Spacing | Tailwind |
|---------|---------|----------|
| Page padding | 24px | `p-6` |
| Section vertical gap | 24px | `gap-6` |
| Sidebar width | 256px | `w-64` |
| Header height | 56px | `h-14` |
| Max content width (optional) | 1280px | `max-w-screen-xl` |

### Page Wrapper
```tsx
<div className="flex flex-1 flex-col gap-6 p-6">
  {/* Page sections */}
</div>
```

## Header Spacing

| Element | Spacing | Tailwind |
|---------|---------|----------|
| Header height | 56px | `h-14` |
| Header horizontal padding | 24px | `px-6` |
| Header items gap | 16px | `gap-4` |
| Header bottom border | 1px | `border-b` |

## Card Spacing

| Element | Spacing | Tailwind |
|---------|---------|----------|
| Card internal padding | Auto (shadcn default) | Via `CardHeader/Content/Footer` |
| Card grid gap | 16px | `gap-4` |
| Stats card grid | responsive | `grid gap-4 sm:grid-cols-2 lg:grid-cols-4` |
| Feature card grid | responsive | `grid gap-6 sm:grid-cols-2 lg:grid-cols-3` |

## Form Spacing

| Element | Spacing | Tailwind |
|---------|---------|----------|
| Form fields vertical gap | 24px | `space-y-6` |
| Label to input gap | 8px | `space-y-2` (FormItem default) |
| Input to helper text | 4px | Handled by FormDescription |
| Two-column field grid | 16px | `grid gap-4 sm:grid-cols-2` |
| Form section divider | 32px | `space-y-8` between sections |
| Button row gap | 8px | `gap-2` |
| Button row alignment | Right | `flex justify-end gap-2` |

## Table Spacing

| Element | Spacing | Tailwind |
|---------|---------|----------|
| Toolbar to table gap | 16px | `space-y-4` |
| Search input max width | flexible | `max-w-sm` |
| Filter buttons gap | 8px | `gap-2` |
| Table cell padding | Auto (shadcn) | Via `TableCell` |
| Pagination to table gap | 16px | `mt-4` |

## Section Spacing Patterns

| Pattern | Tailwind |
|---------|----------|
| Between major sections | `gap-6` or `gap-8` |
| Between related items | `gap-4` |
| Between tightly grouped items | `gap-2` |
| Charts side by side | `grid gap-6 lg:grid-cols-2` |
| Header + actions row | `flex items-center justify-between` |
| Filters row | `flex flex-wrap items-center gap-2` |

## Button Spacing

| Pattern | Tailwind |
|---------|----------|
| Button group (same priority) | `flex gap-2` |
| Primary + Secondary | `flex justify-end gap-2` |
| Icon inside button | `mr-2 size-4` (before text) |
| Icon-only button | `size-icon` variant |
| Button row in card footer | `flex justify-end gap-2` |
| Full-width button (auth pages) | `w-full` |

## Responsive Spacing Adjustments

| Breakpoint | Page padding | Section gap |
|-----------|-------------|-------------|
| Mobile (< 640px) | `p-4` | `gap-4` |
| Tablet (640px+) | `p-6` | `gap-6` |
| Desktop (1024px+) | `p-6` | `gap-6` |

```tsx
{/* Responsive page wrapper */}
<div className="flex flex-1 flex-col gap-4 p-4 sm:gap-6 sm:p-6">
```

## Auth Page Spacing (Centered Form Layout)

| Element | Spacing | Tailwind |
|---------|---------|----------|
| Page center wrapper | full viewport | `flex min-h-screen items-center justify-center` |
| Form card max width | 400-480px | `w-full max-w-md` |
| Form card padding | 32px | `p-8` |
| Heading to form gap | 24px | `gap-6` |
| Brand logo to heading gap | 20px | `gap-5` |
| Footer text margin | 16px | `mt-4` |

## Rules

- Use the Tailwind spacing scale — never raw pixel values in code.
- Page padding: always `p-6` (or `p-4` on mobile).
- Section gap: always `gap-6` between major sections.
- Card grid gap: `gap-4` for stats, `gap-6` for larger cards.
- Form fields: `space-y-6` vertically.
- Buttons: `gap-2` between them, right-aligned with `justify-end`.
- When Figma provides exact values, use those. This guide provides defaults for Mode B (auto-design).
- Consistency > pixel-perfection when no Figma design: pick the nearest scale value.
