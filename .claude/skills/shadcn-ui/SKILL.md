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
