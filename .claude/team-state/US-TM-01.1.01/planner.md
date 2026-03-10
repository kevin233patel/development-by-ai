# Implementation Plan: US-TM-01.1.01 — Enter Work Email to Begin

## A. Prerequisites

### shadcn/ui Components to Install

No shadcn/ui primitives are currently installed in `src/components/ui/`. All required components must be added:

```bash
npx shadcn@latest add form input label button badge separator alert
```

This single command installs: Form (FormField, FormItem, FormLabel, FormControl, FormMessage, FormDescription), Input, Label, Button, Badge, Separator, Alert (Alert, AlertTitle, AlertDescription).

### npm Packages to Install

All core npm dependencies are already present in `package.json`:
- `react-hook-form`, `@hookform/resolvers`, `zod` -- form + validation
- `@tanstack/react-query` -- server state (used for mutation)
- `axios` -- HTTP client
- `lucide-react` -- icons (AlertCircle, Loader2, Moon, Sun)
- `@reduxjs/toolkit`, `react-redux` -- client state (entry session)

No additional npm packages needed.

### CSS Custom Properties to Add to `src/index.css`

The following Figma-specific tokens are NOT covered by existing semantic variables. Add to `:root` and `.dark`:

```css
/* Add inside :root block — Figma design tokens for entry page */
--color-heading: #111c2c;
--color-para: #1d2a3e;
--color-subdued: #516381;
--color-neutral-40: #cad3e2;
--color-neutral-30: #e3e8f2;
--color-neutral-20: #ecf1f9;
--color-neutral-10: #f6f9fc;
--color-neutral-50: #8e9fbc;

/* Add inside .dark block — dark mode counterparts */
--color-heading: #f1f5f9;
--color-para: #94a3b8;
--color-subdued: #64748b;
--color-neutral-40: #334155;
--color-neutral-30: #043cb5;
--color-neutral-20: #001489;
--color-neutral-10: #043cb5;
--color-neutral-50: #5b7394;
```

---

## B. UI Component Inventory

### Layer 1: shadcn/ui Primitives (to be installed)

| Component | Layer | Import Path | Used For |
|-----------|-------|-------------|----------|
| Form, FormField, FormItem, FormLabel, FormControl, FormMessage | 1 (shadcn) | `@/components/ui/form` | Email field group: label + input + error message, React Hook Form integration |
| Input | 1 (shadcn) | `@/components/ui/input` | Email input field (type="email") |
| Label | 1 (shadcn) | `@/components/ui/label` | "Work email" label (used via FormLabel) |
| Button | 1 (shadcn) | `@/components/ui/button` | "Continue with email", "Continue with Microsoft", "Continue with Google", Dark mode toggle |
| Badge | 1 (shadcn) | `@/components/ui/badge` | "Next-Gen SAAS" heading badge (variant="outline", custom colors) |
| Separator | 1 (shadcn) | `@/components/ui/separator` | "OR" divider between email and OAuth sections |
| Alert, AlertDescription | 1 (shadcn) | `@/components/ui/alert` | Rate limit error display (Failure Flow 3), OAuth errors (Edge Case 10) |

### Layer 2: Existing Composed Components

| Component | Layer | Import Path | Used For |
|-----------|-------|-------------|----------|
| ThemeToggle | 2 (common) | `@/components/common/ThemeToggle` | NOT used directly -- design calls for a simpler dark mode toggle (single button, not 3-option segmented). A new `DarkModeToggle` component will be built for the entry page footer. |

### Layer 3: Custom Components to Build

| Component | Location | Purpose |
|-----------|----------|---------|
| GoogleIcon | `@/components/icons/GoogleIcon.tsx` | Google "G" brand SVG logo (4-color) |
| MicrosoftIcon | `@/components/icons/MicrosoftIcon.tsx` | Microsoft brand SVG logo (4-color squares) |
| MotadataLogo | `@/components/icons/MotadataLogo.tsx` | Platform logo for entry page header |

**HARD RULE: feature-dev MUST use shadcn/ui components from this inventory. Raw HTML elements (`<input>`, `<button>`, `<label>`, `<select>`) are PROHIBITED in feature code.**

---

## C. File Structure

All paths are relative to: `/Users/kevingardhariya/Documents/code/Development/motadata/development-by-ai/projects/motadata-nextgen/`

| # | File Path | Action | Description |
|---|-----------|--------|-------------|
| 1 | `src/index.css` | Modify | Add Figma design tokens (--color-heading, --color-para, etc.) to :root and .dark |
| 2 | `src/features/entry/types/entry.types.ts` | Create | TypeScript interfaces: PlanId, EntryPath, EmailEntryFormState, EmailEntryError, TypoSuggestion, EntrySessionState, EmailEntryRequest, EmailEntryResponse, AnalyticsEvent, component props |
| 3 | `src/features/entry/schemas/entrySchemas.ts` | Create | Zod schemas: emailEntrySchema (V-01 required, V-02 format), disposableEmailCheck (V-04), typo detection map (V-03) |
| 4 | `src/features/entry/utils/disposableEmails.ts` | Create | Static set of disposable email domains (~3,500+), exported as `isDisposableEmail(domain): boolean` |
| 5 | `src/features/entry/utils/typoDetection.ts` | Create | Common domain typo map (gmial.com -> gmail.com, etc.), exported as `detectTypo(email): TypoSuggestion \| null` |
| 6 | `src/features/entry/services/entryService.ts` | Create | API service: `submitEmailEntry(req: EmailEntryRequest): Promise<EmailEntryResponse>` -- POST /api/v1/entry/email |
| 7 | `src/features/entry/slices/entrySlice.ts` | Create | Redux slice for entry session state: normalizedEmail, rawPlanParam, resolvedPlan, entryPath |
| 8 | `src/stores/store.ts` | Modify | Register entrySlice reducer |
| 9 | `src/test/renderWithProviders.tsx` | Modify | Add entrySlice to test store setup |
| 10 | `src/features/entry/hooks/useEmailEntryForm.ts` | Create | Form orchestration hook: RHF setup, blur validation (V-01/V-02/V-03/V-04), submit handler, API call, loading state, error mapping |
| 11 | `src/features/entry/hooks/useTypoDetection.ts` | Create | Hook wrapping typoDetection util: manages suggestion state, dismiss, accept |
| 12 | `src/features/entry/hooks/usePlanParam.ts` | Create | Hook to extract and resolve ?plan= from URL search params, dispatch to entrySlice |
| 13 | `src/components/icons/GoogleIcon.tsx` | Create | Google "G" brand SVG component |
| 14 | `src/components/icons/MicrosoftIcon.tsx` | Create | Microsoft brand SVG component |
| 15 | `src/components/icons/MotadataLogo.tsx` | Create | Platform logo SVG component |
| 16 | `src/components/icons/index.ts` | Create | Barrel export for icons |
| 17 | `src/features/entry/components/BackgroundGradient/BackgroundGradient.tsx` | Create | Decorative gradient div (absolute positioned, bottom layer) |
| 18 | `src/features/entry/components/BackgroundGradient/index.ts` | Create | Barrel export |
| 19 | `src/features/entry/components/TagInHeadingBadge/TagInHeadingBadge.tsx` | Create | Badge variant="outline" with "Next-Gen SAAS" text, exact Figma styling |
| 20 | `src/features/entry/components/TagInHeadingBadge/index.ts` | Create | Barrel export |
| 21 | `src/features/entry/components/EmailField/EmailField.tsx` | Create | FormField wrapper: FormLabel + Input + FormMessage (with AlertCircle icon) + TypoSuggestion |
| 22 | `src/features/entry/components/EmailField/index.ts` | Create | Barrel export |
| 23 | `src/features/entry/components/TypoSuggestion/TypoSuggestion.tsx` | Create | Non-blocking suggestion display: "Did you mean [corrected]?" with clickable correction, ESC dismiss |
| 24 | `src/features/entry/components/TypoSuggestion/index.ts` | Create | Barrel export |
| 25 | `src/features/entry/components/ContinueEmailButton/ContinueEmailButton.tsx` | Create | Button with loading state (Loader2 spinner), disabled during submission |
| 26 | `src/features/entry/components/ContinueEmailButton/index.ts` | Create | Barrel export |
| 27 | `src/features/entry/components/OrDivider/OrDivider.tsx` | Create | Separator + "OR" centered text |
| 28 | `src/features/entry/components/OrDivider/index.ts` | Create | Barrel export |
| 29 | `src/features/entry/components/OAuthButton/OAuthButton.tsx` | Create | OAuth button: variant="outline", provider icon + text, Google/Microsoft variants |
| 30 | `src/features/entry/components/OAuthButton/index.ts` | Create | Barrel export |
| 31 | `src/features/entry/components/PageFooter/PageFooter.tsx` | Create | Footer: copyright, Terms/Privacy links, ToS consent text, dark mode toggle |
| 32 | `src/features/entry/components/PageFooter/index.ts` | Create | Barrel export |
| 33 | `src/features/entry/pages/EmailEntryPage.tsx` | Create | Page component composing all entry components, full layout |
| 34 | `src/features/entry/index.ts` | Create | Feature barrel export |
| 35 | `src/app/router.tsx` | Modify | Add /signup, /signin, /entry routes (all pointing to EmailEntryPage), new EntryLayout without AuthLayout wrapper |

---

## D. Component Hierarchy

```
EmailEntryPage
├── BackgroundGradient (decorative, absolute, z-0)
├── <div> Logo wrapper (centered, pt-6)
│   └── MotadataLogo
├── MainFormContainer (max-w-[400px], centered)
│   ├── TitleSection (flex col, gap-4, text-center)
│   │   ├── TagInHeadingBadge ("Next-Gen SAAS")
│   │   ├── <h1> "Welcome to NextGen"
│   │   └── <p> subtitle text
│   └── FormSection (flex col, gap-5, mt-11)
│       ├── <Form> (React Hook Form provider)
│       │   └── EmailFieldGroup (flex col, gap-4)
│       │       ├── EmailField (FormField > FormItem > FormLabel + FormControl(Input) + FormMessage + TypoSuggestion)
│       │       └── ContinueEmailButton (Button with Loader2 spinner)
│       └── OAuthSection (flex col, gap-5)
│           ├── OrDivider (Separator + "OR")
│           └── OAuthButtonGroup (flex col, gap-4)
│               ├── OAuthButton provider="microsoft"
│               └── OAuthButton provider="google"
├── Alert (rate limit / OAuth error -- conditional, above MainFormContainer)
└── PageFooter (absolute bottom-11 / relative on mobile)
    ├── FooterLeft (copyright + Terms + Privacy links)
    ├── FooterCenter (ToS consent text with links)
    └── FooterRight (DarkModeToggle button)
```

---

## E. Phased Build Plan

### Phase 1: Infrastructure (CSS tokens, types, schemas, utilities)

| # | File | What to Implement | Skills | Dependencies | shadcn Used |
|---|------|-------------------|--------|--------------|-------------|
| 1 | `src/index.css` | Add 8 CSS custom properties to `:root` and `.dark` blocks. See Section A for exact values. | tailwind-css, dark-light-theming | None | None |
| 2 | `src/features/entry/types/entry.types.ts` | All TypeScript interfaces from story Section 13. PlanId union type, EntryPath, EmailEntryFormState, EmailEntryError, TypoSuggestion, EntrySessionState, EmailEntryRequest, EmailEntryResponse (discriminated union), AnalyticsEvent, component prop types (EmailFieldProps, ContinueButtonProps, OAuthButtonProps). | react-typescript | None | None |
| 3 | `src/features/entry/schemas/entrySchemas.ts` | Zod schema: `emailEntrySchema` with V-01 (`.min(1, "Email address is required")`), V-02 (`.email("Please enter a valid email address")`), max 255 chars. Also `parsePlanParam(raw: string \| null): PlanId` helper. | react-hook-form-zod, react-typescript | #2 types | None |
| 4 | `src/features/entry/utils/disposableEmails.ts` | Export `DISPOSABLE_DOMAINS: ReadonlySet<string>` loaded from a static array of ~3,500 domains. Export `isDisposableEmail(email: string): boolean` that extracts domain and checks set membership. Import a community list (e.g., disposable-email-domains npm package, or inline a curated subset). | react-typescript | None | None |
| 5 | `src/features/entry/utils/typoDetection.ts` | Export `COMMON_TYPOS: ReadonlyMap<string, string>` mapping misspelled domains to corrections (gmial.com->gmail.com, yaho.com->yahoo.com, outlok.com->outlook.com, hotmial.com->hotmail.com, etc.). Export `detectTypo(email: string): TypoSuggestion \| null`. | react-typescript | #2 types (TypoSuggestion interface) | None |

### Phase 2: Data Layer (service, Redux slice)

| # | File | What to Implement | Skills | Dependencies | shadcn Used |
|---|------|-------------------|--------|--------------|-------------|
| 6 | `src/features/entry/services/entryService.ts` | `submitEmailEntry(req: EmailEntryRequest): Promise<EmailEntryResponse>` -- POST to `/api/v1/entry/email`. Uses `apiClient` from `@/lib/apiClient`. Handles 200 success, 422 disposable error, 429 rate limit. Maps `ApiError` responses to typed `EmailEntryErrorResponse`. No auth header needed (public endpoint). | rest-api-integration | #2 types, existing `apiClient.ts` | None |
| 7 | `src/features/entry/slices/entrySlice.ts` | Redux slice `entrySlice` with state: `{ normalizedEmail: string \| null, rawPlanParam: string \| null, resolvedPlan: PlanId, entryPath: EntryPath \| null }`. Actions: `setPlanParam(raw: string \| null)`, `setEmailSubmitted(email: string)`, `setEntryPath(path: EntryPath)`, `resetEntryState()`. Selectors: `selectEntrySession`, `selectResolvedPlan`. Uses `parsePlanParam` from schemas. | redux-toolkit | #2 types, #3 schemas | None |
| 8 | `src/stores/store.ts` | Add `entry: entrySlice.reducer` to the store's reducer map. Update `RootState` type (automatic via configureStore). | redux-toolkit | #7 entrySlice | None |
| 9 | `src/test/renderWithProviders.tsx` | Import `entrySlice`, add `entry` to the test store reducer map and PreloadedState interface. | vitest | #7 entrySlice | None |

### Phase 3: Hooks

| # | File | What to Implement | Skills | Dependencies | shadcn Used |
|---|------|-------------------|--------|--------------|-------------|
| 10 | `src/features/entry/hooks/useTypoDetection.ts` | Hook returning `{ typoSuggestion: TypoSuggestion \| null, checkTypo: (email: string) => void, dismissSuggestion: () => void, acceptSuggestion: () => string }`. Wraps `detectTypo()` util. Manages dismissed state. Returns null if dismissed. Resets on email change. | react-typescript | #5 typoDetection util, #2 types | None |
| 11 | `src/features/entry/hooks/usePlanParam.ts` | Hook that reads `?plan=` from `useSearchParams()`, dispatches `setPlanParam` to entrySlice on mount. Returns `resolvedPlan` from store. | react-router, redux-toolkit | #7 entrySlice, #3 schemas | None |
| 12 | `src/features/entry/hooks/useEmailEntryForm.ts` | Orchestration hook. Sets up `useForm` with `zodResolver(emailEntrySchema)`. On blur: runs V-01, V-02, calls `isDisposableEmail` for V-04, calls `checkTypo` for V-03. On submit: normalizes to lowercase, validates V-01+V-02+V-04 client-side, if passes calls `submitEmailEntry()`, on success dispatches `setEmailSubmitted` + `setEntryPath('email')` and navigates to OTP page, on 422 error maps to field error, on 429 sets rate limit error state. Returns: form, isSubmitting, rateLimitError, onSubmit, emailInputRef. | react-hook-form-zod, rest-api-integration, react-typescript | #3 schemas, #4 disposable, #6 service, #7 slice, #10 typoDetection hook | Form |

### Phase 4: UI Components (leaf to composite)

| # | File | What to Implement | Skills | Dependencies | shadcn Used |
|---|------|-------------------|--------|--------------|-------------|
| 13 | `src/components/icons/GoogleIcon.tsx` + `MicrosoftIcon.tsx` + `MotadataLogo.tsx` + `index.ts` | SVG components for brand icons. GoogleIcon: 4-color "G". MicrosoftIcon: 4-color squares. MotadataLogo: platform logo. All accept className prop for sizing. | react-typescript | None | None |
| 14 | `src/features/entry/components/BackgroundGradient/BackgroundGradient.tsx` + `index.ts` | Decorative div. Classes: `absolute bottom-0 left-0 w-full h-[652px] pointer-events-none select-none -z-0 hidden sm:block`. CSS gradient from transparent to a soft blue tint. Dark mode: adjust or hide. | react-typescript, tailwind-css | None | None |
| 15 | `src/features/entry/components/TagInHeadingBadge/TagInHeadingBadge.tsx` + `index.ts` | shadcn `Badge` with `variant="outline"`. Override classes: `border-[#4cb1fe] text-[#4cb1fe] rounded-full text-[11px] font-normal bg-transparent mx-auto`. Text: "Next-Gen SAAS". `aria-hidden="true"` (decorative). | react-typescript, shadcn-ui, tailwind-css, accessibility | None | Badge |
| 16 | `src/features/entry/components/TypoSuggestion/TypoSuggestion.tsx` + `index.ts` | Conditional display. Shows "Did you mean " + clickable button with suggested email + "?". Container: `role="status"`, classes `flex items-center gap-1.5 text-xs text-[#516381] dark:text-muted-foreground`. Suggestion button: `text-[#006dfa] underline text-xs font-medium`. Dismiss on ESC key (useEffect keydown listener). Accept on click/Enter/Space. | react-typescript, tailwind-css, accessibility | #2 types (TypoSuggestion interface) | None (custom, but uses Button-like pattern) |
| 17 | `src/features/entry/components/EmailField/EmailField.tsx` + `index.ts` | shadcn `FormField` > `FormItem` > `FormLabel` ("Work email", classes: `text-xs font-normal text-[#516381] dark:text-muted-foreground`) > `FormControl` > `Input` (type="email", autoFocus, placeholder: "Enter you work email address...", h-10, border-[#cad3e2], error state: border-destructive, aria-required="true"). Below Input: `FormMessage` (with AlertCircle icon, text-xs text-destructive, role="alert"). Below FormMessage: TypoSuggestion component (if active). | react-typescript, shadcn-ui, react-hook-form-zod, tailwind-css, accessibility | #16 TypoSuggestion, #3 schemas | Form, FormField, FormItem, FormLabel, FormControl, FormMessage, Input |
| 18 | `src/features/entry/components/ContinueEmailButton/ContinueEmailButton.tsx` + `index.ts` | shadcn `Button` with custom classes: `w-full h-10 rounded-[6px] bg-[#ecf1f9] hover:bg-[#e3e8f2] text-[#516381] text-xs font-medium dark:bg-[#001489] dark:text-[#99cdff] dark:hover:bg-[#043cb5]`. Loading state: `Loader2` icon (animate-spin, h-4 w-4, mr-2) + text "Continuing...". Disabled: `isSubmitting`. `aria-busy={isSubmitting}`. type="submit". | react-typescript, shadcn-ui, tailwind-css, accessibility | None | Button |
| 19 | `src/features/entry/components/OrDivider/OrDivider.tsx` + `index.ts` | Container `flex items-center gap-3`. Two `Separator` components (flex-1, bg-[#e3e8f2] dark:bg-[#043cb5]). Centered `<span>` with text "OR" (text-[11px] font-normal text-[#516381] dark:text-muted-foreground). | react-typescript, shadcn-ui, tailwind-css | None | Separator |
| 20 | `src/features/entry/components/OAuthButton/OAuthButton.tsx` + `index.ts` | shadcn `Button variant="outline"`. Props: `provider: 'google' \| 'microsoft'`, `onClick`, `disabled`. Icon: GoogleIcon or MicrosoftIcon (h-4 w-4). Text: "Continue with Google" / "Continue with Microsoft". Classes: `w-full h-10 rounded-[6px] border-[#cad3e2] text-[#111c2c] text-xs font-medium hover:bg-[#f6f9fc] dark:border-[#334155] dark:bg-transparent dark:text-foreground dark:hover:bg-[#001489]`. `aria-label="Continue with {provider}"`. Never disabled on this page. | react-typescript, shadcn-ui, tailwind-css, accessibility | #13 icons | Button |
| 21 | `src/features/entry/components/PageFooter/PageFooter.tsx` + `index.ts` | `<footer>` element. Three sections: FooterLeft (copyright "Motadata (c)2026", vertical separator, "Terms" link, "Privacy" link), FooterCenter (ToS consent text with linked "Terms of Service" and "Privacy Policy" -- target="_blank" rel="noopener noreferrer", aria-label with "(opens in new tab)"), FooterRight (dark mode toggle using shadcn Button variant="ghost" + Moon/Sun icon from lucide-react + useTheme hook). Responsive: absolute bottom-11 on desktop, relative stacked on mobile. All text: text-[11px] text-[#516381] dark:text-muted-foreground. | react-typescript, shadcn-ui, tailwind-css, accessibility, dark-light-theming | existing useTheme hook | Button, Separator |

### Phase 5: Page Composition

| # | File | What to Implement | Skills | Dependencies | shadcn Used |
|---|------|-------------------|--------|--------------|-------------|
| 22 | `src/features/entry/pages/EmailEntryPage.tsx` | Page component. Full-viewport layout: `relative min-h-screen bg-background overflow-hidden`. Contains: BackgroundGradient, Logo section, MainFormContainer with TitleSection (TagInHeadingBadge + h1 + subtitle) and FormSection (shadcn Form wrapping EmailField + ContinueEmailButton, then OrDivider + OAuthButtons). Conditional Alert for rate limit / OAuth errors above form. PageFooter at bottom. Calls `usePlanParam()` on mount, `useEmailEntryForm()` for form state. OAuth button click dispatches `setEntryPath('oauth_google'/'oauth_microsoft')` and redirects. Default export for lazy loading. | react-router, react-typescript, shadcn-ui, tailwind-css, responsive-design, accessibility | All Phase 4 components, all Phase 3 hooks | Form, Alert |
| 23 | `src/features/entry/index.ts` | Barrel export: `export { default as EmailEntryPage } from './pages/EmailEntryPage'`. Export types, schemas, services, hooks for reuse by downstream stories. | react-typescript | #22 page | None |

### Phase 6: Route Integration

| # | File | What to Implement | Skills | Dependencies | shadcn Used |
|---|------|-------------------|--------|--------------|-------------|
| 24 | `src/app/router.tsx` | Add new route group for entry pages (public, outside AuthLayout). Routes: `/signup`, `/signin`, `/entry` -- all resolve to lazy-loaded EmailEntryPage. New `EntryLayout` wrapper (minimal: Suspense + fallback, NO AuthLayout redirect logic since this is pre-auth). Remove placeholder RegisterPage. Keep existing /login, /dashboard routes. | react-router | #22 EmailEntryPage | None |

---

## F. shadcn/ui Enforcement Rules

### Hard Gates (feature-dev must not violate)

1. **Form pattern is mandatory:** Every form field MUST use:
   ```
   Form > FormField > FormItem > FormLabel + FormControl + FormMessage
   ```
   NEVER: `<label>` + `<input>` + `<span className="error">`

2. **No raw HTML elements:**
   - `<input>` --> `Input` from `@/components/ui/input`
   - `<button>` --> `Button` from `@/components/ui/button`
   - `<label>` --> `FormLabel` from `@/components/ui/form` (or `Label`)
   - `<hr>` / divider --> `Separator` from `@/components/ui/separator`

3. **Design tokens from design-analyzer are source of truth:**
   - Use exact hex values from Figma Token Map (Section B of design spec)
   - Use exact Tailwind classes from component detail sections
   - No arbitrary approximations of colors

4. **Copy text from Copy Text Table is character-for-character:**
   - Badge: "Next-Gen SAAS" (all-caps SAAS)
   - Heading: "Welcome to NextGen" (one word)
   - Placeholder: "Enter you work email address..." (yes, "you" not "your" -- match Figma)
   - CTA: "Continue with email" (lowercase email)
   - All error messages match story spec exactly

### Component-to-shadcn Mapping

| UI Element | shadcn Component | Variant/Props |
|------------|-----------------|---------------|
| Email label | FormLabel | className override to text-xs |
| Email input | Input | type="email", h-10, custom border |
| Validation error | FormMessage | Extended with AlertCircle icon |
| Submit button | Button | Custom bg-[#ecf1f9], NOT default variant |
| Microsoft OAuth button | Button | variant="outline", custom border |
| Google OAuth button | Button | variant="outline", custom border |
| "Next-Gen SAAS" badge | Badge | variant="outline", custom colors |
| "OR" divider line | Separator | Custom bg color |
| Rate limit alert | Alert | variant="destructive" |
| Dark mode toggle | Button | variant="ghost", size="sm" |

---

## G. Task Descriptions for feature-dev

### Task 1: [IMPL] Types + Schemas + Utils -- entry feature foundation

**What to build:** Files #2, #3, #4, #5 from the manifest.

**`src/features/entry/types/entry.types.ts`:**
- Copy all interfaces from story Section 13 (TypeScript Type Definitions)
- PlanId: `'starter' | 'professional' | 'business' | 'unknown'`
- EntryPath: `'email' | 'oauth_google' | 'oauth_microsoft'`
- EmailEntryFormState, EmailEntryError, TypoSuggestion, EntrySessionState
- EmailEntryRequest, EmailEntrySuccessResponse, EmailEntryErrorResponse, EmailEntryResponse (discriminated union on `success`)
- AnalyticsEvent union type
- Component props: EmailFieldProps, ContinueButtonProps, OAuthButtonProps

**`src/features/entry/schemas/entrySchemas.ts`:**
- Zod schema `emailEntrySchema` = `z.object({ email: z.string().min(1, "Email address is required").email("Please enter a valid email address").max(255) })`
- Export `type EmailEntryFormValues = z.infer<typeof emailEntrySchema>`
- Export `parsePlanParam(raw: string | null): PlanId` -- maps known values to PlanId, defaults to 'professional'
- Export `normalizeEmail(email: string): string` -- trims and lowercases

**`src/features/entry/utils/disposableEmails.ts`:**
- Export `DISPOSABLE_DOMAINS: ReadonlySet<string>` -- static list of ~3,500+ domains
- Export `isDisposableEmail(email: string): boolean` -- extracts domain after @, checks set
- Error message constant: `DISPOSABLE_EMAIL_ERROR = "Disposable email addresses are not allowed. Please use a permanent email address."`

**`src/features/entry/utils/typoDetection.ts`:**
- Export `COMMON_TYPOS: ReadonlyMap<string, string>` -- at minimum: gmial.com->gmail.com, gmal.com->gmail.com, gmai.com->gmail.com, yaho.com->yahoo.com, yahooo.com->yahoo.com, outlok.com->outlook.com, outloo.com->outlook.com, hotmial.com->hotmail.com, protonmal.com->protonmail.com
- Export `detectTypo(email: string): TypoSuggestion | null` -- splits email at @, checks domain against map, returns suggestion with suggestedDomain, suggestedEmail, displayText "Did you mean {domain}?", dismissed: false

**Validation rules mapping:**
- V-01 "Email address is required" --> `z.string().min(1, ...)`
- V-02 "Please enter a valid email address" --> `z.string().email(...)`
- V-03 "Did you mean [corrected domain]?" --> `detectTypo()` function
- V-04 "Disposable email addresses not allowed..." --> `isDisposableEmail()` function

### Task 2: [IMPL] Service + Slice + Store -- data layer

**What to build:** Files #1, #6, #7, #8, #9 from the manifest.

**`src/index.css`:**
- Add to `:root` block: `--color-heading: #111c2c; --color-para: #1d2a3e; --color-subdued: #516381; --color-neutral-40: #cad3e2; --color-neutral-30: #e3e8f2; --color-neutral-20: #ecf1f9; --color-neutral-10: #f6f9fc; --color-neutral-50: #8e9fbc;`
- Add to `.dark` block: `--color-heading: #f1f5f9; --color-para: #94a3b8; --color-subdued: #64748b; --color-neutral-40: #334155; --color-neutral-30: #043cb5; --color-neutral-20: #001489; --color-neutral-10: #043cb5; --color-neutral-50: #5b7394;`

**`src/features/entry/services/entryService.ts`:**
- Import `apiClient` from `@/lib/apiClient`, types from `../types/entry.types`
- `submitEmailEntry(req: EmailEntryRequest): Promise<EmailEntryResponse>` -- POST `/api/v1/entry/email` with `{ email: req.email, planParam: req.planParam }`
- Handle success (200): return `{ success: true, verificationToken }`
- Handle 422: catch `ApiError`, check `isValidationError`, return `{ success: false, ruleId: 'V-04', message }`
- Handle 429: throw specific rate limit error (or return typed error)
- No auth token needed -- public endpoint

**`src/features/entry/slices/entrySlice.ts`:**
- State: `EntrySessionState` from types (normalizedEmail: null, rawPlanParam: null, resolvedPlan: 'professional', entryPath: null)
- Actions: `setPlanParam(payload: string | null)` -- sets rawPlanParam and resolvedPlan via parsePlanParam(), `setEmailSubmitted(payload: string)` -- sets normalizedEmail, `setEntryPath(payload: EntryPath)`, `resetEntryState()` -- returns to initial
- Selectors: `selectEntrySession(state)`, `selectResolvedPlan(state)`, `selectNormalizedEmail(state)`

**`src/stores/store.ts`:**
- Import `entrySlice` from `@/features/entry/slices/entrySlice`
- Add `entry: entrySlice.reducer` to reducer map

**`src/test/renderWithProviders.tsx`:**
- Import `entrySlice`
- Add `entry?: Partial<...>` to PreloadedState
- Add `entry: entrySlice.reducer` to test configureStore
- Add `entry: { ...entrySlice.getInitialState(), ...preloadedState.entry }` to preloadedState

### Task 3: [IMPL] Hooks -- useTypoDetection, usePlanParam, useEmailEntryForm

**What to build:** Files #10, #11, #12 from the manifest.

**`src/features/entry/hooks/useTypoDetection.ts`:**
- State: `suggestion: TypoSuggestion | null`
- `checkTypo(email: string)`: calls `detectTypo(email)`, sets state if result is non-null and not dismissed
- `dismissSuggestion()`: sets suggestion to `{ ...suggestion, dismissed: true }` then null
- `acceptSuggestion()`: returns `suggestion.suggestedEmail`, then clears suggestion
- Resets suggestion when email changes significantly (new blur trigger)

**`src/features/entry/hooks/usePlanParam.ts`:**
- Uses `useSearchParams()` from react-router-dom
- On mount: reads `searchParams.get('plan')`, dispatches `setPlanParam(raw)` to store
- Returns `{ resolvedPlan }` from `useAppSelector(selectResolvedPlan)`

**`src/features/entry/hooks/useEmailEntryForm.ts`:**
- Sets up `useForm<EmailEntryFormValues>` with `zodResolver(emailEntrySchema)`, mode: 'onBlur'
- Creates `emailInputRef` via `useRef<HTMLInputElement>(null)`
- `handleBlur(email: string)`: runs V-01 (empty check), V-02 (format), V-04 (disposable check via `isDisposableEmail`), V-03 (typo via `checkTypo`). Sets field errors for blocking ones.
- `handleSubmit(values)`: normalizes email, validates V-01+V-02+V-04 client-side, calls `submitEmailEntry()`, on success dispatches `setEmailSubmitted(normalized)` + `setEntryPath('email')`, navigates to `/verify-otp` (or wherever OTP page will be), on V-04 server error sets field error, on 429 sets `rateLimitError` state string
- Manages `rateLimitError: string | null` state
- Returns: `{ form, isSubmitting: form.formState.isSubmitting, rateLimitError, onSubmit: form.handleSubmit(handleSubmit), emailInputRef, typoSuggestion, onAcceptTypo, onDismissTypo, clearRateLimitError }`

### Task 4: [IMPL] Icons + Leaf Components -- BackgroundGradient, TagInHeadingBadge, TypoSuggestion, OrDivider

**What to build:** Files #13-16 (icons), #17-20 (BackgroundGradient, TagInHeadingBadge), #23-24 (TypoSuggestion), #27-28 (OrDivider).

**Icons (`src/components/icons/`):**
- `GoogleIcon.tsx`: SVG with 4-color Google "G" logo. Accept `className` prop. Named export.
- `MicrosoftIcon.tsx`: SVG with 4-color Microsoft squares. Accept `className` prop. Named export.
- `MotadataLogo.tsx`: Platform logo SVG. Accept `className` prop. Dark mode: `dark:invert` or conditional rendering. Named export.
- `index.ts`: Barrel re-export all three.

**`BackgroundGradient.tsx`:**
- Single `<div>` with `absolute bottom-0 left-0 w-full h-[652px] pointer-events-none select-none -z-0 hidden sm:block`
- CSS radial-gradient from `rgba(76, 177, 254, 0.05)` to transparent (or similar soft blue)
- Dark mode: reduce opacity or switch to dark-appropriate gradient

**`TagInHeadingBadge.tsx`:**
- `<Badge variant="outline" className="border-[#4cb1fe] text-[#4cb1fe] rounded-full text-[11px] font-normal bg-transparent mx-auto" aria-hidden="true">Next-Gen SAAS</Badge>`
- No props needed (static content)

**`TypoSuggestion.tsx`:**
- Props: `suggestion: TypoSuggestion | null`, `onAccept: (suggestedEmail: string) => void`, `onDismiss: () => void`
- If `suggestion` is null or dismissed, render nothing
- Outer div: `role="status"`, classes `flex items-center gap-1.5 text-xs text-[#516381] dark:text-muted-foreground`
- Text: "Did you mean " + `<button className="text-[#006dfa] underline text-xs font-medium hover:text-[#0263e0] bg-transparent border-0 p-0 cursor-pointer" onClick={() => onAccept(suggestion.suggestedEmail)}>{suggestion.suggestedDomain}</button>` + "?"
- ESC key handler: `useEffect` with `keydown` listener, calls `onDismiss` on Escape

**`OrDivider.tsx`:**
- `<div className="flex items-center gap-3"><Separator className="flex-1 bg-[#e3e8f2] dark:bg-[#043cb5]" /><span className="text-[11px] font-normal text-[#516381] dark:text-muted-foreground whitespace-nowrap">OR</span><Separator className="flex-1 bg-[#e3e8f2] dark:bg-[#043cb5]" /></div>`

**SHADCN ENFORCEMENT:** Use Badge from `@/components/ui/badge`, Separator from `@/components/ui/separator`. NO raw `<hr>` or `<div>` with border-bottom.

### Task 5: [IMPL] Form Components + Page -- EmailField, ContinueEmailButton, OAuthButton, PageFooter, EmailEntryPage, router

**What to build:** Files #21-22, #25-26, #29-32, #33-34, #35 from the manifest.

**`EmailField.tsx`:**
- Uses shadcn Form pattern: `FormField` > `FormItem` > `FormLabel` + `FormControl(Input)` + custom error + TypoSuggestion
- FormLabel: text "Work email", classes `text-xs font-normal text-[#516381] dark:text-muted-foreground`
- Input: `type="email"`, `autoFocus`, `placeholder="Enter you work email address..."`, `aria-required="true"`, classes `h-10 w-full rounded-[6px] border border-[#cad3e2] px-3 py-2 text-xs placeholder:text-[#8e9fbc] bg-white focus-visible:ring-2 focus-visible:ring-primary dark:border-[#334155] dark:bg-[#001489] dark:text-foreground dark:placeholder:text-[#5b7394]`
- Error state: `cn(baseClasses, field.error && "border-destructive focus-visible:ring-destructive")`
- FormMessage: wrap with `<div className="flex items-center gap-1.5 text-xs text-destructive" role="alert"><AlertCircle className="h-3.5 w-3.5 shrink-0" />{field.error.message}</div>`
- Below error: render `<TypoSuggestion>` component

**`ContinueEmailButton.tsx`:**
- `<Button type="submit" disabled={isLoading} className="w-full h-10 rounded-[6px] bg-[#ecf1f9] hover:bg-[#e3e8f2] text-[#516381] text-xs font-medium dark:bg-[#001489] dark:text-[#99cdff] dark:hover:bg-[#043cb5]" aria-busy={isLoading}>`
- Content: `{isLoading ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" />Continuing...</> : "Continue with email"}`

**`OAuthButton.tsx`:**
- Props: `provider: 'google' | 'microsoft'`, `onClick: () => void`
- `<Button variant="outline" onClick={onClick} className="w-full h-10 rounded-[6px] border-[#cad3e2] text-[#111c2c] text-xs font-medium hover:bg-[#f6f9fc] hover:text-[#111c2c] dark:border-[#334155] dark:bg-transparent dark:text-foreground dark:hover:bg-[#001489]" aria-label={`Continue with ${providerName}`}>`
- Icon: `provider === 'google' ? <GoogleIcon className="h-4 w-4 shrink-0" /> : <MicrosoftIcon className="h-4 w-4 shrink-0" />`
- Text: `Continue with ${providerName}`

**`PageFooter.tsx`:**
- `<footer>` with responsive classes: `absolute bottom-11 left-0 right-0 px-8 flex items-center justify-between` on desktop, `relative flex-col items-center gap-2 py-6 px-5 text-center` on mobile
- FooterLeft: "Motadata (c)2026" + vertical Separator + "Terms" link + "Privacy" link (all text-[11px] text-[#516381])
- FooterCenter: "By continuing, you agree to our [Terms of Service] and [Privacy Policy]" -- links: `target="_blank" rel="noopener noreferrer"`, `aria-label="Terms of Service (opens in new tab)"`
- FooterRight: Dark mode toggle -- `Button variant="ghost" size="sm"` with Moon/Sun icon + "Dark mode" text, uses `useTheme` hook
- All links: `hover:underline` or `underline decoration-dotted` for ToS links

**`EmailEntryPage.tsx`:**
- Default export (for lazy loading)
- Full layout: `<div className="relative min-h-screen bg-background overflow-hidden flex flex-col items-center">`
- BackgroundGradient
- Logo: `<div className="w-full flex justify-center pt-6"><MotadataLogo className="h-10 w-[180px] sm:w-[180px] w-[140px]" /></div>`
- MainFormContainer: `<div className="w-full max-w-[400px] mx-auto pt-24 px-5 lg:pt-[182px] lg:px-0 z-10">`
- TitleSection: TagInHeadingBadge + h1 + subtitle
- Rate limit Alert (conditional): `{rateLimitError && <Alert variant="destructive"><AlertCircle /><AlertDescription>{rateLimitError}</AlertDescription></Alert>}`
- `<Form {...form}>` wrapping EmailField + ContinueEmailButton
- OAuthSection: OrDivider + OAuthButton(microsoft) + OAuthButton(google)
- PageFooter
- Calls `usePlanParam()`, `useEmailEntryForm()`
- OAuth click: dispatch entryPath, redirect to OAuth URL (placeholder for US-TM-01.1.02)

**`src/features/entry/index.ts`:**
- `export { default as EmailEntryPage } from './pages/EmailEntryPage'`
- Export key types, hooks, services for downstream stories

**`src/app/router.tsx`:**
- Add lazy import: `const EmailEntryPage = lazy(() => import('@/features/entry/pages/EmailEntryPage'))`
- New route group (before AuthLayout group):
  ```
  {
    children: [
      { path: '/signup', element: <Suspense fallback={<PageSkeleton />}><EmailEntryPage /></Suspense> },
      { path: '/signin', element: <Suspense fallback={<PageSkeleton />}><EmailEntryPage /></Suspense> },
      { path: '/entry', element: <Suspense fallback={<PageSkeleton />}><EmailEntryPage /></Suspense> },
    ],
  }
  ```
- Remove placeholder RegisterPage function and lazy wrapper

---

## Test Plan

### Unit Tests (tdd-runner writes FIRST -- RED phase)

| Test File | Story Scenarios | What It Tests |
|-----------|----------------|---------------|
| `src/features/entry/schemas/entrySchemas.test.ts` | TS-03, TS-04, TS-13 | V-01 empty rejection, V-02 format rejection, valid email passes, normalizeEmail lowercases, parsePlanParam defaults |
| `src/features/entry/utils/disposableEmails.test.ts` | TS-05 | isDisposableEmail returns true for known domains, false for legitimate domains |
| `src/features/entry/utils/typoDetection.test.ts` | TS-06, TS-07 | detectTypo returns suggestion for gmial.com, returns null for valid uncommon domains |
| `src/features/entry/services/entryService.test.ts` | TS-01, TS-05 (server) | submitEmailEntry calls correct endpoint, returns success response, handles 422 and 429 errors |
| `src/features/entry/slices/entrySlice.test.ts` | TS-02, TS-14 | setPlanParam stores raw and resolves, setEmailSubmitted stores normalized, resetEntryState clears, default plan is 'professional' |
| `src/features/entry/hooks/useEmailEntryForm.test.ts` | TS-01, TS-03, TS-04, TS-05, TS-12, TS-13 | Form submission flow, validation error display, double-submit prevention, disposable rejection, case normalization |
| `src/features/entry/components/EmailField/EmailField.test.tsx` | TS-03, TS-04, TS-06 | Renders label, input, shows error on invalid email, shows typo suggestion, accepts suggestion |
| `src/features/entry/components/ContinueEmailButton/ContinueEmailButton.test.tsx` | TS-12 | Shows loading state, disabled when loading, shows spinner |
| `src/features/entry/components/OAuthButton/OAuthButton.test.tsx` | TS-11 | Renders with correct icon and text per provider, calls onClick |
| `src/features/entry/pages/EmailEntryPage.test.tsx` | TS-01, TS-02, TS-08, TS-14 | Full page renders all elements (FC-01), no password field (FC-02), plan param captured, form submission navigates |

### E2E Tests (e2e-runner writes AFTER implementation)

| Test File | Acceptance Criteria | What It Tests |
|-----------|-------------------|---------------|
| `e2e/tests/email-entry.spec.ts` | FC-01 thru FC-15, NFC-01 thru NFC-06 | Happy path: enter email -> navigate to OTP page. Validation: empty, invalid, disposable. Typo suggestion: show, accept, dismiss. OAuth: button click redirects. Plan param: captured in session. Loading state: button disabled. Keyboard navigation: tab order. |

---

## Architecture Notes

### State Management Choices

- **Redux (entrySlice):** Entry session state (normalizedEmail, planParam, resolvedPlan, entryPath) -- this is client-only transient state that needs to persist across page navigations within the entry flow. TanStack Query is not appropriate because this is not server-fetched data.
- **React Hook Form:** Form state for the email field (value, errors, submission state). Single source of truth for the form.
- **TanStack Query:** NOT used in this story. The single API call (POST /api/v1/entry/email) is a mutation that is better handled directly in the form submit handler via the service function. A TanStack `useMutation` could be used but adds unnecessary complexity for a single fire-and-forget mutation. If the team prefers consistency, wrap in `useMutation` later.
- **No localStorage for entry state:** Session state is Redux-only. If browser tab is closed, entry state is lost (acceptable -- user re-enters email).

### Permissions

- No permission checks needed. Entry page is fully public.

### Reusable Components

- `useTheme` hook: Reused in PageFooter for dark mode toggle
- `apiClient`: Reused via entryService
- `cn()` utility: Used throughout for conditional classes
- `renderWithProviders`: Updated to support entry slice for testing
- Icons (GoogleIcon, MicrosoftIcon, MotadataLogo): Shared across features

---

## PRD Invariant Compliance

- [x] INV-1: Auth state includes roles -- No conflict. No user created at this step.
- [x] INV-2: Seed roles cannot be deleted -- No conflict. No role operations.
- [x] INV-3: Permission model is additive -- No conflict. No permissions in this story.
- [x] INV-4: Roles are flat -- No conflict. No role structures.
- [x] INV-5: Groups are flat -- No conflict. No group structures.
- [x] INV-6: Org structure is flat -- No conflict. No org operations.
- [x] INV-7: Single-tenant architecture -- No conflict. No multi-tenant patterns. Entry page creates no records.
- [x] INV-8: No OAuth components/routes -- **NOTE:** Story explicitly includes OAuth buttons. Story-analyzer flagged this (INV-8 check). Per the story, the platform is fully passwordless using OTP + OAuth. INV-8 likely applies to internal auth only. Confirmed by the epic design decision D-TM-26. OAuth buttons are part of the specified design.
- [x] INV-9: No self-registration routes -- **NOTE:** This IS a self-service entry route. INV-9 likely applies to the internal platform (adding team members within an existing tenant), not tenant self-service provisioning. Confirmed by EP-TM-01 scope.
- [x] INV-10: Foundation owns email delivery -- No conflict. This story sends no emails.
- [x] INV-11: No client-side canonical data storage -- Compliant. Redux stores only transient session state (email, plan param). No server data cached in Redux. TanStack Query cache is not used here.

---

## Story Traceability

| Requirement | Mapped To |
|-------------|-----------|
| Field: Email Address | `entry.types.ts` EmailEntryFormState.email, `entrySchemas.ts` emailEntrySchema.email, `EmailField.tsx` FormField |
| Field: Plan (hidden) | `entry.types.ts` EntrySessionState.rawPlanParam/resolvedPlan, `entrySlice.ts` setPlanParam, `usePlanParam.ts` hook |
| V-01: Required | `entrySchemas.ts` z.string().min(1, ...), `EmailField.test.tsx` TS-03 |
| V-02: Format | `entrySchemas.ts` z.string().email(...), `EmailField.test.tsx` TS-04 |
| V-03: Typo | `typoDetection.ts` detectTypo(), `useTypoDetection.ts` hook, `TypoSuggestion.tsx`, TS-06/TS-07 |
| V-04: Disposable | `disposableEmails.ts` isDisposableEmail(), `useEmailEntryForm.ts` blur+submit, `entryService.ts` server check, TS-05 |
| FC-01: Page elements | `EmailEntryPage.tsx` renders all, `EmailEntryPage.test.tsx` TS-01 |
| FC-02: No password | `EmailEntryPage.test.tsx` asserts no password field |
| FC-05: Uniform response | `entryService.ts` returns same shape regardless, TS-08/TS-09/TS-10 |
| FC-07: Plan capture | `usePlanParam.ts`, `entrySlice.ts`, TS-02 |
| FC-10: Button disable | `ContinueEmailButton.tsx` disabled prop, TS-12 |
| FC-12: Lowercase | `entrySchemas.ts` normalizeEmail(), TS-13 |
| FC-14: Typo accept | `TypoSuggestion.tsx` onClick, `useTypoDetection.ts` acceptSuggestion, TS-06 |
| FC-15: Typo dismiss | `TypoSuggestion.tsx` ESC handler, `useTypoDetection.ts` dismissSuggestion |
| TS-11: OAuth Google | `OAuthButton.tsx`, `EmailEntryPage.tsx` OAuth click handler |
| TS-12: Double-submit | `useEmailEntryForm.ts` isSubmitting guard, `ContinueEmailButton.tsx` disabled |
| TS-14: Unrecognized plan | `entrySchemas.ts` parsePlanParam defaults to 'professional' |
