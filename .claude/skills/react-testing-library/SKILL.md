---
name: react-testing-library
description: Provides React Testing Library patterns for component testing in React + TypeScript SaaS applications. Covers queries, user interactions, async testing, form testing, accessible selectors, and common component patterns. Must use when writing component tests with user-centric assertions.
---

# React Testing Library Best Practices

## Core Principle: Test Like a User

Query elements the way a user would find them — by visible text, labels, roles, and placeholders. **If a user can't see it or interact with it, don't query it.**

## Query Priority

### Always Prefer Accessible Queries

```tsx
// PRIORITY 1: Accessible to everyone (prefer these)
screen.getByRole('button', { name: 'Submit' });     // Best — semantic role + name
screen.getByLabelText('Email');                       // Form inputs
screen.getByPlaceholderText('Search...');             // When no label
screen.getByText('Welcome back');                     // Visible text
screen.getByDisplayValue('john@example.com');         // Input current value

// PRIORITY 2: Semantic queries
screen.getByAltText('User avatar');                   // Images
screen.getByTitle('Close');                           // Title attribute

// PRIORITY 3: Last resort (avoid when possible)
screen.getByTestId('custom-dropdown');                // Only when no semantic alternative

// BAD: Never query by class, id, or DOM structure
document.querySelector('.btn-primary');                // Not testing library!
container.querySelector('#submit-btn');                // Implementation detail!
```

### Common Role Queries

```tsx
// Buttons
screen.getByRole('button', { name: 'Save' });
screen.getByRole('button', { name: /delete/i });      // Regex for flexibility

// Links
screen.getByRole('link', { name: 'View Profile' });

// Headings
screen.getByRole('heading', { name: 'Settings', level: 1 });

// Form elements
screen.getByRole('textbox', { name: 'Email' });       // input[type="text/email"]
screen.getByRole('checkbox', { name: 'Remember me' });
screen.getByRole('combobox', { name: 'Country' });    // select
screen.getByRole('radio', { name: 'Monthly' });
screen.getByRole('switch', { name: 'Dark mode' });    // toggle

// Navigation
screen.getByRole('navigation');
screen.getByRole('banner');                            // header
screen.getByRole('main');                              // main content

// Lists
screen.getByRole('list');
screen.getAllByRole('listitem');

// Dialogs
screen.getByRole('dialog', { name: 'Confirm Delete' });
screen.getByRole('alertdialog');
```

## User Interactions with userEvent

### Always Use userEvent Over fireEvent

```tsx
import userEvent from '@testing-library/user-event';

// BAD: fireEvent doesn't simulate real user behavior
fireEvent.click(button);           // No focus, no hover, no pointer events
fireEvent.change(input, { target: { value: 'hello' } }); // Bypasses input logic

// GOOD: userEvent simulates complete user interaction
const user = userEvent.setup();

// Click
await user.click(screen.getByRole('button', { name: 'Submit' }));

// Type (includes focus, keydown, keyup, input events)
await user.type(screen.getByLabelText('Email'), 'john@example.com');

// Clear and type
await user.clear(screen.getByLabelText('Search'));
await user.type(screen.getByLabelText('Search'), 'new query');

// Select from dropdown
await user.selectOptions(screen.getByRole('combobox'), 'admin');

// Check/uncheck
await user.click(screen.getByRole('checkbox', { name: 'Remember me' }));

// Tab between elements
await user.tab();

// Keyboard shortcuts
await user.keyboard('{Enter}');
await user.keyboard('{Escape}');
```

## Testing Forms

### Complete Form Test

```tsx
describe('LoginForm', () => {
  it('submits with valid credentials', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();
    render(<LoginForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: 'Sign In' }));

    expect(onSubmit).toHaveBeenCalledWith({
      email: 'john@example.com',
      password: 'password123',
    });
  });

  it('shows validation errors for empty fields', async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: 'Sign In' }));

    expect(await screen.findByText('Please enter a valid email')).toBeInTheDocument();
    expect(screen.getByText('Password is required')).toBeInTheDocument();
  });

  it('shows server error message', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new ApiError('Invalid credentials', 401));
    const user = userEvent.setup();
    render(<LoginForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.type(screen.getByLabelText('Password'), 'wrongpass');
    await user.click(screen.getByRole('button', { name: 'Sign In' }));

    expect(await screen.findByText('Invalid credentials')).toBeInTheDocument();
  });

  it('disables submit button while submitting', async () => {
    const onSubmit = vi.fn(() => new Promise((r) => setTimeout(r, 1000)));
    const user = userEvent.setup();
    render(<LoginForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText('Email'), 'john@example.com');
    await user.type(screen.getByLabelText('Password'), 'password123');
    await user.click(screen.getByRole('button', { name: 'Sign In' }));

    expect(screen.getByRole('button', { name: /signing in/i })).toBeDisabled();
  });
});
```

## Async Testing

### Waiting for Elements

```tsx
// BAD: Using waitFor for everything
await waitFor(() => {
  expect(screen.getByText('Hello')).toBeInTheDocument();
});

// GOOD: Use findBy queries — they wait automatically
expect(await screen.findByText('Hello')).toBeInTheDocument();

// GOOD: Use waitFor for assertions that need retrying
await waitFor(() => {
  expect(mockNavigate).toHaveBeenCalledWith('/dashboard');
});

// GOOD: Wait for element to disappear
await waitFor(() => {
  expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
});

// GOOD: waitForElementToBeRemoved
await waitForElementToBeRemoved(() => screen.queryByText('Loading...'));
```

### Testing Loading → Success Flow

```tsx
it('shows loading state then data', async () => {
  mockProjectService.getAll.mockResolvedValue({ data: mockProjects });

  renderWithProviders(<ProjectList />);

  // Loading state
  expect(screen.getByText('Loading...')).toBeInTheDocument();

  // Data loaded
  expect(await screen.findByText('Project Alpha')).toBeInTheDocument();
  expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
});
```

## Testing Patterns

### Testing Conditional Rendering

```tsx
describe('PermissionGate', () => {
  it('renders children when user has permission', () => {
    renderWithProviders(
      <PermissionGate permission="project:delete">
        <button>Delete</button>
      </PermissionGate>,
      { preloadedState: { auth: { user: { role: 'admin' }, isAuthenticated: true } } }
    );

    expect(screen.getByRole('button', { name: 'Delete' })).toBeInTheDocument();
  });

  it('renders nothing when user lacks permission', () => {
    renderWithProviders(
      <PermissionGate permission="project:delete">
        <button>Delete</button>
      </PermissionGate>,
      { preloadedState: { auth: { user: { role: 'viewer' }, isAuthenticated: true } } }
    );

    expect(screen.queryByRole('button', { name: 'Delete' })).not.toBeInTheDocument();
  });
});
```

### Testing Dialog/Modal

```tsx
it('opens dialog and submits', async () => {
  const user = userEvent.setup();
  renderWithProviders(<CreateProjectDialog />);

  // Open dialog
  await user.click(screen.getByRole('button', { name: 'Create Project' }));

  // Dialog appears
  expect(screen.getByRole('dialog')).toBeInTheDocument();
  expect(screen.getByRole('heading', { name: 'Create Project' })).toBeInTheDocument();

  // Fill form
  await user.type(screen.getByLabelText('Project Name'), 'My Project');

  // Submit
  await user.click(screen.getByRole('button', { name: 'Create' }));

  // Dialog closes on success
  await waitFor(() => {
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
```

### Testing Lists

```tsx
it('renders correct number of items', () => {
  renderWithProviders(<UserList users={mockUsers} />);

  const items = screen.getAllByRole('listitem');
  expect(items).toHaveLength(mockUsers.length);
});

it('renders each user name and email', () => {
  renderWithProviders(<UserList users={mockUsers} />);

  mockUsers.forEach((user) => {
    expect(screen.getByText(user.name)).toBeInTheDocument();
    expect(screen.getByText(user.email)).toBeInTheDocument();
  });
});
```

## Assertions (jest-dom Matchers)

```tsx
// Visibility
expect(element).toBeVisible();
expect(element).not.toBeVisible();

// In the document
expect(element).toBeInTheDocument();
expect(screen.queryByText('X')).not.toBeInTheDocument();

// Enabled/disabled
expect(button).toBeEnabled();
expect(button).toBeDisabled();

// Content
expect(heading).toHaveTextContent('Welcome');
expect(input).toHaveValue('hello');
expect(input).toHaveDisplayValue('hello');

// Attributes
expect(link).toHaveAttribute('href', '/dashboard');
expect(input).toBeRequired();
expect(input).toBeValid();
expect(input).toBeInvalid();

// Classes (use sparingly — prefer semantic assertions)
expect(element).toHaveClass('active');

// Checked
expect(checkbox).toBeChecked();
expect(checkbox).not.toBeChecked();

// Focus
expect(input).toHaveFocus();

// Accessibility
expect(element).toHaveAccessibleName('Submit');
expect(element).toHaveAccessibleDescription('Save your changes');
```

## Anti-Patterns to Avoid

```tsx
// BAD: Testing implementation details
expect(component.state.isOpen).toBe(true);     // Don't access state
expect(setState).toHaveBeenCalledWith(true);    // Don't spy on setState

// GOOD: Test what the user sees
expect(screen.getByRole('dialog')).toBeInTheDocument();

// BAD: Using container.querySelector
const { container } = render(<Button />);
expect(container.querySelector('.btn')).toBeTruthy();

// GOOD: Use accessible queries
expect(screen.getByRole('button')).toBeInTheDocument();

// BAD: Using data-testid as first choice
<div data-testid="user-name">{name}</div>

// GOOD: Use text content or semantic HTML
<h2>{name}</h2>
screen.getByRole('heading', { name });

// BAD: Not using async properly
expect(screen.getByText('Loaded')).toBeInTheDocument(); // May not be rendered yet!

// GOOD: Use findBy for async content
expect(await screen.findByText('Loaded')).toBeInTheDocument();
```

## Summary: Decision Tree

1. **Querying elements?** → `getByRole` > `getByLabelText` > `getByText` > `getByTestId`
2. **Simulating interaction?** → Always `userEvent.setup()`, never `fireEvent`
3. **Waiting for async?** → `findByText` for elements, `waitFor` for assertions
4. **Element should NOT exist?** → `queryByText` (returns null, doesn't throw)
5. **Testing form validation?** → Submit empty, assert error messages visible
6. **Testing loading state?** → Assert loading UI, then `findByText` for data
7. **Testing conditional render?** → Provide different preloadedState, assert visibility
8. **Testing dialog?** → Click trigger, assert `getByRole('dialog')`, interact, assert closed
9. **Assertion choice?** → Prefer semantic matchers (`toBeVisible`, `toBeDisabled`, `toHaveTextContent`)
10. **Test structure?** → Arrange (render) → Act (interact) → Assert (expect)
