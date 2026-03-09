#!/bin/bash
# TeammateIdle hook — enforces quality gates before teammates go idle
# Exit code 2 = send feedback and keep teammate working
# Exit code 0 = allow idle

INPUT=$(cat)

# Parse teammate name from JSON input
TEAMMATE=$(python3 -c "
import sys, json
try:
    d = json.loads('''$INPUT''')
    print(d.get('teammate_name', ''))
except:
    pass
" 2>/dev/null || echo "")

# Fallback: try with stdin
if [ -z "$TEAMMATE" ]; then
    TEAMMATE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('teammate_name', ''))
except:
    pass
" 2>/dev/null || echo "")
fi

TRANSCRIPT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('transcript', ''))
except:
    pass
" 2>/dev/null || echo "")

case "$TEAMMATE" in
  tdd-runner)
    # Must report coverage numbers before going idle
    if ! echo "$TRANSCRIPT" | grep -qiE "([0-9]+(\.[0-9]+)?%|coverage|all tests pass)"; then
      echo "Coverage check not completed. Run: npx vitest run --coverage and include the percentage in your report before finishing."
      exit 2
    fi
    ;;

  code-reviewer)
    # Must state a verdict before going idle
    if ! echo "$TRANSCRIPT" | grep -qiE "(Verdict|APPROVE|REQUEST CHANGES|BLOCK)"; then
      echo "Review verdict not stated. Your report must include a Verdict line: APPROVE, REQUEST CHANGES, or BLOCK."
      exit 2
    fi
    ;;

  security-reviewer)
    # Must state a risk level before going idle
    if ! echo "$TRANSCRIPT" | grep -qiE "(Risk Level|CLEAN|CRITICAL|HIGH|MEDIUM|LOW)"; then
      echo "Security risk level not stated. Your report must include a Risk Level: CLEAN, LOW, MEDIUM, HIGH, or CRITICAL."
      exit 2
    fi
    ;;

  feature-dev)
    # Must run typecheck before going idle
    if ! echo "$TRANSCRIPT" | grep -qiE "(tsc --noEmit|typecheck|no type errors|0 errors)"; then
      echo "TypeScript check not confirmed. Run 'npx tsc --noEmit' and report the result before finishing."
      exit 2
    fi
    ;;
esac

exit 0
