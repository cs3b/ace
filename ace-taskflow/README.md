# ace-taskflow

Unified task and idea management for ACE projects.

## Installation

Add this gem to your Gemfile:

```ruby
gem 'ace-taskflow'
```

Or install it directly:

```bash
gem install ace-taskflow
```

## Base36 Compact ID Format

**New in v0.9.0**: ace-taskflow now uses 6-character Base36 compact IDs by default (e.g., `i50jj3`) instead of 14-character timestamps (e.g., `20250106-123000`).

### Key Features

- **Compact**: 6 characters vs 14 characters (57% shorter)
- **Sortable**: String sorting equals chronological sorting
- **Precision**: ~1.85 seconds per increment (sufficient for task/idea management)
- **Coverage**: 108 years from configured year_zero (default: 2000)

### Configuration

All ideas use 6-character Base36 compact IDs by default. The file naming pattern can be customized in `.ace/taskflow/config.yml`:

```yaml
taskflow:
  file_naming:
    title_max_length: 50   # Max length of title in filename (default: 50)
```

### Precision Notes

The Base36 format has approximately **1.85 seconds of precision**:
- Two ideas created within ~1.85 seconds may share the same ID
- The system appends a counter (e.g., `i50jj3-1`, `i50jj3-2`) to handle collisions
- This precision is intentional for compactness and is sufficient for task/idea use cases

For more details on the encoding scheme, see the [ace-b36ts README](https://github.com/cs3b/ace-meta/tree/main/ace-b36ts).

## Filename Formats

### Idea Files

All ideas use the `{slug}.idea.s.md` format within their ID directory:

```
ideas/
  └── abc123-dark-mode/
      └── dark-mode.idea.s.md
```

**Structure**:
- `{base36-id}-{slug}/` - Directory with Base36 ID and descriptive slug
- `{slug}.idea.s.md` - Idea file with descriptive slug

**Example**: `abc123-add-dark-mode/add-dark-mode.idea.s.md`

### Retrospective Files

All retrospectives use the `{base36-id}-{slug}.md` format:

```
retros/
  └── i50jj3-sprint-review.md
```

**Structure**:
- `{base36-id}-{slug}.md` - Base36 timestamp ID with descriptive slug

**Benefits**:
- Sortable by creation time (string sort = chronological sort)
- Compact filenames (6-char ID)
- Consistent with idea directory naming

## Usage

### Capture Ideas

Idea management is provided by the standalone `ace-idea` gem. Quickly capture ideas with
automatic timestamping and organization:

```bash
# Capture text idea
ace-idea create "Add dark mode support to the application"

# Capture from clipboard
ace-idea create --clipboard "Design review findings"
```

Ideas are saved to `.ace-ideas/` with subfolders for lifecycle stages:
- `_next/` — High-priority ideas queued for action
- `_maybe/` — Ideas parked for later consideration
- `_anytime/` — Good ideas with no urgency
- `_archive/` — Completed or skipped ideas

### List Ideas

Browse and filter ideas with flexible options:

```bash
# List all ideas (default)
ace-idea list

# List ideas in a specific folder
ace-idea list --in next
ace-idea list --in maybe

# Filter by status
ace-idea list --status done
ace-idea list --status pending
```

**Output format:**
```
⚪ 8ppq7w Add dark mode support [ux enhancement] (_next)
⚪ 3kx9mz Design review findings [design] (_maybe)
```

### Move and Update Ideas

```bash
# Mark idea as done and archive it
ace-idea move <id> --to archive
ace-idea update <id> --set status=done

# Park an idea for later
ace-idea move <id> --to maybe

# Promote parked idea to next queue
ace-idea move <id> --to next

# Move to anytime folder
ace-idea move <id> --to anytime
```

### Task Management

Create and manage tasks with descriptive paths:

```bash
# Create a new task (automatically generates descriptive path)
ace-task create "Implement user authentication"
# Creates: .ace-taskflow/v.0.9.0/t/035-feat-user-authentication/task.035.md

# Create with metadata flags
ace-task create --title "Fix bug" --status draft --estimate 2h
ace-task create "Write tests" --dependencies 041,042 --estimate 4h

# Create in different contexts
ace-task create "Future feature" --backlog
ace-task create "Hotfix" --release v.0.10.0

# List and navigate tasks
ace-task list
ace-task          # Get next task
ace-task show 035 # Navigate to specific task
ace-task complete 035

# Migrate existing tasks to new descriptive format
ace-taskflow migrate-paths              # Migrate all tasks
ace-taskflow migrate-paths --dry-run    # Preview changes without migrating
```

#### Descriptive Task Paths

Tasks now use semantic directory names that include:
- **Task number**: Unique identifier (e.g., `035`)
- **Type**: Task nature (`feat`, `fix`, `docs`, `test`, `refactor`)
- **Context**: Component affected (e.g., `taskflow`, `context`, `nav`)
- **Keywords**: Descriptive summary from title

Example: `035-feat-taskflow-github-import/task.035.md`

Benefits:
- Instant context when browsing directories
- Better organization and grouping
- Improved searchability
- AI-friendly structure

#### Orphan Subtasks Display

When filtering tasks with presets (e.g., `ace-task list next`), subtasks whose parent tasks are not in the filtered results are displayed with their parent context shown above them. These are called "orphan subtasks."

The parent task is marked with a `[context]` indicator to show it's being displayed for context only (it's not part of the filtered results):

```
  v.0.9.0+task.202 🟢 Parent Orchestrator (Orchestrator) [context]
    .ace-taskflow/v.0.9.0/tasks/202-task-refactor/202-rename-support-gems.s.md
    └─ v.0.9.0+task.203 🟡 Show parent task context for orphan subtasks
```

**When orphan display occurs:**

1. **Filtered results don't include the parent**: When you use a preset that filters tasks (e.g., `next` shows only pending tasks), and a subtask matches the filter but its parent doesn't
2. **Parent lookup succeeds**: The command finds the parent task via `show_task` and displays it for context
3. **Parent is marked with `[context]`**: The parent line includes a `[context]` indicator to distinguish it from actual filtered results

**Example scenario:**

```
# Parent task 202 is "done", subtask 203 is "pending"
ace-task list next   # Shows only pending tasks

# Output:
  v.0.9.0+task.202 🟢 Rename Support Gems (Orchestrator) [context]
    .ace-taskflow/v.0.9.0/tasks/202-task-refactor/202-rename-support-gems.s.md
    └─ v.0.9.0+task.203 🟡 Show parent context for orphan subtasks
```

The parent (202) is shown because it provides context for subtask 203, even though task 202 itself doesn't match the "pending" filter. The `[context]` marker makes it clear that task 202 is not part of the filtered results.

**Debug mode:**

If a parent task cannot be found (e.g., it was deleted), use `--verbose` or `--debug` to see which subtasks were skipped:

```bash
ace-task list next --verbose
# Output: [DEBUG] Parent task 202 not found for orphan subtask group (1 subtask(s) skipped)
```

### Retrospective Management

Capture and manage reflection notes for development sessions:

```bash
# Create a new reflection note
ace-retro create "sprint-23-learnings"

# List active retrospective notes
ace-retro list

# View specific retro
ace-retro show sprint-23-learnings

# Mark retro as done (moves to configured archive directory)
ace-retro done sprint-23-learnings

# List all retros including done
ace-retro list --all

# List only done retros
ace-retro list --done
```

Retrospective notes follow the archive pattern similar to ideas:
- **Active retros**: Stored in `.ace-taskflow/<release>/retros/` (configurable)
- **Done retros**: Moved to configured archive directory (default: `done/` subdirectory within retros/)
- **Default listing**: Excludes done retros for cleaner view
- **Show all**: Use `--all` or `--done` flags to include completed retros

#### Configuring Retro Directory

Customize the retro directory name in `.ace/taskflow/config.yml`:

```yaml
taskflow:
  directories:
    retros: "reflections"  # or any name you prefer
```

**Default**: `retros`
**Applies to**: All releases, doctor validation, and CLI commands

### Status Information

Get taskflow status with task activity awareness:

```bash
# Get current status (markdown output)
ace-taskflow status

# Get status as JSON
ace-taskflow status --json

# Customize activity display limits
ace-taskflow status --recently-done-limit 5 --up-next-limit 10

# Include draft tasks in Up Next section
ace-taskflow status --include-drafts

# Disable task activity section entirely
ace-taskflow status --no-include-activity
```

The status command provides:
- **Release info**: Active release with done/total counts and codename
- **Task info**: Resolved task from branch pattern (ID, title, status, estimate)
- **Task Activity**: Recently completed, in-progress, and upcoming tasks

For git state (branch, PR), use `ace-git status`.

#### Release Codename Extraction

The codename shown in the release header (e.g., "v.0.9.0: 15/31 tasks • Mono-Repo Multiple Gems") is extracted from the release directory's `README.md` file. The first markdown header is parsed:

```markdown
# v.0.9.0 Mono-Repo Multiple Gems
```

The descriptive part after the version (e.g., "Mono-Repo Multiple Gems") becomes the codename. If no README.md exists or the header doesn't match the expected pattern, no codename is displayed.

Requires the `ace-git` gem for task pattern detection from branch names.

### Release Management (Coming Soon)

Future releases will include release management features:

```bash
ace-release create v1.0.0
ace-release current
ace-release list
```

## Configuration

ace-taskflow uses the ACE configuration cascade system. Create a `.ace/taskflow/config/taskflow.yml` file in your project:

```yaml
taskflow:
  idea:
    directory: "./dev-taskflow/backlog/ideas"
    template: |
      # %{title}

      %{content}

      ---
      Captured: %{timestamp}
      Tags: %{tags}
    timestamp_format: "%Y-%m-%d %H:%M:%S"
  task:
    directory: "./dev-taskflow/current"
  release:
    directory: "./dev-taskflow/done"
```

### Configuration Options

- **idea.directory**: Where to save idea files (default: `./ideas`)
- **idea.template**: Template for formatting ideas (supports `%{content}`, `%{timestamp}`, `%{title}`, `%{tags}`)
- **idea.timestamp_format**: Format for timestamps (default: `%Y-%m-%d %H:%M:%S`)

### Status Activity Configuration

The status command's Task Activity section can be configured in `.ace/taskflow/config.yml`:

```yaml
status:
  activity:
    recently_done_limit: 3      # Max recently completed tasks to show (default: 3, 0 to disable)
    up_next_limit: 3            # Max upcoming tasks to show (default: 3, 0 to disable)
    include_drafts: false       # Include draft tasks in Up Next (default: false)
```

These defaults can be overridden via CLI flags:
- `--recently-done-limit N`: Show N recently completed tasks
- `--up-next-limit N`: Show N upcoming tasks
- `--include-drafts`: Include draft tasks in the Up Next section
- `--no-include-activity`: Disable the entire Task Activity section

Set a limit to `0` to disable that section entirely.

## Architecture

ace-taskflow follows the ATOM architecture pattern:

- **Atoms**: Pure functions for data transformation
- **Molecules**: Focused operations (e.g., FileNamer)
- **Organisms**: Business logic orchestration (e.g., IdeaWriter)
- **Models**: Data structures
- **Commands**: CLI command implementations

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rake test
```

To test the CLI:

```bash
bundle exec ace-idea "Test idea"
```

## License

MIT License - see LICENSE file for details.
