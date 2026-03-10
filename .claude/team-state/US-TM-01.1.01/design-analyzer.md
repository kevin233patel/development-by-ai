# UI Specification: US-TM-01.1.01 — Enter Work Email to Begin

## Design Source

- [x] Figma: Onboarding-Signup frame (1440x900) — Mode A
- Mode A: Figma layout metadata + variable definitions extracted and applied

---

## Page Type

Auth Entry Page — Centered single-column form, no sidebar, full-viewport layout.

---

## Component Hierarchy

### Page: EmailEntryPage

```
EmailEntryPage (full-viewport, bg: white / dark: blue-90 #030b5d)
├── BackgroundGradient (absolute, bottom layer, 2000x652)
├── Logo (centered, top: 24px / pt-6)
├── MainFormContainer (400px fixed width, centered horizontally and vertically offset from top)
│   ├── TitleSection (flex col, gap-4)
│   │   ├── TagInHeadingBadge — shadcn: Badge (custom variant)
│   │   │   └── Text: "Next-Gen SAAS"
│   │   ├── Heading — h1, text-[28px] font-semibold
│   │   │   └── Text: "Welcome to NextGen"
│   │   └── Subtitle — p, text-xs font-normal
│   │       └── Text: "This is a gentle AI-native platform where you can manage everything at your own pace, with AI as your helpful assistant"
│   └── FormSection (flex col, gap-5, mt-11)
│       ├── EmailFieldGroup (flex col, gap-4)
│       │   ├── EmailInputGroup (flex col, gap-2)
│       │   │   ├── WorkEmailLabel — shadcn: FormLabel
│       │   │   │   └── Text: "Work email"
│       │   │   ├── EmailInput — shadcn: Input (type="email")
│       │   │   │   └── Placeholder: "Enter you work email address..."
│       │   │   ├── FieldError — shadcn: FormMessage (conditional, with AlertCircle icon)
│       │   │   └── TypoSuggestion (conditional, non-blocking)
│       │   └── ContinueEmailButton — shadcn: Button (custom secondary style)
│       │       └── Text: "Continue with email"
│       └── OAuthSection (flex col, gap-5)
│           ├── OrDivider (custom, Separator + "OR" text)
│           └── OAuthButtonGroup (flex col, gap-4)
│               ├── MicrosoftButton — shadcn: Button (variant="outline")
│               │   └── Text: "Continue with Microsoft"
│               └── GoogleButton — shadcn: Button (variant="outline")
│                   └── Text: "Continue with Google"
└── PageFooter (1376px wide, absolute bottom-11)
    ├── FooterLeft (flex row, gap-3)
    │   ├── Copyright: "Motadata ©2026"
    │   ├── Separator (vertical, decorative)
    │   ├── TermsLink: "Terms"
    │   └── PrivacyLink: "Privacy"
    ├── FooterCenter (ToS consent text, inline links)
    │   └── "By continuing, you agree to our [Terms of Service] and [Privacy Policy]"
    └── FooterRight
        └── DarkModeToggle — shadcn: Button (variant="ghost", size="sm")
            └── Text: "Dark mode" + Moon/Sun icon
```

---

## Component Details

### 1. BackgroundGradient

- **Element type:** Decorative `<div>` — not a shadcn component
- **Tailwind classes:** `absolute bottom-0 left-0 w-full h-[652px] pointer-events-none select-none -z-0`
- **Implementation note:** A CSS gradient or SVG background image. The Figma shows a soft decorative gradient at the bottom half of the page. Use a `radial-gradient` or linear gradient from a neutral blue-tinted tone fading to white.
- **Dark mode:** Adjust gradient opacity / colors via `dark:` — or omit in dark mode if not designed.
- **Responsive:** `hidden sm:block` — hide on very small viewports to avoid visual noise.

---

### 2. Logo

- **Element type:** `<img>` or SVG component — not a shadcn component
- **Position:** Centered horizontally at the top of the page, `pt-6` from top (24px per Figma)
- **Dimensions:** 180px wide, 40px tall (per Figma: 180x40)
- **Tailwind classes:** `mx-auto block h-10 w-[180px] object-contain`
- **Wrapper:** `<div className="w-full flex justify-center pt-6">`
- **Dark mode:** `dark:invert` if logo is dark-on-light (or supply a separate dark logo asset)
- **Responsive:** Scale down on mobile: `w-[140px] sm:w-[180px]`

---

### 3. MainFormContainer

- **Element type:** `<div>` — structural wrapper
- **Figma:** 400px wide, centered horizontally, positioned at top: 182px from page top
- **Tailwind classes:** `w-full max-w-[400px] mx-auto`
- **Vertical position:** The page wrapper uses `flex min-h-screen flex-col items-center` with `pt-[182px]` on desktop. On mobile this collapses to `pt-24 px-4`.
- **Note:** The 400px width is a fixed design constraint from Figma — use `max-w-[400px]` with `w-full` for mobile responsiveness.
- **Responsive:**
  - Mobile: `w-full px-5 pt-24` — full width with side padding
  - Desktop (lg+): `max-w-[400px] pt-[182px]` — exact 400px fixed, positioned per Figma

---

### 4. TitleSection

- **Element type:** `<div>` — structural wrapper
- **Figma:** flex column, `gap-16px` between children
- **Tailwind classes:** `flex flex-col gap-4 text-center`
- **Children:** TagInHeadingBadge, Heading (h1), Subtitle (p)
- **Note:** The entire title section is center-aligned per Figma layout.

---

### 5. TagInHeadingBadge

- **shadcn base:** `Badge` — customized variant
- **Figma specs:**
  - Text: "Next-Gen SAAS"
  - Border: 1px solid `#4cb1fe`
  - Background: transparent (no fill)
  - Border-radius: 48px (fully rounded pill)
  - Font: 11px, regular 400, Inter
  - Text color: `#4cb1fe` (matches border)
- **Tailwind classes:** `inline-flex items-center border border-[#4cb1fe] text-[#4cb1fe] text-[11px] font-normal rounded-full px-3 py-1 bg-transparent mx-auto`
- **shadcn override:** The default Badge has opaque backgrounds. Override: `variant="outline"` then apply `className="border-[#4cb1fe] text-[#4cb1fe] rounded-full text-[11px] font-normal bg-transparent"`
- **Dark mode:** `dark:border-[#4cb1fe] dark:text-[#4cb1fe]` — color stays the same (it's a brand accent, not a semantic token)
- **Props:** `variant="outline"`
- **ARIA:** Decorative — `aria-hidden="true"` since it's a marketing label, not functional information

---

### 6. Heading (h1)

- **Element type:** `<h1>` — semantic heading
- **Figma specs:**
  - Text: "Welcome to NextGen"
  - Font: Inter, 28px, Semi Bold (600)
  - Color: `#111c2c` (Text/Heading token)
  - Alignment: center
- **Tailwind classes:** `text-[28px] font-semibold text-[#111c2c] text-center leading-tight`
- **Dark mode:** `dark:text-[var(--color-foreground)]` — map to semantic `text-foreground` since `#111c2c` (Text/Heading) becomes near-white in dark. Use: `text-[#111c2c] dark:text-foreground`
- **Note:** `text-[28px]` is non-standard Tailwind — Figma specifies this exactly. Use arbitrary value.

---

### 7. Subtitle (p)

- **Element type:** `<p>` — body copy
- **Figma specs:**
  - Text: "This is a gentle AI-native platform where you can manage everything at your own pace, with AI as your helpful assistant"
  - Font: Inter, 12px, Regular (400)
  - Color: `#1d2a3e` (Text/Para token)
  - Max width: 354px (narrower than the 400px container — creates visual breathing room)
  - Alignment: center
- **Tailwind classes:** `text-xs font-normal text-[#1d2a3e] text-center max-w-[354px] mx-auto leading-relaxed`
- **Dark mode:** `dark:text-[#a0b4c8]` — Text/Para needs a lighter counterpart in dark. Use `text-[#1d2a3e] dark:text-muted-foreground` as the semantic approximation.
- **Responsive:** On mobile, `max-w-full` — let it reflow naturally within the padded container.

---

### 8. FormSection

- **Element type:** `<div>` — structural wrapper
- **Figma:** flex column, `gap-20px` at top level (between EmailFieldGroup and OAuthSection), `mt-44px` from TitleSection (Figma shows 44px gap between title section and form section)
- **Tailwind classes:** `flex flex-col gap-5 mt-11`
- **Note:** `gap-5 = 20px` on Tailwind 4px base. `mt-11 = 44px` exactly matching Figma's 44px title-to-form gap.

---

### 9. EmailFieldGroup

- **Element type:** `<div>` — groups label, input, error, and CTA button
- **Figma:** flex column, gap-16px between EmailInputGroup and ContinueEmailButton
- **Tailwind classes:** `flex flex-col gap-4`
- **Children:** EmailInputGroup, ContinueEmailButton

---

### 10. EmailInputGroup (FormField wrapper)

- **shadcn base:** `Form`, `FormField`, `FormItem`, `FormLabel`, `FormControl`, `FormMessage`
- **Element type:** `<div>` — label + input + error message grouped
- **Figma:** flex column, gap-8px between label and input
- **Tailwind classes on FormItem:** `flex flex-col gap-2`
- **Implementation:** Use React Hook Form + Zod + shadcn Form pattern (see FormField pattern in shadcn skill)

---

### 11. WorkEmailLabel (FormLabel)

- **shadcn base:** `FormLabel` (in form context) or `Label` (standalone)
- **Figma specs:**
  - Text: "Work email"
  - Font: Inter, 12px, Regular (400)
  - Color: `#516381` (Text/Subdued token)
- **Tailwind classes:** `text-xs font-normal text-[#516381]`
- **shadcn override:** Default FormLabel is typically `text-sm font-medium`. Override with className.
- **Dark mode:** `dark:text-[#8ea4bf]` — subdued text needs a lighter equivalent in dark. Use `text-[#516381] dark:text-muted-foreground`.
- **Accessibility:** Automatically associated with input via shadcn Form's htmlFor wiring

---

### 12. EmailInput

- **shadcn base:** `Input` (type="email")
- **Figma specs:**
  - Width: 400px (full container width)
  - Height: 40px
  - Border: 1px solid `#cad3e2` (Neutral/40 token)
  - Border-radius: 6px
  - Padding: 12px horizontal, 8px vertical (px-12 py-8 in Figma px = 12px, py = 8px)
  - Placeholder: "Enter you work email address..." (exact text including typo "you" — match Figma exactly)
  - Font: Inter, 12px (placeholder text size not explicitly stated but consistent with form)
  - Background: white / transparent
- **Tailwind classes:** `h-10 w-full rounded-[6px] border border-[#cad3e2] px-3 py-2 text-xs placeholder:text-[#8e9fbc] bg-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#006dfa] focus-visible:ring-offset-0`
- **Padding translation:** Figma px-12px = `px-3` (Tailwind 3 = 12px). Figma py-8px = `py-2` (Tailwind 2 = 8px). Height is fixed at `h-10` (40px).
- **shadcn override:** Default Input has `h-9` and standard ring styling. Override height to `h-10` and border color to `[#cad3e2]`.
- **Error state:** When validation error exists — add `border-destructive focus-visible:ring-destructive` via `cn()`.
- **Disabled state:** `disabled:opacity-50 disabled:cursor-not-allowed` (shadcn default, keep as-is)
- **Auto-focus:** `autoFocus` prop on the Input — per story accessibility requirement
- **Dark mode:**
  - Border: `dark:border-[#334155]`
  - Background: `dark:bg-[#001489]` (blue-80 card bg)
  - Text: `dark:text-foreground`
  - Placeholder: `dark:placeholder:text-[#5b7394]`
- **ARIA:** `aria-required="true"`, `aria-describedby` pointing to the FormMessage element id, `aria-invalid` when error is present

---

### 13. FieldError (FormMessage with icon)

- **shadcn base:** `FormMessage` — extended with AlertCircle icon
- **Figma specs:** Not explicitly shown in Figma (error state frame not provided), but derived from story V-01/V-02/V-04 requirements and Figma color tokens
- **Tailwind classes:** `flex items-center gap-1.5 text-xs text-destructive` (wraps icon + message text)
- **Icon:** `AlertCircle` from lucide-react, `h-3.5 w-3.5 shrink-0`
- **Display:** Conditional — only rendered when `field.error` exists
- **Story messages (exact text per validation rule):**
  - V-01: "Email address is required"
  - V-02: "Please enter a valid email address"
  - V-04: "Disposable email addresses are not allowed. Please use a permanent email address."
  - Rate limit: "We're unable to process your request right now. Please try again in a few minutes."
- **Dark mode:** `dark:text-destructive` — semantic token handles it automatically
- **Accessibility:** Rendered with `role="alert"` so screen readers announce immediately. Associated to input via `aria-describedby`.
- **Timing:** Appears on blur (V-01, V-02, V-04) and on submit (all)

---

### 14. TypoSuggestion (non-blocking V-03)

- **Element type:** Custom `<div>` — not a shadcn component, but uses shadcn styling patterns
- **Figma specs:** Not explicitly shown — derived from story V-03 requirement
- **Display:** Conditionally rendered below the email input, above the error (or replacing it when no blocking error)
- **Tailwind classes:** `flex items-center gap-1.5 text-xs text-[#516381] dark:text-muted-foreground`
- **Content pattern:** "Did you mean [corrected@domain.com]?" where the corrected email is a clickable/button element
- **Clickable suggestion:** `<button>` styled with `text-[#006dfa] underline cursor-pointer bg-transparent border-0 p-0 text-xs font-medium hover:text-[#0263e0]`
- **Dismiss:** ESC key dismisses it, or continuing to type hides it
- **ARIA:** `role="status"` so screen reader announces the suggestion without interrupting flow
- **Keyboard:** Suggestion text is activatable via Enter/Space (if implemented as a `<button>`)

---

### 15. ContinueEmailButton

- **shadcn base:** `Button` — customized appearance (not standard primary/secondary)
- **Figma specs:**
  - Text: "Continue with email"
  - Width: 400px (full container width)
  - Height: 40px
  - Background: `#ecf1f9` (Neutral/20 token)
  - Text color: `#516381` (Text/Subdued token)
  - Font: Inter, 12px, Medium (500)
  - Border-radius: 6px
  - No border (no border stroke in Figma)
- **Tailwind classes:** `w-full h-10 rounded-[6px] bg-[#ecf1f9] text-[#516381] text-xs font-medium hover:bg-[#e3e8f2] transition-colors duration-150`
- **shadcn override:** This is NOT a standard shadcn variant. Use `variant="ghost"` as base and override: `className="w-full h-10 rounded-[6px] bg-[#ecf1f9] hover:bg-[#e3e8f2] text-[#516381] text-xs font-medium"`
- **Loading state:**
  - Button disabled: `disabled:opacity-70 disabled:cursor-not-allowed`
  - Shows `<Loader2 className="mr-2 h-4 w-4 animate-spin" />` before text
  - Text changes to "Continuing..." during submission
- **Dark mode:**
  - Background: `dark:bg-[#001489]` (blue-80 — subtle dark card)
  - Text: `dark:text-[#99cdff]` (blue-30 — readable subdued on dark)
  - Hover: `dark:hover:bg-[#043cb5]`
- **Disabled when:** `isSubmitting === true` OR form is invalid and has been submitted once

---

### 16. OrDivider

- **shadcn base:** `Separator` — with centered "OR" label overlaid
- **Figma specs:**
  - Horizontal line: color `#e3e8f2` (Neutral/30 token)
  - "OR" text: Inter, 11px, regular 400, color `#516381` (Text/Subdued)
  - Pattern: line — "OR" — line (centered text breaks the line)
- **Implementation pattern:**
```
<div className="flex items-center gap-3">
  <Separator className="flex-1 bg-[#e3e8f2]" />
  <span className="text-[11px] font-normal text-[#516381] whitespace-nowrap">OR</span>
  <Separator className="flex-1 bg-[#e3e8f2]" />
</div>
```
- **Tailwind classes (container):** `flex items-center gap-3`
- **Dark mode:** `dark:bg-[#043cb5]` on Separator, `dark:text-muted-foreground` on "OR" text

---

### 17. OAuthButtonGroup

- **Element type:** `<div>` — structural wrapper
- **Figma:** flex column, gap-16px between Microsoft and Google buttons
- **Tailwind classes:** `flex flex-col gap-4`

---

### 18. MicrosoftButton

- **shadcn base:** `Button` (`variant="outline"`)
- **Figma specs:**
  - Text: "Continue with Microsoft"
  - Width: 400px (full container width)
  - Height: 40px
  - Border: 1px solid `#cad3e2` (Neutral/40 token)
  - Background: white / transparent
  - Border-radius: 6px
  - Font: Inter, 12px, Medium (500)
  - Text color: `#111c2c` (Text/Heading token)
  - Icon: Microsoft logo icon (colored SVG, left-aligned, standard Microsoft branding)
- **Tailwind classes:** `w-full h-10 rounded-[6px] border border-[#cad3e2] bg-white text-[#111c2c] text-xs font-medium hover:bg-[#f6f9fc] transition-colors duration-150 flex items-center justify-center gap-2`
- **shadcn override:** `variant="outline"` then `className="w-full h-10 rounded-[6px] border-[#cad3e2] text-[#111c2c] text-xs font-medium hover:bg-[#f6f9fc] hover:text-[#111c2c]"`
- **Icon:** `<MicrosoftIcon className="h-4 w-4 shrink-0" />` — custom SVG component or an inline SVG. NOT from lucide-react (must use official Microsoft branding logo).
- **Dark mode:**
  - Border: `dark:border-[#334155]`
  - Background: `dark:bg-transparent`
  - Text: `dark:text-foreground`
  - Hover: `dark:hover:bg-[#001489]`
- **ARIA:** `aria-label="Continue with Microsoft"` — full accessible label even though text is visible (reinforces provider name for screen readers)
- **Disabled when:** Never on this page — OAuth buttons remain active even during email processing (per story Failure Flow 3)

---

### 19. GoogleButton

- **shadcn base:** `Button` (`variant="outline"`)
- **Figma specs:** Same structure as MicrosoftButton
  - Text: "Continue with Google"
  - Width: 400px (full container width)
  - Height: 40px
  - Border: 1px solid `#cad3e2` (Neutral/40 token)
  - Background: white / transparent
  - Border-radius: 6px
  - Font: Inter, 12px, Medium (500)
  - Text color: `#111c2c` (Text/Heading token)
  - Icon: Google "G" logo (colored SVG, left-aligned, standard Google branding)
- **Tailwind classes:** `w-full h-10 rounded-[6px] border border-[#cad3e2] bg-white text-[#111c2c] text-xs font-medium hover:bg-[#f6f9fc] transition-colors duration-150 flex items-center justify-center gap-2`
- **Icon:** `<GoogleIcon className="h-4 w-4 shrink-0" />` — custom SVG component using Google's official "G" mark colors. NOT from lucide-react.
- **Dark mode:** Same as MicrosoftButton
- **ARIA:** `aria-label="Continue with Google"`
- **Tab order:** Google button comes AFTER Microsoft button in Figma layout — maintain this DOM order

---

### 20. PageFooter

- **Element type:** `<footer>` — semantic element
- **Figma:** absolute, bottom 44px from page bottom, 1376px wide (centered within 1440px page = side padding of 32px each)
- **Tailwind classes:** `absolute bottom-11 left-0 right-0 px-8 flex items-center justify-between`
- **Note:** On mobile, footer shifts to `relative` position and stacks vertically.
- **Responsive:**
  - Mobile: `relative flex-col items-center gap-2 py-6 px-5 text-center`
  - Desktop (lg+): `absolute bottom-11 flex-row justify-between px-8`

---

### 21. FooterLeft

- **Element type:** `<div>` — copyright and legal links
- **Figma specs:** "Motadata ©2026" + "Terms" + "Privacy", gap-12px between items, 11px text, `#516381`
- **Tailwind classes:** `flex items-center gap-3 text-[11px] text-[#516381]`
- **Links:** `<a>` elements with `text-[11px] text-[#516381] hover:underline` — target="_blank" for Terms and Privacy
- **Dark mode:** `dark:text-muted-foreground`

---

### 22. FooterCenter (ToS Consent)

- **Element type:** `<p>` — terms of service consent text
- **Figma specs:** 11px, `#516381`, centered, inline links with dotted underline
- **Exact copy:** "By continuing, you agree to our [Terms of Service] and [Privacy Policy]"
- **Tailwind classes:** `text-[11px] text-[#516381] text-center`
- **Links:** `<a target="_blank" rel="noopener noreferrer">` styled with `underline decoration-dotted`
- **ARIA:** Links include `aria-label="Terms of Service (opens in new tab)"` and `aria-label="Privacy Policy (opens in new tab)"` per story accessibility requirement
- **Dark mode:** `dark:text-muted-foreground`

---

### 23. DarkModeToggle (FooterRight)

- **shadcn base:** `Button` (`variant="ghost"`, `size="sm"`)
- **Figma specs:** Icon + "Dark mode" text, 11px, `#516381`
- **Implementation:** Uses `useTheme` hook — toggles between light and dark
- **Tailwind classes:** `flex items-center gap-1.5 text-[11px] text-[#516381] hover:text-foreground transition-colors`
- **Icon:** `<Moon className="h-3.5 w-3.5" />` in light mode, `<Sun className="h-3.5 w-3.5" />` in dark mode
- **Dark mode:** Icon switches, text `dark:text-muted-foreground`
- **ARIA:** `aria-label="Toggle dark mode"` + `aria-pressed` to indicate current state

---

## Form Fields (from story Field Definitions)

| Field | shadcn Component | Type | Tailwind Classes | Placeholder | Required |
|-------|-----------------|------|-----------------|-------------|---------|
| Email Address | `Input` inside `FormField` | `type="email"` | `h-10 w-full rounded-[6px] border-[#cad3e2] px-3 py-2 text-xs` | "Enter you work email address..." | Yes — `aria-required="true"` |
| Plan | Hidden — no UI element | `type="hidden"` / session state | — | — | No — auto-captured |

**Note on placeholder text:** The Figma placeholder reads "Enter you work email address..." — this appears to be a Figma content typo (missing "r" in "your"). The story does not specify a placeholder. Implement as shown in Figma exactly: `"Enter you work email address..."` — flag this as a content review item for the product owner before shipping.

---

## Action Buttons

| Action | Component | Figma Variant | Position | Disabled When |
|--------|-----------|---------------|----------|---------------|
| Continue with email | `Button` (custom bg-[#ecf1f9]) | Not standard variant — custom subdued | Below email input, full width | `isSubmitting === true` |
| Continue with Microsoft | `Button variant="outline"` | Outline, custom border color | Below OR divider | Never (stays active during email rate limit) |
| Continue with Google | `Button variant="outline"` | Outline, custom border color | Below Microsoft button | Never |

---

## Figma Token Map → CSS Variable Mapping

| Figma Token | Hex Value | CSS Variable | Tailwind Usage |
|------------|-----------|-------------|----------------|
| Text/Heading | `#111c2c` | `--color-heading` (custom) | `text-[#111c2c]` with `dark:text-foreground` |
| Text/Para | `#1d2a3e` | `--color-para` (custom) | `text-[#1d2a3e]` with `dark:text-muted-foreground` |
| Text/Subdued | `#516381` | `--color-subdued` (custom) | `text-[#516381]` with `dark:text-muted-foreground` |
| Neutral/40 | `#cad3e2` | used for borders | `border-[#cad3e2]` with `dark:border-[#334155]` |
| Neutral/30 | `#e3e8f2` | used for dividers | `bg-[#e3e8f2]` with `dark:bg-[#043cb5]` |
| Neutral/20 | `#ecf1f9` | used for CTA bg | `bg-[#ecf1f9]` with `dark:bg-[#001489]` |
| Neutral/10 | `#f6f9fc` | used for hover bg | `hover:bg-[#f6f9fc]` |
| Neutral/50 | `#8e9fbc` | used for placeholder text | `placeholder:text-[#8e9fbc]` |
| Neutral/110 | `#2b394f` | not used in primary UI | — |
| Core/White | `#ffffff` | `--color-background` | `bg-white` / `bg-background` |
| Core/Black | `#07101f` | — | Not used in visible UI |
| background/base-weak | `#ffffff` | `--color-background` | `bg-background` |
| Shadow/Black-6 | `#07101f0f` | — | `shadow-sm` pattern |

**CSS Variable additions needed in `src/index.css`:**

The following tokens from Figma do not map to existing semantic variables in the current theme. Add them:

```css
/* Add to :root (light mode) */
--color-heading: #111c2c;      /* Figma: Text/Heading */
--color-para: #1d2a3e;         /* Figma: Text/Para */
--color-subdued: #516381;      /* Figma: Text/Subdued */
--color-neutral-40: #cad3e2;   /* Figma: Neutral/40 — border */
--color-neutral-30: #e3e8f2;   /* Figma: Neutral/30 — divider */
--color-neutral-20: #ecf1f9;   /* Figma: Neutral/20 — subtle bg */
--color-neutral-10: #f6f9fc;   /* Figma: Neutral/10 — hover bg */

/* Add to .dark */
--color-heading: #f1f5f9;
--color-para: #94a3b8;
--color-subdued: #64748b;
--color-neutral-40: #334155;
--color-neutral-30: #043cb5;
--color-neutral-20: #001489;
--color-neutral-10: #043cb5;
```

---

## Figma → Tailwind Translation Reference

### Spacing

| Figma Value | Tailwind Class | Exact px |
|------------|---------------|---------|
| gap: 8px | `gap-2` | 8px |
| gap: 12px | `gap-3` | 12px |
| gap: 16px | `gap-4` | 16px |
| gap: 20px | `gap-5` | 20px |
| gap: 44px (title-to-form) | `mt-11` | 44px |
| padding: 12px (input horizontal) | `px-3` | 12px |
| padding: 8px (input vertical) | `py-2` | 8px |
| top: 24px (logo from top) | `pt-6` | 24px |
| top: 182px (form from top) | `pt-[182px]` | 182px |
| bottom: 44px (footer from bottom) | `bottom-11` | 44px |
| width: 400px (form container) | `max-w-[400px]` | 400px |
| width: 354px (subtitle max-width) | `max-w-[354px]` | 354px |
| height: 40px (inputs, buttons) | `h-10` | 40px |
| page horizontal padding (footer) | `px-8` | 32px each side |

### Typography

| Figma Value | Tailwind Class | Notes |
|------------|---------------|-------|
| 28px, SemiBold 600 | `text-[28px] font-semibold` | Heading h1 — non-standard, use arbitrary |
| 12px, Regular 400 | `text-xs font-normal` | Body text, label, subtitle |
| 12px, Medium 500 | `text-xs font-medium` | Button labels, OAuth buttons |
| 11px, Regular 400 | `text-[11px] font-normal` | Footer text, "OR" divider — use arbitrary |
| Font family | `font-sans` (Inter via CSS variable) | Set `--font-sans: 'Inter', system-ui, sans-serif` in @theme |

### Border Radius

| Figma Value | Tailwind Class | Notes |
|------------|---------------|-------|
| 6px (inputs, buttons) | `rounded-[6px]` | Non-standard — use arbitrary |
| 48px (badge) | `rounded-full` | Pill shape |

### Colors (exact hex — not approximated)

| Usage | Light Hex | Dark Hex | Tailwind |
|-------|-----------|----------|---------|
| Heading text | `#111c2c` | foreground | `text-[#111c2c] dark:text-foreground` |
| Para text | `#1d2a3e` | muted-foreground | `text-[#1d2a3e] dark:text-muted-foreground` |
| Subdued text | `#516381` | muted-foreground | `text-[#516381] dark:text-muted-foreground` |
| Badge border/text | `#4cb1fe` | `#4cb1fe` | `border-[#4cb1fe] text-[#4cb1fe]` |
| Input border | `#cad3e2` | `#334155` | `border-[#cad3e2] dark:border-[#334155]` |
| Divider line | `#e3e8f2` | `#043cb5` | `bg-[#e3e8f2] dark:bg-[#043cb5]` |
| CTA button bg | `#ecf1f9` | `#001489` | `bg-[#ecf1f9] dark:bg-[#001489]` |
| CTA hover bg | `#e3e8f2` | `#043cb5` | `hover:bg-[#e3e8f2] dark:hover:bg-[#043cb5]` |
| OAuth hover bg | `#f6f9fc` | `#001489` | `hover:bg-[#f6f9fc] dark:hover:bg-[#001489]` |
| Placeholder text | `#8e9fbc` | `#5b7394` | `placeholder:text-[#8e9fbc] dark:placeholder:text-[#5b7394]` |
| Page background | `#ffffff` | `#030b5d` | `bg-background` (semantic token) |
| Focus ring | `#006dfa` | `#66b3ff` | `ring-[#006dfa] dark:ring-[#66b3ff]` or `ring-primary` |

---

## Layout Grid

### Desktop (lg+ / 1440px Figma frame)

```
┌─────────────────────────────────────────────────────────────┐
│                        Page (1440px)                        │
│                                                             │
│              Logo (centered, 180x40, top 24px)              │
│                                                             │
│         ┌──────────────────────────────────────┐           │
│         │     MainFormContainer (400px)         │           │
│         │                                      │           │
│         │  [Badge: "Next-Gen SAAS"]            │           │
│         │  [h1: "Welcome to NextGen"]          │           │
│         │  [p: subtitle text centered]         │           │
│         │                                      │           │
│         │  ─────── 44px gap ───────            │           │
│         │                                      │           │
│         │  [Label: "Work email"]               │           │
│         │  [Input: email field — h-10]         │           │
│         │  [CTA: "Continue with email" — h-10] │           │
│         │                                      │           │
│         │  ─── OR ───────────────────          │           │
│         │                                      │           │
│         │  [Microsoft Button — h-10]           │           │
│         │  [Google Button — h-10]              │           │
│         └──────────────────────────────────────┘           │
│                                                             │
│  ┌─────────────┐  ┌──────────────────────┐  ┌──────────┐  │
│  │ Motadata    │  │ ToS consent text      │  │Dark mode │  │
│  │ ©2026 Terms │  │ (centered)            │  │ toggle   │  │
│  │ Privacy     │  │                       │  │          │  │
│  └─────────────┘  └──────────────────────┘  └──────────┘  │
│                     (footer, absolute bottom-11)            │
│                                                             │
│ [Background gradient — decorative, absolute bottom layer]   │
└─────────────────────────────────────────────────────────────┘
```

### Mobile (default / < 640px)

```
┌─────────────────────────────────────┐
│         Page (full-width)           │
│                                     │
│     [Logo — centered, 140px wide]   │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  MainFormContainer (w-full)   │  │
│  │                               │  │
│  │  [Badge] centered             │  │
│  │  [h1] centered, smaller       │  │
│  │  [p] subtitle, full width     │  │
│  │                               │  │
│  │  [Label: "Work email"]        │  │
│  │  [Input: full width, h-10]    │  │
│  │  [Error message if any]       │  │
│  │  [CTA button — full width]    │  │
│  │                               │  │
│  │  ─── OR ─────────────────     │  │
│  │                               │  │
│  │  [Microsoft Button full-w]    │  │
│  │  [Google Button full-w]       │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Footer (relative, stacked)    │  │
│  │ ToS text (centered)           │  │
│  │ Copyright   Terms   Privacy   │  │
│  │         [Dark mode toggle]    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## Copy Text Table (Character-for-Character from Figma)

| Element | Exact Copy | Notes |
|---------|-----------|-------|
| Badge | "Next-Gen SAAS" | All-caps "SAAS" |
| Page heading | "Welcome to NextGen" | "NextGen" as one word |
| Subtitle | "This is a gentle AI-native platform where you can manage everything at your own pace, with AI as your helpful assistant" | Exact punctuation, hyphen in "AI-native" |
| Label | "Work email" | Lowercase "email" |
| Placeholder | "Enter you work email address..." | Contains typo "you" instead of "your" — match Figma exactly, flag for review |
| CTA button | "Continue with email" | Lowercase "email" |
| OR divider | "OR" | All caps |
| Microsoft button | "Continue with Microsoft" | Proper casing |
| Google button | "Continue with Google" | Proper casing |
| Footer copyright | "Motadata ©2026" | Copyright symbol ©, not (c) |
| Footer Terms | "Terms" | No period |
| Footer Privacy | "Privacy" | No period |
| ToS consent | "By continuing, you agree to our Terms of Service and Privacy Policy" | "Terms of Service" and "Privacy Policy" are linked |
| Dark mode toggle | "Dark mode" | Lowercase "mode" |
| V-01 error | "Email address is required" | Exact per story |
| V-02 error | "Please enter a valid email address" | Exact per story |
| V-04 error | "Disposable email addresses are not allowed. Please use a permanent email address." | Exact per story, two sentences with period |
| Rate limit error | "We're unable to process your request right now. Please try again in a few minutes." | Exact per story, two sentences |
| V-03 suggestion | "Did you mean [corrected domain]?" | Dynamic — corrected domain interpolated |
| OAuth error (provider) | "We couldn't complete authentication with [Google/Microsoft]. Please try again or use email instead." | Dynamic per provider |
| OAuth error (email missing) | "We couldn't retrieve your email from [Google/Microsoft]. Please try again or use email instead." | Dynamic per provider |
| OAuth error (unavailable) | "[Google/Microsoft] authentication is temporarily unavailable. Please try again later or use email instead." | Dynamic per provider |

---

## Color Strategy

### Use CSS Variable Semantic Tokens for:

| Element | Token | Rationale |
|---------|-------|-----------|
| Page background | `bg-background` | Maps to `#ffffff` / dark: `#030b5d` — automatic theming |
| Destructive error text | `text-destructive` | Maps to `#db132a` / dark: `#f58a8a` — semantic |
| Focus ring on email input | `ring-primary` or `ring-ring` | Maps to `#006dfa` / dark: `#66b3ff` — semantic |
| Footer links hover | `hover:text-foreground` | Semantic for hover transitions |

### Use Exact Hex (Figma-accurate, not approximated) for:

| Element | Hex | Reason for Exact Hex |
|---------|-----|---------------------|
| Heading text | `#111c2c` | Figma Text/Heading token — no matching semantic token |
| Para text | `#1d2a3e` | Figma Text/Para token — no matching semantic token |
| Subdued text | `#516381` | Figma Text/Subdued token — no matching semantic token |
| Badge border/text | `#4cb1fe` | Brand accent, one-off — exact hex required |
| Input border | `#cad3e2` | Figma Neutral/40 — no matching semantic token |
| Divider line | `#e3e8f2` | Figma Neutral/30 — no matching semantic token |
| CTA button bg | `#ecf1f9` | Figma Neutral/20 — no matching semantic token |
| Hover backgrounds | `#e3e8f2`, `#f6f9fc` | Figma Neutral/30, Neutral/10 — exact required |
| Placeholder color | `#8e9fbc` | Figma Neutral/50 — no matching semantic token |

---

## Loading States

### Skeleton Layout (page loading / prefetch)

Not applicable for this page — the entry page has no async data to load before rendering. The form renders immediately. No skeleton needed.

### Submit Loading State (in-flight after "Continue with email")

```
MainFormContainer
├── TitleSection (unchanged)
└── FormSection
    ├── EmailFieldGroup
    │   ├── EmailInputGroup
    │   │   ├── Label (unchanged)
    │   │   └── Input — disabled (opacity-50)
    │   └── ContinueEmailButton
    │       ├── Loader2 icon (animate-spin, h-4 w-4, mr-2)
    │       └── Text: "Continuing..."  [or keep "Continue with email" — product decision]
    │       [Button: disabled, opacity-70]
    └── OAuthSection (unchanged — OAuth buttons remain fully interactive)
```

**Submit state details:**
- `isSubmitting = true` — set immediately on first click, before any validation
- Email Input: `disabled={isSubmitting}` — prevents editing during request
- ContinueEmailButton: `disabled={isSubmitting}` — shows spinner icon
- OAuth buttons: NOT disabled during email submission (per story Failure Flow 3)

---

## Error States

### Field-Level Errors (V-01, V-02, V-04)

- **Display position:** Directly below the email Input, above the ContinueEmailButton
- **Icon:** `<AlertCircle className="h-3.5 w-3.5 shrink-0" />` from lucide-react
- **Text style:** `text-xs text-destructive` — 12px, `#db132a` light / `#f58a8a` dark
- **Input border changes:** `border-destructive` — red border on the Input when error is active
- **Timing:**
  - V-01, V-02, V-04: Shown on blur and on submit
  - V-03 (suggestion): Shown on blur only, NOT blocking
- **Recovery:** Error clears when user focuses the field and starts typing (debounce or on any input change)
- **ARIA:** `role="alert"` on the error message div for immediate announcement

### Rate Limit Error (Failure Flow 3)

- **Display position:** Above the email input (page-level inline error, not field-level)
- **Component:** `Alert` from shadcn/ui with `AlertCircle` icon
- **Variant:** `destructive`
- **Tailwind classes:** `w-full rounded-[6px]`
- **Content:** "We're unable to process your request right now. Please try again in a few minutes."
- **Behavior:** Email field and Continue button remain visible and interactive. OAuth buttons unaffected.

### OAuth Provider Errors (Edge Case 10)

- **Display position:** Below the OAuth button that was clicked, or as a page-level `Alert`
- **Component:** `Alert` variant="destructive" — shown above the form section on return from OAuth
- **Dismiss:** Cleared when user starts typing in the email field or clicks any button

---

## Accessibility Spec (from story)

### Focus Management

| Moment | Focus Target | Implementation |
|--------|-------------|----------------|
| Page load | Email Input | `autoFocus` prop on Input |
| Validation error (V-01/V-02/V-04) | Email Input | `inputRef.current?.focus()` after error state set |
| Typo suggestion shown | Email Input stays focused | Suggestion appears non-intrusively below |
| Submit success | Navigate to OTP page | Focus reset by new page mount |
| OAuth error return | Email Input | Auto-focus on page re-render |

### Tab Order

1. Email Input (auto-focused on load)
2. ContinueEmailButton ("Continue with email")
3. MicrosoftButton ("Continue with Microsoft")
4. GoogleButton ("Continue with Google")
5. ToS "Terms of Service" link (FooterCenter)
6. ToS "Privacy Policy" link (FooterCenter)
7. Footer "Terms" link (FooterLeft)
8. Footer "Privacy" link (FooterLeft)
9. DarkModeToggle

**Implementation:** Maintain natural DOM order — do not use `tabindex` overrides. The DOM order must match the visual order above.

### Screen Reader Announcements

| Trigger | What is Announced | ARIA Implementation |
|---------|------------------|---------------------|
| Error appears (V-01/V-02/V-04) | Error message text immediately | `role="alert"` on error div |
| Typo suggestion (V-03) | "Did you mean [email]?" | `role="status"` — polite announcement |
| Button loading state | "Loading" or "Continuing..." | Button text change + `aria-busy="true"` |
| Email input | "Work email, required, edit text" | `FormLabel` + `aria-required="true"` |
| ToS links | "Terms of Service, opens in new tab" | `aria-label` with "(opens in new tab)" |
| OAuth buttons | "Continue with Google, button" | Visible text + `aria-label` |

### Keyboard Interactions

| Element | Key | Action |
|---------|-----|--------|
| Email Input | Enter | Submits form (same as clicking Continue) |
| TypoSuggestion | Escape | Dismisses suggestion |
| TypoSuggestion (as button) | Enter / Space | Accepts correction, updates input |
| OAuth Button | Enter / Space | Initiates OAuth redirect |
| Dark mode toggle | Enter / Space | Toggles theme |
| ToS links | Enter | Opens link in new tab |

### Visual Accessibility

- Error state uses BOTH `text-destructive` color AND `AlertCircle` icon — not color alone
- Input error state uses both red border AND error message below — not color alone
- Continue button loading state uses BOTH spinner icon AND disabled opacity
- All interactive elements have visible focus rings (`focus-visible:ring-2 focus-visible:ring-primary`)
- Minimum touch target: 40px height on all buttons and input (matches Figma h-10 = 40px)

---

## Dark Mode Notes

### Elements Requiring `dark:` Variants

| Element | Light | Dark | Implementation |
|---------|-------|------|---------------|
| Page background | `bg-white` | `bg-background` (dark: `#030b5d`) | Use `bg-background` semantic token |
| Heading text | `text-[#111c2c]` | `dark:text-foreground` | Pair with dark: override |
| Subtitle text | `text-[#1d2a3e]` | `dark:text-muted-foreground` | Pair with dark: override |
| Subdued text | `text-[#516381]` | `dark:text-muted-foreground` | Pair with dark: override |
| Input border | `border-[#cad3e2]` | `dark:border-[#334155]` | Pair with dark: override |
| Input background | `bg-white` | `dark:bg-[#001489]` | Pair with dark: override |
| CTA button bg | `bg-[#ecf1f9]` | `dark:bg-[#001489]` | Pair with dark: override |
| CTA hover | `hover:bg-[#e3e8f2]` | `dark:hover:bg-[#043cb5]` | Pair with dark: override |
| OAuth button bg | `bg-white` | `dark:bg-transparent` | Pair with dark: override |
| Divider line | `bg-[#e3e8f2]` | `dark:bg-[#043cb5]` | Pair with dark: override |
| Footer text | `text-[#516381]` | `dark:text-muted-foreground` | Pair with dark: override |
| Logo | As-is | `dark:invert` or dark asset | Depends on logo SVG |

### Badge (`#4cb1fe`) in Dark Mode

The badge border and text color `#4cb1fe` is a brand accent — it reads well on both light and dark backgrounds. **No dark: override needed** for the badge — use the same color in both modes.

---

## Component File Map (for feature-dev reference)

```
src/
├── pages/
│   └── entry/
│       └── EmailEntryPage.tsx          ← Page component (EmailEntryPageProps)
├── features/
│   └── entry/
│       ├── components/
│       │   ├── EmailField.tsx          ← EmailFieldProps (Input + Label + FormMessage + TypoSuggestion)
│       │   ├── ContinueEmailButton.tsx ← ContinueButtonProps (LoadingButton wrapper)
│       │   ├── OAuthButton.tsx         ← OAuthButtonProps (Microsoft + Google variants)
│       │   ├── OrDivider.tsx           ← Separator + "OR" layout
│       │   ├── TypoSuggestion.tsx      ← TypoSuggestion display + dismiss
│       │   ├── TagInHeadingBadge.tsx   ← Badge with exact Figma styles
│       │   └── PageFooter.tsx          ← Footer with ToS, copyright, dark mode toggle
│       ├── hooks/
│       │   ├── useEmailEntryForm.ts    ← Form state + validation + submission logic
│       │   └── useTypoDetection.ts     ← V-03 typo detection logic
│       └── validation/
│           └── emailEntrySchema.ts     ← Zod schema (V-01, V-02, V-04)
└── components/
    ├── ui/                             ← shadcn primitives
    └── common/
        └── ThemeToggle.tsx             ← Dark mode toggle (reusable)
```

---

## shadcn Components Required

Install via `npx shadcn@latest add`:

```bash
npx shadcn@latest add form
npx shadcn@latest add input
npx shadcn@latest add label
npx shadcn@latest add button
npx shadcn@latest add badge
npx shadcn@latest add separator
npx shadcn@latest add alert
```

Custom SVG components needed (NOT from shadcn, build manually):
- `GoogleIcon` — Google "G" logo (4 colors, official branding)
- `MicrosoftIcon` — Microsoft logo (4-color squares, official branding)

---

## Pre-flight Checklist

- [x] Every field from story's Field Definitions has a corresponding UI component — Email: Input (visible), Plan: hidden/session (no UI)
- [x] Every flow (main, alternate, failure) has UI representation:
  - Main Flow: Email Input + ContinueEmailButton → loading state → navigate
  - Alternate Flow A: MicrosoftButton + GoogleButton → redirect
  - Failure Flow 1: FieldError (V-01, V-02) inline below input
  - Failure Flow 2: FieldError (V-04) inline below input
  - Failure Flow 3: Alert (rate limit) above form
- [x] Loading, empty, and error states are defined — submit loading, field errors, rate limit alert, OAuth errors
- [x] Responsive behavior is specified for mobile (w-full, stacked footer) and desktop (400px fixed, absolute footer)
- [x] Accessibility requirements from story are mapped — auto-focus, tab order, aria-describedby, role="alert", aria-required, screen reader announcements
- [x] Color tokens use CSS variables where semantic tokens exist; exact hex where they don't
- [x] Component choices follow shadcn/ui patterns — Form, Input, Label, Button, Badge, Separator, Alert
- [x] Layout follows mobile-first approach — `w-full` base, `max-w-[400px]` on desktop
- [x] All copy text from Figma is character-for-character accurate (including placeholder typo flagged)
- [x] Dark mode `dark:` variants are specified for every element using exact hex colors
- [x] Validation timing correctly reflected: on blur (V-01, V-02, V-03, V-04), on submit client (V-01, V-02, V-04), on submit server (V-04)
- [x] Double-submission prevention reflected in button disabled state
- [x] Anti-enumeration invariant has no UI implication (uniform behavior — no extra UI state needed)
- [x] OAuth buttons remain active during email rate limit — documented in disabled conditions
- [x] V-03 typo suggestion is non-blocking (separate from FormMessage error, different ARIA role)

---

## Open Items / Flags for Review

1. **Placeholder typo:** Figma placeholder reads "Enter you work email address..." — appears to be missing "r" ("your"). Implement as Figma shows; flag to product owner for confirmation before shipping.
2. **Background gradient:** Figma shows a decorative gradient at the bottom half of the page. Exact gradient colors and stops are not captured in the token map provided. Feature-dev should request the gradient CSS from the designer or extract from the Figma export.
3. **Submit button text during loading:** Story says button shows "a loading indicator" — does not specify if button text changes. Current spec proposes keeping "Continue with email" + spinner. Confirm with product.
4. **INV-8 / INV-9 invariant conflict:** Flagged in story-analyzer — confirm scope before implementation. No UI change needed, but architectural decision may affect OAuth button wiring.
5. **Plan parameter badge:** Story mentions capturing `?plan=` parameter but states it is NOT displayed on this page (no plan badge or plan information). Confirmed: no plan UI element on this page.
