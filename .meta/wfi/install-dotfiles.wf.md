# Install Dotfiles Workflow Instruction

**Goal:** Install and customize configuration files (.coding-agent/*.yml) for a new project context.

## Prerequisites

* Project root identified and accessible
* Access to template files in dev-handbook/.meta/tpl/dotfiles/
* Understanding of project-specific requirements

## Overview

This workflow installs the standard configuration files and then customizes them based on the specific project context and requirements.

## Process Steps

1. **Install Standard Dotfiles:**
   ```bash
   coding_agent_tools install-dotfiles
   ```

2. **Verify Installation:**
   ```bash
   ls -la .coding-agent/
   ```
   
   Expected files:
   - `lint.yml` - Linting configuration
   - `path.yml` - Path resolution and navigation patterns
   - `tree.yml` - Tree display and directory scanning settings

3. **Customize for Project Context:**

   **For path.yml customization:**
   - Update project name in the configuration
   - Adjust repository scanning order if needed
   - Modify path generation patterns for project-specific needs
   - Update security patterns based on project structure

   **For lint.yml customization:**
   - Configure linting rules specific to the project's language/framework
   - Adjust file patterns and exclusions
   - Set project-specific quality standards

   **For tree.yml customization:**
   - Configure directory display preferences
   - Set project-specific ignore patterns
   - Adjust scanning depth and performance settings

4. **Validate Configuration:**
   ```bash
   # Test path resolution
   nav-path --help
   
   # Test tree navigation
   nav-tree --help
   
   # Verify commands work with new configuration
   release-manager current
   nav-path task-new "test-configuration"
   ```

5. **Project-Specific Adjustments:**

   **Multi-repository projects:**
   - Update `repositories.scan_order` in path.yml
   - Configure repository-specific patterns
   - Adjust security allowed/forbidden patterns

   **Single repository projects:**
   - Simplify repository configuration
   - Focus path patterns on single-repo structure
   - Optimize performance settings

   **Language-specific projects:**
   - Ruby: Configure StandardRB integration in lint.yml
   - JavaScript: Configure ESLint/Prettier integration
   - Python: Configure flake8/black integration
   - Mixed: Configure multi-language linting

## Common Customizations

### Project Name and Structure
```yaml
# In path.yml
project:
  name: "your-project-name"
  root: ".."

repositories:
  scan_order:
    - name: "your-project-name"
      path: "."
      priority: 1
```

### Development Workflow Integration
```yaml
# In path.yml - customize task/docs patterns
path_patterns:
  task_new:
    template: "{release_path}/tasks/{id}-{slug}.md"
    variables:
      release_path: "release-manager current --format json | jq -r '.data.path'"
```

### Security Configuration
```yaml
# In path.yml - adjust for project structure
security:
  forbidden_patterns:
    - "**/.git/**"
    - "**/node_modules/**"    # Add for JS projects
    - "**/venv/**"            # Add for Python projects
    - "**/target/**"          # Add for Rust/Java projects
```

## Validation Checklist

- [ ] All three configuration files installed (.coding-agent/*.yml)
- [ ] Project name updated in configurations
- [ ] Repository structure properly configured
- [ ] Security patterns appropriate for project
- [ ] Path generation works correctly
- [ ] Navigation commands function properly
- [ ] Linting integration works for project languages
- [ ] Tree display shows relevant project structure

## Troubleshooting

**Installation Issues:**
- If files already exist, use `--force` flag
- Check template directory exists: `dev-handbook/.meta/tpl/dotfiles/`
- Verify project root detection works correctly

**Configuration Issues:**
- Test individual commands: `nav-path`, `nav-tree`, `release-manager`
- Check YAML syntax with `yaml-lint` or similar
- Review path resolution with `--debug` flags

**Performance Issues:**
- Adjust scanning limits in tree.yml
- Optimize forbidden patterns for faster exclusion
- Configure appropriate cache settings

## Integration Notes

This workflow is typically run as part of:
- New project initialization
- Project structure updates
- Development environment setup
- Team onboarding processes

## Expected Outcomes

- Functional .coding-agent/ configuration directory
- Project-optimized navigation and tooling
- Consistent development workflow setup
- Integration with project-specific tools and patterns