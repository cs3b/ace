# Shell Binstub Implementation Patterns

## Overview

This guide documents the shell script patterns used in the Coding Agent Tools project for creating binstubs that delegate to executables in the `dev-tools/exe/` directory. These patterns ensure proper directory context management and argument passing.

## Core Pattern: Directory Context Management

All shell binstubs in this project follow a consistent pattern for directory context management:

```shell
#!/bin/sh
# [Description of the script's purpose]

set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"

# Trap to ensure we always return to original directory
trap 'cd "$ORIGINAL_DIR"' EXIT

# Change to dev-tools directory where the gem files are located
cd "$(dirname "$0")/../dev-tools"

echo "INFO: [Action description] from dev-tools directory: $(pwd)"

# Execute the main operation
[main operation]
```

## Template: Basic Shell Binstub

Use this template for creating new shell binstubs:

```shell
#!/bin/sh
# [Brief description of what this script does]

set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"

# Trap to ensure we always return to original directory
trap 'cd "$ORIGINAL_DIR"' EXIT

# Change to dev-tools directory where the gem files are located
cd "$(dirname "$0")/../dev-tools"

echo "INFO: [Action description] from dev-tools directory: $(pwd)"

# Execute the main command with all arguments passed through
[command] "$@"
```

## Argument Passing Patterns

### Pass All Arguments Through

Most binstubs should pass all arguments to the underlying command:

```shell
bundle exec rspec "$@"
```

### Process Specific Arguments

For scripts that need to process specific arguments before delegation:

```shell
# Parse arguments
while [ $# -gt 0 ]; do
    case $1 in
        --special-flag)
            SPECIAL_FLAG=1
            shift
            ;;
        *)
            # Pass other arguments through
            break
            ;;
    esac
done

# Execute with remaining arguments
bundle exec [command] "$@"
```

## Directory Context Patterns

### When to Use Directory Context

Use directory context management when:
- The underlying command needs to run from a specific directory (e.g., `dev-tools/`)
- Configuration files are located in a specific directory
- Bundle dependencies need to be resolved from a specific location

### Pattern Components

1. **Save Original Directory**: Always save the user's current directory
2. **Trap Setup**: Ensure cleanup happens even if the script exits unexpectedly
3. **Directory Change**: Change to the required directory using relative paths
4. **Informative Output**: Log the directory change for debugging

## Real-World Examples

### Example 1: Test Runner (bin/test)

```shell
#!/bin/sh
# Test script for Coding Agent Tools gem
# Runs RSpec test suite with coverage reporting

set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"

# Trap to ensure we always return to original directory
trap 'cd "$ORIGINAL_DIR"' EXIT

# Change to dev-tools directory where the gem files are located
cd "$(dirname "$0")/../dev-tools"

echo "INFO: Running RSpec test suite with coverage from dev-tools directory: $(pwd)"

# Run RSpec with coverage reporting
bundle exec rspec "$@"

# Post-execution checks
if [ -f "coverage/index.html" ]; then
  echo "SUCCESS: Coverage report generated at coverage/index.html"
fi
```

### Example 2: Setup Script (bin/setup)

```shell
#!/bin/sh
# Setup script for Coding Agent Tools gem
# Installs dependencies and sets up development environment

set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"

# Trap to ensure we always return to original directory
trap 'cd "$ORIGINAL_DIR"' EXIT

# Change to dev-tools directory where the gem files are located
cd "$(dirname "$0")/../dev-tools"

echo "INFO: Setting up development environment from dev-tools directory: $(pwd)"

# Install gem dependencies
echo "INFO: Installing bundle dependencies..."
bundle install

echo "SUCCESS: Development environment setup completed"
```

## Error Handling Patterns

### Basic Error Handling

```shell
set -e  # Exit on any error

# Your commands here
command_that_might_fail "$@"

# Check specific conditions
if [ $? -ne 0 ]; then
    echo "ERROR: Command failed"
    exit 1
fi
```

### Advanced Error Handling with Cleanup

```shell
set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"

# Trap for cleanup
cleanup() {
    cd "$ORIGINAL_DIR"
    # Additional cleanup if needed
}
trap cleanup EXIT

# Your operations here
```

## Delegation to dev-tools/exe/

### Direct Delegation

For simple delegation to executables in `dev-tools/exe/`:

```shell
#!/bin/sh
# Delegate to dev-tools/exe/[executable]

set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"
trap 'cd "$ORIGINAL_DIR"' EXIT

# Change to dev-tools directory
cd "$(dirname "$0")/../dev-tools"

# Execute the corresponding executable
./exe/[executable-name] "$@"
```

### Bundle Exec Delegation

For Ruby executables that need bundle context:

```shell
#!/bin/sh
# Delegate to bundled executable

set -e

# Save original directory
ORIGINAL_DIR="$(pwd)"
trap 'cd "$ORIGINAL_DIR"' EXIT

# Change to dev-tools directory
cd "$(dirname "$0")/../dev-tools"

# Execute through bundle
bundle exec ./exe/[executable-name] "$@"
```

## When NOT to Use Directory Context

Direct execution (without directory context) is appropriate when:
- The command is system-wide and doesn't depend on project-specific configuration
- The executable handles its own directory context
- No bundler dependencies are involved

Example:
```shell
#!/bin/sh
# Simple delegation without directory context

exec [system-command] "$@"
```

## Troubleshooting

### Common Issues

#### 1. Bundle Install Failures

**Problem**: `bundle install` fails when running from wrong directory

**Solution**: Ensure the script changes to `dev-tools/` directory before running bundle commands:

```shell
cd "$(dirname "$0")/../dev-tools"
bundle install
```

#### 2. Missing Configuration Files

**Problem**: Scripts fail because they can't find `.standard.yml`, `Gemfile`, or other config files

**Solution**: Check that directory context is properly set:

```shell
# Debug: Show current directory
echo "DEBUG: Current directory: $(pwd)"
echo "DEBUG: Files in directory: $(ls -la)"
```

#### 3. Arguments Not Passing Through

**Problem**: Command-line arguments are not reaching the target executable

**Solution**: Ensure proper argument passing:

```shell
# Wrong - loses arguments
bundle exec rspec

# Right - passes all arguments
bundle exec rspec "$@"
```

#### 4. Permission Errors

**Problem**: Scripts fail with permission denied errors

**Solution**: Ensure the script has execute permissions:

```shell
chmod +x bin/[script-name]
```

#### 5. Trap Not Working

**Problem**: Directory doesn't restore on script exit

**Solution**: Check trap syntax and ensure it's set before directory changes:

```shell
# Set trap before changing directory
trap 'cd "$ORIGINAL_DIR"' EXIT
cd "$(dirname "$0")/../dev-tools"
```

### Debugging Tips

1. **Add Debug Output**: Temporarily add debug statements to understand execution flow:

```shell
echo "DEBUG: Starting in directory: $(pwd)"
echo "DEBUG: Target directory: $(dirname "$0")/../dev-tools"
cd "$(dirname "$0")/../dev-tools"
echo "DEBUG: Now in directory: $(pwd)"
```

2. **Check Path Resolution**: Verify that relative paths resolve correctly:

```shell
echo "DEBUG: Script location: $(dirname "$0")"
echo "DEBUG: Resolved path: $(cd "$(dirname "$0")/../dev-tools" && pwd)"
```

3. **Test Argument Passing**: Verify arguments are passed correctly:

```shell
echo "DEBUG: Arguments received: $@"
echo "DEBUG: Argument count: $#"
```

## Best Practices

### 1. Consistent Shebang

Always use `#!/bin/sh` for maximum compatibility:

```shell
#!/bin/sh
# Not #!/bin/bash unless bash-specific features are needed
```

### 2. Error Handling

Always include `set -e` to fail fast on errors:

```shell
#!/bin/sh
set -e
```

### 3. Documentation

Include clear comments explaining the script's purpose:

```shell
#!/bin/sh
# Brief description of what this script does
# Additional context if needed
```

### 4. Informative Output

Provide helpful status messages:

```shell
echo "INFO: [Action description] from dev-tools directory: $(pwd)"
```

### 5. Cleanup Traps

Always use traps to ensure cleanup happens:

```shell
trap 'cd "$ORIGINAL_DIR"' EXIT
```

## Project-Specific Patterns

### Multi-Repository Scripts

Some scripts operate across multiple repositories (like `bin/gc`). These may use different patterns but should still follow the core principles of directory management and argument passing.

### Bundle-Dependent Scripts

Scripts that rely on Ruby gems should always change to the `dev-tools/` directory where the `Gemfile` is located:

```shell
cd "$(dirname "$0")/../dev-tools"
bundle exec [command]
```

### Test and Development Scripts

Development scripts should provide helpful output about their execution context:

```shell
echo "INFO: Running [action] from dev-tools directory: $(pwd)"
echo "INFO: Configuration loaded from [config-file]"
```

---

This guide provides the foundation for creating consistent, reliable shell binstubs that properly delegate to executables while maintaining correct directory context and argument passing.