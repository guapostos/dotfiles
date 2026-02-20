# tmux cheatsheet

Prefix: **`C-]`** (Ctrl+])

## Panes

| Action | Keys |
|---|---|
| Split vertical (side-by-side) | `C-] v` |
| Split horizontal (top/bottom) | `C-] s` |
| Navigate h/j/k/l | `C-] h/j/k/l` |
| Resize (5 units, repeatable) | `C-] H/J/K/L` |
| Resize (1 unit) | `C-] M-h/j/k/l` |
| Swap pane down/up | `C-] >` / `C-] <` |
| Rotate panes | `C-] C-o` |
| Zoom/unzoom pane | `C-] z` |
| Close pane | `C-] x` |
| Sync panes toggle | `C-] S` |
| Dev layout (2x2 grid) | `C-] T` |

## Windows (tabs)

| Action | Keys |
|---|---|
| New window | `C-] c` |
| Next / prev window | `C-] n` / `C-] p` |
| Go to window N | `M-1` through `M-5` (no prefix!) |
| Go to window N (6+) | `C-] 6` through `C-] 9` |
| Rename window | `C-] ,` |
| Kill window | `C-] &` |
| Window tree picker | `C-] w` |

## Sessions

| Action | Keys |
|---|---|
| Detach | `C-] d` |
| Session/window tree | `C-] w` |
| Rename session | `C-] $` |

## Copy/paste (emacs mode)

| Action | Keys |
|---|---|
| Enter copy mode | `C-] [` |
| Move around | Arrow keys or `C-b/f/n/p` |
| Page up / down | `M-v` / `C-v` |
| Top / bottom | `M-<` / `M->` |
| Search forward / back | `C-s` / `C-r` |
| Start selection | `C-Space` |
| Copy to clipboard | `M-w` |
| Paste tmux buffer | `C-] ]` |
| Quit copy mode | `q` or `C-g` |

`M-w` copies to system clipboard (pbcopy on macOS, wl-copy/xclip on Linux).

## Other

| Action | Keys |
|---|---|
| Reload config | `C-] r` |
| Command prompt | `C-] :` |
| List keybindings | `C-] ?` |

## CLI

```bash
tmux new -s name          # new named session
tmux attach -t name       # attach to session
tmux ls                   # list sessions
tmux kill-session -t name # kill session
```
