---
name: dark-light-theming
description: Provides dark/light theme patterns for React + TypeScript SaaS applications. Covers CSS variable theming, theme provider, system preference detection, persistence, and component-level theming. Must use when implementing theme switching or dark mode support.
---

# Dark/Light Theming Best Practices

## Core Principle: Semantic Tokens, Not Color Modes

Use CSS custom properties with semantic names (e.g., `--color-background`, `--color-foreground`). **Components reference tokens, not colors.** Switching theme only changes token values — zero component changes needed.

## Theme Provider

### Theme Context + Hook

```tsx
// src/hooks/useTheme.ts
import { useAppDispatch, useAppSelector } from '@/stores/hooks';
import { setTheme, selectTheme } from '@/stores/uiSlice';
import { useEffect } from 'react';

type Theme = 'light' | 'dark' | 'system';

export function useTheme() {
  const dispatch = useAppDispatch();
  const theme = useAppSelector(selectTheme);

  useEffect(() => {
    const root = document.documentElement;

    const applyTheme = (resolved: 'light' | 'dark') => {
      root.classList.remove('light', 'dark');
      root.classList.add(resolved);
    };

    if (theme === 'system') {
      const media = window.matchMedia('(prefers-color-scheme: dark)');
      applyTheme(media.matches ? 'dark' : 'light');

      const handler = (e: MediaQueryListEvent) => applyTheme(e.matches ? 'dark' : 'light');
      media.addEventListener('change', handler);
      return () => media.removeEventListener('change', handler);
    } else {
      applyTheme(theme);
    }
  }, [theme]);

  return {
    theme,
    setTheme: (newTheme: Theme) => {
      dispatch(setTheme(newTheme));
      localStorage.setItem('theme', newTheme);
    },
    resolvedTheme: document.documentElement.classList.contains('dark') ? 'dark' : 'light',
  };
}
```

### Theme Toggle Component

```tsx
// src/components/common/ThemeToggle.tsx
import { Moon, Sun, Monitor } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { useTheme } from '@/hooks/useTheme';

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <Sun className="h-4 w-4 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-4 w-4 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme('light')}>
          <Sun className="mr-2 h-4 w-4" /> Light
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme('dark')}>
          <Moon className="mr-2 h-4 w-4" /> Dark
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme('system')}>
          <Monitor className="mr-2 h-4 w-4" /> System
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
```

## CSS Setup

### Color Palette — Primitive Tokens

Full brand palette available as CSS variables. Reference these when building new semantic tokens.

```
Red:    red-05 #fef5f5 → red-10 #feecec → red-20 #fccfcf → red-30 #f6b1b1
        red-40 #f58a8a → red-50 #ec5b5b → red-60 #db132a → red-65 #c72323
        red-70 #ad1111 → red-80 #750c0c → red-90 #4a0b0b → red-100 #310c0c

Orange: orange-05 #fdf7f4 → orange-10 #fef5ee → orange-20 #fddcc4 → orange-30 #fac2a0
        orange-40 #ffb37a → orange-50 #fa9950 → orange-60 #f47c22 → orange-65 #e56b19
        orange-70 #c35323 → orange-80 #8d3118 → orange-90 #541914 → orange-100 #40130f

Yellow: yellow-05 #fffdf4 → yellow-10 #fffbea → yellow-20 #fff1b3 → yellow-30 #ffe980
        yellow-40 #ffdd35 → yellow-50 #fad100 → yellow-60 #e8b407 → yellow-70 #c28e00
        yellow-80 #855c15 → yellow-90 #543308 → yellow-100 #3d2106

Green:  green-05 #f5fdf8 → green-10 #edfdf3 → green-20 #d1fae0 → green-30 #a2f6c3
        green-40 #7beaa5 → green-50 #36d576 → green-60 #14b053 → green-70 #0e7c3a
        green-80 #0b602d → green-90 #0d3a1f → green-100 #052912

Blue:   blue-05 #f4f9ff → blue-10 #ebf4ff → blue-20 #cce4ff → blue-30 #99cdff
        blue-40 #66b3ff → blue-50 #008cff → blue-55 #006dfa → blue-60 #0263e0
        blue-70 #043cb5 → blue-80 #001489 → blue-90 #030b5d → blue-100 #06033a

Purple: purple-05 #faf7fd → purple-10 #f5f0fc → purple-20 #e7dcfa → purple-30 #c8aff0
        purple-40 #a67fe3 → purple-50 #8c5bd8 → purple-60 #6d2ed1 → purple-70 #5817bd
        purple-80 #380e78 → purple-90 #22094a → purple-100 #160433
```

### CSS Variables with Dark Mode Override

```css
/* src/index.css */
@import 'tailwindcss';

/* Primitive tokens — raw palette, use in semantic tokens or one-off overrides */
:root {
  /* Red */
  --red-05: #fef5f5; --red-10: #feecec; --red-20: #fccfcf; --red-30: #f6b1b1;
  --red-40: #f58a8a; --red-50: #ec5b5b; --red-60: #db132a; --red-65: #c72323;
  --red-70: #ad1111; --red-80: #750c0c; --red-90: #4a0b0b; --red-100: #310c0c;
  /* Orange */
  --orange-05: #fdf7f4; --orange-10: #fef5ee; --orange-20: #fddcc4; --orange-30: #fac2a0;
  --orange-40: #ffb37a; --orange-50: #fa9950; --orange-60: #f47c22; --orange-65: #e56b19;
  --orange-70: #c35323; --orange-80: #8d3118; --orange-90: #541914; --orange-100: #40130f;
  /* Yellow */
  --yellow-05: #fffdf4; --yellow-10: #fffbea; --yellow-20: #fff1b3; --yellow-30: #ffe980;
  --yellow-40: #ffdd35; --yellow-50: #fad100; --yellow-60: #e8b407; --yellow-70: #c28e00;
  --yellow-80: #855c15; --yellow-90: #543308; --yellow-100: #3d2106;
  /* Green */
  --green-05: #f5fdf8; --green-10: #edfdf3; --green-20: #d1fae0; --green-30: #a2f6c3;
  --green-40: #7beaa5; --green-50: #36d576; --green-60: #14b053; --green-70: #0e7c3a;
  --green-80: #0b602d; --green-90: #0d3a1f; --green-100: #052912;
  /* Blue */
  --blue-05: #f4f9ff; --blue-10: #ebf4ff; --blue-20: #cce4ff; --blue-30: #99cdff;
  --blue-40: #66b3ff; --blue-50: #008cff; --blue-55: #006dfa; --blue-60: #0263e0;
  --blue-70: #043cb5; --blue-80: #001489; --blue-90: #030b5d; --blue-100: #06033a;
  /* Purple */
  --purple-05: #faf7fd; --purple-10: #f5f0fc; --purple-20: #e7dcfa; --purple-30: #c8aff0;
  --purple-40: #a67fe3; --purple-50: #8c5bd8; --purple-60: #6d2ed1; --purple-70: #5817bd;
  --purple-80: #380e78; --purple-90: #22094a; --purple-100: #160433;
}

/* Semantic tokens — light mode (default) */
@theme {
  --color-background: #ffffff;
  --color-foreground: #030b5d;          /* blue-90 — deep navy text */
  --color-card: #ffffff;
  --color-card-foreground: #030b5d;
  --color-primary: #006dfa;             /* blue-55 — brand primary */
  --color-primary-foreground: #ffffff;
  --color-secondary: #f4f9ff;           /* blue-05 — subtle tinted bg */
  --color-secondary-foreground: #030b5d;
  --color-muted: #ebf4ff;               /* blue-10 */
  --color-muted-foreground: #043cb5;    /* blue-70 — readable muted text */
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
}

/* Semantic tokens — dark mode override */
.dark {
  --color-background: #030b5d;          /* blue-90 — deep navy bg */
  --color-foreground: #f4f9ff;          /* blue-05 — near-white text */
  --color-card: #001489;                /* blue-80 */
  --color-card-foreground: #f4f9ff;
  --color-primary: #66b3ff;             /* blue-40 — lighter for dark bg */
  --color-primary-foreground: #030b5d;  /* dark text on light primary */
  --color-secondary: #001489;           /* blue-80 */
  --color-secondary-foreground: #f4f9ff;
  --color-muted: #043cb5;               /* blue-70 */
  --color-muted-foreground: #99cdff;    /* blue-30 — readable on dark */
  --color-accent: #043cb5;              /* blue-70 */
  --color-accent-foreground: #f4f9ff;
  --color-destructive: #f58a8a;         /* red-40 — softened for dark */
  --color-destructive-foreground: #310c0c; /* red-100 */
  --color-success: #36d576;             /* green-50 */
  --color-success-foreground: #052912;  /* green-100 */
  --color-warning: #fa9950;             /* orange-50 */
  --color-warning-foreground: #40130f;  /* orange-100 */
  --color-border: #043cb5;              /* blue-70 */
  --color-input: #043cb5;
  --color-ring: #66b3ff;                /* blue-40 */
}
```

### Prevent Flash of Wrong Theme

```html
<!-- index.html — inline script runs before React -->
<script>
  (function() {
    const theme = localStorage.getItem('theme') || 'system';
    const isDark = theme === 'dark' ||
      (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
    document.documentElement.classList.add(isDark ? 'dark' : 'light');
  })();
</script>
```

## Using Semantic Tokens

```tsx
// BAD: Hardcoded colors with dark: prefix everywhere
<div className="bg-white text-black dark:bg-gray-900 dark:text-white">
  <p className="text-gray-500 dark:text-gray-400">Subtitle</p>
  <div className="border-gray-200 dark:border-gray-700">Card</div>
</div>

// GOOD: Semantic tokens — one class, both modes handled by CSS
<div className="bg-background text-foreground">
  <p className="text-muted-foreground">Subtitle</p>
  <div className="border-border bg-card text-card-foreground">Card</div>
</div>
```

## Dark Mode From the Start (CRITICAL)

If the design supports dark mode, add `dark:` variants on EVERY element in the first pass. Don't defer dark mode to a second pass — it's much harder to retrofit.

```tsx
// BAD: light mode only — breaks in dark mode
<div className="bg-white text-[#111C2C] border-[#ECF1F9]">

// GOOD: always pair light + dark variants from the start
<div className="bg-white text-[#111C2C] border-[#ECF1F9] dark:bg-[#0B1120] dark:text-[#F1F5F9] dark:border-[#334155]">

// BEST: Use semantic tokens — automatic dark mode, zero dark: prefixes
<div className="bg-background text-foreground border-border">
```

**Decision rule:**
- If the color maps to a semantic token → use the token (e.g., `bg-background`)
- If the color is an accent/badge/one-off → use exact hex with `dark:` counterpart (e.g., `bg-[#FBF4EC] dark:bg-[#3D2106]`)

## Accent & Badge Colors (Exact Hex Strategy)

For design-specific accent colors that don't map to the theme (badges, status dots, category tags), use the **exact hex from Figma** — never approximate with Tailwind palette colors.

```tsx
// BAD: Tailwind palette approximation
"bg-orange-50 text-orange-700"

// GOOD: Exact hex from Figma fill data
"bg-[#FBF4EC] text-[#D28E3D]"
```

When extracting accent colors from Figma, build a color map:
```typescript
const badgeColors = {
  internal: 'bg-[#FBF4EC] text-[#D28E3D] dark:bg-[#3D2106] dark:text-[#FFCC80]',
  marketing: 'bg-[#F7F7E8] text-[#B1AB1D] dark:bg-[#3D3A06] dark:text-[#FFEE58]',
  // ... extract ALL variants from Figma component set
} as const;
```

## Figma Token → CSS Variable Mapping Process

When design-analyzer extracts tokens via `get_variable_defs`:

1. Map each Figma token to the corresponding CSS variable in `src/index.css`
2. If a Figma token maps to an existing semantic slot (e.g., `--color-primary`), use it directly
3. If a Figma token is new (e.g., a new status color), add it to both `:root` and `.dark` blocks
4. Keep hex format for our brand palette (not OKLCH) — our theme is hex-based

| Figma Token | CSS Variable | Light Hex | Dark Hex | Tailwind Class |
|---|---|---|---|---|
| Brand Primary | `--color-primary` | `#006dfa` | `#66b3ff` | `bg-primary` / `text-primary` |
| Background | `--color-background` | `#ffffff` | `#030b5d` | `bg-background` |
| Destructive | `--color-destructive` | `#db132a` | `#f58a8a` | `bg-destructive` |
| Success | `--color-success` | `#14b053` | `#36d576` | `bg-success` |

## Charts and Data Visualization

```tsx
// Charts need theme-aware colors — mapped from the brand palette
function useChartColors() {
  const { resolvedTheme } = useTheme();
  const dark = resolvedTheme === 'dark';

  return useMemo(() => ({
    primary:    dark ? '#66b3ff' : '#006dfa',  // blue-40 : blue-55
    success:    dark ? '#36d576' : '#14b053',  // green-50 : green-60
    warning:    dark ? '#fa9950' : '#f47c22',  // orange-50 : orange-60
    danger:     dark ? '#f58a8a' : '#db132a',  // red-40 : red-60
    info:       dark ? '#a67fe3' : '#8c5bd8',  // purple-40 : purple-50
    background: dark ? '#030b5d' : '#ffffff',  // blue-90 : white
    grid:       dark ? '#043cb5' : '#cce4ff',  // blue-70 : blue-20
    text:       dark ? '#f4f9ff' : '#030b5d',  // blue-05 : blue-90
  }), [resolvedTheme]);
}
```

## Summary: Decision Tree

1. **Setting up theming?** → CSS variables in `@theme` + `.dark` override
2. **Referencing colors?** → Always use semantic tokens (`bg-background`), not `dark:` prefix
3. **Theme switching?** → useTheme hook + Redux + localStorage persistence
4. **System preference?** → `matchMedia('(prefers-color-scheme: dark)')` with listener
5. **Prevent flash?** → Inline `<script>` in index.html before React loads
6. **Theme toggle UI?** → Dropdown with Light/Dark/System options
7. **Charts/images?** → Use theme-aware colors from `useChartColors`
8. **Testing themes?** → Toggle class on `<html>` element in tests
