---
name: react-typescript
description: Provides React component patterns with strict TypeScript conventions. Covers component structure, typing, hooks, state management, generics, and anti-patterns. Must use when creating, reading, or writing React components (.tsx, .jsx files) with TypeScript.
---

# React + TypeScript Best Practices

## Pair with Other Skills

When working with React + TypeScript, always load relevant skills together: `redux-toolkit` for state, `tanstack-query` for server state, `react-hook-form-zod` for forms, `shadcn-ui` for components.

## Core Principle: Type Safety First

Every component, hook, and utility must be fully typed. **No `any`, no shortcuts, no type casting without justification.** TypeScript should catch bugs at compile time, not runtime.

## Component Structure

### File Organization

Every component gets its own folder with co-located files:

```
src/components/common/UserProfile/
├── UserProfile.tsx          # Main component
├── UserProfile.test.tsx     # Unit tests
├── UserProfile.types.ts     # Types/interfaces (if complex)
└── index.ts                 # Re-export
```

### Placement Rules

- `ui` → `src/components/ui/` (shadcn/ui wrappers, atomic elements)
- `common` → `src/components/common/` (shared across features)
- `feature` → `src/features/{feature-name}/components/`
- `page` → `src/pages/` or `src/features/{feature-name}/pages/`

### Component Declaration

```tsx
// BAD: Using React.FC (doesn't support generics, implicit children)
const UserProfile: React.FC<Props> = ({ userId }) => {
  return <div>{userId}</div>;
};

// BAD: Default export
export default function UserProfile({ userId }: Props) {
  return <div>{userId}</div>;
}

// GOOD: Named function declaration with named export
export function UserProfile({ userId, onUpdate, children }: UserProfileProps) {
  return <div>{children}</div>;
}
```

### Props Interface

```tsx
// BAD: Inline types, no JSDoc
export function UserProfile({ userId, onUpdate }: { userId: string; onUpdate: (u: User) => void }) {
  return <div />;
}

// GOOD: Separate interface with JSDoc
interface UserProfileProps {
  /** The unique user identifier */
  userId: string;
  /** Callback fired when profile is successfully updated */
  onUpdate?: (user: User) => void;
  /** Child elements to render inside the profile card */
  children?: React.ReactNode;
}

export function UserProfile({ userId, onUpdate, children }: UserProfileProps) {
  return <div>{children}</div>;
}
```

### Index Re-export

```ts
// Always use named exports — never default
export { UserProfile } from './UserProfile';
export type { UserProfileProps } from './UserProfile.types';
```

## TypeScript Patterns

### No `any` — Use `unknown` with Type Narrowing

```tsx
// BAD: Using any
function processData(data: any) {
  return data.name.toUpperCase();
}

// GOOD: Using unknown with type guard
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'name' in data &&
    typeof (data as { name: unknown }).name === 'string'
  );
}

function processData(data: unknown) {
  if (isUser(data)) {
    return data.name.toUpperCase(); // Type-safe
  }
  throw new Error('Invalid data');
}
```

### No `enum` — Use `as const` Objects or Union Types

```tsx
// BAD: TypeScript enum
enum UserRole {
  Admin = 'admin',
  Editor = 'editor',
  Viewer = 'viewer',
}

// GOOD: as const object (iterable, works at runtime)
const USER_ROLES = {
  Admin: 'admin',
  Editor: 'editor',
  Viewer: 'viewer',
} as const;

type UserRole = (typeof USER_ROLES)[keyof typeof USER_ROLES];
// Result: 'admin' | 'editor' | 'viewer'

// GOOD: Simple union (when you don't need runtime iteration)
type UserRole = 'admin' | 'editor' | 'viewer';
```

### No Type Casting — Use Type Guards

```tsx
// BAD: Casting with as
const user = apiResponse as User;

// GOOD: Type guard with validation
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data
  );
}

const data = apiResponse;
if (isUser(data)) {
  // data is now typed as User
  console.log(data.email);
}
```

### Discriminated Unions for State

```tsx
// BAD: Multiple booleans
interface DataState {
  isLoading: boolean;
  isError: boolean;
  data: User[] | null;
  error: string | null;
}

// GOOD: Discriminated union — impossible states are impossible
type DataState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };

function UserList() {
  const [state, setState] = useState<DataState<User[]>>({ status: 'idle' });

  switch (state.status) {
    case 'idle':
      return <p>Ready to load</p>;
    case 'loading':
      return <Spinner />;
    case 'success':
      return <List items={state.data} />; // data is guaranteed here
    case 'error':
      return <ErrorMessage message={state.error} />; // error is guaranteed here
  }
}
```

### Extending Native HTML Props

```tsx
// BAD: Manually defining HTML attributes
interface ButtonProps {
  onClick?: () => void;
  disabled?: boolean;
  className?: string;
  type?: 'button' | 'submit';
  children: React.ReactNode;
}

// GOOD: Extend native props, override what you need
interface ButtonProps extends React.ComponentPropsWithoutRef<'button'> {
  /** Visual style variant */
  variant?: 'primary' | 'secondary' | 'destructive';
  /** Size of the button */
  size?: 'sm' | 'md' | 'lg';
  /** Show loading spinner and disable */
  isLoading?: boolean;
}

export function Button({ variant = 'primary', size = 'md', isLoading, children, ...rest }: ButtonProps) {
  return (
    <button disabled={isLoading || rest.disabled} {...rest}>
      {isLoading ? <Spinner /> : children}
    </button>
  );
}
```

### Generics for Reusable Components

```tsx
// BAD: Hardcoded type
interface SelectProps {
  options: { label: string; value: string }[];
  onChange: (value: string) => void;
}

// GOOD: Generic — works with any type
interface SelectProps<T> {
  options: T[];
  getLabel: (option: T) => string;
  getValue: (option: T) => string;
  onChange: (option: T) => void;
}

export function Select<T>({ options, getLabel, getValue, onChange }: SelectProps<T>) {
  return (
    <select onChange={(e) => {
      const selected = options.find((opt) => getValue(opt) === e.target.value);
      if (selected) onChange(selected);
    }}>
      {options.map((option) => (
        <option key={getValue(option)} value={getValue(option)}>
          {getLabel(option)}
        </option>
      ))}
    </select>
  );
}

// Usage — TypeScript infers T automatically
<Select
  options={users}
  getLabel={(u) => u.name}
  getValue={(u) => u.id}
  onChange={(u) => setSelectedUser(u)} // u is typed as User
/>
```

## Hooks Patterns

### Custom Hook Naming and Structure

```tsx
// BAD: Custom hook that doesn't use hooks
function useFormatDate(date: Date) {
  return date.toLocaleDateString(); // No hooks used!
}

// GOOD: Regular utility function
function formatDate(date: Date): string {
  return date.toLocaleDateString();
}

// GOOD: Actual custom hook using hooks
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}
```

### Custom Hook with Return Type

```tsx
// BAD: Untyped return
function useAuth() {
  const [user, setUser] = useState(null);
  return { user, setUser, isLoggedIn: !!user };
}

// GOOD: Explicitly typed return
interface UseAuthReturn {
  user: User | null;
  isLoggedIn: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
}

function useAuth(): UseAuthReturn {
  const [user, setUser] = useState<User | null>(null);

  const login = async (credentials: LoginCredentials) => {
    const userData = await authService.login(credentials);
    setUser(userData);
  };

  const logout = () => {
    authService.logout();
    setUser(null);
  };

  return { user, isLoggedIn: !!user, login, logout };
}
```

## State Management Rules

### Choose the Right Tool

```tsx
// LOCAL STATE: UI-only concerns (modals, toggles, form inputs)
const [isOpen, setIsOpen] = useState(false);
const [searchQuery, setSearchQuery] = useState('');

// REDUX TOOLKIT: Global/shared app state (auth, theme, sidebar)
const user = useSelector(selectCurrentUser);
const dispatch = useDispatch();
dispatch(setTheme('dark'));

// TANSTACK QUERY: Server state (API data, caching, sync)
const { data: users, isLoading } = useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
});
```

### Derived State — Calculate, Don't Store

```tsx
// BAD: Storing derived state
const [items, setItems] = useState<Item[]>([]);
const [filteredItems, setFilteredItems] = useState<Item[]>([]);
const [totalPrice, setTotalPrice] = useState(0);

useEffect(() => {
  setFilteredItems(items.filter((i) => i.active));
}, [items]);

useEffect(() => {
  setTotalPrice(filteredItems.reduce((sum, i) => sum + i.price, 0));
}, [filteredItems]);

// GOOD: Calculate during render
const [items, setItems] = useState<Item[]>([]);
const filteredItems = items.filter((i) => i.active);
const totalPrice = filteredItems.reduce((sum, i) => sum + i.price, 0);

// GOOD: useMemo if actually expensive (measure first!)
const filteredItems = useMemo(
  () => items.filter((i) => i.active),
  [items]
);
```

## Event Handler Conventions

```tsx
// BAD: Inconsistent naming
function UserCard({ click, onSave }: Props) {
  const save = () => { /* ... */ };
  return <button onClick={save}>Save</button>;
}

// GOOD: handle* internally, on* in props
interface UserCardProps {
  onSave: (user: User) => void;
  onDelete: (userId: string) => void;
}

function UserCard({ onSave, onDelete }: UserCardProps) {
  const handleSave = () => {
    const updatedUser = validateAndTransform();
    onSave(updatedUser);
  };

  const handleDelete = () => {
    if (confirm('Are you sure?')) {
      onDelete(user.id);
    }
  };

  return (
    <>
      <button onClick={handleSave}>Save</button>
      <button onClick={handleDelete}>Delete</button>
    </>
  );
}
```

## Composition Over Prop Drilling

```tsx
// BAD: Prop drilling
<App user={user}>
  <Layout user={user}>
    <Header user={user}>
      <Avatar user={user} />
    </Header>
  </Layout>
</App>

// GOOD: Composition with children/render props
<App>
  <Layout>
    <Header avatar={<Avatar user={user} />} />
  </Layout>
</App>

// GOOD: Context for truly global state
const UserContext = createContext<User | null>(null);

function useUser() {
  const user = useContext(UserContext);
  if (!user) throw new Error('useUser must be within UserProvider');
  return user;
}
```

## Code Splitting

```tsx
// BAD: Eager loading all pages
import { Dashboard } from '@/pages/Dashboard';
import { Settings } from '@/pages/Settings';
import { Analytics } from '@/pages/Analytics';

// GOOD: Lazy loading at route level
const Dashboard = lazy(() => import('@/pages/Dashboard'));
const Settings = lazy(() => import('@/pages/Settings'));
const Analytics = lazy(() => import('@/pages/Analytics'));

function AppRoutes() {
  return (
    <Suspense fallback={<PageSkeleton />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/analytics" element={<Analytics />} />
      </Routes>
    </Suspense>
  );
}
```

## Summary: Decision Tree

1. **Typing a component?** → Named export + interface for props + no React.FC
2. **Need a reusable component?** → Use generics
3. **Extending HTML element?** → Use `ComponentPropsWithoutRef<'element'>`
4. **Need constants?** → Use `as const` object, not `enum`
5. **Handling unknown data?** → Use `unknown` + type guard, not `any`
6. **State for UI only?** → `useState`
7. **State shared globally?** → Redux Toolkit
8. **State from API?** → TanStack Query
9. **Computed value?** → Calculate during render (useMemo if expensive)
10. **Reusable logic with hooks?** → Custom hook in `src/hooks/`
11. **Reusable logic without hooks?** → Plain utility function in `src/lib/`
