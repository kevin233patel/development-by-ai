#!/bin/bash
# PostToolUse hook for SendMessage — logs all inter-agent messages to audit log
# Fires after every SendMessage tool call

INPUT=$(cat)

# Extract fields
TOOL=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except: pass
" 2>/dev/null || echo "")

# Only handle SendMessage
if [[ "$TOOL" != "SendMessage" ]]; then
  exit 0
fi

SESSION=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('session_id', 'unknown'))
except: pass
" 2>/dev/null || echo "unknown")

TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    inp = d.get('tool_input', {})
    print(json.dumps(inp))
except: pass
" 2>/dev/null || echo "{}")

RECIPIENT=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('recipient', 'unknown'))
except: pass
" 2>/dev/null || echo "unknown")

MESSAGE=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    print(d.get('message', '')[:120])
except: pass
" 2>/dev/null || echo "")

# Extract story ID from message if present (format: [US-FND-XX.X.XX])
STORY_ID=$(echo "$MESSAGE" | grep -oE '\[US-[A-Z]+-[0-9]+\.[0-9]+\.[0-9]+\]' | head -1 | tr -d '[]' || echo "unknown")

# Determine log directory
if [[ "$STORY_ID" != "unknown" ]]; then
  LOG_DIR="/Users/kevingardhariya/Documents/code/Development/motadata/development-by-ai/.claude/team-state/$STORY_ID"
else
  LOG_DIR="/Users/kevingardhariya/Documents/code/Development/motadata/development-by-ai/.claude/team-state/general"
fi

mkdir -p "$LOG_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "$TIMESTAMP | session:$SESSION | MSG_SENT | → $RECIPIENT | $MESSAGE" >> "$LOG_DIR/audit.log"

exit 0
