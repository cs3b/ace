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

## Usage

### Capture Ideas

Quickly capture ideas with automatic timestamping and organization:

```bash
# Capture text idea
ace-taskflow idea create "Add dark mode support to the application"

# Capture from clipboard (macOS with rich content support)
ace-taskflow idea create --clipboard "Design review findings"
# Automatically detects and saves images, files, HTML, RTF from clipboard

# Capture with clipboard merge
ace-taskflow idea create -gc --clipboard "Meeting notes"
# Merges typed content with clipboard content
```

Ideas are saved to the configured directory with timestamped filenames:
- **Simple ideas**: Single `.md` file (e.g., `20251007-125830-dark-mode-support.md`)
- **Rich ideas**: Directory with `idea.md` + attachments (e.g., `20251007-125830-design-review/`)

#### Clipboard Support (macOS)

When using `--clipboard` on macOS, ace-taskflow automatically detects and saves:
- **Text**: Plain and rich text
- **Images**: PNG, JPEG, TIFF formats
- **Files**: Finder file copies (preserves original filenames)
- **HTML/RTF**: Web content and formatted text

Non-macOS platforms fall back to text-only clipboard support.

### List Ideas

Browse and filter ideas with flexible display options:

```bash
# List pending ideas (default - optimized for LLMs with paths)
ace-taskflow ideas
ace-taskflow ideas next

# Human-friendly list (no paths, shows IDs for reference)
ace-taskflow ideas --short

# JSON output for programmatic use
ace-taskflow ideas --format json

# List all ideas including completed
ace-taskflow ideas all

# List only completed ideas
ace-taskflow ideas done

# Recent ideas (last 7 days)
ace-taskflow ideas recent
ace-taskflow ideas recent --days 3

# Limit results
ace-taskflow ideas --limit 10
```

#### Display Formats

**Default (LLM-optimized)**: Shows file paths for direct access
```
• add documentation for new llm features
  .ace-taskflow/v.0.9.0/ideas/20250925-005011-add-documentation-for-new-llm-features.md
• design review findings 📎 3
  .ace-taskflow/v.0.9.0/ideas/20251007-125830-design-review/idea.md
```

**--short (Human-friendly)**: Shows IDs without paths
```
• [20250925-005011] add documentation for new llm features
• [20251007-125830] design review findings 📎 3
```

**--format json**: Structured output with metadata
```json
{
  "release": "v.0.9.0",
  "summary": {
    "ideas": {"total": 31, "active": 23, "completed": 8}
  },
  "ideas": [
    {
      "id": "20251007-125830",
      "title": "design review findings",
      "type": "rich",
      "path": ".ace-taskflow/v.0.9.0/ideas/20251007-125830-design-review/idea.md",
      "attachments": 3,
      "attachment_types": [".png", ".pdf"]
    }
  ]
}
```

**Rich ideas**: Ideas with attachments are marked with 📎 icon and attachment count.

### Task Management

Create and manage tasks with descriptive paths:

```bash
# Create a new task (automatically generates descriptive path)
ace-taskflow task create "Implement user authentication"
# Creates: .ace-taskflow/v.0.9.0/t/035-feat-user-authentication/task.035.md

# Create with metadata flags
ace-taskflow task create --title "Fix bug" --status draft --estimate 2h
ace-taskflow task create "Write tests" --dependencies 041,042 --estimate 4h

# Create in different contexts
ace-taskflow task create "Future feature" --backlog
ace-taskflow task create "Hotfix" --release v.0.10.0

# List and navigate tasks
ace-taskflow task list
ace-taskflow task          # Get next task
ace-taskflow task 035      # Navigate to specific task
ace-taskflow task complete 035

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

### Retrospective Management

Capture and manage reflection notes for development sessions:

```bash
# Create a new reflection note
ace-taskflow retro create "sprint-23-learnings"

# List active retrospective notes
ace-taskflow retros

# View specific retro
ace-taskflow retro show sprint-23-learnings

# Mark retro as done (moves to done/ folder)
ace-taskflow retro done sprint-23-learnings

# List all retros including done
ace-taskflow retros --all

# List only done retros
ace-taskflow retros --done
```

Retrospective notes follow the done pattern similar to ideas:
- **Active retros**: Stored in `.ace-taskflow/<release>/retro/`
- **Done retros**: Moved to `.ace-taskflow/<release>/retro/done/`
- Default listing excludes done retros (cleaner view)
- Use `--all` or `--done` flags to include completed retros

### Release Management (Coming Soon)

Future releases will include release management features:

```bash
ace-taskflow release create v1.0.0
ace-taskflow release current
ace-taskflow release list
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
bundle exec ace-taskflow idea "Test idea"
```

## License

MIT License - see LICENSE file for details.