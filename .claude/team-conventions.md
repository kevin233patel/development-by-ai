# Agent Team Conventions

Every agent in this team MUST follow these conventions. Read this file at spawn time.

---

## 1. Structured Message Format (Observability)

ALL SendMessage calls must use this format:

```
[{storyId}][{agentName}][{status}] {message}
```

**status values:**
- `DONE` — task completed successfully
- `BLOCKED` — cannot proceed, need intervention
- `INFO` — progress update (not done, not blocked)
- `REVIEW_PASS` — review approved
- `REVIEW_FAIL` — review requested changes
- `ERROR` — unexpected failure

**Examples:**
```
[US-FND-03.1.01][tdd-runner][DONE] RED phase complete. 8 tests written, all failing.
[US-FND-03.1.01][feature-dev][BLOCKED] Planner task 3 depends on task 2 which is still pending.
[US-FND-03.1.01][code-reviewer][REVIEW_FAIL] 2 critical issues. Sending to feature-dev.
[US-FND-03.1.01][build-fixer][ERROR] Attempt 3/3 failed. Escalating to human.
```

**Why:** Every message is traceable to a story, agent, and status. Lead can understand the full picture at a glance.

---

## 2. State Persistence (Crash Recovery)

Every agent MUST write a state file before going idle or completing a task.

**State file location:** `.claude/team-state/{storyId}/{agentName}.md`

**Write this after each task completion:**

```markdown
# State: {agentName} — {storyId}
**Last updated:** {ISO timestamp}
**Status:** IN_PROGRESS | DONE | BLOCKED
**Completed tasks:**
- [ task-id ]: {description} — DONE at {time}

**In progress:**
- [ task-id ]: {description} — started at {time}

**Output summary:**
{1-3 sentences describing what was produced}

**Files created/modified:**
- src/features/roles/types/role.types.ts
- src/features/roles/schemas/roleSchemas.ts
```

**On re-spawn (after crash):** First action is always to read this state file:
```bash
cat .claude/team-state/{storyId}/{agentName}.md 2>/dev/null
```
If the file exists, resume from where you left off. Do NOT restart from scratch.

---

## 3. Agent Boundary Rules (No Overlap)

### Exclusive Ownership

| Concern | Owner | Everyone Else |
|---------|-------|---------------|
| TypeScript / ESLint errors | build-fixer | Do NOT fix — report to build-fixer |
| Security vulnerabilities | security-reviewer | Do NOT fix — report to security-reviewer |
| Code quality / patterns | code-reviewer | Do NOT comment on quality — that's code-reviewer's job |
| Business logic implementation | feature-dev | Do NOT write implementation code |
| Test files | tdd-runner | Do NOT write tests — report needed tests to tdd-runner |
| Git / PR operations | ci-cd-manager | Do NOT commit or push |
| API contract definition | api-contract | Do NOT invent endpoints or response shapes |
| Task list creation | planner | Do NOT create tasks — only planner creates the initial task list |

### Overlap Resolution
- **Permission logic:** security-reviewer owns. code-reviewer only verifies the pattern is used correctly (e.g., `hasPermission()` is called), not whether the permission is correct.
- **Error message text:** story-analyzer owns. Everyone else copies exactly.
- **Build errors after code-reviewer changes:** feature-dev requests build-fixer, does NOT fix directly.

---

## 4. Deadlock Prevention

### One-Way Communication Rule
Messages flow **down the pipeline** or **to lead**. No agent waits for a response from an agent earlier in the pipeline.

```
ALLOWED:  feature-dev → tdd-runner (notify GREEN start)
ALLOWED:  any agent → lead (status/blocked)
ALLOWED:  code-reviewer → feature-dev (issues list — one-way, no waiting)
FORBIDDEN: feature-dev waits for tdd-runner to respond before continuing
FORBIDDEN: code-reviewer waits for feature-dev to fix before completing its task
```

### Max Review Cycles
**code-reviewer** and **security-reviewer**: Maximum **2 review cycles** per story.
- Cycle 1: Initial review → issues to feature-dev
- Cycle 2: Re-review of fixes → final verdict
- If still failing after cycle 2: `SendMessage` lead `[...][BLOCKED] 2 review cycles exhausted. Human review required.` — do NOT start cycle 3.

---

## 5. Resource Limits

### Team Size
- **Maximum teammates:** 6 active at once
- **Recommended:** 4-5 for a standard feature story

### Task Limits (planner enforces)
- **Max tasks total:** 15 per story
- **Max tasks per agent:** 6
- If a story needs more: split into sub-stories, do not create mega-task lists

### build-fixer Circuit Breaker
- **Max attempts:** 3 per error type
- After 3 failed attempts on the same error: stop, message lead with `[ERROR] Circuit breaker open.`
- Lead must involve human or feature-dev for architectural fix

---

## 6. Failure Ownership Matrix

When something goes wrong, exactly one agent owns recovery:

| Failure Scenario | Primary Owner | Escalation Path |
|-----------------|---------------|-----------------|
| TypeScript/lint error | build-fixer | → feature-dev (architectural) → lead (human) |
| Test fails after implementation | feature-dev (logic bug) or tdd-runner (test setup bug) | → lead to decide |
| E2E test fails | feature-dev (if implementation bug) | → lead |
| Code review: critical issues | feature-dev | → lead if not fixed in 1 cycle |
| Security: critical vulnerability | feature-dev | → lead immediately (STOP pipeline) |
| Build-fixer exhausted | lead | → human escalation |
| Teammate unresponsive (no message in >5 turns) | lead | → re-spawn teammate with state file |
| Task stuck in pending (dependency never completed) | lead | → investigate blocked agent |

### Unresponsive Agent Protocol
If an agent sends no message for 5+ turns after being assigned a task:
1. Lead sends: `"[{storyId}][lead][INFO] Checking status — are you still working on {task}?"`
2. If no response in 2 more turns: lead re-spawns the agent with state file as context
3. New agent reads state file and resumes from last checkpoint

---

## 7. Observability: Audit Log

Every agent writes to a shared audit log on every significant action:

**Log file:** `.claude/team-state/{storyId}/audit.log`

**Format (append, one line per entry):**
```
{ISO-timestamp} | {agentName} | {action} | {detail}
```

**Required log entries:**
```bash
# On task start
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | feature-dev | TASK_START | [IMPL] Types + schemas" >> .claude/team-state/US-FND-03.1.01/audit.log

# On task complete
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | feature-dev | TASK_DONE | [IMPL] Types + schemas — src/features/roles/types/role.types.ts created" >> .claude/team-state/US-FND-03.1.01/audit.log

# On message sent
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | feature-dev | MSG_SENT | → tdd-runner: GREEN phase triggered" >> .claude/team-state/US-FND-03.1.01/audit.log

# On error
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) | build-fixer | ERROR | Attempt 2/3: TS2322 at role.types.ts:15 — fix failed" >> .claude/team-state/US-FND-03.1.01/audit.log
```

**Why:** The lead can read `audit.log` at any point to reconstruct exactly what happened and who did what. Debugging a failure means reading the audit log, not asking each agent for their history.

---

## Quick Reference Card

```
ON SPAWN:
1. Read .claude/team-state/{storyId}/{myName}.md (resume if crash recovery)
2. Read .claude/team-conventions.md (this file)
3. Check TaskList for assigned tasks

ON EACH TASK:
1. Log TASK_START to audit.log
2. Do the work
3. Log TASK_DONE to audit.log
4. Write state file
5. TaskUpdate → completed
6. SendMessage with structured format

ON BLOCK:
1. Log ERROR to audit.log
2. SendMessage lead: [{storyId}][{me}][BLOCKED] {reason}
3. Wait — do NOT attempt workarounds outside your boundary

ON COMPLETION (all tasks done):
1. Write final state file with status: DONE
2. SendMessage lead: [{storyId}][{me}][DONE] All tasks complete. {summary}
3. Go idle
```
