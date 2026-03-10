# Story Specification: US-TM-01.1.01 — Enter Work Email to Begin

---

## 1. Metadata

| Field | Value |
|-------|-------|
| Story ID | US-TM-01.1.01 |
| Title | Enter Work Email to Begin |
| Epic ID | EP-TM-01 |
| Epic Name | Self-Service Tenant Provisioning |
| Feature ID | FE-TM-01.1 |
| Feature Name | Identity Entry & Validation |
| Story Type | User-Facing (Functional) |
| Primary Actor | Prospective Tenant Admin |
| Secondary Actors | System |
| Applies To | All Tenants (Direct) |
| Story Version | v1.8 |
| Last Updated | 2026-02-22 |
| Build Phase | A (foundation — must ship before any other FE-TM-01.1 stories that depend on entry) |

---

## 2. User Story

- **As a** Prospective Tenant Admin
- **I want** to enter my work email address on the entry page
- **So that** the platform can verify my identity and route me to workspace creation (new user) or my existing workspace (returning user)
- **Success:** The user's email is accepted, validated, and the user is directed to the OTP verification page (email path) or OAuth authentication flow (OAuth path). The system gives a uniform response regardless of whether the email is new or already registered — no account existence information is revealed.

---

## 3. Scope

### Preconditions

1. Entry page is publicly accessible (platform is not in maintenance mode or entry-disabled state)
2. Seeded subscription plans and system configuration are available (FE-TM-01.0 dependency)
3. Email delivery service is operational (required for OTP step that follows)
4. Google and Microsoft OAuth provider integration is configured (required for OAuth entry options)

### Out of Scope

- OAuth authentication flow behavior — buttons are displayed on this page but flow logic is in the OAuth authentication story (US-TM-01.1.02)
- OTP generation and sending logic — handled by OTP send story (US-TM-01.1.03)
- OTP verification and session establishment — handled by OTP verify story (US-TM-01.1.04)
- Workspace creation page — personal details, organization name, subdomain, and workspace setup (Step 3 — US-TM-01.1.05); returning users redirected to existing workspace by verification stories
- Anti-fraud checks beyond disposable email detection — handled by anti-fraud story (US-TM-01.1.08)
- Plan parameter validation and display logic — handled by plan acceptance story (US-TM-01.1.09); this story only captures and persists the parameter
- User and Tenant record creation — both happen at workspace creation in Step 3, not here
- Password-based authentication (platform is fully passwordless in MVP)
- Magic link verification (not planned; OTP only)
- MFA setup (deferred)
- Enterprise SSO / SAML for workspace login (Phase 2)
- "Join existing organization" flow
- Pricing page UI, "Contact Sales" CTA, and enterprise-specific entry flows
- Payment collection during entry

---

## 4. Flows

### Main Flow (Happy Path)

1. Prospective tenant navigates to entry page (e.g., `/signup`, `/signin`, `/entry` — all resolve to same page) from pricing page with plan query parameter, from marketing site, or directly.
2. System displays entry page with:
   - Email Address field (required, auto-focused)
   - "Continue" button (primary CTA)
   - "Continue with Google" button (OAuth alternate)
   - "Continue with Microsoft" button (OAuth alternate)
   - Implicit Terms of Service consent text: "By continuing, you agree to our [Terms of Service] and [Privacy Policy]" — links open in new tab
3. If a `?plan=` query parameter is present in the URL, system captures it in session state for use in later entry steps (plan acceptance story handles parameter details). Defaults to Professional trial if absent or unrecognized.
4. Prospective tenant enters their email address.
5. Prospective tenant clicks the "Continue" button.
6. System immediately disables the "Continue" button and shows a loading indicator to prevent double-submission.
7. System validates email per validation rules (V-01, V-02, V-04 on submit client-side gate).
8. System checks disposable email blocklist server-side as the authoritative validation (V-04). If blocked, error returned to entry page, "Continue" re-enabled.
9. If all checks pass, system directs user to OTP verification page and triggers OTP send (US-TM-01.1.03) — uniform response regardless of whether the email is new or already registered.
10. System records audit event: "Entry initiated (email path)" with protected email reference, IP address, user agent, plan parameter (if present), and timestamp.

**End State:**
- User is on the OTP verification page, waiting to receive and enter the OTP code.
- No User or Tenant records are created at this step.
- Plan parameter (if present) is preserved in session state.
- ToS consent is implied by proceeding (timestamp and version recorded at tenant creation in Step 3).

**Processing Behavior:**
- On validation failure: inline error message appears below the email field; "Continue" button re-enabled; email field value preserved.
- Expected processing time: under 1 second (user-perceived).

### Alternate Flows

#### Alternate Flow A — OAuth Entry Selected

**Trigger Condition:** User clicks "Continue with Google" or "Continue with Microsoft" instead of entering email.

1. System redirects to the selected OAuth provider's authentication page.
2. Subsequent behavior is defined in the OAuth authentication story (US-TM-01.1.02).

**End State:** User is in the OAuth provider's authentication flow. This story's responsibility ends at the redirect.

### Failure Flows

#### Failure Flow 1 — Email Validation Errors (Client-Side)

**Trigger Condition:** Email field is empty, or email format is invalid.

1. System does not proceed past the entry page.
2. No server-side checks performed for format failures caught client-side.
3. Inline error message displayed below the email field (see Validation Rules for specific messages).
4. "Continue" button re-enabled for retry.
5. Email field value preserved.

**Recovery:** User corrects the email and clicks "Continue" again.

#### Failure Flow 2 — Disposable Email Detected

**Trigger Condition:** Email domain is in the disposable email blocklist (client-side on blur/submit, or server-side on submit).

1. System blocks the entry attempt.
2. No OTP is sent.
3. Error message displayed below email field: "Disposable email addresses are not allowed. Please use a permanent email address."
4. "Continue" button re-enabled.

**Recovery:** User enters a non-disposable (permanent) email address.

#### Failure Flow 3 — Rate Limited

**Trigger Condition:** User has exceeded per-IP entry rate limits (anti-fraud story details).

1. Error message displayed: "We're unable to process your request right now. Please try again in a few minutes."
2. Email field and "Continue" button remain visible.
3. OAuth buttons remain active (not affected by email rate limits).

---

## 5. Data Model

### Field Definitions

| Field | Type | Required | Length | Default | Allowed Characters | Behavior |
|-------|------|----------|--------|---------|---------------------|----------|
| Email Address | email input | Yes | Max 255 characters | — (empty) | Valid email format per RFC 5322 | Normalized to lowercase before validation and storage. Value preserved on validation error. Auto-focused on page load. |
| Plan | hidden (session) | No | — | "professional" (trial) | URL-safe plan identifier string | Captured from URL query parameter `?plan=...`. Not user-editable. Not displayed on this page. Persisted in session state for use in workspace setup (Step 3). Defaults to Professional trial if absent or unrecognized (including "enterprise"). |

### Validation Rules

| ID | Field | Condition | Error Message | Display | Timing | Blocking |
|----|-------|-----------|---------------|---------|--------|---------|
| V-01 | Email Address | Field is empty on blur or submit | "Email address is required" | Inline below field | On blur (client), on submit (client) | Yes — blocks form submission |
| V-02 | Email Address | Value does not conform to RFC 5322 email format | "Please enter a valid email address" | Inline below field | On blur (client), on submit (client) | Yes — blocks form submission |
| V-03 | Email Address | Common domain typo detected (e.g., "gmial.com", "yaho.com", "outlok.com") — not an exhaustive list | "Did you mean [corrected domain]?" (where [corrected domain] is the suggested correction) | Suggestion below field (dismissible) | On blur (client) only — not on submit | No — suggestion only, does not block |
| V-04 | Email Address | Domain is in the disposable email blocklist (community-maintained open-source list, e.g., disposable-email-domains, ~3,500+ domains, bundled as static client asset) | "Disposable email addresses are not allowed. Please use a permanent email address." | Inline below field | On blur (client), on submit (client + server-side as authoritative check) | Yes — blocks form submission |

### Validation Timing Summary

| Timing | Rules Applied |
|--------|--------------|
| On blur, client-side | V-01, V-02, V-03, V-04 |
| On submit, client-side (gate before server call) | V-01, V-02, V-04 |
| On submit, server-side (authoritative) | V-04 |

**Anti-enumeration note:** Account existence is never checked or revealed at this step. All valid, non-disposable emails proceed uniformly to the OTP verification page — this is a hard invariant.

---

## 6. State Machine

No User or Tenant state transitions occur in this story. No records are created at this step.

| From State | Event | To State | User Visibility |
|------------|-------|----------|-----------------|
| (no record exists) | Email submitted and passes all validation (V-01, V-02, V-04) | (no record — session state only: email + plan parameter) | User directed to OTP verification page |
| (no record exists) | OAuth button clicked | (no record) | User redirected to OAuth provider authentication page |
| (no record exists) | Validation failure (V-01 / V-02 / V-04) | (no record) | Inline error shown; user remains on entry page |

---

## 7. Side Effects

### Notifications

No notifications are sent in this story.

### Audit Events

| Action | Trigger | Captured Data | Privacy |
|--------|---------|---------------|---------|
| Entry initiated (email path) | User submits email and passes all validation (Main Flow step 10) | Actor email (protected/hashed — not plaintext), IP address, user agent, plan parameter (if present), timestamp | Email stored as hash — not plaintext |

### Analytics Events

| Event | Trigger | Business Signal | Metrics It Feeds |
|-------|---------|-----------------|------------------|
| Entry page viewed | User loads entry page (Main Flow step 2) | Top-of-funnel entry | Entry funnel, traffic source analysis, landing page effectiveness |
| Email entry initiated | User submits email and passes validation (Main Flow step 9) | Email path chosen, Step 1 completed | Entry funnel (email vs OAuth split), Step 1 to Step 2 conversion rate |
| OAuth path selected | User clicks Google or Microsoft button (Alternate Flow A) | OAuth path chosen, provider preference | Entry funnel (email vs OAuth split), provider distribution |
| Disposable email blocked | Disposable email rejected by V-04 | Fraud/abuse signal | Anti-fraud effectiveness, blocklist coverage |
| Typo suggestion shown | Common domain typo detected by V-03 | Input quality signal | Typo suggestion frequency, acceptance rate |

---

## 8. Data Lifecycle

No PII is persisted by this story's functional flow. Email is validated client-side and passed to the OTP send story — no server-side storage at this step. Plan parameter is stored in session (non-PII, transient).

| Data Element | PII | Retention | Deletion Trigger | Compliance Basis |
|--------------|-----|-----------|------------------|-----------------|
| Audit event (email reference — hashed) | Yes (protected) | Per platform audit retention policy | Platform audit retention rules | SOC2 CC7.2; GDPR Art. 5(1)(e) |
| Plan parameter (session state) | No | Duration of entry session | Session expiry or workspace creation | Not applicable |
| Email (in-flight, not stored) | Yes | Not persisted at this step | Passed to OTP send story | Not applicable |

---

## 9. Edge Cases

1. **Double-click "Continue":** Button is disabled on first click (step 6 of main flow). Only one request is processed. Button shows loading state after first click. No error shown. Single normal flow proceeds.

2. **Browser back after proceeding to OTP page:** Entry page is displayed (standard browser behavior). If user re-enters the same email and submits, the uniform flow applies — user is directed to OTP verification page again. OTP send story (US-TM-01.1.03) handles whether to send a new OTP or reuse the existing one. No error or indication that a previous attempt exists.

3. **Expired pending signup — re-entry:** User enters an email that had a previous pending signup where all OTP attempts expired and verification window closed. System cleans up the expired pending record. Treats email as new. Normal main flow proceeds. User is not aware of the previous expired attempt.

4. **Session timeout before OTP entry:** User submits email, is directed to OTP page, but takes too long before entering OTP (session expires). OTP verification page detects expired session. User is directed back to entry page. User re-enters email. Uniform flow applies — OTP send story handles fresh OTP generation.

5. **Email with uppercase characters:** Normalized to lowercase before validation and storage (e.g., "Admin@COMPANY.COM" becomes "admin@company.com"). No error shown.

6. **Unrecognized plan parameter:** Plan parameter is captured but not recognized as a valid self-service plan (e.g., "?plan=enterprise", "?plan=gold"). Silently defaults to Professional trial. No error or warning shown at this step.

7. **Existing registered email (returning user):** Uniform flow — identical response to a new email. User proceeds to OTP verification page. Account status routing happens after verification in subsequent stories.

8. **Email with pending verification:** Identical response to new email. User proceeds to OTP verification page. OTP send story (US-TM-01.1.03) decides whether to send a new OTP or reuse existing.

9. **OAuth cancel (user cancels at provider):** User returns to entry page. No error message shown. All buttons available for retry.

10. **OAuth provider error:** User returns from OAuth to entry page. Inline error displayed. All buttons available for retry. Error messages:
    - Provider error: "We couldn't complete authentication with [Google/Microsoft]. Please try again or use email instead."
    - Email missing: "We couldn't retrieve your email from [Google/Microsoft]. Please try again or use email instead."
    - Provider unavailable: "[Google/Microsoft] authentication is temporarily unavailable. Please try again later or use email instead."

---

## 10. Accessibility

- **Focus:** Email field is auto-focused on page load. On validation error (V-01, V-02, V-04), focus returns to the email field.
- **Screen Reader:**
  - Validation errors (V-01, V-02, V-04) announced to screen readers immediately when they appear below the field.
  - Typo suggestion (V-03) announced as a non-blocking suggestion.
  - "Continue" button loading state (disabled + spinner) announced as processing state.
  - ToS and Privacy Policy links indicate they open in a new tab (e.g., via `aria-label` or visible text cue).
- **Keyboard:**
  - Tab order: Email field → Continue button → Continue with Google → Continue with Microsoft → ToS link → Privacy Policy link.
  - Typo suggestion (V-03) dismissible via Escape key or by continuing to type.
  - Typo suggestion clickable/activatable via Enter or Space.
  - OAuth buttons activatable via Enter or Space.
- **Visual:**
  - Email field labeled (visible or accessible label).
  - Required field indicated.
  - Error state uses distinct color and icon — not color alone.
  - Inline error message associated with field via `aria-describedby` or equivalent.
  - OAuth buttons include provider name in accessible label (not icon-only): "Continue with Google", "Continue with Microsoft".
  - "Continue" button visually indicates disabled/loading state during processing.

---

## 11. Acceptance Criteria

### Functional

- FC-01: Entry page displays email field, "Continue" button, "Continue with Google" button, "Continue with Microsoft" button, and ToS consent text with working links.
- FC-02: No password field, no organization name field, no subdomain field is present on this page.
- FC-03: Prospective tenant can submit an email address to begin the entry flow.
- FC-04: Disposable email addresses are rejected before proceeding to the OTP page — client-side (on blur and on submit) for fast feedback, server-side (on submit) as the authoritative validation.
- FC-05: All valid non-disposable emails proceed uniformly to the OTP verification page — no account existence information is revealed at this step.
- FC-06: System gives identical response for new emails, previously used emails (regardless of signup stage), and emails with pending verification — uniform "proceed to OTP" behavior.
- FC-07: If `?plan=` query parameter is present in URL, it is captured in session state for later use.
- FC-08: If plan parameter is absent or unrecognized, Professional trial is assumed silently — no error shown.
- FC-09: Entry initiation event is logged in audit trail with hashed email, IP, user agent, plan parameter, and timestamp.
- FC-10: "Continue" button is disabled during processing and re-enabled after validation failure.
- FC-11: ToS consent is implicit — proceeding constitutes agreement (text and links displayed before action).
- FC-12: Email is normalized to lowercase before validation and storage.
- FC-13: On validation error, email field value is preserved (not cleared).
- FC-14: Clicking a typo suggestion (V-03) updates the email field with the corrected value.
- FC-15: V-03 typo suggestion is dismissible via Escape key or by continuing to type.

### Non-Functional

- NFC-01: Email validation and submission completes within 1 second (user-perceived response time).
- NFC-02: Entry page is keyboard navigable — all interactive elements reachable and operable via keyboard alone.
- NFC-03: Entry page is screen reader compatible — all fields, errors, and states have proper ARIA labels and announcements.
- NFC-04: Error messages are clear, specific, and actionable.
- NFC-05: Page works on both desktop and mobile viewports.
- NFC-06: OAuth buttons are visually distinct and recognizable per Google and Microsoft branding guidelines.
- NFC-07: Entry page must not be indexed by search engines in a way that reveals internal routing details.
- NFC-08: No account enumeration is possible at this step — uniform response is enforced at all layers (client and server).

---

## 12. Test Scenarios

### TS-01: Happy Path — New Email, No Plan Parameter

- **Precondition:** No existing user with "admin@newcompany.com"
- **Steps:**
  1. Navigate to `/signup` (no plan query parameter)
  2. Verify page displays email field, Continue button, Google/Microsoft OAuth buttons, ToS text — no plan badge or plan information displayed
  3. Enter "admin@newcompany.com"
  4. Click "Continue"
  5. Verify "Continue" button shows loading indicator and becomes disabled
  6. Verify system validates email (valid format, not disposable)
  7. Verify user is directed to OTP verification page
  8. Verify entry initiation audit event is logged
- **Expected Result:** User is on OTP verification page. No User or Tenant record created. Session state has no plan parameter (will default to Professional trial at workspace setup).
- **Validation Rules Exercised:** V-02 (passes), V-04 (passes)

### TS-02: Happy Path — New Email, With Plan Parameter

- **Precondition:** No existing user with "founder@startup.io"
- **Steps:**
  1. Navigate to `/signup?plan=business`
  2. Verify system captures "business" plan parameter in session state
  3. Enter "founder@startup.io"
  4. Click "Continue"
  5. Verify email passes all checks
  6. Verify user is directed to OTP verification page
- **Expected Result:** User is on OTP verification page. Plan parameter "business" preserved in session state for use at workspace setup (Step 3).
- **Validation Rules Exercised:** V-02 (passes), V-04 (passes)

### TS-03: Validation Failure — Empty Email on Submit

- **Precondition:** None
- **Steps:**
  1. Navigate to `/signup`
  2. Click "Continue" without entering any email
  3. Verify V-01 error displayed inline below email field: "Email address is required"
  4. Verify "Continue" button is re-enabled
- **Expected Result:** Error shown. No navigation away from entry page. No server request made.
- **Validation Rules Exercised:** V-01 (triggered)

### TS-04: Validation Failure — Invalid Email Format

- **Precondition:** None
- **Steps:**
  1. Navigate to `/signup`
  2. Enter "not-an-email" in email field
  3. Click "Continue"
  4. Verify V-02 error displayed: "Please enter a valid email address"
  5. Verify "Continue" button is re-enabled
  6. Verify email field retains "not-an-email"
- **Expected Result:** Error shown. Email field retains entered value. No navigation.
- **Validation Rules Exercised:** V-02 (triggered)

### TS-05: Disposable Email Rejected

- **Precondition:** "tempmail.com" is in disposable email blocklist
- **Steps:**
  1. Navigate to `/signup`
  2. Enter "test@tempmail.com"
  3. Click "Continue"
  4. Verify V-04 error displayed: "Disposable email addresses are not allowed. Please use a permanent email address."
  5. Verify "Continue" button is re-enabled
- **Expected Result:** Entry blocked. No OTP sent. No records created.
- **Validation Rules Exercised:** V-04 (triggered — client-side and server-side)

### TS-06: Email Typo Suggestion — User Accepts

- **Precondition:** None
- **Steps:**
  1. Navigate to `/signup`
  2. Enter "admin@gmial.com"
  3. Tab away from email field (blur)
  4. Verify suggestion displayed: "Did you mean gmail.com?" (V-03)
  5. Click the suggestion
  6. Verify email field updates to "admin@gmail.com"
  7. Click "Continue" — verify proceeds normally with corrected email
- **Expected Result:** Typo suggestion shown on blur. Accepting updates the field. Entry proceeds with corrected email.
- **Validation Rules Exercised:** V-03 (triggered, accepted)

### TS-07: Email Typo Suggestion — User Ignores Valid Custom Domain

- **Precondition:** None
- **Steps:**
  1. Navigate to `/signup`
  2. Enter "admin@mycompany.co"
  3. Tab away from field
  4. Verify no typo suggestion is shown (uncommon but valid domain)
  5. Click "Continue" — verify proceeds normally
- **Expected Result:** No false-positive suggestions for uncommon but valid domains.
- **Validation Rules Exercised:** V-03 (not triggered)

### TS-08: Uniform Response — Email Already Registered (Existing User With Workspace)

- **Precondition:** "existing@company.com" has an existing User record with an active workspace
- **Steps:**
  1. Enter "existing@company.com"
  2. Click "Continue"
  3. Verify email passes format and disposable checks
  4. Verify user is directed to OTP verification page (same behavior as new email)
  5. Verify no indication that an account already exists is shown
- **Expected Result:** Identical user experience to a new email. No account enumeration. Subsequent routing handled by verification stories.
- **Validation Rules Exercised:** V-02 (passes), V-04 (passes) — anti-enumeration enforced

### TS-09: Uniform Response — Previously Verified Email, No Workspace Created

- **Precondition:** "verified@company.com" was previously verified but user did not complete workspace creation (no User or Tenant record)
- **Steps:**
  1. Enter "verified@company.com"
  2. Click "Continue"
  3. Verify user is directed to OTP verification page (same behavior as new email)
- **Expected Result:** Identical user experience to a new email. Post-verification behavior handled by subsequent stories.
- **Validation Rules Exercised:** Anti-enumeration enforced

### TS-10: Uniform Response — Email With Pending Verification

- **Precondition:** "pending@company.com" has an existing pending signup (OTP sent but not verified)
- **Steps:**
  1. Enter "pending@company.com"
  2. Click "Continue"
  3. Verify user is directed to OTP verification page (same behavior as new email)
- **Expected Result:** Identical user experience to a new email. OTP send story decides whether to send new or reuse existing OTP.
- **Validation Rules Exercised:** Anti-enumeration enforced

### TS-11: OAuth Path Selected — Google

- **Precondition:** None
- **Steps:**
  1. Navigate to `/signup?plan=professional`
  2. Verify system captures plan parameter
  3. Click "Continue with Google" (instead of entering email)
  4. Verify system redirects to Google OAuth authentication page
- **Expected Result:** User is in Google OAuth flow. Plan parameter preserved in session. OAuth authentication story takes over.
- **Validation Rules Exercised:** None (OAuth path)

### TS-12: Double-Submission Prevention

- **Precondition:** None
- **Steps:**
  1. Enter "admin@newcompany.com"
  2. Click "Continue" rapidly three times
  3. Verify "Continue" button disables and shows loading indicator after first click
  4. Verify only one server request is processed
- **Expected Result:** Single flow proceeds. No duplicate requests sent to server.
- **Validation Rules Exercised:** Double-submission prevention (edge case)

### TS-13: Email Case Normalization

- **Precondition:** No existing user with "admin@company.com"
- **Steps:**
  1. Enter "Admin@COMPANY.COM"
  2. Click "Continue"
  3. Verify system normalizes email to "admin@company.com"
  4. Verify validation uses normalized value — passes all checks
  5. Verify user is directed to OTP verification page
- **Expected Result:** Email normalized to lowercase. No error shown. OTP sent to normalized email.
- **Validation Rules Exercised:** Normalization behavior

### TS-14: Unrecognized Plan Parameter Defaults Silently

- **Precondition:** None
- **Steps:**
  1. Navigate to `/signup?plan=enterprise`
  2. Verify no error or warning displayed about unrecognized plan
  3. Enter valid email and click "Continue"
  4. Verify entry proceeds normally
- **Expected Result:** Unrecognized plan silently defaults to Professional trial at workspace setup. No error shown. Same behavior for `?plan=gold` or any other invalid value.
- **Validation Rules Exercised:** Plan parameter handling

---

## 13. TypeScript Type Definitions

These types are derived from the story requirements and are ready for implementation.

```typescript
// ---- Enums ----

/** Known self-service plan identifiers. UNKNOWN covers all unrecognized values. */
export type PlanId = 'starter' | 'professional' | 'business' | 'unknown';

/** Entry path chosen by the user on the entry page. */
export type EntryPath = 'email' | 'oauth_google' | 'oauth_microsoft';

// ---- Form Types ----

/** Raw form state managed by the email entry form. */
export interface EmailEntryFormState {
  /** Raw value as entered by the user — not yet normalized. */
  email: string;
  /** True while the server request is in flight. Controls button disabled state. */
  isSubmitting: boolean;
  /** Active blocking validation error, if any. Null when no error. */
  error: EmailEntryError | null;
  /** Active typo suggestion (V-03), if any. Null when no suggestion. */
  typoSuggestion: TypoSuggestion | null;
}

/** A single validation error on the email field. */
export interface EmailEntryError {
  /** Validation rule that produced this error. */
  ruleId: 'V-01' | 'V-02' | 'V-04';
  /** Exact error message as defined in the story (character-for-character). */
  message: string;
}

/** A non-blocking typo suggestion (V-03). */
export interface TypoSuggestion {
  /** The corrected domain suggested to the user (e.g., "gmail.com"). */
  suggestedDomain: string;
  /** The full suggested email address (local-part + suggestedDomain). */
  suggestedEmail: string;
  /** Display text shown to the user. Format: "Did you mean [suggestedDomain]?" */
  displayText: string;
  /** Whether the suggestion has been dismissed by the user. */
  dismissed: boolean;
}

// ---- Session / State Types ----

/** Session state captured at the entry page and carried forward through the entry flow. */
export interface EntrySessionState {
  /**
   * Normalized (lowercase) email submitted by the user.
   * Populated after successful submission.
   */
  normalizedEmail: string | null;
  /**
   * Raw plan parameter from the URL query string (?plan=...).
   * Null if not present. Stored as-is — resolution to PlanId happens in plan acceptance story.
   */
  rawPlanParam: string | null;
  /**
   * Resolved plan ID after validation against known self-service plans.
   * Defaults to 'professional' if rawPlanParam is absent or unrecognized.
   */
  resolvedPlan: PlanId;
  /** Entry path chosen by the user. Populated on action (email submit or OAuth click). */
  entryPath: EntryPath | null;
}

// ---- API Contract Types ----

/** Request body sent to the server when the user submits their email. */
export interface EmailEntryRequest {
  /** Normalized (lowercase) email address. */
  email: string;
  /** Raw plan parameter from URL, if present. Null if not in URL. */
  planParam: string | null;
}

/**
 * Server response when email entry succeeds (passes server-side V-04 check).
 * Client redirects to OTP verification page on this response.
 */
export interface EmailEntrySuccessResponse {
  success: true;
  /** OTP verification flow token / session reference (opaque to client). */
  verificationToken: string;
}

/**
 * Server error response when email entry fails server-side validation.
 * Currently only V-04 (disposable email) produces a server-side error at this step.
 */
export interface EmailEntryErrorResponse {
  success: false;
  /** Rule ID that caused the rejection. */
  ruleId: 'V-04';
  /** Exact error message to display inline below the email field. */
  message: string;
}

export type EmailEntryResponse = EmailEntrySuccessResponse | EmailEntryErrorResponse;

// ---- Audit Event Type ----

/** Audit event payload recorded when email entry succeeds. */
export interface EntryInitiatedAuditEvent {
  action: 'entry_initiated_email';
  /** Hashed/protected email reference — never plaintext. */
  emailHash: string;
  ipAddress: string;
  userAgent: string;
  planParam: string | null;
  timestamp: string; // ISO 8601
}

// ---- Analytics Event Types ----

export type AnalyticsEvent =
  | { event: 'entry_page_viewed' }
  | { event: 'email_entry_initiated'; plan: string | null }
  | { event: 'oauth_path_selected'; provider: 'google' | 'microsoft'; plan: string | null }
  | { event: 'disposable_email_blocked'; domain: string }
  | { event: 'typo_suggestion_shown'; originalDomain: string; suggestedDomain: string };

// ---- Component Props ----

export interface EmailEntryPageProps {
  /** Plan parameter from URL (resolved by page loader). Null if not present. */
  initialPlanParam: string | null;
}

export interface EmailFieldProps {
  value: string;
  onChange: (value: string) => void;
  onBlur: () => void;
  error: EmailEntryError | null;
  typoSuggestion: TypoSuggestion | null;
  onAcceptTypoSuggestion: (suggestedEmail: string) => void;
  onDismissTypoSuggestion: () => void;
  disabled: boolean;
}

export interface ContinueButtonProps {
  isLoading: boolean;
  disabled: boolean;
  onClick: () => void;
}

export interface OAuthButtonProps {
  provider: 'google' | 'microsoft';
  onClick: () => void;
  disabled: boolean;
}
```

---

## 14. API Contracts

### POST /api/v1/entry/email

**Purpose:** Submit email to begin the entry flow. Performs server-side authoritative V-04 disposable email check. If valid, triggers OTP send (US-TM-01.1.03) and returns a verification token.

**Authentication:** None required (public endpoint).

**Request:**
```http
POST /api/v1/entry/email
Content-Type: application/json

{
  "email": "admin@company.com",      // normalized to lowercase by client before sending
  "planParam": "business"            // raw value from ?plan= URL param; null if absent
}
```

**Success Response (200):**
```json
{
  "success": true,
  "verificationToken": "<opaque-token>"
}
```

**Error Response — Disposable Email (422):**
```json
{
  "success": false,
  "ruleId": "V-04",
  "message": "Disposable email addresses are not allowed. Please use a permanent email address."
}
```

**Error Response — Rate Limited (429):**
```json
{
  "success": false,
  "ruleId": "RATE_LIMIT",
  "message": "We're unable to process your request right now. Please try again in a few minutes."
}
```

**Notes:**
- Server does NOT return whether the email is new or already registered (anti-enumeration invariant).
- OTP send is triggered by this endpoint on success (internal pipeline, not a separate client call at this step).
- Rate limiting details defined in anti-fraud story (US-TM-01.1.08).

---

## 15. Dependencies

### Blocking Dependencies (must exist before this story can be implemented or tested)

| Dependency | Story/Feature ID | What Is Needed |
|------------|-----------------|----------------|
| Configuration Bootstrap | FE-TM-01.0 | Seeded plans and system configuration; OAuth provider config |
| Identity & Authentication Infrastructure | (upstream platform) | Google and Microsoft OAuth integration configured; session management |

### Non-Blocking Dependencies (this story can be built and tested independently)

| Dependency | Story/Feature ID | Relationship |
|------------|-----------------|--------------|
| Send email verification OTP | US-TM-01.1.03 | Triggered immediately after this story completes (email path) |
| OAuth authentication — Google or Microsoft | US-TM-01.1.02 | OAuth buttons on this page redirect to OAuth flow |
| Workspace creation page | US-TM-01.1.05 | After verification, workspace creation handles new user setup |
| Anti-fraud checks | US-TM-01.1.08 | Disposable email blocklist source; detailed anti-fraud rules |
| Plan parameter handling | US-TM-01.1.09 | Detailed plan query parameter behavior and plan-to-template mapping |

### Stories That Depend on This Story

| Dependent Story | Story ID | Dependency Nature |
|-----------------|----------|-------------------|
| Send email verification OTP | US-TM-01.1.03 | Entry page is the entry point; US-TM-01.1.03 is triggered immediately after |
| OAuth authentication | US-TM-01.1.02 | OAuth buttons exist on this page; redirect is initiated here |

### Build Phase

**Phase A** — This is a foundational story. It is the entry point of the entire provisioning flow and must be implemented before any downstream step (OTP, workspace creation, etc.).

### Constraints

- Subdomain must comply with INV-4 (Canonical URL Contract): `{subdomain}.motadata.com` — not applicable to this story but relevant to the broader flow.
- Tenant isolation per INV-1 — entry data for one prospect must not be visible to another.
- Anti-enumeration is a hard invariant at this step: the server must return an identical response path for all valid non-disposable emails regardless of account existence.
- Email normalization (lowercase) must occur before validation and before the server request.

---

## 16. PRD Invariant Check

| Invariant | Status | Notes |
|-----------|--------|-------|
| INV-1: Every user must have at least one role | No conflict | No user created at this step. User and Tenant records created atomically at workspace creation (Step 3). |
| INV-2: Seed roles (Admin, Agent, End-User) cannot be deleted | No conflict | No role operations in this story. |
| INV-3: Permission model is additive only (no deny rules) | No conflict | No permission operations in this story. |
| INV-4: Roles are flat (no hierarchy) | No conflict | No role operations in this story. |
| INV-5: Groups are flat (no nesting) | No conflict | No group operations in this story. |
| INV-6: Organizational structure is flat | No conflict | No org structure operations in this story. |
| INV-7: Single-tenant architecture | No conflict | Entry page creates no records; each user gets one workspace. Single-tenant model preserved. |
| INV-8: Password-only authentication (no OAuth/social) | **NOTE — CHECK REQUIRED** | Story includes OAuth buttons ("Continue with Google", "Continue with Microsoft"). This conflicts with INV-8 if INV-8 is defined as "password-only." However, the story and epic explicitly state the platform is **fully passwordless** — using OTP and OAuth. If INV-8 in the PRD invariants list means "password-based authentication is the only method," this is a direct conflict. If INV-8 has been superseded by a design decision (D-TM-26, fully passwordless, OAuth allowed), then there is no conflict. **This must be confirmed against the current PRD invariant definition before implementation proceeds.** |
| INV-9: Admin-provisioned users only (no self-registration) | **NOTE — CHECK REQUIRED** | This story is the entry point for **self-service provisioning** (EP-TM-01). If INV-9 states "admin-provisioned users only," this conflicts with the entire self-service provisioning epic. Likely INV-9 applies to the internal platform admin portal (provisioning team members within an existing tenant), not to tenant self-service entry. **This must be confirmed against the current PRD invariant scope before implementation proceeds.** |
| INV-10: Foundation owns email rendering and delivery | No conflict | This story does not send emails. OTP email delivery is handled by US-TM-01.1.03 which must comply with INV-10. |
| INV-11: Portal is presentation layer, not data owner | No conflict | No data ownership operations. Entry page captures email in session state only; no records created at this step. |

**Critical Items Requiring Confirmation:**
- INV-8 and INV-9 above require clarification on scope. If these invariants apply to tenant self-service entry, there is a conflict with the core purpose of EP-TM-01. Most likely these invariants apply only to the platform admin portal / internal user management, not to external tenant self-service entry. Confirm before implementation.

---

## Completeness Checklist

- [x] All story sections extracted (20+ sections in source story)
- [x] Field Definitions table with all columns present (Email Address, Plan)
- [x] Validation Rules with exact error message text (V-01, V-02, V-03, V-04)
- [x] Test Scenarios numbered sequentially (TS-01 through TS-14)
- [x] Acceptance Criteria numbered (FC-01 through FC-15, NFC-01 through NFC-08)
- [x] Dependencies include build phase (Phase A)
- [x] PRD invariant check complete (all 11 checked, 2 flagged for confirmation)
- [x] Out of Scope section present
- [x] TypeScript types derived from story requirements
- [x] API contract specified (POST /api/v1/entry/email)
- [x] Edge cases (10 scenarios) documented with exact handling
- [x] Analytics events (5) documented
- [x] Audit events documented with privacy level
- [x] Data lifecycle documented
- [x] Accessibility requirements documented (focus, screen reader, keyboard, visual)
- [x] State machine documented
- [x] Validation timing summary (on blur, on submit client, on submit server)
