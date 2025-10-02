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
ace-taskflow idea "Add dark mode support to the application"
```

Ideas are saved to the configured directory (default: `./ideas`) with timestamped filenames.

### Task Management

Create and manage tasks with descriptive paths:

```bash
# Create a new task (automatically generates descriptive path)
ace-taskflow task create "Implement user authentication"
# Creates: .ace-taskflow/v.0.9.0/t/035-feat-user-authentication/task.035.md

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