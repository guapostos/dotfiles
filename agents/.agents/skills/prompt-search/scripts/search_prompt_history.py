#!/usr/bin/env python3
"""Search local prompt history across coding-agent tools."""

from __future__ import annotations

import argparse
import glob
import json
import os
import sqlite3
import sys
from datetime import datetime
from pathlib import Path


HOME = Path.home()
TOOL_ALL = "all"
TOOLS = ("claude", "codex", "gemini", "opencode")


def collapse_whitespace(text: str) -> str:
    return " ".join(text.split())


def preview(text: str, limit: int = 140) -> str:
    text = collapse_whitespace(text)
    if len(text) <= limit:
        return text
    return text[: limit - 3] + "..."


def fmt_ts(value) -> str:
    if value in (None, "", 0):
        return "unknown"
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00")).strftime("%Y-%m-%d %H:%M")
        except ValueError:
            return value
    if isinstance(value, (int, float)):
        ts = float(value)
        if ts > 10_000_000_000:
            ts /= 1000.0
        return datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M")
    return str(value)


def print_section(title: str, rows: list[str]) -> None:
    if not rows:
        return
    print(f"== {title} ==")
    for row in rows:
        print(row)
    print()


def newest_sqlite(pattern: str) -> Path | None:
    matches = [Path(p) for p in glob.glob(os.path.expanduser(pattern))]
    if not matches:
        return None
    return max(matches, key=lambda path: path.stat().st_mtime)


def search_claude(term: str, limit: int) -> list[str]:
    rows: list[tuple[str, str, str]] = []

    db_path = HOME / ".claude/__store.db"
    if db_path.exists():
        conn = sqlite3.connect(db_path)
        try:
            cursor = conn.execute(
                """
                SELECT
                    b.session_id,
                    b.timestamp,
                    b.cwd,
                    u.message
                FROM user_messages u
                JOIN base_messages b ON u.uuid = b.uuid
                WHERE lower(u.message) LIKE ?
                  AND u.tool_use_result IS NULL
                ORDER BY b.timestamp DESC
                LIMIT ?
                """,
                (f"%{term.lower()}%", limit),
            )
            for session_id, ts, cwd, message in cursor:
                try:
                    payload = json.loads(message)
                    content = payload.get("content", message)
                    if isinstance(content, list):
                        content = " ".join(str(part) for part in content)
                    message = str(content)
                except Exception:
                    pass
                rows.append((fmt_ts(ts), session_id, f"{cwd} | {preview(message)}"))
        finally:
            conn.close()

    history_path = HOME / ".claude/history.jsonl"
    if history_path.exists():
        seen = {(ts, sid, body) for ts, sid, body in rows}
        history_rows: list[tuple[str, str, str]] = []
        with history_path.open() as handle:
            for line in handle:
                if term.lower() not in line.lower():
                    continue
                try:
                    payload = json.loads(line)
                except json.JSONDecodeError:
                    continue
                session_id = str(payload.get("sessionId", ""))[:12] or "unknown"
                project = str(payload.get("project", "")).split("/")[-1] or "-"
                message = payload.get("display", "")
                row = (fmt_ts(payload.get("timestamp", 0)), session_id, f"{project} | {preview(str(message))}")
                if row not in seen:
                    history_rows.append(row)
                    seen.add(row)
        rows.extend(reversed(history_rows[-limit:]))

    formatted = [f"{ts} | {sid} | {body}" for ts, sid, body in rows[:limit]]
    return formatted


def recent_claude(limit: int) -> list[str]:
    db_path = HOME / ".claude/__store.db"
    if not db_path.exists():
        return []
    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.execute(
            """
            SELECT
                b.session_id,
                MIN(b.timestamp),
                MAX(b.timestamp),
                COUNT(*),
                b.cwd
            FROM base_messages b
            GROUP BY b.session_id
            ORDER BY MAX(b.timestamp) DESC
            LIMIT ?
            """,
            (limit,),
        )
        return [
            f"{fmt_ts(started)} -> {fmt_ts(ended)} | {session_id} | {count} msgs | {cwd}"
            for session_id, started, ended, count, cwd in cursor
        ]
    finally:
        conn.close()


def search_codex(term: str, limit: int) -> list[str]:
    rows: list[str] = []

    history_path = HOME / ".codex/history.jsonl"
    if history_path.exists():
        history_rows: list[str] = []
        with history_path.open() as handle:
            for line in handle:
                try:
                    payload = json.loads(line)
                except json.JSONDecodeError:
                    continue
                text = str(payload.get("text", ""))
                if term.lower() not in text.lower():
                    continue
                session_id = str(payload.get("session_id", ""))[:12] or "unknown"
                ts = fmt_ts(payload.get("ts", 0))
                history_rows.append(f"{ts} | {session_id} | {preview(text)}")
        rows.extend(reversed(history_rows[-limit:]))

    state_db = newest_sqlite("~/.codex/state*.sqlite")
    if state_db is not None and len(rows) < limit:
        conn = sqlite3.connect(state_db)
        try:
            cursor = conn.execute(
                """
                SELECT
                    id,
                    updated_at,
                    cwd,
                    title,
                    first_user_message
                FROM threads
                WHERE lower(title || ' ' || first_user_message || ' ' || cwd) LIKE ?
                ORDER BY updated_at DESC
                LIMIT ?
                """,
                (f"%{term.lower()}%", max(limit - len(rows), 1)),
            )
            for thread_id, updated_at, cwd, title, first_user_message in cursor:
                rows.append(
                    f"{fmt_ts(updated_at)} | {thread_id[:12]} | {preview(f'{title} | {cwd} | {first_user_message}')}"
                )
        finally:
            conn.close()

    return rows[:limit]


def recent_codex(limit: int) -> list[str]:
    state_db = newest_sqlite("~/.codex/state*.sqlite")
    if state_db is None:
        return []
    conn = sqlite3.connect(state_db)
    try:
        cursor = conn.execute(
            """
            SELECT
                id,
                updated_at,
                cwd,
                title
            FROM threads
            ORDER BY updated_at DESC
            LIMIT ?
            """,
            (limit,),
        )
        return [
            f"{fmt_ts(updated_at)} | {thread_id[:12]} | {cwd} | {preview(title)}"
            for thread_id, updated_at, cwd, title in cursor
        ]
    finally:
        conn.close()


def search_gemini(term: str, limit: int) -> list[str]:
    rows: list[str] = []
    pattern = os.path.expanduser("~/.gemini/tmp/*/chats/session-*.json")
    for path_str in sorted(glob.glob(pattern), reverse=True):
        path = Path(path_str)
        try:
            payload = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        project = path.parts[-3]
        session_id = str(payload.get("sessionId", path.stem))[:12]
        for message in payload.get("messages", []):
            if message.get("type") != "user":
                continue
            text = "".join(part.get("text", "") for part in message.get("content", []))
            if term.lower() not in text.lower():
                continue
            rows.append(
                f"{fmt_ts(message.get('timestamp') or payload.get('startTime'))} | {session_id} | {project} | {preview(text)}"
            )
            break
        if len(rows) >= limit:
            break
    return rows


def recent_gemini(limit: int) -> list[str]:
    rows: list[tuple[str, str]] = []
    pattern = os.path.expanduser("~/.gemini/tmp/*/chats/session-*.json")
    for path_str in sorted(glob.glob(pattern), reverse=True):
        path = Path(path_str)
        try:
            payload = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        project = path.parts[-3]
        session_id = str(payload.get("sessionId", path.stem))[:12]
        last_updated = payload.get("lastUpdated") or payload.get("startTime")
        count = sum(1 for message in payload.get("messages", []) if message.get("type") == "user")
        rows.append((str(last_updated), f"{fmt_ts(last_updated)} | {session_id} | {project} | {count} user prompts"))
    rows.sort(key=lambda item: item[0], reverse=True)
    return [row for _, row in rows[:limit]]


def search_opencode(term: str, limit: int) -> list[str]:
    rows: list[str] = []

    prompt_history = HOME / ".local/state/opencode/prompt-history.jsonl"
    if prompt_history.exists():
        history_rows: list[str] = []
        with prompt_history.open() as handle:
            for line in handle:
                try:
                    payload = json.loads(line)
                except json.JSONDecodeError:
                    continue
                text = str(payload.get("input") or payload.get("prompt") or payload.get("message") or "")
                if term.lower() not in text.lower():
                    continue
                history_rows.append(f"prompt-history | {preview(text)}")
        rows.extend(reversed(history_rows[-limit:]))

    db_path = HOME / ".local/share/opencode/opencode.db"
    if db_path.exists() and len(rows) < limit:
        conn = sqlite3.connect(db_path)
        try:
            cursor = conn.execute(
                """
                SELECT
                    s.slug,
                    s.title,
                    s.directory,
                    s.time_created,
                    m.data
                FROM message m
                JOIN session s ON m.session_id = s.id
                WHERE lower(m.data) LIKE ?
                ORDER BY m.time_created DESC
                LIMIT ?
                """,
                (f"%{term.lower()}%", max(limit - len(rows), 1)),
            )
            for slug, title, directory, created, data in cursor:
                rows.append(f"{fmt_ts(created)} | {slug} | {preview(f'{title} | {directory} | {data}')}")
        finally:
            conn.close()

    return rows[:limit]


def recent_opencode(limit: int) -> list[str]:
    db_path = HOME / ".local/share/opencode/opencode.db"
    if not db_path.exists():
        return []
    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.execute(
            """
            SELECT
                slug,
                title,
                directory,
                time_updated
            FROM session
            ORDER BY time_updated DESC
            LIMIT ?
            """,
            (limit,),
        )
        return [
            f"{fmt_ts(updated)} | {slug} | {directory} | {preview(title)}"
            for slug, title, directory, updated in cursor
        ]
    finally:
        conn.close()


SEARCHERS = {
    "claude": search_claude,
    "codex": search_codex,
    "gemini": search_gemini,
    "opencode": search_opencode,
}

RECENTS = {
    "claude": recent_claude,
    "codex": recent_codex,
    "gemini": recent_gemini,
    "opencode": recent_opencode,
}


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode_or_terms", nargs="*", help="'recent' or search terms")
    parser.add_argument("--tool", choices=(TOOL_ALL,) + TOOLS, default=TOOL_ALL)
    parser.add_argument("--limit", type=int, default=10)
    args = parser.parse_args(argv)

    if args.mode_or_terms and args.mode_or_terms[0] == "recent":
        args.mode = "recent"
        args.term = ""
    else:
        args.mode = "search"
        args.term = " ".join(args.mode_or_terms).strip()
    return args


def selected_tools(tool: str) -> tuple[str, ...]:
    if tool == TOOL_ALL:
        return TOOLS
    return (tool,)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.mode == "search" and not args.term:
        args.mode = "recent"

    any_output = False
    for tool in selected_tools(args.tool):
        if args.mode == "recent":
            rows = RECENTS[tool](args.limit)
            title = f"{tool.title()} Recent"
        else:
            rows = SEARCHERS[tool](args.term, args.limit)
            title = f"{tool.title()} Matches"
        if rows:
            print_section(title, rows)
            any_output = True

    if not any_output:
        if args.mode == "recent":
            print("No local prompt history found.")
        else:
            print(f"No matches found for: {args.term}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
