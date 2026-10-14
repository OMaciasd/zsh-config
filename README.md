# zsh-config

Reusable Zsh prompt configuration with Git status, an optional Trivy indicator,
and a previous-command exit status indicator.

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/OMaciasd/zsh-config.git
   ```
2. Source the prompt file from `~/.zshrc`:
   ```zsh
   source /path/to/zsh-config/config/prompt.zsh
   ```
3. Define `get_git_custom_status` before sourcing if you want a Git segment.

## Exit status codes

| Code | Symbol | Meaning                  |
|------|--------|--------------------------|
| 0    | (none) | Success clears indicator |
| 1    | ❌ (red) | General error           |
| 2    | ⚠️ (yellow) | Misuse / shell error    |
| 126  | 🚫 (red) | Not executable          |
| 127  | 🔎 (yellow) | Command not found       |
| 130  | 🛑 (yellow) | Interrupted (Ctrl+C)    |
| 137  | 💀 (red) | Killed (SIGKILL)        |
| 143  | 🔴 (yellow) | Terminated (SIGTERM)    |
| *    | ✗ (red) | Other failure            |

## Dependencies

- Zsh 5.0 or newer (`add-zsh-hook`).
- Optional `get_git_custom_status` function. When absent, the Git segment is
  omitted silently.
- Optional `TRIVY_PROMPT_ICON` environment variable.

## Tests

```sh
zsh tests/check-syntax.zsh
zsh tests/test-prompt.zsh
```

## Limitations

- Trivy status is supplied externally through `TRIVY_PROMPT_ICON`; this
  repository does not run Trivy.
- Git status formatting is delegated to `get_git_custom_status`.
- Emoji rendering depends on the terminal font.
