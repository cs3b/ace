# ACE Configuration Directory

This directory contains all configuration for the ACE (Agent Coding Environment) development system.

**Important**: All configurations are explicit - there are no hidden defaults in the gems. Each gem provides example configurations in their `ace.example/` directories that should be copied here and customized for your project.

## Directory Structure

```
.ace/
├── core/                  # Core configuration
│   └── settings.yml       # Cascade settings, environment, paths
├── context/               # Context loading
│   ├── config.yml         # Cache settings, output formats
│   └── presets/           # Context presets
│       ├── project.md     # Full project context
│       ├── minimal.md     # Minimal context
│       └── *.md          # Custom presets
├── git/                   # Git operations
│   └── commit.yml         # Commit generation settings
├── llm/                   # LLM integration
│   ├── query.yml          # Default models, generation settings
│   └── providers/         # Provider configurations
│       ├── openai.yml
│       ├── anthropic.yml
│       └── *.yml
├── nav/                   # Navigation and discovery
│   ├── config.yml         # Navigation settings
│   └── protocols/         # Protocol definitions
│       ├── wfi.yml        # Workflow instructions
│       ├── guide.yml      # Guides
│       ├── task.yml       # Tasks
│       └── sources/       # Protocol sources
├── taskflow/              # Task management
│   ├── config.yml         # Task management settings
│   └── presets/           # Task filter presets
│       ├── current.yml
│       ├── next.yml
│       └── recent.yml
├── test/                  # Testing
│   ├── runner.yml         # Test runner configuration
│   └── suite.yml          # Test suite definitions
└── README.md              # This file
```

## Configuration Cascade

Configurations are loaded using a cascade system where later values override earlier ones:

1. **Gem defaults** (removed - all config must be explicit)
2. **User home**: `~/.ace/namespace/file.yml`
3. **Project local**: `./.ace/namespace/file.yml` (highest priority)
4. **Environment variables**: `ACE_NAMESPACE_KEY=value` (override all)

### Example Cascade

For the git commit configuration:
1. Load `~/.ace/git/commit.yml` (user defaults)
2. Load `./.ace/git/commit.yml` (project specific)
3. Check `ACE_GIT_MODEL` environment variable
4. Final value: project overrides user, env overrides all

## Namespace Conventions

Each ace-* gem owns its configuration namespace:

| Gem | Namespace | Main Config | Additional Files |
|-----|-----------|-------------|------------------|
| ace-core | `core/` | `settings.yml` | - |
| ace-context | `context/` | `config.yml` | `presets/*.md` |
| ace-git-commit | `git/` | `commit.yml` | - |
| ace-llm | `llm/` | `query.yml` | `providers/*.yml` |
| ace-nav | `nav/` | `config.yml` | `protocols/*.yml` |
| ace-taskflow | `taskflow/` | `config.yml` | `presets/*.yml` |
| ace-test-runner | `test/` | `runner.yml` | `suite.yml` |

## Configuration Loading

### Ruby API

```ruby
# Load namespace configuration
Ace::Core.get("git")           # Loads git/commit.yml
Ace::Core.get("llm")           # Loads llm/query.yml
Ace::Core.get("test", file: "runner")  # Loads test/runner.yml

# Access nested values
Ace::Core.get("git", "conventions", "format")  # "conventional"

# Load all configs in namespace
Ace::Core.get("test")  # Loads and merges test/*.yml
```

### Command Line

```bash
# Most commands automatically load their namespace config
ace-git-commit          # Uses git/commit.yml
ace-test               # Uses test/runner.yml
ace-context project    # Uses context/config.yml and presets/project.md
```

## Initial Setup

### Quick Setup

Copy all example configurations from gems:

```bash
bin/setup-ace-config
```

### Manual Setup

Copy example configs from specific gems:

```bash
# Copy from a specific gem
cp -r ace-core/ace.example/* .ace/
cp -r ace-git-commit/ace.example/* .ace/
# ... etc

# Or copy all at once
for gem in ace-*/ace.example; do
  cp -r "$gem"/* .ace/
done
```

### Minimal Setup

For a minimal working configuration:

```bash
# Core settings (required)
cp ace-core/ace.example/core/settings.yml .ace/core/

# Add configurations for gems you use
cp ace-git-commit/ace.example/git/commit.yml .ace/git/
cp ace-test-runner/ace.example/test/*.yml .ace/test/
```

## Customization

### Project-Specific Overrides

Edit any configuration file to override defaults. For example, to use a different LLM model:

```yaml
# .ace/llm/query.yml
llm:
  default_model: "gpt-4"  # Override default
  aliases:
    fast: "gpt-3.5-turbo"  # Custom alias
```

### User-Wide Defaults

Place configurations in `~/.ace/` for user-wide defaults:

```bash
# Set user defaults
mkdir -p ~/.ace/git
cp .ace/git/commit.yml ~/.ace/git/
# Edit ~/.ace/git/commit.yml with your preferences
```

### Environment Variables

Override any configuration with environment variables:

```bash
# Override LLM model
export ACE_LLM_DEFAULT_MODEL="claude-3"

# Override test runner format
export ACE_TEST_FORMAT="json"
```

## Testing Configuration

### Verify Loading

```bash
# Test namespace loading
ruby -r ace/core -e "p Ace::Core.get('git')"
ruby -r ace/core -e "p Ace::Core.get('test', file: 'runner')"

# Test cascade
mkdir -p ~/.ace/core
echo "test: home" > ~/.ace/core/settings.yml
ruby -r ace/core -e "p Ace::Core.get('core')['test']"  # Should show "home"
```

### Debug Loading

```bash
# Enable debug output
export ACE_DEBUG=true

# Run any ace command to see config loading
ace-git-commit --dry-run
```

## Troubleshooting

### Config Not Loading

1. Check file exists: `ls -la .ace/namespace/file.yml`
2. Verify YAML syntax: `ruby -r yaml -e "YAML.load_file('.ace/namespace/file.yml')"`
3. Check namespace spelling matches exactly
4. Enable debug mode: `export ACE_DEBUG=true`

### Cascade Not Working

1. Check search paths: `ruby -r ace/core -e "p Ace::Core::Organisms::ConfigResolver.new.search_paths"`
2. Verify file permissions: `ls -la ~/.ace .ace`
3. Test with explicit path: `ACE_CONFIG_PATH=/path/to/.ace ace-command`

### Wrong Values

1. Check for environment overrides: `env | grep ACE_`
2. Verify cascade order (project overrides user)
3. Look for typos in configuration keys

## Best Practices

1. **Keep configs in version control**: Track `.ace/` in git for team consistency
2. **Use comments**: Document custom settings in YAML files
3. **Start minimal**: Only configure what you need to change
4. **Test changes**: Verify config changes with dry-run options
5. **Namespace isolation**: Don't mix configs between namespaces

## Migration from Old Structure

If you have old configuration files:

```bash
# Old → New mappings
mv .ace/settings.yml .ace/core/settings.yml
mv .ace/taskflow.yml .ace/taskflow/config.yml
mv .ace/test.yml .ace/test/runner.yml
mv .ace/test-suite.yml .ace/test/suite.yml
mv .ace/git/config/git.yml .ace/git/commit.yml
mv .ace/protocols/* .ace/nav/protocols/
```

## Additional Resources

- Each gem's `ace.example/` directory contains fully documented example configs
- Run `ace-<gem> --help` for gem-specific configuration options
- See individual gem READMEs for detailed configuration documentation

---

*Configuration version: 0.9.0*
*Last updated: Task 008 completion*