# Prompt Search Skill

Search across Claude Code conversation history: $ARGUMENTS

## Data Sources

Claude Code stores conversations in three locations:
1. `~/.claude/__store.db` - SQLite with messages, sessions, summaries
2. `~/.claude/history.jsonl` - Index of user prompts (display text only)
3. `~/.claude/projects/<path>/<session>.jsonl` - Full conversation files

## Schema (DO NOT guess columns — use only these)

```
base_messages(uuid PK, parent_uuid, session_id, timestamp, message_type, cwd, user_type, version, isSidechain, original_cwd)
user_messages(uuid PK/FK→base_messages, message, tool_use_result, timestamp, is_at_mention_read, is_meta)
assistant_messages(uuid PK/FK→base_messages, cost_usd, duration_ms, message, is_api_error_message, timestamp, model)
conversation_summaries(leaf_uuid PK/FK→base_messages, summary, updated_at)
```

NOTE: `conversation_summaries` has NO `session_id`. To find summaries for a session, join: `conversation_summaries cs JOIN base_messages b ON cs.leaf_uuid = b.uuid WHERE b.session_id = ...`

## Quick Search: User Prompts (history.jsonl)

Cleanest source for what the user actually typed. Includes sessionId for resume:

```bash
python3 -c "
import json
from datetime import datetime
term = '$ARGUMENTS'.lower()
with open('$HOME/.claude/history.jsonl') as f:
    matches = [json.loads(l) for l in f if term in l.lower()]
for d in matches[-20:]:
    ts = datetime.fromtimestamp(d.get('timestamp', 0) / 1000)
    proj = d.get('project', '').split('/')[-1]
    sid = d.get('sessionId', '')[:8]
    disp = d.get('display', '')[:100].replace('\n', ' ')
    print(f'{ts:%Y-%m-%d %H:%M} | {sid} | {proj:20} | {disp}')
"
```

## Database Search: Messages with Session IDs

Search SQLite for messages (includes tool results, filter as needed):

```bash
sqlite3 ~/.claude/__store.db "
SELECT
    b.session_id,
    datetime(b.timestamp, 'unixepoch', 'localtime') as date,
    b.cwd,
    CASE
        WHEN json_valid(u.message) AND json_type(json_extract(u.message, '\$.content')) = 'text'
        THEN substr(json_extract(u.message, '\$.content'), 1, 100)
        ELSE '[complex message]'
    END as preview
FROM user_messages u
JOIN base_messages b ON u.uuid = b.uuid
WHERE u.message LIKE '%$ARGUMENTS%'
  AND u.tool_use_result IS NULL
ORDER BY b.timestamp DESC
LIMIT 15;
"
```

## Database Search: Conversation Summaries

AI-generated summaries of conversations:

```bash
sqlite3 ~/.claude/__store.db "
SELECT
    cs.summary,
    datetime(cs.updated_at, 'unixepoch', 'localtime') as date
FROM conversation_summaries cs
WHERE cs.summary LIKE '%$ARGUMENTS%'
ORDER BY cs.updated_at DESC
LIMIT 10;
"
```

## Database Search: Recent Sessions

List recent sessions with message counts:

```bash
sqlite3 ~/.claude/__store.db "
SELECT
    b.session_id,
    datetime(MIN(b.timestamp), 'unixepoch', 'localtime') as started,
    datetime(MAX(b.timestamp), 'unixepoch', 'localtime') as ended,
    COUNT(*) as msgs,
    b.cwd
FROM base_messages b
GROUP BY b.session_id
ORDER BY MAX(b.timestamp) DESC
LIMIT 10;
"
```

## Project Conversation Files

Search full conversation content in project files:

```bash
# Find project directories
ls ~/.claude/projects/

# Search within a specific project's conversations
grep -l "$ARGUMENTS" ~/.claude/projects/-home-*/*.jsonl 2>/dev/null | head -10

# Extract session ID from filename for resuming
# File: ~/.claude/projects/-home-foo/abc123-def4-....jsonl
# Session ID: abc123-def4-....
```

## Resume a Session

After finding a relevant session_id:

```bash
# Resume interactively with search
claude --resume

# Resume specific session
claude --resume SESSION_ID

# Fork instead of continuing (new session from that point)
claude --resume SESSION_ID --fork-session
```

## Full Search Pipeline

Run comprehensive search across all sources:

```bash
echo "=== HISTORY.JSONL (user prompts) ===" && \
python3 -c "
import json,os
from datetime import datetime
term = '$ARGUMENTS'.lower()
with open(os.path.expanduser('~/.claude/history.jsonl')) as f:
    matches = [json.loads(l) for l in f if term in l.lower()]
for d in matches[-10:]:
    ts = datetime.fromtimestamp(d.get('timestamp',0)/1000)
    print(f'{ts:%Y-%m-%d} | {d.get(\"sessionId\",\"\")[:8]} | {d.get(\"project\",\"\").split(\"/\")[-1]:20} | {d.get(\"display\",\"\")[:60]}')
"

echo "" && echo "=== CONVERSATION SUMMARIES ===" && \
sqlite3 ~/.claude/__store.db "SELECT datetime(updated_at,'unixepoch','localtime'), substr(summary,1,80) FROM conversation_summaries WHERE summary LIKE '%$ARGUMENTS%' ORDER BY updated_at DESC LIMIT 5;" 2>/dev/null

echo "" && echo "=== PROJECT FILES ===" && \
grep -l "$ARGUMENTS" ~/.claude/projects/*/*.jsonl 2>/dev/null | head -5
```

## Output

After running searches, report:
1. Matching user prompts with dates and projects
2. Related conversation summaries
3. Session IDs that can be resumed with `claude --resume SESSION_ID`
