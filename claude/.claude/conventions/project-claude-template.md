# Project CLAUDE.md Template

Copy to `CLAUDE.md` in project root. Fill sections that apply, delete the rest.

```markdown
# <Project Name>

<1-line description>

## Services

- **API**: `uvicorn app.main:app --reload` on :8000
- **DB**: PostgreSQL on :5432, schema in `migrations/`

## Commands

- `make test` — run pytest (unit only)
- `make test-all` — run pytest including @slow
- `make lint` — ruff check + mypy

## Domain

- Key concept: <brief explanation>
- Data flow: <input> → <processing> → <output>

## Pitfalls

- <thing that breaks and isn't obvious>
- <workaround for known issue>

## Architecture

- `src/core/` — domain logic (no I/O)
- `src/api/` — HTTP handlers
- `src/infra/` — DB, external services
```
