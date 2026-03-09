---
name: frontend-security
description: Provides frontend security patterns for React + TypeScript SaaS applications. Covers XSS prevention, CSP, secure token storage, input sanitization, dependency auditing, and OWASP top 10 for SPAs. Must use when handling user input, authentication tokens, or implementing security measures.
---

# Frontend Security Best Practices

## Core Principle: Defense in Depth

No single security measure is enough. **Layer multiple defenses: sanitize input, encode output, use CSP, secure tokens, audit dependencies.** The frontend is a trust boundary — treat all user input as potentially malicious.

## XSS Prevention

### React's Built-in Protection

```tsx
// React automatically escapes JSX expressions — this is SAFE
const userInput = '<script>alert("xss")</script>';
<p>{userInput}</p>  // Rendered as text, not executed

// DANGER: dangerouslySetInnerHTML bypasses React's escaping
// BAD: Never use with unsanitized input
<div dangerouslySetInnerHTML={{ __html: userInput }} />

// If you MUST render HTML (e.g., from a rich text editor):
import DOMPurify from 'dompurify';

// GOOD: Sanitize before rendering
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(richTextContent) }} />
```

```bash
npm install dompurify
npm install -D @types/dompurify
```

### URL Sanitization

```tsx
// BAD: User-controlled URLs without validation
<a href={userProvidedUrl}>Click here</a>
// Could be: javascript:alert('xss')

// GOOD: Validate URL protocol
function sanitizeUrl(url: string): string {
  try {
    const parsed = new URL(url);
    if (!['http:', 'https:', 'mailto:'].includes(parsed.protocol)) {
      return '#';
    }
    return url;
  } catch {
    return '#';
  }
}

<a href={sanitizeUrl(userProvidedUrl)}>Click here</a>
```

### Event Handler Injection

```tsx
// BAD: Interpolating user input into event handlers
<button onClick={() => eval(userInput)}>Click</button>

// GOOD: Never use eval(), new Function(), or setTimeout with strings
// Always use function references
<button onClick={handleClick}>Click</button>
```

## Content Security Policy (CSP)

```html
<!-- index.html — or set via server headers (preferred) -->
<meta http-equiv="Content-Security-Policy" content="
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' https://api.myapp.com;
  font-src 'self';
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
">
```

```
Best practice: Set CSP via HTTP headers on the server, not meta tags.
The server approach is more secure and harder to bypass.
```

## Secure Token Storage

```tsx
// WORST: Token in localStorage accessible to XSS
localStorage.setItem('token', accessToken);  // Any XSS can steal this

// BETTER: Token in memory (Redux) — cleared on tab close
dispatch(setCredentials({ user, token: accessToken }));
// Pros: Not accessible to XSS via storage APIs
// Cons: Lost on page refresh

// BEST: httpOnly cookie set by server
// Server response: Set-Cookie: token=xxx; HttpOnly; Secure; SameSite=Strict
// Frontend: Just sends requests with credentials: 'include'
// XSS cannot read httpOnly cookies

// Practical SaaS approach:
// - Short-lived accessToken (~15min) → Redux memory
// - Long-lived refreshToken → httpOnly cookie (server-set)
// - Auto-refresh via interceptor on 401
```

## Input Validation

### Client-Side (UX) + Server-Side (Security)

```tsx
// Client-side validation is for UX, NOT security
// Always validate on the server too!

// Zod schema for client-side validation
const createProjectSchema = z.object({
  name: z.string()
    .min(1, 'Required')
    .max(100, 'Too long')
    .regex(/^[a-zA-Z0-9\s-]+$/, 'Only letters, numbers, spaces, and hyphens'),
  description: z.string().max(1000).optional(),
  url: z.string().url('Invalid URL').optional().or(z.literal('')),
});

// NEVER trust client validation alone
// Server must re-validate everything
```

### Sanitize Before Sending to API

```tsx
// BAD: Sending raw user input
const data = { name: formData.name, bio: formData.bio };
await apiClient.post('/users', data);

// GOOD: Trim and sanitize
const data = {
  name: formData.name.trim(),
  bio: formData.bio.trim().slice(0, 1000), // Enforce max length
};
await apiClient.post('/users', data);
```

## Dependency Security

```bash
# Audit dependencies for known vulnerabilities
npm audit

# Fix automatically
npm audit fix

# Check for outdated packages
npm outdated

# Use lockfile for deterministic installs
npm ci  # In CI, always use ci instead of install
```

### .npmrc Security

```ini
# .npmrc
# Don't run install scripts from untrusted packages
ignore-scripts=true

# After install, manually run trusted scripts
# npm run postinstall
```

## Sensitive Data Handling

```tsx
// BAD: Logging sensitive data
console.log('User token:', token);
console.log('Request body:', { email, password });

// GOOD: Never log tokens, passwords, or PII
console.log('Login attempt for user:', email);
// Use structured logging in production with PII redaction

// BAD: Sensitive data in URL params
navigate(`/callback?token=${token}`); // Token in browser history!

// GOOD: Sensitive data in request body or headers
await apiClient.post('/auth/callback', { token });

// BAD: Sensitive data in error messages shown to users
toast.error(`Login failed: Invalid password for ${email}`);

// GOOD: Generic error messages
toast.error('Invalid email or password');
```

## CORS and API Security

```tsx
// API client should only talk to your backend
const apiClient = axios.create({
  baseURL: env.VITE_API_URL,  // Your API only
  withCredentials: true,       // Send cookies for httpOnly auth
});

// Never make requests to user-provided URLs
// BAD:
const response = await fetch(userProvidedUrl); // SSRF risk!

// GOOD: Only call your own API endpoints
const response = await apiClient.get(`/proxy?url=${encodeURIComponent(userProvidedUrl)}`);
// Let the server validate and proxy the request
```

## Clickjacking Prevention

```tsx
// Server should set X-Frame-Options header
// X-Frame-Options: DENY

// Or via CSP
// Content-Security-Policy: frame-ancestors 'none'

// Client-side check (defense in depth)
if (window.self !== window.top) {
  // Page is in an iframe — potential clickjacking
  window.top?.location.replace(window.self.location.href);
}
```

## Environment Variables

```tsx
// BAD: Secrets in frontend code
const API_KEY = 'sk-secret-1234567890';  // Visible in bundle!

// GOOD: Only non-secret config in VITE_ env vars
// VITE_ prefix means it's bundled into the client — NEVER put secrets here!
const apiUrl = env.VITE_API_URL;       // OK: not secret
const appName = env.VITE_APP_NAME;     // OK: not secret
// const apiKey = env.VITE_API_KEY;    // DANGER: if this is a secret key!

// Secrets belong on the server, never in the frontend bundle
```

## Dependency Injection Attack Prevention

```tsx
// BAD: Dynamic property access from user input
const value = object[userInput];  // Prototype pollution risk

// GOOD: Validate against allowed keys
const ALLOWED_KEYS = ['name', 'email', 'role'] as const;
type AllowedKey = (typeof ALLOWED_KEYS)[number];

function safeAccess(obj: Record<string, unknown>, key: string): unknown {
  if (!ALLOWED_KEYS.includes(key as AllowedKey)) {
    throw new Error(`Invalid key: ${key}`);
  }
  return obj[key];
}
```

## Security Checklist

```
[ ] React JSX escaping — never use dangerouslySetInnerHTML without DOMPurify
[ ] URL validation — check protocol before rendering user URLs
[ ] Token storage — memory or httpOnly cookies, not localStorage
[ ] CSP headers — restrict script/style/connect sources
[ ] Input validation — Zod on client + server-side validation
[ ] Dependency audit — npm audit in CI pipeline
[ ] No secrets in frontend — VITE_ vars are public
[ ] CORS configured — API only accepts requests from your domain
[ ] Error messages — never expose internal details to users
[ ] Console logs — no sensitive data logged in production
```

## Summary: Decision Tree

1. **Rendering user content?** → React auto-escapes. If HTML needed: `DOMPurify.sanitize()`
2. **User-provided URLs?** → Validate protocol (http/https only)
3. **Storing tokens?** → Redux memory (short-lived) + httpOnly cookie (refresh)
4. **Validating input?** → Zod on client for UX + server validates for security
5. **Third-party packages?** → `npm audit` in CI, update regularly
6. **Environment variables?** → `VITE_` prefix = public. Never put secrets here
7. **Error messages?** → Generic to users, detailed in server logs only
8. **CSP?** → Set via server headers, restrict all sources
9. **Logging?** → Never log tokens, passwords, or PII
10. **CORS?** → API should only accept your frontend's origin
