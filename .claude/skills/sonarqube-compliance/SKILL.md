---
name: sonarqube-compliance
description: Provides SonarQube code quality compliance patterns for React + TypeScript SaaS applications. Covers code smells, cognitive complexity, duplication, naming conventions, dead code, security hotspots, and maintainability. Must use when writing code to ensure it passes SonarQube quality gates without issues.
---

# SonarQube Compliance Best Practices

## Core Principle: Write Clean Code That Passes Quality Gates

SonarQube flags code smells, bugs, vulnerabilities, and maintainability issues. **Write code that's clean from the start** — don't fix SonarQube issues after the fact. Every function, component, and module should be simple, readable, and well-structured.

## Cognitive Complexity (Max: 15)

SonarQube's most important metric. Measures how hard code is to understand. **Keep every function's cognitive complexity under 15.**

### What Increases Complexity

```tsx
// Each of these adds +1 complexity:
// if, else if, else, switch, for, while, do-while, catch
// &&, ||, ternary (?)
// Nesting adds additional +1 per level

// BAD: Cognitive complexity = 21 (SonarQube will flag this)
function processOrder(order: Order, user: User): string {
  if (order.items.length === 0) {                    // +1
    return 'empty';
  }
  if (user.isBlocked) {                              // +1
    return 'blocked';
  }
  let total = 0;
  for (const item of order.items) {                  // +1
    if (item.quantity > 0) {                         // +2 (nesting)
      if (item.price > 100) {                        // +3 (nesting)
        total += item.price * item.quantity * 0.9;
      } else {                                       // +1
        total += item.price * item.quantity;
      }
      if (item.isFragile) {                          // +3 (nesting)
        total += 5;
        if (item.weight > 10) {                      // +4 (nesting)
          total += 10;
        }
      }
    }
  }
  if (user.isPremium && total > 50) {                // +1 +1 (&&)
    total *= 0.95;
  } else if (total > 200) {                          // +1
    total *= 0.97;
  }
  return total.toFixed(2);
}

// GOOD: Cognitive complexity = 4 (extracted into focused functions)
function processOrder(order: Order, user: User): string {
  if (order.items.length === 0) return 'empty';      // +1
  if (user.isBlocked) return 'blocked';              // +1

  const subtotal = calculateSubtotal(order.items);
  const total = applyDiscount(subtotal, user);
  return total.toFixed(2);
}

function calculateSubtotal(items: OrderItem[]): number {
  return items
    .filter((item) => item.quantity > 0)
    .reduce((sum, item) => {
      const itemTotal = calculateItemTotal(item);
      const shipping = calculateShipping(item);
      return sum + itemTotal + shipping;
    }, 0);
}

function calculateItemTotal(item: OrderItem): number {
  const discount = item.price > 100 ? 0.9 : 1;      // +1
  return item.price * item.quantity * discount;
}

function calculateShipping(item: OrderItem): number {
  if (!item.isFragile) return 0;                     // +1
  return item.weight > 10 ? 15 : 5;                 // +1
}

function applyDiscount(total: number, user: User): number {
  if (user.isPremium && total > 50) return total * 0.95;  // +1 +1
  if (total > 200) return total * 0.97;                    // +1
  return total;
}
```

### Reducing Complexity Patterns

```tsx
// BAD: Nested if/else chain
function getStatusLabel(status: string, role: string): string {
  if (status === 'active') {                       // +1
    if (role === 'admin') {                        // +2
      return 'Active (Admin)';
    } else if (role === 'member') {                // +1
      return 'Active (Member)';
    } else {                                       // +1
      return 'Active';
    }
  } else if (status === 'inactive') {              // +1
    return 'Inactive';
  } else if (status === 'banned') {                // +1
    return 'Banned';
  }
  return 'Unknown';
}

// GOOD: Early returns + lookup map (complexity = 2)
const STATUS_LABELS: Record<string, string> = {
  inactive: 'Inactive',
  banned: 'Banned',
};

const ACTIVE_ROLE_LABELS: Record<string, string> = {
  admin: 'Active (Admin)',
  member: 'Active (Member)',
};

function getStatusLabel(status: string, role: string): string {
  if (status !== 'active') {                       // +1
    return STATUS_LABELS[status] ?? 'Unknown';
  }
  return ACTIVE_ROLE_LABELS[role] ?? 'Active';
}
```

## Code Duplication (DRY)

SonarQube flags duplicated blocks of code (typically 10+ duplicated lines or 3+ duplicated statements).

```tsx
// BAD: Duplicated fetch + error handling pattern
async function fetchUsers() {
  try {
    const response = await apiClient.get('/users');
    if (!response.data) throw new Error('No data');
    return response.data;
  } catch (error) {
    console.error('Failed to fetch users:', error);
    toast.error('Failed to load users');
    throw error;
  }
}

async function fetchProjects() {
  try {
    const response = await apiClient.get('/projects');
    if (!response.data) throw new Error('No data');
    return response.data;
  } catch (error) {
    console.error('Failed to fetch projects:', error);
    toast.error('Failed to load projects');
    throw error;
  }
}

// GOOD: Extract common pattern into a shared function
async function fetchEntity<T>(endpoint: string, label: string): Promise<T> {
  try {
    const response = await apiClient.get<T>(endpoint);
    if (!response.data) throw new Error('No data');
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch ${label}:`, error);
    toast.error(`Failed to load ${label}`);
    throw error;
  }
}

const fetchUsers = () => fetchEntity<User[]>('/users', 'users');
const fetchProjects = () => fetchEntity<Project[]>('/projects', 'projects');
```

```tsx
// BAD: Duplicated JSX patterns
function AdminDashboard() {
  return (
    <div>
      <div className="rounded-lg border p-4">
        <h3 className="text-lg font-semibold">Total Users</h3>
        <p className="text-3xl font-bold">{userCount}</p>
        <p className="text-sm text-muted-foreground">+12% from last month</p>
      </div>
      <div className="rounded-lg border p-4">
        <h3 className="text-lg font-semibold">Total Revenue</h3>
        <p className="text-3xl font-bold">{revenue}</p>
        <p className="text-sm text-muted-foreground">+8% from last month</p>
      </div>
      <div className="rounded-lg border p-4">
        <h3 className="text-lg font-semibold">Active Projects</h3>
        <p className="text-3xl font-bold">{projectCount}</p>
        <p className="text-sm text-muted-foreground">+3% from last month</p>
      </div>
    </div>
  );
}

// GOOD: Extract reusable component
interface StatCardProps {
  title: string;
  value: string | number;
  change: string;
}

function StatCard({ title, value, change }: StatCardProps) {
  return (
    <div className="rounded-lg border p-4">
      <h3 className="text-lg font-semibold">{title}</h3>
      <p className="text-3xl font-bold">{value}</p>
      <p className="text-sm text-muted-foreground">{change}</p>
    </div>
  );
}

function AdminDashboard() {
  return (
    <div>
      <StatCard title="Total Users" value={userCount} change="+12% from last month" />
      <StatCard title="Total Revenue" value={revenue} change="+8% from last month" />
      <StatCard title="Active Projects" value={projectCount} change="+3% from last month" />
    </div>
  );
}
```

## Function Length (Max: 40 lines)

SonarQube flags functions longer than ~40 lines. Break large functions into smaller, named helper functions.

```tsx
// BAD: 80-line function doing too many things
function handleFormSubmit(data: FormValues) {
  // validate...    (10 lines)
  // transform...   (15 lines)
  // call API...    (10 lines)
  // update state.. (15 lines)
  // show toast...  (5 lines)
  // navigate...    (5 lines)
  // analytics...   (10 lines)
}

// GOOD: Composed from focused helper functions
async function handleFormSubmit(data: FormValues) {
  const validated = validateAndTransform(data);
  const result = await submitToApi(validated);
  updateLocalState(result);
  showSuccessFeedback();
  navigateToResult(result.id);
  trackAnalytics('form_submitted', result);
}
```

## Parameter Count (Max: 4)

```tsx
// BAD: Too many parameters (SonarQube flags > 4)
function createUser(
  name: string,
  email: string,
  role: string,
  department: string,
  isActive: boolean,
  avatarUrl: string
): User { ... }

// GOOD: Use an object parameter
interface CreateUserInput {
  name: string;
  email: string;
  role: string;
  department: string;
  isActive: boolean;
  avatarUrl?: string;
}

function createUser(input: CreateUserInput): User { ... }
```

## Dead Code

SonarQube flags unreachable code, unused imports, unused variables, and commented-out code.

```tsx
// BAD: Dead code that SonarQube will flag

// Unreachable code after return
function getValue(flag: boolean): string {
  return 'active';
  console.log('unreachable');  // SonarQube: Remove this unreachable code
}

// Unused variable
const unusedConfig = { timeout: 5000 };  // SonarQube: Remove unused variable

// Commented-out code
// function oldImplementation() {
//   return fetch('/api/old');
// }

// Unused import
import { format, parse } from 'date-fns';  // parse is never used

// GOOD: Remove all dead code — version control has the history
import { format } from 'date-fns';

function getValue(): string {
  return 'active';
}
```

## Naming Conventions

```tsx
// SonarQube enforces consistent naming

// BAD: Inconsistent or unclear names
const x = getUserData();           // Single-letter variable
const data = fetchUsers();         // Generic "data"
const flag = true;                 // Unclear boolean
const arr = [1, 2, 3];            // Abbreviation
function doStuff() { ... }        // Vague function name
const handleIt = () => { ... };   // Unclear handler

// GOOD: Descriptive, consistent names
const currentUser = getUserData();
const users = fetchUsers();
const isVisible = true;            // Boolean starts with is/has/should/can
const numbers = [1, 2, 3];
function validateEmail(email: string) { ... }
const handleDeleteProject = () => { ... };

// Naming patterns
// Variables/functions: camelCase
const userName = 'John';
function getUserById(id: string) { ... }

// Components: PascalCase
function UserProfile() { ... }

// Constants: UPPER_SNAKE_CASE
const MAX_RETRY_COUNT = 3;
const API_TIMEOUT_MS = 30000;

// Types/Interfaces: PascalCase
interface UserProfile { ... }
type UserRole = 'admin' | 'member';

// Boolean naming: is/has/should/can prefix
const isLoading = true;
const hasPermission = false;
const shouldShowBanner = true;
const canDelete = user.role === 'admin';
```

## Security Hotspots

SonarQube raises security hotspots for patterns that need human review.

```tsx
// HOTSPOT: Hardcoded credentials
const API_KEY = 'sk-1234567890';  // SonarQube: Hardcoded secret
// FIX: Use environment variables
const apiKey = env.VITE_API_KEY;

// HOTSPOT: innerHTML usage
element.innerHTML = userInput;     // SonarQube: XSS risk
// FIX: Use DOMPurify or React's JSX escaping
element.textContent = userInput;

// HOTSPOT: Insecure random
const token = Math.random().toString(36);  // SonarQube: Not cryptographically secure
// FIX: Use crypto API
const token = crypto.randomUUID();

// HOTSPOT: Unvalidated redirect
window.location.href = userProvidedUrl;    // SonarQube: Open redirect
// FIX: Validate URL against allowlist
const ALLOWED_ORIGINS = ['https://myapp.com', 'https://api.myapp.com'];
function safeRedirect(url: string) {
  try {
    const parsed = new URL(url);
    if (ALLOWED_ORIGINS.includes(parsed.origin)) {
      window.location.href = url;
    }
  } catch {
    window.location.href = '/';
  }
}

// HOTSPOT: Console logging in production
console.log('Debug:', data);  // SonarQube: Remove console statement
// FIX: Use proper logging or guard with environment check
if (import.meta.env.DEV) {
  console.log('Debug:', data);
}
```

## Promise Handling

```tsx
// BAD: Unhandled promise (SonarQube: Promise returned but not awaited)
function handleClick() {
  saveData();  // Returns a promise but not awaited!
}

// GOOD: Always handle promises
async function handleClick() {
  await saveData();
}

// Or explicitly handle without await
function handleClick() {
  saveData().catch((error) => {
    toast.error(getErrorMessage(error));
  });
}

// BAD: Empty catch block
try {
  await riskyOperation();
} catch (error) {
  // SonarQube: Empty catch block
}

// GOOD: At minimum, log the error
try {
  await riskyOperation();
} catch (error) {
  console.error('Operation failed:', error);
}
```

## Switch Statements

```tsx
// BAD: Switch without default (SonarQube flags this)
switch (status) {
  case 'active': return 'Active';
  case 'inactive': return 'Inactive';
  // No default!
}

// BAD: Switch with fall-through (SonarQube flags this)
switch (status) {
  case 'active':
  case 'pending':
    doSomething();  // Intentional fall-through? Not clear
  case 'inactive':
    doOther();
    break;
}

// GOOD: Always include default, no fall-through
switch (status) {
  case 'active':
    return 'Active';
  case 'inactive':
    return 'Inactive';
  case 'pending':
    return 'Pending';
  default:
    return 'Unknown';
}

// BETTER: Use a lookup map instead of switch
const STATUS_LABELS: Record<string, string> = {
  active: 'Active',
  inactive: 'Inactive',
  pending: 'Pending',
};

function getStatusLabel(status: string): string {
  return STATUS_LABELS[status] ?? 'Unknown';
}
```

## React-Specific SonarQube Rules

```tsx
// BAD: Array index as key (SonarQube: Do not use Array index in keys)
{items.map((item, index) => (
  <li key={index}>{item.name}</li>
))}

// GOOD: Use stable, unique identifier
{items.map((item) => (
  <li key={item.id}>{item.name}</li>
))}

// BAD: State update in render (SonarQube: Side effect in render)
function Component() {
  const [count, setCount] = useState(0);
  setCount(count + 1);  // Called during render!
  return <div>{count}</div>;
}

// BAD: Missing dependency in useEffect
useEffect(() => {
  fetchData(userId);
}, []);  // SonarQube: Missing dependency 'userId'

// GOOD: Include all dependencies
useEffect(() => {
  fetchData(userId);
}, [userId]);

// BAD: Constructing JSX in loops without extracting components
function UserList({ users }: Props) {
  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>
          {/* 30 lines of JSX per item */}
          <div className="...">
            <div>...</div>
            <div>...</div>
            {/* ... more nested JSX */}
          </div>
        </li>
      ))}
    </ul>
  );
}

// GOOD: Extract into a separate component
function UserListItem({ user }: { user: User }) {
  return (
    <li>
      <div className="...">...</div>
    </li>
  );
}

function UserList({ users }: Props) {
  return (
    <ul>
      {users.map((user) => (
        <UserListItem key={user.id} user={user} />
      ))}
    </ul>
  );
}
```

## Equality and Type Checks

```tsx
// BAD: Loose equality (SonarQube: Use === instead of ==)
if (value == null) { ... }
if (status == 'active') { ... }

// GOOD: Strict equality always
if (value === null || value === undefined) { ... }
if (status === 'active') { ... }

// SHORTCUT: Nullish check (SonarQube accepts this)
if (value == null) { ... }  // Only exception: == null checks both null and undefined
// Better: Use optional chaining or nullish coalescing
const name = user?.name ?? 'Unknown';
```

## File and Module Structure

```tsx
// SonarQube flags files that are too large (typically > 300 lines)

// BAD: Single file with component + hooks + utils + types + constants
// UserProfile.tsx — 500 lines

// GOOD: Split into focused files
// UserProfile.tsx — component (< 100 lines)
// UserProfile.types.ts — types
// useUserProfile.ts — custom hook
// userProfileUtils.ts — utility functions

// SonarQube flags too many imports (typically > 15)
// If you need 20+ imports, your component is doing too much — split it
```

## Summary: Decision Tree

1. **Writing a function?** → Keep cognitive complexity < 15, length < 40 lines
2. **Function has > 4 params?** → Use an object parameter instead
3. **Nested if/else?** → Early returns + lookup maps + extract helper functions
4. **Duplicated code?** → Extract shared function or component
5. **Switch statement?** → Always include default, prefer lookup maps
6. **Boolean variable?** → Name with is/has/should/can prefix
7. **Promise returned?** → Always await or .catch() — never fire-and-forget
8. **Catch block?** → Never empty — at minimum log the error
9. **Array rendering?** → Use stable `key` (never array index)
10. **File too large?** → Split: component, hooks, utils, types into separate files
11. **Dead code?** → Delete it — git has the history
12. **Console.log?** → Guard with `import.meta.env.DEV` or remove
