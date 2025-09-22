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
ace-tf idea "Add dark mode support to the application"
```

Ideas are saved to the configured directory (default: `./ideas`) with timestamped filenames.

### Task Management (Coming Soon)

Future releases will include task management capabilities:

```bash
ace-tf task create "Implement user authentication"
ace-tf task list
ace-tf task complete TASK_ID
```

### Release Management (Coming Soon)

Future releases will include release management features:

```bash
ace-tf release create v1.0.0
ace-tf release current
ace-tf release list
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
bundle exec ace-tf idea "Test idea"
```

## License

MIT License - see LICENSE file for details.