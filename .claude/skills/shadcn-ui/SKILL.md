---
name: shadcn-ui
description: Provides shadcn/ui component patterns for React + TypeScript SaaS applications. Covers component installation, customization, composition, form integration, data tables, and theming. Must use when adding, customizing, or composing shadcn/ui components.
---

# shadcn/ui Best Practices

## Core Principle: Own Your Components

shadcn/ui is NOT a component library you install as a dependency. **It copies component source code into your project.** You own it, you customize it, you maintain it. This means you can and should modify components to fit your needs.

## Installation & Setup

### Initialize shadcn/ui

```bash
npx shadcn@latest init
```

This creates:
- `components.json` — configuration file
- `src/components/ui/` — where components live
- `src/lib/utils.ts` — the `cn()` utility

### Adding Components

```bash
# Add individual components as needed
npx shadcn@latest add button
npx shadcn@latest add card
npx shadcn@latest add dialog
npx shadcn@latest add form
npx shadcn@latest add table
npx shadcn@latest add input
npx shadcn@latest add select
npx shadcn@latest add toast

# DON'T add everything at once — only add what you need
# BAD: npx shadcn@latest add --all
```

### components.json Configuration

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"
}
```

## Component Architecture

### Layer Structure

```
src/components/
├── ui/                      # Layer 1: shadcn/ui primitives (auto-generated)
│   ├── button.tsx           # Don't modify unless necessary
│   ├── card.tsx
│   ├── dialog.tsx
│   ├── input.tsx
│   └── table.tsx
├── common/                  # Layer 2: Composed components (your patterns)
│   ├── DataTable/
│   ├── PageHeader/
│   ├── ConfirmDialog/
│   ├── LoadingButton/
│   └── EmptyState/
└── layouts/                 # Layer 3: Layout components
    ├── DashboardLayout/
    ├── AuthLayout/
    └── Sidebar/
```

### Layer Rules

```tsx
// Layer 1: shadcn/ui primitives — import from @/components/ui
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

// Layer 2: Composed components — combine primitives for reuse
import { DataTable } from '@/components/common/DataTable';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';

// Layer 3: Layouts — app-level structure
import { DashboardLayout } from '@/components/layouts/DashboardLayout';
```

## Button Patterns

### Variants and Sizes

```tsx
import { Button } from '@/components/ui/button';

// Primary actions
<Button>Save Changes</Button>
<Button size="lg">Get Started</Button>

// Secondary actions
<Button variant="secondary">Cancel</Button>
<Button variant="outline">Export</Button>

// Destructive actions
<Button variant="destructive">Delete Account</Button>

// Ghost / link-style
<Button variant="ghost">View More</Button>
<Button variant="link">Learn more</Button>

// Icon buttons
import { Plus, Trash2, Settings } from 'lucide-react';

<Button size="icon" variant="outline">
  <Settings className="h-4 w-4" />
</Button>

// Button with icon + text
<Button>
  <Plus className="mr-2 h-4 w-4" />
  Add Item
</Button>
```

### Loading Button (Composed Component)

```tsx
// src/components/common/LoadingButton/LoadingButton.tsx
import { Loader2 } from 'lucide-react';
import { Button, type ButtonProps } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface LoadingButtonProps extends ButtonProps {
  isLoading?: boolean;
}

export function LoadingButton({ isLoading, disabled, children, ...props }: LoadingButtonProps) {
  return (
    <Button disabled={isLoading || disabled} {...props}>
      {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
      {children}
    </Button>
  );
}

// Usage
<LoadingButton isLoading={isSaving} onClick={handleSave}>
  Save Changes
</LoadingButton>
```

## Dialog Patterns

### Basic Dialog

```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';

export function CreateProjectDialog() {
  const [open, setOpen] = useState(false);

  const handleSubmit = async (data: FormData) => {
    await createProject(data);
    setOpen(false); // Close on success
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Create Project</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create Project</DialogTitle>
          <DialogDescription>
            Add a new project to your workspace.
          </DialogDescription>
        </DialogHeader>
        <ProjectForm onSubmit={handleSubmit} />
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)}>
            Cancel
          </Button>
          <Button type="submit" form="project-form">
            Create
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

### Confirm Dialog (Reusable Composed Component)

```tsx
// src/components/common/ConfirmDialog/ConfirmDialog.tsx
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { buttonVariants } from '@/components/ui/button';

interface ConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: string;
  onConfirm: () => void;
  confirmText?: string;
  variant?: 'default' | 'destructive';
}

export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  onConfirm,
  confirmText = 'Confirm',
  variant = 'default',
}: ConfirmDialogProps) {
  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          <AlertDialogDescription>{description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction
            className={buttonVariants({ variant })}
            onClick={onConfirm}
          >
            {confirmText}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}

// Usage
const [showDelete, setShowDelete] = useState(false);

<ConfirmDialog
  open={showDelete}
  onOpenChange={setShowDelete}
  title="Delete Project"
  description="This action cannot be undone. This will permanently delete the project and all its data."
  confirmText="Delete"
  variant="destructive"
  onConfirm={handleDelete}
/>
```

## Form Integration (with React Hook Form + Zod)

### shadcn/ui Form Components

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';

const projectSchema = z.object({
  name: z.string().min(1, 'Name is required').max(50),
  description: z.string().max(500).optional(),
  visibility: z.enum(['public', 'private']),
});

type ProjectFormValues = z.infer<typeof projectSchema>;

export function ProjectForm({ onSubmit }: { onSubmit: (data: ProjectFormValues) => void }) {
  const form = useForm<ProjectFormValues>({
    resolver: zodResolver(projectSchema),
    defaultValues: {
      name: '',
      description: '',
      visibility: 'private',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} id="project-form" className="space-y-4">
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Project Name</FormLabel>
              <FormControl>
                <Input placeholder="My Project" {...field} />
              </FormControl>
              <FormDescription>This will be your project's display name.</FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="description"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Description</FormLabel>
              <FormControl>
                <Textarea placeholder="What's this project about?" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="visibility"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Visibility</FormLabel>
              <Select onValueChange={field.onChange} defaultValue={field.value}>
                <FormControl>
                  <SelectTrigger>
                    <SelectValue placeholder="Select visibility" />
                  </SelectTrigger>
                </FormControl>
                <SelectContent>
                  <SelectItem value="public">Public</SelectItem>
                  <SelectItem value="private">Private</SelectItem>
                </SelectContent>
              </Select>
              <FormMessage />
            </FormItem>
          )}
        />
      </form>
    </Form>
  );
}
```

## Data Table Pattern

### Using TanStack Table + shadcn/ui

```tsx
// src/components/common/DataTable/DataTable.tsx
import {
  type ColumnDef,
  flexRender,
  getCoreRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  type SortingState,
  useReactTable,
} from '@tanstack/react-table';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { useState } from 'react';

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[];
  data: TData[];
}

export function DataTable<TData, TValue>({ columns, data }: DataTableProps<TData, TValue>) {
  const [sorting, setSorting] = useState<SortingState>([]);

  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
    onSortingChange: setSorting,
    state: { sorting },
  });

  return (
    <div>
      <div className="rounded-md border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(header.column.columnDef.header, header.getContext())}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow key={row.id}>
                  {row.getVisibleCells().map((cell) => (
                    <TableCell key={cell.id}>
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-24 text-center">
                  No results.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
      <div className="flex items-center justify-end gap-2 py-4">
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.previousPage()}
          disabled={!table.getCanPreviousPage()}
        >
          Previous
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => table.nextPage()}
          disabled={!table.getCanNextPage()}
        >
          Next
        </Button>
      </div>
    </div>
  );
}
```

### Defining Columns

```tsx
// src/features/users/columns.tsx
import { type ColumnDef } from '@tanstack/react-table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { MoreHorizontal, ArrowUpDown } from 'lucide-react';

export const userColumns: ColumnDef<User>[] = [
  {
    accessorKey: 'name',
    header: ({ column }) => (
      <Button
        variant="ghost"
        onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
      >
        Name
        <ArrowUpDown className="ml-2 h-4 w-4" />
      </Button>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
  },
  {
    accessorKey: 'role',
    header: 'Role',
    cell: ({ row }) => <Badge variant="secondary">{row.getValue('role')}</Badge>,
  },
  {
    id: 'actions',
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon">
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem>Edit</DropdownMenuItem>
          <DropdownMenuItem className="text-destructive">Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
];
```

## Toast / Notifications

### Using Sonner (Recommended by shadcn/ui)

```tsx
// Setup in App providers
import { Toaster } from '@/components/ui/sonner';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <Toaster richColors position="top-right" />
    </>
  );
}

// Usage anywhere in the app
import { toast } from 'sonner';

// Success
toast.success('Project created successfully');

// Error
toast.error('Failed to save changes');

// With description
toast.success('Invitation sent', {
  description: 'An email has been sent to john@example.com',
});

// Promise-based
toast.promise(saveProject(data), {
  loading: 'Saving...',
  success: 'Project saved!',
  error: 'Failed to save project',
});

// With action
toast('File deleted', {
  action: {
    label: 'Undo',
    onClick: () => restoreFile(),
  },
});
```

## Empty States

```tsx
// src/components/common/EmptyState/EmptyState.tsx
import { type LucideIcon } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export function EmptyState({ icon: Icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center rounded-lg border border-dashed p-8 text-center">
      <div className="rounded-full bg-muted p-3">
        <Icon className="h-6 w-6 text-muted-foreground" />
      </div>
      <h3 className="mt-4 text-lg font-semibold">{title}</h3>
      <p className="mt-2 text-sm text-muted-foreground">{description}</p>
      {action && (
        <Button onClick={action.onClick} className="mt-4">
          {action.label}
        </Button>
      )}
    </div>
  );
}

// Usage
import { FolderOpen } from 'lucide-react';

<EmptyState
  icon={FolderOpen}
  title="No projects yet"
  description="Get started by creating your first project."
  action={{ label: 'Create Project', onClick: () => setShowCreateDialog(true) }}
/>
```

## CRITICAL RULE: Never Raw HTML When shadcn/ui Exists

**This is the #1 rule.** Never use raw HTML elements when a shadcn/ui component exists for the same purpose.

```tsx
// FORBIDDEN — raw HTML elements
<input type="email" placeholder="you@company.com" />
<button onClick={handleSubmit}>Submit</button>
<label htmlFor="email">Email</label>
<select onChange={handleChange}><option>A</option></select>
<textarea rows={4} />

// REQUIRED — shadcn/ui components
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Select, SelectTrigger, SelectValue, SelectContent, SelectItem } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';

<Input type="email" placeholder="you@company.com" />
<Button onClick={handleSubmit}>Submit</Button>
<Label htmlFor="email">Email</Label>
<Select onValueChange={handleChange}>
  <SelectTrigger><SelectValue /></SelectTrigger>
  <SelectContent><SelectItem value="a">A</SelectItem></SelectContent>
</Select>
<Textarea rows={4} />
```

**For forms with validation**, always use the full shadcn Form pattern:
```tsx
// FORBIDDEN — raw form pattern
<label>Email</label>
<input id="email" />
<span className="error">{errors.email}</span>

// REQUIRED — shadcn Form pattern
<FormField control={form.control} name="email" render={({ field }) => (
  <FormItem>
    <FormLabel>Email</FormLabel>
    <FormControl><Input {...field} /></FormControl>
    <FormMessage />
  </FormItem>
)} />
```

**When to install**: If a needed component isn't in `src/components/ui/`, install it:
```bash
npx shadcn@latest add input button label select textarea form
```

## Component Lookup Map (Figma Element → shadcn Component)

Use this map when selecting components for any UI element from a Figma design or story requirement.

### Buttons & Actions
| UI Element | Component | Import |
|---|---|---|
| Primary button | `<Button>` | `@/components/ui/button` |
| Secondary/outline button | `<Button variant="outline">` | `@/components/ui/button` |
| Danger/delete button | `<Button variant="destructive">` | `@/components/ui/button` |
| Ghost/text button | `<Button variant="ghost">` | `@/components/ui/button` |
| Icon button | `<Button variant="ghost" size="icon">` | `@/components/ui/button` |
| Link-style button | `<Button variant="link">` | `@/components/ui/button` |
| Toggle button | `<Toggle>` | `@/components/ui/toggle` |
| Toggle group | `<ToggleGroup>` | `@/components/ui/toggle-group` |

### Form Inputs
| UI Element | Component | Import |
|---|---|---|
| Text field | `<Input>` + `<Label>` | `input`, `label` |
| Textarea / multiline | `<Textarea>` | `@/components/ui/textarea` |
| Simple dropdown | `<Select>` | `@/components/ui/select` |
| Dropdown with search | `<Command>` inside `<Popover>` (Combobox) | `command`, `popover` |
| Checkbox | `<Checkbox>` | `@/components/ui/checkbox` |
| Radio buttons | `<RadioGroup>` | `@/components/ui/radio-group` |
| On/off toggle | `<Switch>` | `@/components/ui/switch` |
| Date picker | `<Calendar>` inside `<Popover>` | `calendar`, `popover` |
| Slider / range | `<Slider>` | `@/components/ui/slider` |
| OTP / code input | `<InputOTP>` | `@/components/ui/input-otp` |
| Full form with validation | `<Form>` (React Hook Form) | `@/components/ui/form` |

### Overlays & Popups
| UI Element | Component | Import |
|---|---|---|
| Modal / dialog | `<Dialog>` | `@/components/ui/dialog` |
| Confirmation popup | `<AlertDialog>` | `@/components/ui/alert-dialog` |
| Right-side panel | `<Sheet side="right">` | `@/components/ui/sheet` |
| Bottom sheet (mobile) | `<Sheet side="bottom">` | `@/components/ui/sheet` |
| Tooltip (on hover) | `<Tooltip>` | `@/components/ui/tooltip` |
| Popover (on click) | `<Popover>` | `@/components/ui/popover` |
| Hover preview card | `<HoverCard>` | `@/components/ui/hover-card` |
| Toast / notification | `toast()` from sonner | `sonner` |
| Command palette (Cmd+K) | `<Command>` inside `<Dialog>` | `command`, `dialog` |

### Navigation
| UI Element | Component | Import |
|---|---|---|
| Tab bar | `<Tabs>` | `@/components/ui/tabs` |
| Sidebar | `<Sidebar>` | `@/components/ui/sidebar` |
| Breadcrumbs | `<Breadcrumb>` | `@/components/ui/breadcrumb` |
| Dropdown menu | `<DropdownMenu>` | `@/components/ui/dropdown-menu` |
| Menu bar | `<Menubar>` | `@/components/ui/menubar` |
| Navigation links | `<NavigationMenu>` | `@/components/ui/navigation-menu` |
| Pagination | `<Pagination>` | `@/components/ui/pagination` |

### Data Display
| UI Element | Component | Import |
|---|---|---|
| Data table | `<DataTable>` (TanStack) | `@/components/common/data-table` |
| Simple table | `<Table>` | `@/components/ui/table` |
| Card / panel | `<Card>` | `@/components/ui/card` |
| Badge / tag | `<Badge>` | `@/components/ui/badge` |
| Avatar / profile pic | `<Avatar>` | `@/components/ui/avatar` |
| Accordion / FAQ | `<Accordion>` | `@/components/ui/accordion` |
| Chart / graph | `<Chart>` (Recharts) | `@/components/ui/chart` |
| Progress bar | `<Progress>` | `@/components/ui/progress` |
| Skeleton loader | `<Skeleton>` | `@/components/ui/skeleton` |
| Horizontal rule | `<Separator>` | `@/components/ui/separator` |
| Scrollable area | `<ScrollArea>` | `@/components/ui/scroll-area` |
| Collapsible section | `<Collapsible>` | `@/components/ui/collapsible` |
| Resizable panels | `<Resizable>` | `@/components/ui/resizable` |
| Carousel / slider | `<Carousel>` | `@/components/ui/carousel` |

### Feedback
| UI Element | Component | Import |
|---|---|---|
| Info/warning banner | `<Alert>` | `@/components/ui/alert` |
| Toast message | `toast()` | `sonner` |
| Loading spinner | `<LoadingSpinner>` | `@/components/common/loading-spinner` |
| Empty state | `<EmptyState>` | `@/components/common/empty-state` |

### shadcn Override Strategy

When a shadcn component's default styles conflict with Figma:

1. **Read the component source** (`src/components/ui/<name>.tsx`) to understand base styles
2. **Override with className**: `<Card className="rounded-lg shadow-none p-0">`
3. **Use `!important` prefix** (`!border`, `!rounded-md`) when base styles override your className
4. **Known override conflicts:**

| Component | Base Style Issue | Fix |
|---|---|---|
| `Card` | `rounded-xl` + shadow + padding | `rounded-lg shadow-none p-0` |
| `Badge` | Fixed padding/radius | `rounded-md px-2 py-0.5` |
| `Button` | Height/padding presets | `h-10 px-4` with exact Figma values |
| `InputOTPSlot` | Connected borders, no radius | `!border !rounded-md shadow-none` |
| `Separator` | Default color | `bg-[#hex]` |

5. **When overrides get complex** (3+ conflicting properties), use a plain `<div>` styled from scratch

## Anti-Patterns to Avoid

```tsx
// BAD: Installing all components upfront
npx shadcn@latest add --all // Bloats your codebase

// GOOD: Add only what you need, when you need it
npx shadcn@latest add button card dialog

// BAD: Wrapping shadcn components with no added value
function MyButton(props: ButtonProps) {
  return <Button {...props} />; // Pointless wrapper
}

// GOOD: Only wrap when adding real behavior
function LoadingButton({ isLoading, ...props }: LoadingButtonProps) {
  return <Button disabled={isLoading} {...props} />;
}

// BAD: Overriding shadcn styles with inline styles
<Button style={{ backgroundColor: 'red', borderRadius: '0' }}>Delete</Button>

// GOOD: Use variants or cn()
<Button variant="destructive" className="rounded-none">Delete</Button>

// BAD: Duplicating shadcn components instead of composing
// Creating a whole new Modal component from scratch when Dialog exists

// GOOD: Compose from shadcn primitives
// Build ConfirmDialog from AlertDialog, build DataTable from Table
```

## Summary: Decision Tree

1. **Need a UI primitive?** → Check if shadcn/ui has it, `npx shadcn@latest add <component>`
2. **Need to customize a primitive?** → Edit the file in `src/components/ui/` directly
3. **Repeated composition?** → Create a composed component in `src/components/common/`
4. **Need a form?** → Use shadcn Form + React Hook Form + Zod
5. **Need a data table?** → Use shadcn Table + TanStack Table
6. **Need notifications?** → Use Sonner via `toast()`
7. **Need confirmation?** → Build from AlertDialog, not window.confirm
8. **Need empty state?** → Create reusable EmptyState component
9. **Modifying a shadcn file?** → Keep the original API, extend with new variants
