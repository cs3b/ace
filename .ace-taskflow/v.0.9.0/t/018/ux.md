# ace-nav Use Cases

Based on the task definition, here are all the use cases for ace-nav:

## 1. Resource Path Resolution

```bash
# Cascade search (searches all sources in order)
ace-nav wfi://setup                   # Finds first 'setup' workflow
ace-nav tmpl://minitest-setup         # Finds first matching template
ace-nav guide://configuration         # Finds first matching guide

# Source-specific with @ prefix
ace-nav wfi://@ace-git/setup          # Only from ace-git gem
ace-nav tmpl://@ace-test/minitest     # Only from ace-test gem
ace-nav wfi://@project/setup          # Only from ./.ace/handbook
ace-nav wfi://@user/setup             # Only from ~/.ace/handbook

# Path navigation (no @ means it's a path)
ace-nav guide://tutorials/advanced    # Cascade search for tutorials/advanced
ace-nav sample://structures/release   # Cascade search for structures/release

# Task navigation (special protocol)
ace-nav task://018
ace-nav task://v.0.9.0+task.018
ace-nav 'task://*ace-nav*'           # Glob pattern for tasks
```

## 2. Direct Content Retrieval

```bash
# Cascade search for content
ace-nav wfi://setup --content         # First matching setup workflow
ace-nav tmpl://task-draft --content   # First matching task-draft template

# Source-specific content retrieval
ace-nav wfi://@ace-git/setup --content       # From ace-git gem only
ace-nav tmpl://@ace-taskflow/task-draft --content | sed 's/{id}/v.0.9.0+task.019/'

# Load guide content for AI agents
ace-nav guide://handbook-structure --content  # Cascade search
ace-nav guide://@ace-nav/handbook-structure --content  # From ace-nav gem

# Get task content directly
ace-nav task://018 --content
```

## 3. Resource Creation from Templates

```bash
# Create from first matching template (cascade search)
ace-nav wfi://load-context --create
# Creates: $PROJECT_ROOT/.ace/handbook/workflow-instructions/load-context.wfi.md

# Create from specific source
ace-nav wfi://@ace-context/load-context --create
# Uses template from ace-context gem specifically

# Create in current working directory's .ace
ace-nav wfi://load-context --create .ace
# Creates: ./.ace/handbook/workflow-instructions/load-context.wfi.md

# Create template in project
ace-nav tmpl://minitest-test --create         # Uses first match
ace-nav tmpl://@ace-test/minitest --create    # Uses ace-test gem version
# Creates: $PROJECT_ROOT/.ace/handbook/templates/minitest-test.tmpl.md

# Initialize structure from sample
ace-nav sample://@ace-release/release-structure --create ./my-release
# Creates: ./my-release/ with structure from ace-release gem
```

## 4. Directory and Resource Listing

```bash
# List all workflows from all sources
ace-nav 'wfi://*' --list

# List workflows from specific source only
ace-nav 'wfi://@ace-git/*' --list     # Only ace-git workflows
ace-nav 'wfi://@project/*' --list     # Only project overrides

# List test-related workflows (cascade search)
ace-nav 'wfi://*test*' --list

# List templates from specific gem
ace-nav 'tmpl://@ace-test/*' --list   # Only from ace-test gem
ace-nav 'tmpl://forms/*' --list       # All forms from any source

# Tree view of workflows
ace-nav 'wfi://*' --tree              # All sources
ace-nav 'wfi://@user/*' --tree        # Only user overrides

# List matching tasks
ace-nav 'task://*nav*' --list

# Note: For file system navigation, use shell tools:
ls $(ace-nav wfi://@ace-git/setup)    # List directory of resolved path
```

## 5. Resource Discovery with Globs

```bash
# List all resources across all sources
ace-nav 'wfi://*' --list              # All workflows
ace-nav 'tmpl://*' --list             # All templates
ace-nav 'guide://*' --list            # All guides

# Source-specific discovery
ace-nav 'wfi://@ace-git/*' --list     # All workflows from ace-git gem
ace-nav 'tmpl://@ace-test/*' --list   # All templates from ace-test gem
ace-nav 'wfi://@project/*' --list     # All project overrides
ace-nav 'tmpl://@user/*' --list       # All user template overrides

# Complex patterns with paths
ace-nav 'wfi://setup/*' --list        # All setup-related workflows
ace-nav 'tmpl://forms/*input*' --list # Input-related form templates

# Complex patterns with sources
ace-nav 'wfi://@ace-*/*test*' --list  # Test workflows from all ace- gems
ace-nav 'task://v.0.9.0+task.*' --list # All tasks in current release
```

## 6. Verbose Resolution Debugging

```bash
# Show cascade search resolution
ace-nav wfi://setup --verbose
# Output:
# Resolving: wfi://setup (cascade search)
# Checking: @project (./.ace/handbook/workflows/setup.wfi.md) [not found]
# Checking: @user (~/.ace/handbook/workflows/setup.wfi.md) [not found]
# Checking: @ace-git (/path/to/gems/ace-git/handbook/workflows/setup.wfi.md) [found]
# Resolved: /path/to/gems/ace-git/handbook/workflows/setup.wfi.md

# Show source-specific resolution
ace-nav wfi://@ace-git/setup --verbose
# Output:
# Resolving: wfi://@ace-git/setup (source-specific)
# Source: @ace-git gem
# Looking in: /path/to/gems/ace-git/handbook/workflows/setup.wfi.md [found]
# Resolved: /path/to/gems/ace-git/handbook/workflows/setup.wfi.md

# Debug glob pattern matching
ace-nav 'wfi://*test*' --list --verbose
# Shows all sources searched, patterns matched, priorities applied
```

## 7. Override System Usage

### Project Override (@project)

```bash
# Create project-specific workflow override
mkdir -p .ace/handbook/workflows
echo "# Custom setup" > .ace/handbook/workflows/setup.wfi.md

# Cascade search finds project override first
ace-nav wfi://setup  # Returns: ./.ace/handbook/workflows/setup.wfi.md

# Explicitly use project version
ace-nav wfi://@project/setup  # Returns: ./.ace/handbook/workflows/setup.wfi.md

# Bypass override to get gem version
ace-nav wfi://@ace-git/setup  # Returns: /path/to/gems/ace-git/handbook/workflows/setup.wfi.md
```

### User Override (@user)

```bash
# Create user-level template customization
mkdir -p ~/.ace/handbook/templates
cp template.md ~/.ace/handbook/templates/minitest.tmpl.md

# Cascade search finds user override (if no project override)
ace-nav tmpl://minitest  # Returns: ~/.ace/handbook/templates/minitest.tmpl.md

# Explicitly use user version
ace-nav tmpl://@user/minitest  # Returns: ~/.ace/handbook/templates/minitest.tmpl.md
```

## 8. Fuzzy Matching & Autocorrection

```bash
# Partial path matching (cascade search)
ace-nav wfi://set
# Output: Autocorrected: 'set' → 'setup'
# Found in: @ace-git
# /path/to/ace-git/handbook/workflows/setup.wfi.md

# Partial matching with source
ace-nav wfi://@ace-git/set
# Output: Autocorrected: 'set' → 'setup' in @ace-git
# /path/to/ace-git/handbook/workflows/setup.wfi.md

# Multiple matches with prioritization
ace-nav tmpl://test
# Output: Multiple matches found:
#   Best match: tmpl://minitest-setup (@project)
#   Also found: tmpl://minitest-helper (@ace-test)
#              tmpl://rspec-setup (@ace-test-support)

# Fuzzy task matching
ace-nav task://18  # Autocorrects to task://018
ace-nav 'task://nav'  # Suggests: task://018-create-ace-nav-gem
```

## 9. AI Agent Integration

```bash
# Simple commands for agents (cascade search preferred)
ace-nav wfi://load-context --content   # Gets best match
ace-nav tmpl://task-draft --content    # Gets best match

# When agents need specific sources
ace-nav wfi://@ace-context/load-context --content  # Specific gem
ace-nav tmpl://@project/task-draft --content       # Project override

# Agents discover available resources
ace-nav 'wfi://*' --list               # All workflows
ace-nav 'wfi://@ace-handbook/*' --list # From specific gem

# Get current task details
ace-nav task://018 --content
```

## 10. Task Navigation

```bash
# Find task by number
ace-nav task://018
ace-nav task://v.0.9.0+task.018

# Find tasks by pattern
ace-nav 'task://*ace-nav*' --list
ace-nav 'task://*pending*' --list

# Get task content
ace-nav task://018 --content

# Navigate to task directory
cd $(dirname $(ace-nav task://018))
```

## 11. Configuration Structure

```yaml
# .ace/nav/settings.yml - Main configuration
handbooks:
  sources:
    - gem: "ace-*"              # All ace-* gems (@ace-git, @ace-test, etc.)
    - gem: "company-handbook"   # Specific non-ace gem (@company-handbook)
    - path: "/opt/handbooks"    # Absolute path with alias (@handbooks)
      alias: "handbooks"
    - path: "~/my-handbooks"    # User directory with alias (@my)
      alias: "my"

  # Special source aliases (built-in)
  # @project → ./.ace/handbook
  # @user → ~/.ace/handbook
  # @local → alias for @project
  # @global → alias for @user

# .ace/nav/wfi.yml - Workflow-specific config
workflows:
  extensions: [.wfi.md, .workflow.md]
  default_dir: workflow-instructions

# .ace/nav/tmpl.yml - Template-specific config
templates:
  extensions: [.tmpl.md, .template.md]
  default_dir: templates

# .ace/nav/task.yml - Task-specific config
tasks:
  search_paths:
    - dev-taskflow/current/*/tasks
    - dev-taskflow/backlog
```

## 12. Wildcard Gem Discovery

```bash
# Automatically discovers all ace-* gems
# No configuration needed - just install gems:
gem install ace-git ace-test ace-release

# All handbooks immediately available
ace-nav 'wfi://*' --list  # Shows workflows from all installed ace-* gems
ace-nav 'tmpl://*' --list # Shows templates from all gems

# Discover what's available from new gem
ace-nav 'wfi://ace-git/*' --list
ace-nav 'tmpl://ace-git/*' --list
```

## 13. Glob Pattern Examples

```bash
# Find all test-related resources (cascade search)
ace-nav 'wfi://*test*' --list          # All test workflows
ace-nav 'tmpl://*test*' --list         # All test templates

# Source-specific glob patterns
ace-nav 'wfi://@ace-*/*test*' --list   # Test workflows from ace- gems
ace-nav 'tmpl://@project/*form*' --list # Form templates from project
ace-nav 'wfi://@user/*setup*' --list   # Setup workflows from user

# Path-based patterns
ace-nav 'wfi://admin/*' --list         # All workflows in admin/ directory
ace-nav 'tmpl://forms/input*' --list   # Input forms from any source

# Complex patterns
ace-nav 'wfi://@ace-*/setup*' --list   # Setup workflows from ace- gems only
ace-nav 'task://v.0.9.0+task.0[0-9]*' --list  # First 10 tasks of release
```

## 14. Shell Integration

```bash
# Use with other Unix tools
cat $(ace-nav wfi://load-context)      # Read first matching file
vim $(ace-nav tmpl://@project/task)    # Edit project template
ls -la $(ace-nav wfi://@ace-git/)      # List gem directory

# In scripts - prefer cascade search for flexibility
WF_PATH=$(ace-nav wfi://setup)
if [ -f "$WF_PATH" ]; then
    echo "Workflow found at: $WF_PATH"
fi

# Source-specific when needed
GEM_TEMPLATE=$(ace-nav tmpl://@ace-test/minitest)
PROJECT_TEMPLATE=$(ace-nav tmpl://@project/minitest)

# Fish shell function
function edit-workflow
    vim (ace-nav wfi://$argv[1])
end

function edit-gem-workflow
    vim (ace-nav wfi://@$argv[1]/$argv[2])
end
```

## 15. Error Handling & Debugging

```bash
# Unknown URI scheme
ace-nav xyz://something
# Error: Unknown scheme 'xyz://' - valid schemes: wfi, tmpl, guide, sample, task

# Unknown source
ace-nav wfi://@unknown/setup
# Error: Unknown source '@unknown'. Available: @project, @user, @ace-git, @ace-test...

# Resource not found with suggestions (cascade)
ace-nav wfi://missing-workflow
# Error: Resource 'wfi://missing-workflow' not found.
# Similar resources found:
#   wfi://missing-handler (@ace-error)
#   wfi://workflow-guide (@ace-handbook)

# Resource not found in specific source
ace-nav wfi://@ace-git/missing
# Error: Resource 'missing' not found in @ace-git
# Try: ace-nav wfi://missing (cascade search)

# No handbooks found
ace-nav 'wfi://*' --list
# Warning: No handbooks found. Install ace-* gems or configure paths in .ace/nav/settings.yml

# Verbose error debugging
ace-nav wfi://missing --verbose
# Cascade search for: wfi://missing
# Checking @project: ./.ace/handbook/workflows/missing.wfi.md [not found]
# Checking @user: ~/.ace/handbook/workflows/missing.wfi.md [not found]
# Checking @ace-git: /path/to/ace-git/handbook/workflows/missing.wfi.md [not found]
# Result: Resource not found
```

## Summary

These use cases cover:
- **Simplified CLI**: Single command with options, no subcommands
- **Source Control**: @ prefix for source-specific access vs cascade search
- **Path Resolution**: Smart resolution with clear source distinction
- **Content Delivery**: Direct content access via --content
- **Resource Discovery**: Glob patterns for powerful queries
- **Task Navigation**: Dedicated task:// protocol for task management
- **Smart Creation**: --create with intelligent path placement
- **Override System**: Project (@project) and user (@user) customizations
- **Debugging**: --verbose mode shows complete resolution logic
- **Shell Integration**: Composable with Unix tools
- **AI-Friendly**: Simple cascade search by default, specific when needed

The ace-nav tool provides a unified, Unix-like interface with:
- **Protocols**: wfi://, tmpl://, guide://, sample://, task://
- **Sources**: @project, @user, @ace-*, @custom-aliases
- **Default**: Cascade search when no @ prefix is used
- **Power**: Glob patterns and fuzzy matching throughout

The @ prefix clearly distinguishes between "search only here" (@ace-git/setup) and "search everywhere" (setup), making the tool intuitive for both humans and AI agents.