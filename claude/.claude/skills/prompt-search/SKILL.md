---
name: "prompt-search"
description: "Search across AI coding assistant conversation history (Claude Code, Gemini CLI, Opencode, Codex). Use when the user wants to find a previous chat, recover context from another session, or search their conversation history. Auto-detects which tools have stored conversations and searches all available storages."
---

# Prompt Search Skill

Search across AI coding assistant conversation history.

## Usage

```
Search for: <term>
# or just: prompt-search <term>
```

The agent should read the search terms and run the commands below. If no terms are given, search `$*` for a demo.

## Auto-detection

The agent runs under a specific tool and should search ALL available storages:
Claude Code, Gemini CLI, Opencode, Codex. Each tool stores conversations in its own format.

## Tool Storage Locations

### Claude Code
| Storage | Path | Format |
|---------|------|--------|
| Messages DB | `~/.claude/__store.db` | SQLite |
| History | `~/.claude/history.jsonl` | JSONL |

### Gemini CLI
| Storage | Path | Format |
|---------|------|--------|
| Sessions | `~/.gemini/tmp/<project>/chats/session-*.json` | JSON |

### Opencode
| Storage | Path | Format |
|---------|------|--------|
| Messages DB | `~/.local/share/opencode/opencode.db` | SQLite |
| History | `~/.local/state/opencode/prompt-history.jsonl` | JSONL |

### Codex (OpenAI)
| Storage | Path | Format |
|---------|------|--------|
| Sessions | `~/.openai/codex/sessions/` | TBD (may be empty) |

---

## Claude Code: Message DB Search

```bash
TERM=$(printf '%s' "$*" | sed "s/'/''/g")
sqlite3 ~/.claude/__store.db "
SELECT
    b.session_id,
    datetime(b.timestamp, 'unixepoch', 'localtime') as date,
    b.cwd,
    CASE
        WHEN json_valid(u.message) AND json_extract(u.message, '$.content') IS NOT NULL
        THEN substr(json_extract(u.message, '$.content'), 1, 120)
        ELSE u.message
    END as preview
FROM user_messages u
JOIN base_messages b ON u.uuid = b.uuid
WHERE u.message LIKE '%${TERM}%'
  AND u.tool_use_result IS NULL
ORDER BY b.timestamp DESC
LIMIT 20;
"
```

## Claude Code: History.jsonl Search

```bash
TERM=$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]')
python3 -c "
import json, sys
from datetime import datetime
term = sys.argv[1]
with open('$HOME/.claude/history.jsonl') as f:
    matches = [json.loads(l) for l in f if term in l.lower()]
for d in matches[-30:]:
    ts = datetime.fromtimestamp(d.get('timestamp', 0) / 1000)
    proj = d.get('project', '').split('/')[-1]
    sid = d.get('sessionId', '')[:10]
    disp = d.get('display', '')[:120].replace('\n', ' ')
    print(f'{ts:%Y-%m-%d %H:%M} | {sid} | {proj:25} | {disp}')
" "$TERM"
```

## Claude Code: Recent Sessions

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
LIMIT 15;
"
```

## Gemini CLI: Session Search

```bash
python3 -c "
import json, sys, glob, os
from datetime import datetime
term = sys.argv[1].lower()
sessions = glob.glob(os.path.expanduser('~/.gemini/tmp/*/chats/session-*.json'))
matches = []
for path in sessions:
    try:
        with open(path) as f:
            data = json.load(f)
        msgs = data.get('messages', [])
        for msg in msgs:
            text = ''
            for c in msg.get('content', []):
                text += c.get('text', '')
            if term in text.lower():
                ts = data.get('startTime', 'unknown')
                project = path.split('/chats/')[0].split('/')[-1]
                matches.append((ts, project, text[:150]))
    except:
        pass
for ts, proj, preview in sorted(matches, reverse=True)[:30]:
    print(f'{ts} | {proj:25} | {preview}')
" "$TERM"
```

## Opencode: Message DB Search

```bash
TERM=$(printf '%s' "$*" | sed "s/'/''/g")
sqlite3 ~/.local/share/opencode/opencode.db "
SELECT
    s.slug,
    s.title,
    datetime(s.time_created, 'unixepoch', 'localtime') as created,
    s.directory,
    substr(m.data, 1, 150) as preview
FROM message m
JOIN session s ON m.session_id = s.id
WHERE m.data LIKE '%${TERM}%'
ORDER BY m.time_created DESC
LIMIT 20;
"
```

## Opencode: Prompt History Search

```bash
TERM=$(printf '%s' "$*" | tr '[:upper:]' '[:lower:]')
python3 -c "
import json, sys
from datetime import datetime
term = sys.argv[1]
path = '$HOME/.local/state/opencode/prompt-history.jsonl'
if not os.path.exists(path):
    print('No prompt history found')
    sys.exit(0)
matches = []
with open(path) as f:
    for line in f:
        if term in line.lower():
            obj = json.loads(line)
            ts = obj.get('timestamp', 0)
            if isinstance(ts, (int, float)):
                dt = datetime.fromtimestamp(ts)
                ts_str = dt.strftime('%Y-%m-%d %H:%M')
            else:
                ts_str = str(ts)
            prompt = obj.get('prompt', obj.get('message', obj.get('display', '')))[:120].replace(chr(10), ' ')
            matches.append((ts_str, prompt))
for ts, prompt in matches[-30:]:
    print(f'{ts} | {prompt}')
" "$TERM"
```

## Resume a Session

```bash
# Claude Code
claude --resume            # interactive search
claude --resume SESSION_ID # specific session
claude --resume SESSION_ID --fork-session  # fork instead of continue

# Gemini CLI
# Sessions auto-resume when you re-open a project directory

# Opencode
opencode --resume SESSION_ID  # if supported, check opencode --help

# Codex
codex --resume                # if supported
```
