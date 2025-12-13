# Task 027: Release Create Command Usage

## Q: How do I create a new release?

**A:** Use the `release create` subcommand with a release name:

```bash
ace-taskflow release create "authentication-system"
```

Expected behavior:
- Auto-increments version from the latest release
- Creates directory structure in backlog (default)
- Generates release overview file
- Creates: `backlog/v.0.10.0-authentication-system/`

## Q: How do I specify a custom version number?

**A:** Use the `--release` flag with a specific version:

```bash
ace-taskflow release create "payment-integration" --release v.1.0.0
```

This creates:
- `backlog/v.1.0.0-payment-integration/`
- Uses exact version specified
- Validates version format (v.MAJOR.MINOR.PATCH)

## Q: How do I create a release as immediately active?

**A:** Use the `--current` flag to create as active release:

```bash
ace-taskflow release create "urgent-hotfix" --current
```

Results in:
- Creates in `.ace-taskflow/current/v.0.9.1-urgent-hotfix/`
- Sets as primary active release
- Available immediately for task creation

## Q: What directory structure is created?

**A:** Each release gets a standard structure:

```bash
ace-taskflow release create "new-feature"
```

Creates:
```
backlog/v.0.10.0-new-feature/
├── tasks/          # Task files go here
├── ideas/          # Idea files go here
├── docs/           # Documentation
├── reflections/    # Development reflections
└── v.0.10.0-new-feature.md  # Release overview
```

## Q: What goes in the release overview file?

**A:** The generated overview file contains:

```markdown
# Release v.0.10.0: new-feature

## Overview
[Release description]

## Goals
- [ ] Primary goal
- [ ] Secondary goal

## Status
- Created: 2024-09-24
- Target: TBD
- State: Planning

## Statistics
- Tasks: 0 total
- Ideas: 0 captured
- Progress: 0%
```

## Q: How does version auto-increment work?

**A:** The system finds the highest version and increments:

```bash
# Current releases: v.0.9.0, v.0.9.1, v.0.10.0
ace-taskflow release create "next-feature"
# Creates: v.0.10.1 (increments PATCH)

ace-taskflow release create "major-update" --major
# Creates: v.1.0.0 (increments MAJOR, resets others)

ace-taskflow release create "minor-update" --minor
# Creates: v.0.11.0 (increments MINOR, resets PATCH)
```

## Q: Can I create multiple releases at once?

**A:** Yes, for planning purposes:

```bash
# Create release series
ace-taskflow release create "phase-1" --release v.1.0.0
ace-taskflow release create "phase-2" --release v.1.1.0
ace-taskflow release create "phase-3" --release v.1.2.0
```

## Q: How do I create a release in a custom location?

**A:** Specify the path:

```bash
# Create in specific directory
ace-taskflow release create "experiment" --path .ace-taskflow/experimental/

# Create in different project area
ace-taskflow release create "module-a" --path modules/a/releases/
```

## Q: What validation is performed?

**A:** The command validates:

1. **Version format**: Must be v.MAJOR.MINOR.PATCH
2. **Duplicate check**: Prevents same version number
3. **Name format**: Converts to slug (lowercase, hyphens)

```bash
# Invalid version
ace-taskflow release create "test" --release 1.0.0
# Error: Invalid version format. Use v.MAJOR.MINOR.PATCH

# Duplicate version
ace-taskflow release create "test" --release v.0.9.0
# Error: Release v.0.9.0 already exists

# Name normalization
ace-taskflow release create "Test Feature!"
# Creates: v.0.10.0-test-feature
```

## Q: How do I add metadata to a release on creation?

**A:** Use additional flags:

```bash
ace-taskflow release create "q4-features" \
  --release v.2.0.0 \
  --description "Q4 2024 feature set" \
  --target-date "2024-12-31" \
  --owner "@teamlead"
```

## Q: Can I create a release from a template?

**A:** Use the `--template` flag:

```bash
# Use predefined template
ace-taskflow release create "standard-feature" --template feature

# Use custom template
ace-taskflow release create "security-update" --template .ace/templates/security-release.md
```

## Common Usage Patterns

### Sprint planning
```bash
# Create next sprint
ace-taskflow release create "sprint-42" --current
```

### Feature branches
```bash
# Create feature release in backlog
ace-taskflow release create "user-dashboard"
```

### Hotfix workflow
```bash
# Create hotfix as active release
ace-taskflow release create "critical-bugfix" --release v.0.9.1 --current
```

### Major version planning
```bash
# Plan major version
ace-taskflow release create "version-2" --release v.2.0.0 --backlog
```

## Integration Examples

### Create release and add tasks
```bash
# Create release
ace-taskflow release create "api-redesign"

# Add tasks to it
ace-taskflow task create "Design API schema" --release v.0.10.0
ace-taskflow task create "Implement endpoints" --release v.0.10.0
```

### Create release with ideas
```bash
# Create release
ace-taskflow release create "improvements"

# Capture ideas
ace-taskflow idea create "Performance optimization" --release v.0.10.0
ace-taskflow idea create "UI enhancements" --release v.0.10.0
```

## Troubleshooting

### Release not created

Check permissions and path:
```bash
# Verify write access
ls -la .ace-taskflow/backlog/

# Check if path exists
ace-taskflow config | grep root
```

### Version conflicts

List existing releases:
```bash
# See all releases
ace-taskflow releases --all

# Check specific version
ace-taskflow releases | grep v.0.10.0
```

### Auto-increment not working

Force version calculation:
```bash
# Debug version detection
ace-taskflow release create "test" --dry-run --debug

# Override with explicit version
ace-taskflow release create "test" --release v.0.10.5
```