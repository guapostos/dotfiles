# Logging Convention

`read_when`: setting up logging, debugging log issues, starting a new project

Cross-project standard for log storage, format, and organization.

## Directory Layout

```
${XDG_STATE_HOME:-~/.local/state}/{project}/runs/
  {YYYYMMDDTHHMMSS.mmm}_{git-sha7}[_dirty]/
    {component}.log
  latest -> {YYYYMMDDTHHMMSS.mmm}_{git-sha7}[_dirty]/
```

- **project**: lowercase, hyphenated (e.g. `my-app`, `web-api`)
- **timestamp**: ISO 8601 basic with subseconds, filesystem-safe (`20260214T201500.123`)
- **git-sha7**: first 7 chars of HEAD (`abc1234`)
- **_dirty**: appended when working tree has uncommitted changes
- **latest**: symlink to most recent run dir — agents always read this

### Example

```
$XDG_STATE_HOME/my-app/runs/
  20260214T201500.123_abc1234/
    server.log
    worker.log
  20260214T203000.456_def5678_dirty/
    server.log
  latest -> 20260214T203000.456_def5678_dirty/
```

## Log Format

JSON lines. One JSON object per line. `.log` extension.

### Required Fields

| Field       | Type   | Example                          |
|-------------|--------|----------------------------------|
| `timestamp` | string | `"2026-02-14T20:15:00.123Z"`     |
| `level`     | string | `debug`, `info`, `warning`, `error` |
| `event`     | string | `server_started`, `order_filled`  |

### Optional Fields

| Field         | Type   | When                             |
|---------------|--------|----------------------------------|
| `module`      | string | Always useful                    |
| `duration_ms` | number | Timed operations                 |
| `error`       | string | With `level: error`              |
| `run_id`      | string | Cross-reference across components|

### Example

```json
{"timestamp":"2026-02-14T20:15:00.123Z","level":"info","event":"server_started","module":"app","port":8080}
{"timestamp":"2026-02-14T20:15:01.456Z","level":"error","event":"db_connect_failed","module":"db","error":"Connection refused"}
```

## Setup Snippets

### Bash (any project)

```bash
PROJECT="my-project"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
if [ "$SHA" = "nogit" ]; then DIRTY=""; else
  DIRTY=$(git status --porcelain 2>/dev/null | grep -q . && echo "_dirty" || echo "")
fi
RUNDIR="$STATE/$PROJECT/runs/$(date +%Y%m%dT%H%M%S.%3N)_${SHA}${DIRTY}"
mkdir -p "$RUNDIR"
ln -sfn "$(basename "$RUNDIR")" "$STATE/$PROJECT/runs/latest"
```

### Python (structlog)

```python
import os, subprocess, datetime
from pathlib import Path

def make_run_dir(project: str) -> Path:
    state = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    sha = subprocess.run(
        ["git", "rev-parse", "--short", "HEAD"],
        capture_output=True, text=True
    ).stdout.strip() or "nogit"
    dirty = ""
    if sha != "nogit":
        status = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True, text=True
        ).stdout.strip()
        dirty = "_dirty" if status else ""
    ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S.%f")[:19]  # ms precision
    run_dir = state / project / "runs" / f"{ts}_{sha}{dirty}"
    run_dir.mkdir(parents=True, exist_ok=True)
    latest = run_dir.parent / "latest"
    latest.unlink(missing_ok=True)
    latest.symlink_to(run_dir.name)  # relative symlink
    return run_dir
```

## Multiprocessing

- Main process: `{component}.log`
- Workers: `{component}_worker{N}.log` OR `QueueHandler` → single file
- Never `print()` from workers — interleaving corrupts output

## Reading Logs

```bash
# Pretty-print latest
jq -r '[.timestamp, .level, .event] | join(" | ")' ${XDG_STATE_HOME:-~/.local/state}/{project}/runs/latest/*.log

# Errors only
jq 'select(.level == "error")' ${XDG_STATE_HOME:-~/.local/state}/{project}/runs/latest/*.log

# Compare two runs
diff <(jq -r .event run1/app.log | sort | uniq -c) <(jq -r .event run2/app.log | sort | uniq -c)
```

## Agent Rules

1. Always read from `runs/latest/` — never scan for "most recent" file
2. Use `jq` for filtering — never parse JSON with regex
3. Summarize, don't paste — count errors by type, show first occurrence
4. Note the git SHA from the run dir name to confirm code version
