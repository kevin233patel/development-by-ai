---
name: react-hook-form-zod
description: Provides React Hook Form + Zod patterns for React + TypeScript SaaS applications. Covers form setup, schema validation, field arrays, multi-step forms, server errors, and shadcn/ui form integration. Must use when creating or modifying forms, validation logic, or form state management.
---

# React Hook Form + Zod Best Practices

## Core Principle: Schema-First Validation

Define your validation schema with Zod first, then infer TypeScript types from it. **The Zod schema is the single source of truth** for both runtime validation and compile-time types.

## Installation

```bash
npm install react-hook-form @hookform/resolvers zod
```

## Schema-First Approach

### Define Schema, Infer Types

```tsx
// BAD: Separate types and validation — they drift apart
interface FormValues {
  name: string;
  email: string;
  role: 'admin' | 'member';
}
// Validation rules defined elsewhere, may not match...

// GOOD: Single source of truth with Zod
import { z } from 'zod';

export const createUserSchema = z.object({
  name: z.string().min(1, 'Name is required').max(100, 'Name too long'),
  email: z.string().email('Invalid email address'),
  role: z.enum(['admin', 'member', 'viewer'], {
    required_error: 'Please select a role',
  }),
  bio: z.string().max(500, 'Bio must be under 500 characters').optional(),
});

// Infer the type — always in sync with validation
export type CreateUserInput = z.infer<typeof createUserSchema>;
// Result: { name: string; email: string; role: 'admin' | 'member' | 'viewer'; bio?: string }
```

## Basic Form Setup

### With shadcn/ui Form Components

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
import { Button } from '@/components/ui/button';

const loginSchema = z.object({
  email: z.string().email('Please enter a valid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type LoginInput = z.infer<typeof loginSchema>;

export function LoginForm({ onSubmit }: { onSubmit: (data: LoginInput) => Promise<void> }) {
  const form = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" placeholder="john@example.com" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input type="password" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" className="w-full" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? 'Signing in...' : 'Sign In'}
        </Button>
      </form>
    </Form>
  );
}
```

## Common Zod Patterns

### Field Validations

```tsx
// String validations
z.string().min(1, 'Required')                    // Required field
z.string().email('Invalid email')                 // Email
z.string().url('Invalid URL')                     // URL
z.string().regex(/^[a-z0-9-]+$/, 'Only lowercase letters, numbers, and hyphens')

// Number validations
z.coerce.number().min(0, 'Must be positive')      // Coerce string to number from input
z.coerce.number().int('Must be a whole number')

// Date validations
z.coerce.date().min(new Date(), 'Must be in the future')

// Password with multiple rules
const passwordSchema = z
  .string()
  .min(8, 'At least 8 characters')
  .regex(/[A-Z]/, 'At least one uppercase letter')
  .regex(/[a-z]/, 'At least one lowercase letter')
  .regex(/[0-9]/, 'At least one number');

// Confirm password
const signupSchema = z
  .object({
    password: passwordSchema,
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

// Conditional validation
const profileSchema = z.discriminatedUnion('accountType', [
  z.object({
    accountType: z.literal('personal'),
    fullName: z.string().min(1, 'Required'),
  }),
  z.object({
    accountType: z.literal('business'),
    companyName: z.string().min(1, 'Required'),
    taxId: z.string().min(1, 'Required'),
  }),
]);
```

### Reusable Schema Parts

```tsx
// src/lib/schemas.ts — shared schema fragments
export const emailSchema = z.string().email('Invalid email address');
export const passwordSchema = z.string().min(8, 'At least 8 characters');
export const nameSchema = z.string().min(1, 'Required').max(100);
export const slugSchema = z.string().regex(/^[a-z0-9-]+$/, 'Only lowercase, numbers, hyphens');

// Compose in feature schemas
const createProjectSchema = z.object({
  name: nameSchema,
  slug: slugSchema,
  description: z.string().max(500).optional(),
});
```

## Server Error Handling

### Map API Errors to Form Fields

```tsx
// BAD: Only showing generic toast on error
const handleSubmit = async (data: FormValues) => {
  try {
    await api.createUser(data);
  } catch {
    toast.error('Something went wrong');
  }
};

// GOOD: Map server errors to specific form fields
interface ApiValidationError {
  field: string;
  message: string;
}

export function CreateUserForm() {
  const form = useForm<CreateUserInput>({
    resolver: zodResolver(createUserSchema),
  });

  const handleSubmit = async (data: CreateUserInput) => {
    try {
      await userService.create(data);
      toast.success('User created');
    } catch (error) {
      if (error instanceof ApiError && error.validationErrors) {
        // Map server validation errors to form fields
        error.validationErrors.forEach((err: ApiValidationError) => {
          form.setError(err.field as keyof CreateUserInput, {
            type: 'server',
            message: err.message,
          });
        });
      } else {
        // Set root error for non-field errors
        form.setError('root', {
          type: 'server',
          message: 'An unexpected error occurred',
        });
      }
    }
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)} className="space-y-4">
        {/* Show root error */}
        {form.formState.errors.root && (
          <div className="rounded-md bg-destructive/10 p-3 text-sm text-destructive">
            {form.formState.errors.root.message}
          </div>
        )}
        {/* form fields... */}
      </form>
    </Form>
  );
}
```

## Dynamic Field Arrays

```tsx
import { useFieldArray } from 'react-hook-form';

const teamSchema = z.object({
  name: z.string().min(1, 'Required'),
  members: z
    .array(
      z.object({
        email: z.string().email('Invalid email'),
        role: z.enum(['admin', 'member']),
      })
    )
    .min(1, 'At least one member required'),
});

type TeamInput = z.infer<typeof teamSchema>;

export function TeamForm() {
  const form = useForm<TeamInput>({
    resolver: zodResolver(teamSchema),
    defaultValues: {
      name: '',
      members: [{ email: '', role: 'member' }],
    },
  });

  const { fields, append, remove } = useFieldArray({
    control: form.control,
    name: 'members',
  });

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        {/* Team name field */}

        <div className="space-y-3">
          <label className="text-sm font-medium">Team Members</label>
          {fields.map((field, index) => (
            <div key={field.id} className="flex gap-2">
              <FormField
                control={form.control}
                name={`members.${index}.email`}
                render={({ field }) => (
                  <FormItem className="flex-1">
                    <FormControl>
                      <Input placeholder="email@example.com" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name={`members.${index}.role`}
                render={({ field }) => (
                  <FormItem>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger className="w-32">
                          <SelectValue />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent>
                        <SelectItem value="admin">Admin</SelectItem>
                        <SelectItem value="member">Member</SelectItem>
                      </SelectContent>
                    </Select>
                  </FormItem>
                )}
              />
              {fields.length > 1 && (
                <Button type="button" variant="ghost" size="icon" onClick={() => remove(index)}>
                  <Trash2 className="h-4 w-4" />
                </Button>
              )}
            </div>
          ))}
          <Button type="button" variant="outline" size="sm" onClick={() => append({ email: '', role: 'member' })}>
            <Plus className="mr-2 h-4 w-4" /> Add Member
          </Button>
        </div>
      </form>
    </Form>
  );
}
```

## Multi-Step Forms

```tsx
const stepOneSchema = z.object({
  name: z.string().min(1, 'Required'),
  email: z.string().email('Invalid email'),
});

const stepTwoSchema = z.object({
  company: z.string().min(1, 'Required'),
  role: z.enum(['admin', 'member']),
});

const fullSchema = stepOneSchema.merge(stepTwoSchema);
type FullFormInput = z.infer<typeof fullSchema>;

const STEPS = [
  { schema: stepOneSchema, fields: ['name', 'email'] as const },
  { schema: stepTwoSchema, fields: ['company', 'role'] as const },
];

export function OnboardingForm() {
  const [step, setStep] = useState(0);

  const form = useForm<FullFormInput>({
    resolver: zodResolver(fullSchema),
    defaultValues: { name: '', email: '', company: '', role: 'member' },
    mode: 'onTouched', // Validate on blur
  });

  const handleNext = async () => {
    const currentFields = STEPS[step].fields;
    const isValid = await form.trigger(currentFields);
    if (isValid) setStep((s) => s + 1);
  };

  const handleBack = () => setStep((s) => s - 1);

  const handleSubmit = async (data: FullFormInput) => {
    await onboardUser(data);
  };

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(handleSubmit)}>
        {step === 0 && (
          <>
            {/* name + email fields */}
            <Button type="button" onClick={handleNext}>Next</Button>
          </>
        )}
        {step === 1 && (
          <>
            {/* company + role fields */}
            <Button type="button" variant="outline" onClick={handleBack}>Back</Button>
            <Button type="submit">Complete</Button>
          </>
        )}
      </form>
    </Form>
  );
}
```

## Form State Management

### Dirty Checking & Unsaved Changes

```tsx
import { useBlocker } from 'react-router-dom';

export function SettingsForm() {
  const form = useForm<SettingsInput>({ ... });
  const { isDirty } = form.formState;

  // Warn before navigating away with unsaved changes
  useBlocker(
    ({ currentLocation, nextLocation }) =>
      isDirty && currentLocation.pathname !== nextLocation.pathname
  );

  // Warn before closing tab
  useEffect(() => {
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
      if (isDirty) e.preventDefault();
    };
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [isDirty]);
}
```

### Reset Form After Submission

```tsx
// BAD: Manually clearing fields
form.setValue('name', '');
form.setValue('email', '');

// GOOD: Reset to defaults
const handleSubmit = async (data: FormValues) => {
  await api.create(data);
  form.reset(); // Resets to defaultValues
};

// GOOD: Reset to new values (e.g., after fetching updated data)
form.reset(updatedData);
```

## Anti-Patterns to Avoid

```tsx
// BAD: useState for form state
const [name, setName] = useState('');
const [email, setEmail] = useState('');
const [errors, setErrors] = useState({});
// Reinventing React Hook Form!

// BAD: Manual validation
const validate = () => {
  const errors = {};
  if (!name) errors.name = 'Required';
  if (!email.includes('@')) errors.email = 'Invalid';
  setErrors(errors);
};
// Use Zod resolver!

// BAD: Uncontrolled inputs without register
<input value={name} onChange={(e) => setName(e.target.value)} />
// Use form.register() or Controller!

// BAD: Form state in Redux
dispatch(setFormField({ name: 'email', value: 'test@test.com' }));
// Forms are local state — use React Hook Form!

// BAD: Validating on every keystroke by default
const form = useForm({ mode: 'onChange' }); // Too aggressive, bad UX
// GOOD: Validate on blur, revalidate on change
const form = useForm({ mode: 'onTouched' }); // Validates after first blur
```

## Summary: Decision Tree

1. **Creating a form?** → Define Zod schema first, infer types with `z.infer`
2. **Setting up form?** → `useForm` with `zodResolver` + `defaultValues`
3. **Rendering fields?** → shadcn `FormField` + `FormControl` + `FormMessage`
4. **Need select/checkbox?** → Use `FormField` with `render` prop
5. **Dynamic fields?** → `useFieldArray` for add/remove rows
6. **Multi-step?** → Single schema, `form.trigger(fields)` per step
7. **Server errors?** → `form.setError('field', { message })` or `root` error
8. **Unsaved changes?** → Check `formState.isDirty` + `useBlocker`
9. **After submission?** → `form.reset()` to clear or reset to new values
10. **Reusing validations?** → Extract shared schemas to `src/lib/schemas.ts`
