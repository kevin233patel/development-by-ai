---
name: tanstack-query
description: Provides TanStack Query (React Query) patterns for React + TypeScript SaaS applications. Covers query/mutation setup, caching, pagination, optimistic updates, error handling, and query invalidation. Must use when fetching API data, managing server state, or implementing data synchronization.
---

# TanStack Query Best Practices

## Core Principle: Server State Is Not Client State

TanStack Query manages **server state** — data that lives on the server and needs synchronization. It handles caching, background refetching, stale-while-revalidate, and deduplication. **Never duplicate server data into Redux.**

## Installation & Setup

```bash
npm install @tanstack/react-query @tanstack/react-query-devtools
```

### Query Client Configuration

```tsx
// src/lib/queryClient.ts
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,       // 5 minutes — data considered fresh
      gcTime: 10 * 60 * 1000,          // 10 minutes — garbage collect unused data
      retry: 1,                         // Retry failed requests once
      refetchOnWindowFocus: false,      // Disable for SaaS (too aggressive)
      refetchOnReconnect: true,         // Refetch when network reconnects
    },
    mutations: {
      retry: 0,                         // Don't retry mutations
    },
  },
});
```

### Provider Setup

```tsx
// src/main.tsx
import { QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { queryClient } from '@/lib/queryClient';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Provider store={store}>
      <QueryClientProvider client={queryClient}>
        <App />
        <ReactQueryDevtools initialIsOpen={false} />
      </QueryClientProvider>
    </Provider>
  </StrictMode>
);
```

## Query Patterns

### Basic Query with Type Safety

```tsx
// BAD: Untyped query with inline fetch
function ProjectList() {
  const { data } = useQuery({
    queryKey: ['projects'],
    queryFn: () => fetch('/api/projects').then(res => res.json()),
  });
}

// GOOD: Typed query with service layer
import { useQuery } from '@tanstack/react-query';
import { projectService } from '@/services/projectService';
import type { Project } from '@/types';

function ProjectList() {
  const {
    data: projects,
    isLoading,
    isError,
    error,
  } = useQuery<Project[]>({
    queryKey: ['projects'],
    queryFn: projectService.getAll,
  });

  if (isLoading) return <ProjectListSkeleton />;
  if (isError) return <ErrorMessage message={error.message} />;
  if (!projects?.length) return <EmptyState />;

  return (
    <div className="grid gap-4">
      {projects.map((project) => (
        <ProjectCard key={project.id} project={project} />
      ))}
    </div>
  );
}
```

### Query with Parameters

```tsx
// GOOD: Query key includes all parameters that affect the result
function ProjectDetail({ projectId }: { projectId: string }) {
  const { data: project, isLoading } = useQuery({
    queryKey: ['project', projectId],
    queryFn: () => projectService.getById(projectId),
    enabled: !!projectId, // Don't fetch if no ID
  });

  return isLoading ? <Skeleton /> : <div>{project?.name}</div>;
}
```

### Query Key Conventions

```tsx
// BAD: Inconsistent, flat query keys
useQuery({ queryKey: ['getProjects'] });
useQuery({ queryKey: ['project-1'] });
useQuery({ queryKey: ['user-projects-active'] });

// GOOD: Hierarchical, predictable query keys
// Pattern: [entity, ...identifiers, ...filters]
useQuery({ queryKey: ['projects'] });                          // All projects
useQuery({ queryKey: ['projects', { status: 'active' }] });   // Filtered
useQuery({ queryKey: ['projects', projectId] });               // Single project
useQuery({ queryKey: ['projects', projectId, 'members'] });    // Project members

// Create a query key factory for consistency
export const projectKeys = {
  all: ['projects'] as const,
  lists: () => [...projectKeys.all, 'list'] as const,
  list: (filters: ProjectFilters) => [...projectKeys.lists(), filters] as const,
  details: () => [...projectKeys.all, 'detail'] as const,
  detail: (id: string) => [...projectKeys.details(), id] as const,
  members: (id: string) => [...projectKeys.detail(id), 'members'] as const,
};

// Usage
useQuery({ queryKey: projectKeys.detail(projectId), queryFn: ... });
useQuery({ queryKey: projectKeys.list({ status: 'active' }), queryFn: ... });
```

## Mutation Patterns

### Basic Mutation

```tsx
// BAD: No loading state, no error handling, no cache update
function CreateProjectButton() {
  const handleCreate = async () => {
    await projectService.create(data);
    // UI is stale now!
  };
}

// GOOD: Mutation with cache invalidation
import { useMutation, useQueryClient } from '@tanstack/react-query';

function CreateProjectDialog() {
  const queryClient = useQueryClient();

  const createMutation = useMutation({
    mutationFn: projectService.create,
    onSuccess: () => {
      // Invalidate and refetch project list
      queryClient.invalidateQueries({ queryKey: projectKeys.all });
      toast.success('Project created');
      setOpen(false);
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to create project');
    },
  });

  const handleSubmit = (data: CreateProjectInput) => {
    createMutation.mutate(data);
  };

  return (
    <form onSubmit={handleFormSubmit(handleSubmit)}>
      {/* form fields */}
      <LoadingButton isLoading={createMutation.isPending} type="submit">
        Create Project
      </LoadingButton>
    </form>
  );
}
```

### Update Mutation with Optimistic Updates

```tsx
function useUpdateProject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateProjectInput }) =>
      projectService.update(id, data),

    // Optimistic update — update UI before server responds
    onMutate: async ({ id, data }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: projectKeys.detail(id) });

      // Snapshot previous value
      const previousProject = queryClient.getQueryData<Project>(projectKeys.detail(id));

      // Optimistically update cache
      queryClient.setQueryData<Project>(projectKeys.detail(id), (old) =>
        old ? { ...old, ...data } : old
      );

      return { previousProject };
    },

    // Rollback on error
    onError: (_error, { id }, context) => {
      if (context?.previousProject) {
        queryClient.setQueryData(projectKeys.detail(id), context.previousProject);
      }
      toast.error('Failed to update project');
    },

    onSettled: (_data, _error, { id }) => {
      // Always refetch after mutation to ensure cache is correct
      queryClient.invalidateQueries({ queryKey: projectKeys.detail(id) });
    },
  });
}

// Usage
function ProjectSettings({ project }: { project: Project }) {
  const updateProject = useUpdateProject();

  const handleSave = (data: UpdateProjectInput) => {
    updateProject.mutate({ id: project.id, data });
  };
}
```

### Delete Mutation

```tsx
function useDeleteProject() {
  const queryClient = useQueryClient();
  const navigate = useNavigate();

  return useMutation({
    mutationFn: projectService.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: projectKeys.all });
      toast.success('Project deleted');
      navigate('/projects');
    },
    onError: () => {
      toast.error('Failed to delete project');
    },
  });
}
```

## Pagination

### Offset-Based Pagination

```tsx
interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

function ProjectList() {
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const { data, isLoading, isPlaceholderData } = useQuery({
    queryKey: projectKeys.list({ page, pageSize }),
    queryFn: () => projectService.getAll({ page, pageSize }),
    placeholderData: (previousData) => previousData, // Keep previous data while fetching
  });

  return (
    <div>
      <div className={cn(isPlaceholderData && 'opacity-50 transition-opacity')}>
        {data?.data.map((project) => (
          <ProjectCard key={project.id} project={project} />
        ))}
      </div>

      <div className="flex items-center justify-between py-4">
        <p className="text-sm text-muted-foreground">
          Showing {((page - 1) * pageSize) + 1} to {Math.min(page * pageSize, data?.total ?? 0)} of {data?.total ?? 0}
        </p>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page === 1}
          >
            Previous
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setPage((p) => p + 1)}
            disabled={page >= (data?.totalPages ?? 1)}
          >
            Next
          </Button>
        </div>
      </div>
    </div>
  );
}
```

### Infinite Scroll

```tsx
import { useInfiniteQuery } from '@tanstack/react-query';
import { useInView } from 'react-intersection-observer';

function ActivityFeed() {
  const { ref, inView } = useInView();

  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = useInfiniteQuery({
    queryKey: ['activities'],
    queryFn: ({ pageParam }) => activityService.getAll({ cursor: pageParam, limit: 20 }),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => lastPage.nextCursor,
  });

  useEffect(() => {
    if (inView && hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  }, [inView, hasNextPage, isFetchingNextPage, fetchNextPage]);

  const activities = data?.pages.flatMap((page) => page.data) ?? [];

  return (
    <div>
      {activities.map((activity) => (
        <ActivityItem key={activity.id} activity={activity} />
      ))}
      <div ref={ref}>
        {isFetchingNextPage && <Spinner />}
      </div>
    </div>
  );
}
```

## Custom Query Hooks

### Encapsulate Queries in Custom Hooks

```tsx
// BAD: useQuery directly in components — scattered, hard to maintain
function ProjectList() {
  const { data } = useQuery({ queryKey: ['projects'], queryFn: projectService.getAll });
}

// GOOD: Custom hooks per entity/feature
// src/features/projects/hooks/useProjects.ts
export function useProjects(filters?: ProjectFilters) {
  return useQuery({
    queryKey: projectKeys.list(filters ?? {}),
    queryFn: () => projectService.getAll(filters),
  });
}

export function useProject(id: string) {
  return useQuery({
    queryKey: projectKeys.detail(id),
    queryFn: () => projectService.getById(id),
    enabled: !!id,
  });
}

export function useCreateProject() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: projectService.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: projectKeys.all });
    },
  });
}

// Usage — clean and reusable
function ProjectList() {
  const { data: projects, isLoading } = useProjects({ status: 'active' });
}

function ProjectDetail({ id }: { id: string }) {
  const { data: project, isLoading } = useProject(id);
}
```

## Error Handling

### Global Error Handler

```tsx
// src/lib/queryClient.ts
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        // Don't retry on 401/403/404
        if (error instanceof ApiError && [401, 403, 404].includes(error.status)) {
          return false;
        }
        return failureCount < 2;
      },
    },
    mutations: {
      onError: (error) => {
        // Global mutation error handler
        if (error instanceof ApiError && error.status === 401) {
          // Token expired — redirect to login
          store.dispatch(logout());
          window.location.href = '/login';
        }
      },
    },
  },
});
```

## Summary: Decision Tree

1. **Fetching API data?** → `useQuery` with typed query function
2. **Need query keys?** → Create a key factory per entity
3. **Creating/updating/deleting?** → `useMutation` + `invalidateQueries`
4. **Need instant UI update?** → Optimistic update with `onMutate` + rollback
5. **Paginated list?** → `useQuery` with page state + `placeholderData`
6. **Infinite scroll?** → `useInfiniteQuery` + intersection observer
7. **Reusing queries?** → Extract to custom hooks per feature
8. **Dependent queries?** → Use `enabled` option
9. **Auth error globally?** → Handle 401 in query client default options
10. **Stale data strategy?** → Configure `staleTime` and `gcTime` per use case
