# Unified Project-Aware Search (UPS) — Specification

**Version:** 1.0.0  
**Date:** 2025-08-09  
**Target OS:** macOS (works on Linux)  
**Authoring Language:** Ruby (wrapper around `fd` and `ripgrep`)  
**Command name:** `search`

> Note: Some previously uploaded specs in this chat have expired. This document is a complete, up-to-date specification that replaces them.

---

## 1. Purpose & Scope

UPS provides a single, project-aware CLI to search file **names**, file **contents**, or **both**, with smart defaults, `.gitignore` awareness, and excellent UX/DX. It always executes from the **project root** (auto-detected), even when invoked from a deep subdirectory.

The tool supports **multi-repo** workspaces: a superproject plus **git submodules** and optionally other nested repos.

---

## 2. Goals / Non-Goals

### Goals
- One intuitive command for filename/content search in monorepos and multirepos.
- Git-aware scopes: tracked, staged, changed, untracked, since `<time>`, ranges.
- First-class **submodule** and **nested repo** handling.
- Consistent, editor-friendly output (and JSON schema for automation).
- Delightful ergonomics: presets, DWIM heuristics, context lines, TUI mode.
- Safe and fast: NUL-safe pipelines, cancellation, chunked execution.

### Non-Goals
- Reimplementing `ripgrep` matching semantics or `fd` traversal—UPS delegates.
- Replacing `git`—UPS queries git for file lists; no history rewriting.
- Windows support (may work via MSYS2/WLS but not a primary target).

---

## 3. Dependencies

- `ripgrep` (`rg`) v13+
- `fd` v8+
- `git` v2.30+
- Optional: `fzf` for interactive mode

UPS performs a self-check on first run and prints precise install hints (Homebrew on macOS).

---

## 4. Project Root Detection

UPS resolves the project root using this precedence:

1. Nearest ancestor with `.git` (worktree supported)  
2. Else nearest ancestor with one of: `.searchrc`, `package.json`, `Gemfile`, `pyproject.toml`, `Cargo.toml`, `.hg`  
3. Else current directory

Users may override with `--root <path>`.

---

## 5. Modes & DWIM Heuristics

- **Files mode**: find files by **glob/name** patterns (delegates to `fd`).
- **Content mode**: search **inside files** (delegates to `rg`).
- **Combined mode**: restrict files by name/glob and then search contents.

**DWIM Rules** (overridable):
- If any `--in`/`--name` globs or `--type` are present → Combined mode.
- If query contains glob tokens (`*`, `?`, `[]`, `**/`) and **no** content flags → Files mode.
- Otherwise → Content mode.

Explicit overrides:
- `-f, --files` → Files mode
- `-c, --content` → Content mode

---

## 6. CLI Synopsis

```bash
search [FLAGS] [--] <pattern>
search --files [FLAGS] [--] <glob>...
search --preset <name> [--var k=v ...] [FLAGS] [--] <pattern?>
```

- `<pattern>`: ripgrep pattern (regex by default; `-F` for fixed string).
- `<glob>`: shell-style glob(s), supports `**`.

### Core Flags
- `-C, --context <N>`: lines of context before/after (content mode). Default: `2`.
- `-n, --name <glob>` / `--in <glob>`: include only files matching glob (repeatable).
- `-e, --expr <pattern>`: explicit pattern (useful with presets).
- `-t, --type <k[,k2...]>`: file types (mapping in §11). Repeatable; union.
- `--ext <e[,e2...]>`: extensions (e.g., `rb,js,ts`).
- `-i, --ignore-case` / `-S, --smart-case` / `-s, --case-sensitive`
- `--hidden`: include hidden files
- `--no-ignore`: disable ignore files
- `--max-results <N>`: stop after N matches
- `--json`: machine-readable output (schema in §10)
- `--open`: open **first** result in `$EDITOR` (see §9)
- `--quickfix <vim|vscode|sublime>`: format output for editor quickfix lists
- `--fzf`: interactive picker (see §8)
- `--explain`: print the exact commands it will run (`fd`/`rg`/`git`), then run
- `--dry-run`: print commands only, do not run
- `--stats`: print timing and counters
- `--root <path>`: override root detection

### Git Scope Flags (see §7)
- `--tracked` | `--staged` | `--untracked`
- `--changed [<range>]` (e.g., `origin/main..HEAD`)
- `--since <time>` (e.g., `2d`, `3w`, `2025-08-01`)
- `--author <pattern>` (limits content search to files touched by author in range/since)

### Multirepo Flags (see §6.3 and §7)
- `--multi-repo <auto|submodules|detect|off>` (default: `auto`)
- `--include-submodules` (on by default when `.gitmodules` exists)
- `--no-submodules`

### Pass-through Flags
- `--fd ...` after `--fd` passes raw args to `fd` until `--rg` or end.
- `--rg ...` passes raw args to `rg`.
- `--` treats everything after as the search pattern (disables flag parsing).

#### 6.1 Exit Codes
- `0`: matches found
- `1`: no matches
- `2`: error (bad flag, missing dependency, etc.)

#### 6.2 Examples
```bash
# Content search with 3 lines of context
search "timeout.*Ms" -C 3

# Restrict by name + search content
search --in "**/*.rb" "class .*Controller"

# Files-only search
search --files "**/*_spec.rb"

# Only tracked files across superproject and submodules
search --tracked "connection leak"

# Changed since yesterday, tests preset, open first result
search @tests --changed --since=1d "flaky" --open
```

#### 6.3 Multirepo Defaults
- If `.gitmodules` exists → include submodules by default.
- `--multi-repo=detect` also includes **nested** repos not registered as submodules (bounded depth, default 3).

---

## 7. Git-Aware Scopes & Multirepo

UPS enumerates repos based on `--multi-repo`:
- **auto**: superproject + submodules (if present)
- **submodules**: superproject + submodules only
- **detect**: superproject + submodules + nested repos discovered via `.git` directories (excluding `.git` files that point outside unless the real dir exists)
- **off**: superproject only

Per repo, UPS builds NUL-delimited file lists using **git pathspecs** derived from `--in/--name`, `--type`, `--ext`:

- **Tracked**: `git -C <repo> ls-files -z -- <pathspec...>`
- **Untracked**: `git -C <repo> ls-files --others --exclude-standard -z -- <pathspec...>`
- **Staged**: `git -C <repo> diff --cached --name-only -z -- <pathspec...>`
- **Changed range**: `git -C <repo> diff <A..B> --name-only -z -- <pathspec...>`
- **Since time**: `git -C <repo> log --since=<t> --name-only -z --pretty=format: -- <pathspec...>`

**Submodule range** nuance: if the superproject points changed from `<A>` to `<B>`, UPS infers `<A..B>` within the submodule and uses that for `--changed` if a range is provided.

De-dup paths across repos, prefix with repo root, then stream to ripgrep.

### 7.1 Git Pathspec Mapping
- Include globs via `:(glob)` prefix:
  - `**/*.rb` → `:(glob)**/*.rb`
- Exclusions (`!glob`) → `:(exclude,glob)<glob>`
- Mixed include/exclude rules are preserved in order.

---

## 8. Interactive Mode (`--fzf`)

When `--fzf` is present:
- Left pane: candidate files (from `fd` or git file list)
- Right pane: live `rg` preview with `-C <context>` and highlighting
- Enter: open selection in `$EDITOR` at first match location
- Multi-select → open multiple files

Implementation: Pipe candidate list to `fzf --preview 'rg -n --color=always -C {context} -- {query} {+f}'` with proper escaping; UPS provides the `{context}` and `{query}` placeholders.

---

## 9. Editor Integration

- `$EDITOR` respected for `--open`. Common formats supported:
  - **VS Code**: `code --goto path:line:col`
  - **Vim/Neovim**: `vim +{line} {path}`
  - **Sublime**: `subl path:line:col`
- `--quickfix` formats output for target editor:
  - `vim`: `path:line:col: message`
  - `vscode`: same as `--goto` input per line

---

## 10. Output Formats

### 10.1 Human (default)
Single-line per match:
```
<path>:<line>:<col>: <text-with-highlight>
```
- No repeated file headers (compact).
- ANSI colors on TTY; suppressed with `--no-ansi`.

### 10.2 JSON (`--json`)
UPS normalizes `rg --json` events and pairs them with file metadata.

#### JSON Schema
```json
{
  "type": "object",
  "properties": {
    "version": { "type": "string" },
    "root": { "type": "string" },
    "repos": {
      "type": "array",
      "items": { "type": "string" }
    },
    "matches": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "path": { "type": "string" },
          "line": { "type": "integer" },
          "column": { "type": "integer" },
          "match": { "type": "string" },
          "lines_before": { "type": "array", "items": { "type": "string" } },
          "lines_after": { "type": "array", "items": { "type": "string" } }
        },
        "required": ["path", "line", "column", "match"]
      }
    },
    "stats": {
      "type": "object",
      "properties": {
        "files_scanned": { "type": "integer" },
        "files_matched": { "type": "integer" },
        "matches": { "type": "integer" },
        "duration_ms": { "type": "integer" }
      }
    }
  },
  "required": ["version", "root", "matches"]
}
```

**Files-only** results emit `matches` where `line=0`, `column=0`, and `match` is the filename (for consistency).

---

## 11. Types & Extensions

Built-in shorthand types map to `fd` and `rg` filters simultaneously:

```yaml
types:
  rb:   [".rb", ".rake", "Rakefile", "Gemfile"]
  js:   [".js", ".jsx"]
  ts:   [".ts", ".tsx"]
  py:   [".py"]
  go:   [".go"]
  rs:   [".rs"]
  java: [".java", ".kt"]
  c:    [".c", ".h"]
  cpp:  [".cpp", ".hpp", ".cc", ".hh"]
  md:   [".md", ".markdown"]
```

Users can extend these in config (see §13).

---

## 12. Ignore Strategy

- Respect `.gitignore`, `.ignore`, and VCS ignores by default.
- Ignore common junk folders: `node_modules`, `dist`, `build`, `target`, `coverage`, `.venv`, unless `--all` or `--no-ignore`.
- Project-specific ignores via `.searchrc: ignore:` (paths/globs).

---

## 13. Configuration & Presets

UPS merges configurations in this order (later wins):
1. **Built-in defaults**
2. `~/.config/search/config.yml` (user)
3. `<project>/.searchrc` (project)

### 13.1 YAML Structure
```yaml
defaults:
  context: 2
  include_submodules: true
  types: { ts: [".mts", ".cts"] }
  ignore:
    - "tmp"
    - "log"

presets:
  tests:
    in: ["**/*_spec.rb"]
    type: ["rb"]
  recent:
    changed: "origin/main..HEAD"
    context: 3
  logs:
    in: ["log/**/*.log"]
    content: false
  owner:
    author: "${who}"
  since:
    since: "${when}"
```

### 13.2 Running Presets
- Single: `search --preset tests "DatabaseCleaner"`
- Multiple (merged left→right): `search --preset tests --preset recent "flaky"`
- Shorthand: `search @tests @recent "flaky"`
- Parameterized: `search --preset owner --var who="Alice <alice@x.com>" "refactor"`
- Inspect: `search --preset show tests`
- Edit: `search --preset edit tests`

**Merge rules:**
- Scalars: last-writer wins.
- Arrays (`type`, `ignore`, `in`): union.
- `--no-*` flags nullify preset entries.

---

## 14. Performance

- Prefer `git ls-files` when scope is `--tracked` (fast, pre-indexed).
- Use chunked NUL-safe piping: write file list to a FIFO and `xargs -0 -n1000 rg ...`.
- Parallelism: respect `rg` default threading; optionally expose `--threads` to cap.
- Optional recency ranking: boost files touched in last 30d (info from `git log`).

---

## 15. Safety & Robustness

- **NUL-safety**: internal pipes carry `\0`-separated paths; no lossy conversions.
- **Quoting**: spawn child processes with argv arrays (no shell-join).
- **Signals**: forward SIGINT/SIGTERM to children; clean shutdown.
- **Path separators**: normalize to `/` in output; preserve native paths for launching editors.

---

## 16. Error Handling

- Missing dependency → actionable message with install command.
- No repos found for `--multi-repo=detect` → fallback to project root with warning.
- Invalid range (e.g., `foo..bar`) → print git error and exit 2.
- Preset not found → suggest `search --presets`.
- Conflicting flags (e.g., `--files` with content-only options) → explain and hint.

---

## 17. Implementation Outline (Ruby)

- CLI parsing via `OptionParser`. Support pass-through zones `--fd` / `--rg` / `--`.
- Root detection (see §4). `Dir.chdir(root)`.
- Repo enumeration (`enumerate_repos(mode)`).
- Build pathspecs (`glob_to_pathspec`):
  - `**/*.rb` → `:(glob)**/*.rb`
  - `!**/*.log` → `:(exclude,glob)**/*.log`
- File list per repo (`git_filelist(repo, scope, pathspecs)`), returns NUL-delimited IO (Tempfile/FIFO).
- Combined mode:
  1) If git scope active → use git-provided list; else use `fd -0` for candidates.
  2) Pipe candidates to `xargs -0 -n1000 rg ...` with constructed args (`-C`, case, etc.).
- JSON mode: wrap `rg --json`, transform events into `matches` array with context.
- `--open`: parse first match; select editor template; spawn editor.
- `--fzf`: wrap picker; on select, re-run `rg` to compute first match location for `--open`.
- `--stats`: wall clock, files scanned/matched, match count.

---

## 18. Testing Strategy

- Unit: pathspec conversion, repo enumeration, preset merging, arg building.
- Integration: fixtures with submodules and nested repos; golden outputs (text & JSON).
- Smoke: dependency checks; exit codes; signal handling (Ctrl-C).

---

## 19. Telemetry (Optional, Off by Default)

- Anonymous counters: command duration, match count, errors (no paths or patterns).
- Opt-in via config `telemetry: true`.

---

## 20. Examples (Quick Reference)

```bash
# 3 lines of context around "timeout"
search "timeout" -C 3

# Rails controllers in Ruby files
search --in "app/**/*.rb" "class .*Controller"

# Tests preset + recent changes
search @tests @recent "flaky"

# Search only staged files across submodules
search --staged "fixme"

# Owner sweep across nested repos
search @owner --var who="Bob <bob@company.com>" "TODO" --multi-repo=detect

# Files-only: list markdown docs
search --files "**/*.md"

# JSON for automation
search --json "jwt" > results.json
```

---

## 21. Versioning & Compatibility

- Semantic versioning for CLI behavior. Breaking flag changes bump major.
- Require `rg >= 13`, `fd >= 8`, `git >= 2.30` for consistent features.
- Config keys are forward-compatible when unknown keys are ignored with warnings.

---

## 22. Open Questions / Future Work

- Windows support (PowerShell quoting and path separators).
- Built-in language server hooks (jump to symbol via ctags/tree-sitter).
- Inverted search (“show me files NOT containing X”).

---

**End of specification.**
