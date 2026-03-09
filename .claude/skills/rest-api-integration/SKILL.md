---
name: rest-api-integration
description: Provides REST API integration patterns for React + TypeScript SaaS applications. Covers API client setup with Axios, interceptors, error handling, typed services, request/response transforms, and retry logic. Must use when creating API clients, service layers, or handling HTTP communication.
---

# REST API Integration Best Practices

## Core Principle: One API Client, Typed Services

Create a single, configured Axios instance as your API client. **All HTTP calls go through typed service functions** — never call `fetch()` or `axios` directly in components.

## Installation

```bash
npm install axios
```

## API Client Setup

### Configured Axios Instance

```tsx
// src/lib/apiClient.ts
import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios';
import { env } from '@/lib/env';
import { store } from '@/stores/store';
import { logout } from '@/stores/authSlice';

export const apiClient = axios.create({
  baseURL: env.VITE_API_URL,
  timeout: env.VITE_API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor — attach auth token
apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = store.getState().auth.token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor — handle errors globally
apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiErrorResponse>) => {
    // Handle 401 — token expired
    if (error.response?.status === 401) {
      store.dispatch(logout());
      window.location.href = '/login';
      return Promise.reject(error);
    }

    // Transform to typed error
    const apiError = new ApiError(
      error.response?.data?.message ?? error.message ?? 'An error occurred',
      error.response?.status ?? 500,
      error.response?.data?.errors
    );

    return Promise.reject(apiError);
  }
);
```

### Custom Error Class

```tsx
// src/lib/apiError.ts
export interface ValidationError {
  field: string;
  message: string;
}

interface ApiErrorResponse {
  message: string;
  errors?: ValidationError[];
}

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public validationErrors?: ValidationError[]
  ) {
    super(message);
    this.name = 'ApiError';
  }

  get isNotFound() {
    return this.status === 404;
  }

  get isUnauthorized() {
    return this.status === 401;
  }

  get isForbidden() {
    return this.status === 403;
  }

  get isValidationError() {
    return this.status === 422;
  }

  get isServerError() {
    return this.status >= 500;
  }
}
```

## Service Layer Pattern

### Typed Service Functions

```tsx
// BAD: API calls scattered in components with inline types
function ProjectList() {
  useEffect(() => {
    fetch('/api/projects')
      .then(res => res.json())
      .then(data => setProjects(data));
  }, []);
}

// GOOD: Centralized, typed service layer
// src/services/projectService.ts
import { apiClient } from '@/lib/apiClient';
import type { Project, CreateProjectInput, UpdateProjectInput } from '@/types';

interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

interface ProjectFilters {
  page?: number;
  pageSize?: number;
  status?: string;
  search?: string;
}

export const projectService = {
  getAll: async (filters?: ProjectFilters): Promise<PaginatedResponse<Project>> => {
    const { data } = await apiClient.get('/projects', { params: filters });
    return data;
  },

  getById: async (id: string): Promise<Project> => {
    const { data } = await apiClient.get(`/projects/${id}`);
    return data;
  },

  create: async (input: CreateProjectInput): Promise<Project> => {
    const { data } = await apiClient.post('/projects', input);
    return data;
  },

  update: async (id: string, input: UpdateProjectInput): Promise<Project> => {
    const { data } = await apiClient.patch(`/projects/${id}`, input);
    return data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/projects/${id}`);
  },
};
```

### Service Layer Organization

```
src/services/
├── authService.ts       # Login, register, refresh token
├── projectService.ts    # Project CRUD
├── userService.ts       # User management
├── teamService.ts       # Team/org management
├── billingService.ts    # Subscription, invoices
└── uploadService.ts     # File uploads
```

## Request/Response Types

### Shared API Types

```tsx
// src/types/api.ts

// Generic paginated response
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

// Generic list response with cursor pagination
export interface CursorPaginatedResponse<T> {
  data: T[];
  nextCursor?: string;
  hasMore: boolean;
}

// Standard success response
export interface ApiResponse<T> {
  data: T;
  message?: string;
}

// Common query params
export interface PaginationParams {
  page?: number;
  pageSize?: number;
}

export interface SortParams {
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface SearchParams {
  search?: string;
}

export type ListParams = PaginationParams & SortParams & SearchParams;
```

### Entity Types

```tsx
// src/types/entities.ts
export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  avatarUrl?: string;
  createdAt: string;
}

export interface Project {
  id: string;
  name: string;
  slug: string;
  description?: string;
  status: ProjectStatus;
  ownerId: string;
  createdAt: string;
  updatedAt: string;
}

// Input types — what we send to the API (subset of entity)
export interface CreateProjectInput {
  name: string;
  slug: string;
  description?: string;
}

export type UpdateProjectInput = Partial<CreateProjectInput>;
```

## Token Refresh Pattern

### Automatic Token Refresh

```tsx
// src/lib/apiClient.ts
import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios';

let isRefreshing = false;
let failedQueue: Array<{
  resolve: (token: string) => void;
  reject: (error: unknown) => void;
}> = [];

function processQueue(error: unknown, token: string | null) {
  failedQueue.forEach(({ resolve, reject }) => {
    if (token) {
      resolve(token);
    } else {
      reject(error);
    }
  });
  failedQueue = [];
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // Queue this request until refresh completes
        return new Promise((resolve, reject) => {
          failedQueue.push({
            resolve: (token: string) => {
              originalRequest.headers.Authorization = `Bearer ${token}`;
              resolve(apiClient(originalRequest));
            },
            reject,
          });
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        const { data } = await axios.post(`${env.VITE_API_URL}/auth/refresh`, {
          refreshToken,
        });

        const newToken = data.token;
        store.dispatch(setCredentials({ user: data.user, token: newToken }));
        processQueue(null, newToken);

        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return apiClient(originalRequest);
      } catch (refreshError) {
        processQueue(refreshError, null);
        store.dispatch(logout());
        window.location.href = '/login';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  }
);
```

## File Upload

```tsx
// src/services/uploadService.ts
export const uploadService = {
  uploadFile: async (
    file: File,
    onProgress?: (percent: number) => void
  ): Promise<{ url: string }> => {
    const formData = new FormData();
    formData.append('file', file);

    const { data } = await apiClient.post('/uploads', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      onUploadProgress: (event) => {
        if (event.total && onProgress) {
          const percent = Math.round((event.loaded * 100) / event.total);
          onProgress(percent);
        }
      },
    });

    return data;
  },

  uploadAvatar: async (file: File): Promise<{ url: string }> => {
    // Validate before uploading
    if (file.size > 5 * 1024 * 1024) {
      throw new Error('File must be under 5MB');
    }
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      throw new Error('Only JPEG, PNG, and WebP images are allowed');
    }
    return uploadService.uploadFile(file);
  },
};

// Usage with progress
function AvatarUpload() {
  const [progress, setProgress] = useState(0);

  const uploadMutation = useMutation({
    mutationFn: (file: File) => uploadService.uploadAvatar(file, setProgress),
    onSuccess: (data) => {
      dispatch(updateUser({ avatarUrl: data.url }));
      toast.success('Avatar updated');
    },
  });

  return (
    <div>
      <input type="file" accept="image/*" onChange={(e) => {
        const file = e.target.files?.[0];
        if (file) uploadMutation.mutate(file);
      }} />
      {uploadMutation.isPending && <Progress value={progress} />}
    </div>
  );
}
```

## Anti-Patterns to Avoid

```tsx
// BAD: Direct API calls in components
function UserList() {
  useEffect(() => {
    axios.get('http://localhost:3001/api/users')  // Hardcoded URL!
      .then(res => setUsers(res.data));            // No error handling!
  }, []);
}

// BAD: Repeating headers/config in every call
axios.get('/api/users', {
  headers: { Authorization: `Bearer ${token}` },
  timeout: 30000,
});

// BAD: Catching errors silently
try {
  await apiClient.post('/projects', data);
} catch {
  // Swallowed error — user sees nothing!
}

// BAD: Using fetch and axios in the same project
fetch('/api/users');        // Some places use fetch
apiClient.get('/projects'); // Others use axios
// Pick one and stick with it!

// BAD: Putting API URLs in components
const API_URL = 'https://api.myapp.com';
fetch(`${API_URL}/users`);
// Use env.VITE_API_URL + apiClient!
```

## Summary: Decision Tree

1. **Making HTTP calls?** → Always go through `apiClient` (configured Axios instance)
2. **Need auth headers?** → Request interceptor handles it automatically
3. **Handling errors?** → Response interceptor transforms to `ApiError`
4. **Creating API functions?** → One service file per entity/domain
5. **Typing responses?** → Define types in `src/types/`, use in service return types
6. **Token expired?** → Auto-refresh with queue pattern in interceptor
7. **Uploading files?** → `FormData` + `onUploadProgress` callback
8. **Need pagination?** → Use `PaginatedResponse<T>` generic type
9. **Calling from components?** → Through TanStack Query hooks that call services
10. **Need retry?** → Configure in TanStack Query, not in Axios
