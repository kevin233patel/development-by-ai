---
name: error-handling
description: Provides error handling patterns for React + TypeScript SaaS applications. Covers error boundaries, global error handling, toast notifications, fallback UI, retry logic, and error logging. Must use when implementing error boundaries, API error handling, or user-facing error states.
---

# Error Handling Best Practices

## Core Principle: Fail Gracefully, Inform Clearly

Errors will happen. **Catch them at the right level, show meaningful messages to users, and log details for debugging.** Never show raw error messages or stack traces to users.

## Error Boundary

### Global Error Boundary

```tsx
// src/components/common/ErrorBoundary.tsx
import { Component, type ErrorInfo, type ReactNode } from 'react';
import { Button } from '@/components/ui/button';
import { AlertTriangle } from 'lucide-react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Log to error reporting service
    console.error('ErrorBoundary caught:', error, errorInfo);
    // errorReportingService.captureException(error, { extra: errorInfo });
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback;

      return (
        <div className="flex min-h-[400px] flex-col items-center justify-center text-center">
          <AlertTriangle className="h-12 w-12 text-destructive" />
          <h2 className="mt-4 text-xl font-semibold">Something went wrong</h2>
          <p className="mt-2 text-sm text-muted-foreground">
            An unexpected error occurred. Please try again.
          </p>
          <Button onClick={this.handleReset} className="mt-4">
            Try Again
          </Button>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Placement Strategy

```tsx
// Wrap the entire app — catches catastrophic errors
<ErrorBoundary>
  <App />
</ErrorBoundary>

// Wrap individual sections — isolate failures
<DashboardLayout>
  <ErrorBoundary fallback={<WidgetError />}>
    <AnalyticsWidget />
  </ErrorBoundary>
  <ErrorBoundary fallback={<WidgetError />}>
    <RecentActivityWidget />
  </ErrorBoundary>
</DashboardLayout>

// Per-route error boundary (React Router)
export const router = createBrowserRouter([
  {
    errorElement: <RouteError />,
    children: [/* routes */],
  },
]);
```

## API Error Handling

### Error States in Components

```tsx
// BAD: No error handling
function ProjectList() {
  const { data } = useQuery({ queryKey: ['projects'], queryFn: fetchProjects });
  return <div>{data?.map(...)}</div>;
}

// GOOD: Handle all states
function ProjectList() {
  const { data: projects, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['projects'],
    queryFn: projectService.getAll,
  });

  if (isLoading) return <ProjectListSkeleton />;

  if (isError) {
    return (
      <div className="flex flex-col items-center gap-4 py-12 text-center">
        <AlertTriangle className="h-8 w-8 text-destructive" />
        <p className="text-muted-foreground">
          {error instanceof ApiError ? error.message : 'Failed to load projects'}
        </p>
        <Button variant="outline" onClick={() => refetch()}>
          Try Again
        </Button>
      </div>
    );
  }

  if (!projects?.length) return <EmptyState />;

  return projects.map((p) => <ProjectCard key={p.id} project={p} />);
}
```

### Mutation Error Handling

```tsx
function useDeleteProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: projectService.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['projects'] });
      toast.success('Project deleted');
    },
    onError: (error) => {
      if (error instanceof ApiError) {
        switch (error.status) {
          case 403:
            toast.error('You don\'t have permission to delete this project');
            break;
          case 404:
            toast.error('Project not found — it may have been already deleted');
            break;
          default:
            toast.error(error.message || 'Failed to delete project');
        }
      } else {
        toast.error('An unexpected error occurred');
      }
    },
  });
}
```

## Toast Notifications

### Using Sonner

```tsx
import { toast } from 'sonner';

// Success
toast.success('Changes saved');

// Error
toast.error('Failed to save changes');

// With description
toast.error('Upload failed', {
  description: 'The file exceeds the 10MB limit',
});

// Promise-based (loading → success/error)
toast.promise(saveProject(data), {
  loading: 'Saving project...',
  success: 'Project saved!',
  error: (err) => err instanceof ApiError ? err.message : 'Failed to save',
});

// With undo action
toast('Project deleted', {
  action: {
    label: 'Undo',
    onClick: () => restoreProject(projectId),
  },
});
```

## Form Error Handling

```tsx
const handleSubmit = async (data: FormValues) => {
  try {
    await api.createProject(data);
    toast.success('Project created');
    form.reset();
  } catch (error) {
    if (error instanceof ApiError && error.validationErrors) {
      // Field-level errors from server
      error.validationErrors.forEach((err) => {
        form.setError(err.field as keyof FormValues, {
          type: 'server',
          message: err.message,
        });
      });
    } else if (error instanceof ApiError) {
      // General API error
      form.setError('root', { message: error.message });
    } else {
      // Unknown error
      form.setError('root', { message: 'An unexpected error occurred. Please try again.' });
    }
  }
};

// Display root error
{form.formState.errors.root && (
  <div className="rounded-md bg-destructive/10 p-3 text-sm text-destructive" role="alert">
    {form.formState.errors.root.message}
  </div>
)}
```

## Not Found / Empty States

```tsx
// 404 Page
function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center">
      <h1 className="text-6xl font-bold text-muted-foreground">404</h1>
      <p className="mt-4 text-lg text-muted-foreground">Page not found</p>
      <Button asChild className="mt-6">
        <Link to="/">Go Home</Link>
      </Button>
    </div>
  );
}

// Resource not found
function ProjectDetail({ projectId }: { projectId: string }) {
  const { data, isError, error } = useProject(projectId);

  if (isError && error instanceof ApiError && error.isNotFound) {
    return (
      <EmptyState
        icon={FolderX}
        title="Project not found"
        description="This project may have been deleted or you don't have access."
        action={{ label: 'Back to Projects', onClick: () => navigate('/projects') }}
      />
    );
  }
}
```

## Network Error Handling

```tsx
// Detect offline state
function useNetworkStatus() {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return isOnline;
}

// Offline banner
function OfflineBanner() {
  const isOnline = useNetworkStatus();

  if (isOnline) return null;

  return (
    <div className="bg-destructive px-4 py-2 text-center text-sm text-destructive-foreground">
      You're offline. Changes will be saved when you reconnect.
    </div>
  );
}
```

## Summary: Decision Tree

1. **Catastrophic crash?** → ErrorBoundary catches and shows fallback UI
2. **Route-level error?** → React Router `errorElement`
3. **API fetch fails?** → Show error state + retry button in component
4. **Mutation fails?** → Toast notification with helpful message
5. **Form submission fails?** → Map server errors to fields, show root error
6. **404?** → Dedicated NotFound page or empty state
7. **Network lost?** → Offline banner + queue changes for reconnect
8. **User-facing messages?** → Never raw errors — always friendly, actionable text
9. **Logging?** → `componentDidCatch` + error reporting service
10. **Retry logic?** → TanStack Query handles retries for queries
