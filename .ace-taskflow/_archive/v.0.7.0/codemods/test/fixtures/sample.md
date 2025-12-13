# Test Fixture for Markdown Files

This document contains various references to dev-* paths that should be updated.

## Documentation Links

- See [Tools Documentation](.ace/tools/docs/README.md)
- Check out the [Handbook](.ace/handbook/index.md)
- Review [Current Tasks](.ace/taskflow/current/)
- Local configuration in [.ace/local/config.yml](.ace/local/config.yml)

## Inline References

The `.ace/tools/` directory contains all executable tools. You can find templates in `.ace/handbook/templates/` and manage tasks in `.ace/taskflow/`.

Local overrides are stored in ".ace/local/" directory.

## Code Blocks

```bash
cd .ace/tools/
./bin/tool --help

# Navigate to handbook
cd ../.ace/handbook/
ls -la

# Check taskflow
cd ../.ace/taskflow/current/
cat README.md

# Local config
cp template.yml ../.ace/local/config.yml
```

```ruby
require '.ace/tools/lib/tool'
load '.ace/handbook/lib/helper.rb'
Dir.glob('.ace/taskflow/**/*.md')
File.read('.ace/local/settings.yml')
```

## Reference Links

[tools]: .ace/tools/README.md "Tools Documentation"
[handbook]: .ace/handbook/README.md "Handbook Documentation"
[taskflow]: .ace/taskflow/README.md "Taskflow Documentation"
[local]: .ace/local/README.md "Local Configuration"

## Table with Paths

| Component | Path | Description |
|-----------|------|-------------|
| Tools | `.ace/tools/` | Executable tools and utilities |
| Handbook | `.ace/handbook/` | Documentation and guides |
| Taskflow | `.ace/taskflow/` | Task management |
| Local | `.ace/local/` | Local configuration |

## URLs and Full Paths

- Full path: /Users/project/.ace/tools/bin/executable
- Relative: ./.ace/handbook/docs/guide.md
- Parent: ../.ace/taskflow/backlog/task.md
- URL style: file://.ace/local/cache/data.json

## Mixed Contexts

The project structure includes ".ace/tools/" for tools, '.ace/handbook/' for documentation, `.ace/taskflow/` for tasks, and .ace/local/ for local settings.

### Nested Paths

- Main: .ace/tools/lib/.ace/tools/core.rb
- Docs: .ace/handbook/docs/.ace/handbook/overview.md
- Tasks: .ace/taskflow/current/.ace/taskflow/structure.md
- Local: .ace/local/cache/.ace/local/temp.txt