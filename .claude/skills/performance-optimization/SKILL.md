---
name: performance-optimization
description: Provides frontend performance optimization patterns for React + TypeScript SaaS applications. Covers code splitting, lazy loading, memoization, virtualization, bundle analysis, image optimization, and Core Web Vitals. Must use when optimizing load times, bundle size, or runtime performance.
---

# Performance Optimization Best Practices

## Runtime Performance Matrix — Enforced Targets

All code must meet these thresholds before merge. **Red = must fix before deploy.**

### Core Web Vitals
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| LCP | ≤ 2.5s | ≤ 4.0s | > 4.0s | **< 2.0s** | Lighthouse / web-vitals |
| INP | ≤ 200ms | ≤ 500ms | > 500ms | **< 150ms** | web-vitals RUM |
| CLS | ≤ 0.1 | ≤ 0.25 | > 0.25 | **< 0.05** | Lighthouse / web-vitals |
| FCP | ≤ 1.8s | ≤ 3.0s | > 3.0s | **< 1.5s** | Lighthouse |
| TTFB | ≤ 800ms | ≤ 1.5s | > 1.5s | **< 600ms** | web-vitals / WebPageTest |

### Bundle Size (gzip)
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| Initial JS Bundle | ≤ 200KB | ≤ 350KB | > 350KB | **< 170KB** | vite-bundle-visualizer |
| Per-Route Chunk | ≤ 50KB | ≤ 100KB | > 100KB | **< 40KB** | Bundle analyzer |
| Total CSS | ≤ 30KB | ≤ 60KB | > 60KB | **< 25KB** | Coverage tab |
| Total Transfer | ≤ 500KB | ≤ 1MB | > 1MB | **< 400KB** | Network tab |

### React Rendering
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| Render p50 | ≤ 8ms | ≤ 16ms | > 16ms | **< 5ms** | React Profiler |
| Render p95 | ≤ 16ms | ≤ 50ms | > 50ms | **< 12ms** | React Profiler |
| Unnecessary Re-renders/Action | 0 | 1–3 | > 3 | **0** | why-did-you-render |
| DOM Node Count (peak) | ≤ 1,500 | ≤ 3,000 | > 3,000 | **< 1,200** | Lighthouse |

### Memory
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| Heap after 30min | ≤ 50MB | ≤ 100MB | > 100MB | **< 40MB** | DevTools Heap Snapshot |
| Memory Leak Rate | ≤ 0.1 MB/min | ≤ 0.5 MB/min | > 0.5 MB/min | **0 MB/min** | MemLab / Timeline |
| Detached DOM Nodes | 0 | ≤ 10 | > 10 | **0** | Heap Snapshot |

### Network & Caching
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| API Response p50 | ≤ 200ms | ≤ 500ms | > 500ms | **< 150ms** | Network tab / Sentry |
| API Response p95 | ≤ 500ms | ≤ 1.5s | > 1.5s | **< 400ms** | Sentry Performance |
| Query Cache Hit Rate | ≥ 80% | ≥ 60% | < 60% | **> 85%** | TanStack Query DevTools |
| CDN Cache Hit Rate | ≥ 95% | ≥ 85% | < 85% | **> 97%** | CDN dashboard |
| Request Waterfall Depth | ≤ 2 | ≤ 3 | > 3 | **≤ 2** | WebPageTest |

### Interaction Speed
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| Search Response | ≤ 300ms | ≤ 800ms | > 800ms | **< 200ms** | Custom RUM |
| Filter/Sort Response | ≤ 200ms | ≤ 500ms | > 500ms | **< 100ms** | Custom RUM |
| Route Navigation | ≤ 300ms | ≤ 800ms | > 800ms | **< 200ms** | Performance marks |
| Form Submission | ≤ 500ms | ≤ 1.5s | > 1.5s | **< 400ms** | Custom RUM |

### Lighthouse Scores
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| Performance Score | ≥ 90 | ≥ 70 | < 70 | **> 95** | Lighthouse CI |
| Total Blocking Time | ≤ 200ms | ≤ 600ms | > 600ms | **< 150ms** | Lighthouse |
| Speed Index | ≤ 3.4s | ≤ 5.8s | > 5.8s | **< 2.5s** | Lighthouse |

### Infrastructure
| Metric | Good | Warning | Critical | **Target** | Tool |
|---|---|---|---|---|---|
| Build Time | ≤ 60s | ≤ 120s | > 120s | **< 45s** | CI logs |
| CI Pipeline Duration | ≤ 5 min | ≤ 10 min | > 10 min | **< 4 min** | GitHub Actions |
| Deploy Time (staging) | ≤ 2 min | ≤ 5 min | > 5 min | **< 90s** | Deploy logs |
| Error Rate (unhandled) | ≤ 0.1% | ≤ 1% | > 1% | **< 0.05%** | Sentry |

---

## Core Principle: Measure First, Optimize Second

Never optimize based on assumptions. **Profile, identify the bottleneck, fix it, measure again.** Premature optimization adds complexity without proven benefit.

## Code Splitting

### Route-Level Lazy Loading

```tsx
// BAD: Importing all pages eagerly
import { Dashboard } from '@/pages/Dashboard';
import { Settings } from '@/pages/Settings';
import { Analytics } from '@/pages/Analytics';

// GOOD: Lazy load at route level
const Dashboard = lazy(() => import('@/pages/Dashboard'));
const Settings = lazy(() => import('@/pages/Settings'));
const Analytics = lazy(() => import('@/pages/Analytics'));

// With named export
const Settings = lazy(() =>
  import('@/features/settings/pages/Settings').then((m) => ({ default: m.Settings }))
);
```

### Component-Level Lazy Loading

```tsx
// Heavy components that aren't always visible
const RichTextEditor = lazy(() => import('@/components/common/RichTextEditor'));
const ChartWidget = lazy(() => import('@/components/common/ChartWidget'));

function ProjectDetail() {
  return (
    <div>
      <ProjectInfo />
      <Suspense fallback={<Skeleton className="h-64" />}>
        <ChartWidget data={chartData} />
      </Suspense>
    </div>
  );
}
```

## Memoization

### When to Use useMemo

```tsx
// BAD: useMemo everywhere "just in case"
const fullName = useMemo(() => `${first} ${last}`, [first, last]); // Trivial!

// GOOD: useMemo ONLY for genuinely expensive operations
const sortedAndFilteredItems = useMemo(() => {
  return items
    .filter((item) => item.status === filter)
    .sort((a, b) => a.name.localeCompare(b.name));
}, [items, filter]);

// How to know if it's expensive? Measure!
console.time('filter');
const result = expensiveOperation(data);
console.timeEnd('filter'); // If > 1ms, consider memoizing
```

### When to Use React.memo

```tsx
// BAD: Wrapping everything in memo
const Button = memo(function Button(props) { ... }); // Re-renders are cheap!

// GOOD: memo for components that:
// 1. Render often with same props (in a list)
// 2. Are expensive to render (charts, tables)
// 3. Receive stable props from above

const ExpensiveChart = memo(function ExpensiveChart({ data }: { data: DataPoint[] }) {
  // Heavy rendering logic
  return <canvas ref={renderChart} />;
});

// GOOD: memo for list items rendered by parent
const ProjectCard = memo(function ProjectCard({ project }: { project: Project }) {
  return (
    <Card>
      <h3>{project.name}</h3>
      <p>{project.description}</p>
    </Card>
  );
});
```

### useCallback for Stable References

```tsx
// BAD: useCallback for every handler
const handleClick = useCallback(() => { ... }, []); // Unnecessary for leaf components

// GOOD: useCallback when passing to memoized children
function ProjectList({ projects }: { projects: Project[] }) {
  const handleDelete = useCallback((id: string) => {
    deleteMutation.mutate(id);
  }, [deleteMutation]);

  return projects.map((p) => (
    // ProjectCard is memo'd, so stable handleDelete prevents re-renders
    <ProjectCard key={p.id} project={p} onDelete={handleDelete} />
  ));
}
```

## List Virtualization

### For Long Lists (100+ items)

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualizedList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 64, // Estimated row height in px
    overscan: 5,            // Render 5 extra items above/below viewport
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            <ListItem item={items[virtualItem.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Image Optimization

```tsx
// BAD: Unoptimized images
<img src="/hero.png" />

// GOOD: Responsive images with lazy loading
<img
  src="/hero.webp"
  srcSet="/hero-400.webp 400w, /hero-800.webp 800w, /hero-1200.webp 1200w"
  sizes="(max-width: 640px) 400px, (max-width: 1024px) 800px, 1200px"
  loading="lazy"         // Native lazy loading
  decoding="async"       // Don't block main thread
  alt="Hero image"
  width={1200}           // Prevent layout shift
  height={600}
/>

// GOOD: Avatar component with lazy loading
function Avatar({ src, alt, size = 40 }: AvatarProps) {
  return (
    <img
      src={src}
      alt={alt}
      width={size}
      height={size}
      loading="lazy"
      decoding="async"
      className="rounded-full object-cover"
    />
  );
}
```

## Bundle Analysis

```bash
# Analyze bundle size
npm run build -- --mode analyze

# Check specific dependency size
npx bundlephobia <package-name>
```

### Reducing Bundle Size

```tsx
// BAD: Importing entire library
import _ from 'lodash';            // 70KB
import { format } from 'date-fns'; // 30KB+ (tree-shakeable, but check)
import * as icons from 'lucide-react'; // All icons

// GOOD: Import only what you need
import debounce from 'lodash/debounce';  // 1KB
import { format } from 'date-fns/format'; // Specific function
import { Search, User } from 'lucide-react'; // Specific icons
```

## Loading States & Skeleton Screens

```tsx
// BAD: Spinner for everything
if (isLoading) return <Spinner />;

// GOOD: Skeleton that matches the layout
function ProjectListSkeleton() {
  return (
    <div className="space-y-4">
      {Array.from({ length: 5 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 rounded-lg border p-4">
          <Skeleton className="h-10 w-10 rounded-full" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-48" />
            <Skeleton className="h-3 w-96" />
          </div>
        </div>
      ))}
    </div>
  );
}
```

## Web Worker for Heavy Computation

```tsx
// For CPU-intensive tasks that block the main thread
// src/workers/dataProcessor.worker.ts
self.onmessage = (event: MessageEvent<DataPayload>) => {
  const result = heavyComputation(event.data);
  self.postMessage(result);
};

// Usage in component
const worker = useMemo(
  () => new Worker(new URL('@/workers/dataProcessor.worker.ts', import.meta.url), { type: 'module' }),
  []
);

useEffect(() => {
  worker.onmessage = (e) => setResult(e.data);
  worker.postMessage(rawData);
  return () => worker.terminate();
}, [rawData, worker]);
```

## Summary: Decision Tree

1. **Page loads slow?** → Route-level lazy loading + code splitting
2. **Component re-renders too much?** → React DevTools Profiler → identify cause
3. **Expensive computation?** → `useMemo` (measure first: > 1ms = worth it)
4. **List item re-renders?** → `React.memo` + `useCallback` for handlers
5. **Long list (100+ items)?** → Virtualize with `@tanstack/react-virtual`
6. **Bundle too large?** → Analyze → tree-shake → split vendor chunks
7. **Images slow?** → `loading="lazy"` + `srcSet` + WebP format
8. **Layout shift (CLS)?** → Set explicit `width`/`height` on images
9. **Loading states?** → Skeleton screens matching layout, not spinners
10. **CPU-intensive work?** → Web Worker to unblock main thread
