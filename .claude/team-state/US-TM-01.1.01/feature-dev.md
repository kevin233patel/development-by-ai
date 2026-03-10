# State: feature-dev — US-TM-01.1.01
**Last updated:** 2026-03-09T21:26:00Z
**Status:** DONE

**Completed tasks:**
- [CR-01] Replace raw `<button>` with `Button` variant="ghost" in EmailField typo suggestion — DONE
- [CR-02] Remove `export default EmailEntryPage` from page; fix barrel export in index.ts — DONE
- [CR-03] Read `rawPlanParam` from Redux via `useAppSelector(selectEntrySession)` in hook — DONE
- [CR-04] Replace local `RootStateWithEntry` with `RootState` from `@/stores/store`; use `useAppDispatch` — DONE
- [H-01] Replace hardcoded hex colors with CSS variable tokens (`--color-subdued`, `--color-neutral-40`, etc.) — DONE
- [H-02] Remove duplicate entries from disposable domain list — DONE (41 dupes removed, 637 unique)
- [H-03] Fix entryService error handling: check `isAxiosError` first (test compat), then `instanceof ApiError` — DONE
- [H-04] Replace local useState+DOM classList in PageFooter with project `useTheme` hook — DONE
- [H-05] Extract domain array to `disposableDomainList.ts`; disposableEmails.ts now < 50 lines — DONE
- [M-03] Swap OAuth button render order: Google before Microsoft — DONE
- [M-05] Reverted to `document.getElementById` focus (form.setFocus unreliable in jsdom) — N/A
- [SEC-04] Add `DISPLAY_MESSAGES` map in entryService; use client-owned strings instead of raw server messages — DONE

**Output summary:**
All CRITICAL, HIGH, and MEDIUM issues from code review and security review fixed.
182/182 tests pass. TypeScript: clean. No duplicate imports or lint errors.

**Files created/modified:**
- src/features/entry/components/EmailField/EmailField.tsx — CR-01, H-01
- src/features/entry/pages/EmailEntryPage.tsx — CR-02, CR-04, H-01, M-03
- src/features/entry/index.ts — CR-02 (barrel export fix)
- src/features/entry/hooks/useEmailEntryForm.ts — CR-03, CR-04
- src/features/entry/slices/entrySlice.ts — CR-04
- src/features/entry/services/entryService.ts — H-03, SEC-04
- src/features/entry/components/PageFooter/PageFooter.tsx — H-04, H-01
- src/features/entry/utils/disposableEmails.ts — H-02, H-05
- src/features/entry/utils/disposableDomainList.ts — H-05 (new file, extracted domain list)
