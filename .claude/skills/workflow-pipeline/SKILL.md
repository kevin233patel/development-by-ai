---
name: workflow-pipeline
description: Defines the full feature development pipeline for Motadata NextGen. Maps the correct agent sequence from story to deployment. Must use when orchestrating multi-agent workflows, planning feature implementation, or understanding which agent to invoke next.
---

# Feature Development Pipeline

## Core Principle: Story-Driven, Agent-Orchestrated

Every feature follows the same pipeline. Each agent hands off structured output to the next. **Never skip steps** — each agent's output is the next agent's input.

## Pipeline Overview

```
[NEW PROJECT ONLY]
project-scaffolding   → Full project setup (one-time, automated)
      │
      ▼
User Story (.md)
      │
      ▼
1. story-analyzer     → Structured spec (types, fields, validations, flows, test scenarios)
      │
      ▼
2. design-analyzer    → UI implementation spec (Figma MCP or auto-design with shadcn/ui + Tailwind)
      │
      ▼
3. planner            → File structure + component architecture + phased build plan
      │
      ▼
4. tdd-runner         → Write tests FIRST (RED) → validate fail → hand to feature-dev
      │
      ▼
5. feature-dev        → Implement components, hooks, services, Redux slices, Zod schemas
      │
      ▼ (parallel)
6a. code-reviewer     → SonarQube compliance, skill patterns, story traceability
6b. security-reviewer → OWASP Top 10, XSS/CSRF, token security, input validation
      │
      ▼
7. tdd-runner (GREEN) → Validate all tests pass, 80%+ coverage confirmed
      │
      ▼
8. e2e-runner         → Playwright E2E tests from acceptance criteria (Page Object Model)
      │
      ▼
9. build-fixer        → Fix any TypeScript/ESLint/build errors (only if needed)
      │
      ▼
10. ci-cd-manager     → Conventional commit + PR creation with story traceability
```

## Agent Responsibilities

### 1. story-analyzer
- **Input**: User story `.md` file path
- **Output**: Structured spec — types, fields, validations, API contracts, test scenarios, dependencies
- **When to skip**: Never — always run first

### 2. design-analyzer
- **Input**: story-analyzer output + optional Figma URL
- **Output**: UI spec — component breakdown, layout, color tokens, responsive behavior
- **Figma MCP**: If URL provided → `get_design_context`. If no URL → auto-design using shadcn/ui + Tailwind brand palette
- **When to skip**: Pure API/logic features with no UI

### 3. planner
- **Input**: story-analyzer output + design-analyzer output
- **Output**: Phased build plan — file list, component hierarchy, implementation order, skill references per file
- **Model**: opus (complex architectural reasoning)
- **When to skip**: Never for features > 3 files

### 4. tdd-runner (RED phase)
- **Input**: story-analyzer test scenarios + planner file list
- **Output**: Failing tests in Vitest + RTL (unit) + Playwright (E2E structure)
- **Rule**: Tests MUST fail before handing to feature-dev — verify RED
- **Coverage target**: 80% minimum

### 5. feature-dev
- **Input**: planner build plan + tdd-runner failing tests + design-analyzer UI spec
- **Output**: Implemented code following 25 skill patterns
- **Skills consulted**: react-typescript, shadcn-ui, tailwind-css, redux-toolkit, tanstack-query, rest-api-integration, react-hook-form-zod, authentication, rbac, error-handling
- **Model**: sonnet

### 6a. code-reviewer (parallel with 6b)
- **Input**: All modified files
- **Checks**: SonarQube compliance (sonarqube-compliance skill), pattern adherence, story requirement traceability
- **Blocking**: CRITICAL and HIGH issues block merge

### 6b. security-reviewer (parallel with 6a)
- **Input**: All modified files
- **Checks**: OWASP Top 10, XSS/CSRF, token storage, secrets exposure, Zod validation at boundaries
- **Blocking**: Any security issue blocks merge

### 7. tdd-runner (GREEN phase)
- **Input**: feature-dev implementation
- **Validates**: All tests pass, 80%+ coverage, no regressions
- **If failing**: Return to feature-dev with specific failing test details

### 8. e2e-runner
- **Input**: story acceptance criteria + feature-dev implementation
- **Output**: Playwright tests using Page Object Model, `getByRole` locators, no `waitForTimeout`
- **Runs**: Against local dev server

### 9. build-fixer (conditional)
- **Input**: Build/lint/type errors only
- **Rule**: Minimal targeted changes — no refactoring, no architecture changes
- **Model**: haiku (fast)
- **When to skip**: If build is clean after feature-dev

### 10. ci-cd-manager
- **Input**: All changes + story reference
- **Output**: Conventional commit + GitHub PR with story traceability
- **Commit format**: `feat(scope): description` referencing story ID
- **Model**: haiku

## Skill Reference Per Phase

| Phase | Primary Skills |
|-------|----------------|
| story-analyzer | (reads story MD) |
| design-analyzer | shadcn-ui, tailwind-css, dark-light-theming, responsive-design, accessibility |
| planner | react-typescript, react-router, redux-toolkit |
| tdd-runner | vitest, react-testing-library, playwright |
| feature-dev | react-typescript, shadcn-ui, tailwind-css, redux-toolkit, tanstack-query, react-hook-form-zod, rest-api-integration, authentication, rbac, error-handling, dark-light-theming |
| code-reviewer | sonarqube-compliance, eslint-prettier |
| security-reviewer | frontend-security, authentication |
| e2e-runner | playwright |
| ci-cd-manager | git-github-cli, github-actions, husky-lint-staged |

## Quick Reference: When to Use Which Agent

| Situation | Agent |
|-----------|-------|
| Starting a new story | story-analyzer |
| Have a Figma URL or need UI design | design-analyzer |
| Need implementation plan | planner |
| Writing tests or verifying coverage | tdd-runner |
| Implementing the feature | feature-dev |
| Code quality review | code-reviewer |
| Security check | security-reviewer |
| E2E tests | e2e-runner |
| Build/type/lint errors | build-fixer |
| Committing and creating PR | ci-cd-manager |

## Summary: Decision Tree

1. **New feature?** → story-analyzer first, always
2. **Has UI?** → design-analyzer after story-analyzer
3. **Ready to build?** → planner → tdd-runner (RED) → feature-dev
4. **Code written?** → code-reviewer + security-reviewer in parallel
5. **Tests passing?** → tdd-runner (GREEN) → e2e-runner
6. **Build errors?** → build-fixer (minimal, targeted)
7. **Ready to ship?** → ci-cd-manager (commit + PR)
