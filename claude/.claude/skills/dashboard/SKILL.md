# Dashboard

Multi-project status overview. Output is readable by both humans and LLM agents.

Follows convention in `~/.claude/conventions/logging.md`.

## 1. Discover Projects

Scan XDG state dir for projects with log activity:

```bash
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
for dir in "$STATE"/*/; do
  proj=$(basename "$dir")
  # Skip non-project dirs
  # Skip known non-project dirs (adjust to your system)
  case "$proj" in nix|mise|venvs|logs|datasets) continue;; esac
  # Check for any .log or .jsonl files
  if ls "$dir"runs/latest/*.log "$dir"*.log "$dir"*.jsonl 2>/dev/null | head -1 > /dev/null 2>&1; then
    echo "$proj"
  fi
done
```

## 2. Per-Project Status

For each discovered project, gather:

```bash
PROJECT="<name>"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/$PROJECT"

# Convention-compliant: runs/latest (symlink is relative)
RUNDIRNAME=$(readlink "$STATE/runs/latest" 2>/dev/null)
if [ -n "$RUNDIRNAME" ]; then
  RUNDIR="$STATE/runs/$RUNDIRNAME"
  # Parse: YYYYMMDDTHHMMSS_sha7[_dirty]
  SHA=$(echo "$RUNDIRNAME" | cut -d'_' -f2)
  DIRTY=$(echo "$RUNDIRNAME" | grep -q '_dirty' && echo "dirty" || echo "clean")
  LOGFILES=$(ls "$RUNDIR"/*.log 2>/dev/null)
else
  # Fallback: flat files
  RUNDIRNAME="(flat)"
  SHA="-"
  DIRTY="-"
  LOGFILES=$(ls "$STATE"/*.log 2>/dev/null)
fi

# Error count
ERRORS=$(jq -c 'select(.level == "error")' $LOGFILES 2>/dev/null | wc -l)
# Fallback for non-JSON
[ "$ERRORS" -eq 0 ] && ERRORS=$(grep -ci 'error\|exception' $LOGFILES 2>/dev/null || echo 0)

# Last event timestamp
LAST_TS=$(jq -r '.timestamp' $LOGFILES 2>/dev/null | tail -1)
# Fallback
[ -z "$LAST_TS" ] && LAST_TS=$(stat -c '%y' $LOGFILES 2>/dev/null | tail -1 | cut -d. -f1)

# Running processes
PROCS=$(ps aux | grep -i "$PROJECT" | grep -v grep | wc -l)
```

## 3. Output Format

```
## Project Dashboard ({date})

| Project | Last Activity | SHA | Tree | Errors | Procs | Log Dir |
|---------|--------------|-----|------|--------|-------|---------|
| web-api | 14:30        | abc1234 | dirty | 3 | 2 | runs/latest |
| my-app  | 13:21        | def5678 | clean | 0 | 0 | runs/latest |
| worker  | 12:57        | -       | -     | - | 1 | (flat) |

### Alerts
- **web-api**: 3 errors — `request_timeout` (2), `ws_disconnect` (1)
- **worker**: no runs/ directory — consider migrating to convention

### Running Processes
- web-api: `python server.py` (pid 12345), `python handler.py` (pid 12346)
```

## 4. Deep Dive

If `$ARGUMENTS` names a specific project, show extended info:
- Last 10 events timeline
- Error details with first occurrence
- Log file sizes
- Previous run comparison (if available)

Use `/log-analyze {project}` for full analysis.

## 5. Quick One-Liner

For a fast check without the full skill:

```bash
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
for d in "$STATE"/*/runs/latest; do
  p=$(basename "$(dirname "$(dirname "$d")")")
  e=$(jq -c 'select(.level=="error")' "$d"/*.log 2>/dev/null | wc -l)
  t=$(jq -r '.timestamp' "$d"/*.log 2>/dev/null | tail -1)
  printf "%-15s %s errors=%d\n" "$p" "${t:-no-logs}" "$e"
done
```
