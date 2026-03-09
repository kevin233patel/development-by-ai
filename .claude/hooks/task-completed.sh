#!/bin/bash
# TaskCompleted hook — blocks task completion if quality gate not met
# Exit code 2 = block completion and send feedback
# Exit code 0 = allow completion

INPUT=$(cat)

COMPLETED_BY=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('completed_by', ''))
except:
    pass
" 2>/dev/null || echo "")

TASK_TITLE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('task_title', ''))
except:
    pass
" 2>/dev/null || echo "")

TRANSCRIPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('transcript', ''))
except:
    pass
" 2>/dev/null || echo "")

# feature-dev: implementation tasks must include typecheck + lint
if [[ "$COMPLETED_BY" == "feature-dev" ]]; then
  if ! echo "$TRANSCRIPT" | grep -qiE "(tsc --noEmit|0 errors|no errors)"; then
    echo "Task '${TASK_TITLE}' blocked: TypeScript check not run. Run 'npx tsc --noEmit', fix all errors, then mark complete."
    exit 2
  fi
fi

# ci-cd-manager: must have PR URL before completing
if [[ "$COMPLETED_BY" == "ci-cd-manager" ]]; then
  if ! echo "$TRANSCRIPT" | grep -qiE "(github\.com|pull/[0-9]+|PR created|PR URL)"; then
    echo "Task '${TASK_TITLE}' blocked: PR not yet created. Create the PR with 'gh pr create' before marking complete."
    exit 2
  fi
fi

# e2e-runner: must report test results before completing
if [[ "$COMPLETED_BY" == "e2e-runner" ]]; then
  if ! echo "$TRANSCRIPT" | grep -qiE "(passed|failed|skipped|test.*result)"; then
    echo "Task '${TASK_TITLE}' blocked: E2E test results not reported. Run tests and include pass/fail counts."
    exit 2
  fi
fi

exit 0
