---
name: git-github-cli
description: Provides Git workflow and GitHub CLI patterns for React + TypeScript SaaS development. Covers branching strategy, conventional commits, PR workflows, code review, and gh CLI usage. Must use when managing branches, creating commits, opening PRs, or reviewing code.
---

# Git + GitHub CLI Best Practices

## Core Principle: Clean History, Fast Reviews

Every commit should be atomic and meaningful. Every PR should be small, focused, and reviewable. **Branches are cheap — use them for everything.**

## Branching Strategy

### Branch Naming Convention

```bash
# Pattern: type/short-description
feat/user-profile-page
fix/login-redirect-loop
refactor/auth-hook-extraction
test/permission-checks
docs/api-documentation
chore/update-dependencies

# BAD: Vague or messy names
my-branch
fix
update-stuff
john/working-on-it
```

### Branch Workflow

```bash
# 1. Always branch from main
git checkout main
git pull origin main
git checkout -b feat/user-profile-page

# 2. Work on your feature with small commits
git add src/features/profile/
git commit -m "feat: add user profile page layout"

git add src/features/profile/components/
git commit -m "feat: add avatar upload component"

git add src/features/profile/__tests__/
git commit -m "test: add profile page tests"

# 3. Push and create PR
git push -u origin feat/user-profile-page
gh pr create
```

## Commit Conventions

### Conventional Commits Format

```
type(scope): subject

body (optional)

footer (optional)
```

### Commit Types

```bash
feat:     # New feature for the user
fix:      # Bug fix for the user
docs:     # Documentation changes
style:    # Formatting, missing semicolons (no code change)
refactor: # Code restructuring (no behavior change)
perf:     # Performance improvement
test:     # Adding/fixing tests
build:    # Build system, dependencies
ci:       # CI/CD configuration
chore:    # Maintenance tasks
revert:   # Reverting a previous commit
```

### Good vs Bad Commits

```bash
# GOOD: Atomic, descriptive commits
git commit -m "feat: add user profile page with avatar upload"
git commit -m "fix: resolve infinite redirect on expired token"
git commit -m "refactor: extract form validation into shared Zod schemas"
git commit -m "test: add E2E tests for login flow"
git commit -m "chore: update React to v19"

# BAD: Vague, large, or noisy
git commit -m "update"
git commit -m "fix stuff"
git commit -m "WIP"
git commit -m "changes"
git commit -m "fix lint"  # Should be squashed with the previous commit
```

### Commit Scope (Optional)

```bash
# Use scope for clarity in larger projects
git commit -m "feat(auth): add social OAuth login"
git commit -m "fix(billing): correct tax calculation for EU"
git commit -m "refactor(api): migrate to typed service layer"
git commit -m "test(projects): add CRUD integration tests"
```

## GitHub CLI (gh) Workflows

### Creating Pull Requests

```bash
# Basic PR
gh pr create --title "feat: add user profile page" --body "## Summary
- Added user profile page with avatar upload
- Integrated with existing auth system

## Test Plan
- [ ] Manual test: update profile
- [ ] Manual test: upload avatar
- [ ] Unit tests pass
- [ ] E2E tests pass"

# PR with reviewers and labels
gh pr create \
  --title "feat: add user profile page" \
  --body-file .github/PULL_REQUEST_TEMPLATE.md \
  --reviewer teammate1,teammate2 \
  --label "feature,frontend"

# Draft PR (work in progress)
gh pr create --draft --title "WIP: billing integration"
```

### PR Review Workflow

```bash
# List open PRs
gh pr list

# View PR details
gh pr view 42

# Check out PR locally for testing
gh pr checkout 42

# Review PR
gh pr review 42 --approve
gh pr review 42 --request-changes --body "Please fix the type errors"
gh pr review 42 --comment --body "Looks good, minor suggestion on line 42"

# Merge PR
gh pr merge 42 --squash --delete-branch

# Close PR without merging
gh pr close 42
```

### Issue Management

```bash
# Create issue
gh issue create --title "Bug: login redirect fails on Safari" --label "bug"

# List issues
gh issue list --label "bug"

# Close issue via PR
gh pr create --title "fix: resolve Safari login redirect" \
  --body "Fixes #42"
```

## PR Best Practices

### PR Size

```bash
# GOOD: Small, focused PRs (< 400 lines changed)
# - One feature, one bug fix, or one refactor per PR
# - Easy to review, easy to revert

# BAD: Large PRs (> 1000 lines)
# - Hard to review thoroughly
# - Higher chance of bugs slipping through
# - Difficult to revert if something breaks

# If a feature is large, break it into stacked PRs:
# PR 1: Add data model and service layer
# PR 2: Add UI components
# PR 3: Add tests
# PR 4: Wire everything together
```

### PR Template

```markdown
<!-- .github/PULL_REQUEST_TEMPLATE.md -->
## Summary
<!-- Brief description of changes -->

## Type of Change
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Test
- [ ] Documentation

## Test Plan
- [ ] Unit tests added/updated
- [ ] E2E tests added/updated
- [ ] Manual testing completed

## Screenshots
<!-- If UI changes, add before/after screenshots -->

## Checklist
- [ ] Code follows project conventions
- [ ] No console.log or debug code
- [ ] Types are correct (no `any`)
- [ ] Tests pass locally
- [ ] PR is focused and < 400 lines
```

## Useful Git Aliases

```bash
# Common aliases (add to ~/.gitconfig)
[alias]
  s = status
  co = checkout
  br = branch
  cm = commit -m
  lg = log --oneline --graph --decorate -20
  last = log -1 HEAD --stat
  unstage = reset HEAD --
  amend = commit --amend --no-edit
```

## Anti-Patterns to Avoid

```bash
# BAD: Committing directly to main
git checkout main
git commit -m "quick fix"  # No review, no CI check!

# GOOD: Always use branches + PRs

# BAD: Force pushing to shared branches
git push --force origin main  # Destroys others' work!

# GOOD: Force push only on your own feature branches
git push --force-with-lease origin feat/my-feature

# BAD: Huge commits with mixed concerns
git add .
git commit -m "add feature, fix bug, update deps, refactor code"

# GOOD: Atomic commits — one concern each
git add src/features/auth/
git commit -m "feat(auth): add OAuth login"
git add package.json package-lock.json
git commit -m "chore: update dependencies"

# BAD: Merge commits cluttering history
# GOOD: Squash merge PRs for clean main branch history
gh pr merge 42 --squash --delete-branch
```

## Summary: Decision Tree

1. **Starting work?** → Branch from main with `type/description` name
2. **Committing?** → Conventional commit format, atomic changes
3. **Ready for review?** → `gh pr create` with summary + test plan
4. **Reviewing code?** → `gh pr checkout` to test locally, `gh pr review` to approve
5. **Merging?** → Squash merge + delete branch
6. **Large feature?** → Break into stacked PRs (< 400 lines each)
7. **Need to fix PR?** → Push to the same branch, add commits
8. **Force push?** → Only `--force-with-lease` on your own branches, never main
9. **Issues?** → Create with `gh issue create`, close via PR reference
10. **Keeping up to date?** → `git pull origin main` + rebase your branch
