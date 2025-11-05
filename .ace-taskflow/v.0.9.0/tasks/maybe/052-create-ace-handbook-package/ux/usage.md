# ace-handbook Usage Guide

## Overview

**ace-handbook** is a pure workflow package gem that provides 8 comprehensive handbook management workflows accessible via the `wfi://` protocol. Unlike other ACE gems, ace-handbook contains no executable code or CLI commands - it's a collection of workflow instructions that guide AI agents and developers through maintaining development guides, workflow files, and agent definitions.

## Available Workflows

### Guide Management
- **`wfi://manage-guides`** - Create, update, and maintain development guides
- **`wfi://review-guides`** - Review guides for quality and consistency

### Workflow Management
- **`wfi://manage-workflow-instructions`** - Create, update, and validate workflow files
- **`wfi://review-workflows`** - Review workflow instructions for quality

### Agent Management
- **`wfi://manage-agents`** - Create, update, and validate agent definitions

### Documentation Synchronization
- **`wfi://update-handbook-docs`** - Maintain handbook README and structure documentation
- **`wfi://update-tools-docs`** - Update tool documentation from implementation
- **`wfi://update-integration-claude`** - Synchronize Claude Code integration files

## Key Benefits

- **Zero Configuration**: Workflows auto-discovered by ace-nav when gem is installed
- **Protocol-Based Access**: Use `wfi://` protocol for consistent, portable workflow references
- **Self-Contained**: All workflows include embedded templates and complete instructions
- **Installable**: Distribute as a gem - `gem install ace-handbook` makes workflows available system-wide
- **Version Controlled**: Workflows versioned with gem releases, ensuring consistency

## Installation

### In a Project

Add to your Gemfile:

```ruby
gem 'ace-handbook'
```

Then run:

```bash
bundle install
```

### System-Wide

```bash
gem install ace-handbook
```

## Usage Scenarios

### Scenario 1: Creating a New Development Guide

**Goal**: Create a new guide explaining testing patterns for the project

**Commands** (executed via Claude Code or command line):

```bash
# Load the manage-guides workflow
ace-nav wfi://manage-guides
```

**Expected Output**: The workflow instructions appear with:
- Step-by-step guide creation process
- Template for guide structure
- Validation criteria
- Integration instructions

**AI Agent Workflow**:
1. AI reads workflow instructions from ace-nav output
2. Follows planning steps to determine guide scope
3. Executes implementation steps to create guide file
4. Validates guide structure against embedded template
5. Creates symlinks and updates documentation

### Scenario 2: Reviewing All Workflows for Quality

**Goal**: Audit all workflow instructions to ensure they follow current standards

**Commands**:

```bash
# Load the review-workflows workflow
ace-nav wfi://review-workflows
```

**Expected Output**: Detailed review process including:
- Quality criteria checklist
- ADR compliance validation (template embedding, self-containment)
- Consistency checks across workflows
- Improvement recommendations

**Process**:
1. Workflow lists all .wf.md files to review
2. Provides systematic review criteria
3. Guides through validation of each workflow
4. Documents findings and recommendations

### Scenario 3: Adding a New Agent Definition

**Goal**: Create a new agent for task-finding functionality

**Commands**:

```bash
# Load the manage-agents workflow
ace-nav wfi://manage-agents
```

**Expected Output**: Agent creation workflow with:
- Agent design principles (single-purpose, composable)
- Template for .ag.md file structure
- Symlink setup instructions
- Integration with .claude/agents/

**Implementation**:
1. Define agent's single purpose
2. Create agent file with standardized metadata
3. Add response format specification
4. Create symlink in .claude/agents/
5. Update CLAUDE.md if needed

### Scenario 4: Synchronizing Tool Documentation

**Goal**: Update ace-search documentation after adding new features

**Commands**:

```bash
# Load the update-tools-docs workflow
ace-nav wfi://update-tools-docs
```

**Expected Output**: Documentation sync process with:
- Steps to read current implementation
- Template for usage documentation
- Integration with ace-docs for tracking
- Validation commands

**Workflow**:
1. Read current tool implementation
2. Extract command-line interface details
3. Generate usage examples
4. Update docs/ directory
5. Validate with ace-docs

### Scenario 5: Migrating Handbook Content to New Gem

**Goal**: Use ace-handbook workflows to manage handbook-related content in a new ace-* gem

**Commands**:

```bash
# List all available handbook workflows
ace-nav 'wfi://*' --list | grep "@ace-handbook"

# Load specific workflow for the task
ace-nav wfi://manage-guides
```

**Expected Output**:
```
wfi://manage-guides → /path/to/gems/ace-handbook/handbook/workflow-instructions/manage-guides.wf.md (@ace-handbook)
wfi://review-guides → /path/to/gems/ace-handbook/handbook/workflow-instructions/review-guides.wf.md (@ace-handbook)
wfi://manage-workflow-instructions → /path/to/gems/ace-handbook/handbook/workflow-instructions/manage-workflow-instructions.wf.md (@ace-handbook)
...
```

**Process**:
1. Workflows discovered automatically from installed gem
2. No local configuration needed
3. Workflows accessible from any project
4. Updates via gem version upgrades

### Scenario 6: Verifying Workflow Discovery After Installation

**Goal**: Ensure ace-handbook gem is properly installed and workflows are discoverable

**Commands**:

```bash
# Check that ace-handbook is registered as a source
ace-nav --sources

# Verify all 8 workflows are discoverable
ace-nav 'wfi://*' --list | grep -c "@ace-handbook"

# Test loading a specific workflow
ace-nav wfi://manage-guides
```

**Expected Output**:

```bash
# From ace-nav --sources:
Available sources:
  ...
  @ace-handbook (gem): /path/to/gems/ace-handbook-0.1.0/handbook/workflow-instructions
  ...

# From workflow count (should be 8):
8

# From specific workflow test:
[Full workflow content displays...]
```

**Verification Checklist**:
- [ ] ace-handbook appears in `--sources` output
- [ ] All 8 workflows discoverable with pattern search
- [ ] Individual workflows load without errors
- [ ] Workflows contain complete instructions and templates

## Command Reference

### Accessing Workflows

All workflows accessed via ace-nav with wfi:// protocol:

```bash
# General syntax
ace-nav wfi://workflow-name

# List all workflows from all sources
ace-nav 'wfi://*' --list

# List only ace-handbook workflows
ace-nav 'wfi://*' --list | grep "@ace-handbook"

# Check workflow source locations
ace-nav --sources
```

### Workflow Discovery

**Internal**: ace-nav automatically discovers workflows from:
1. Installed gems with `handbook/workflow-instructions/` directory
2. Project `.ace/handbook/workflow-instructions/` directory
3. User `~/.ace/handbook/workflow-instructions/` directory
4. Custom configured sources

**Priority**: Lower priority number = higher precedence
- Project (10) > User (20) > Gems (100+) > Custom (200)

### Using Workflows in Claude Code

Workflows can be invoked via slash commands:

```
/ace:load-context wfi://manage-guides
```

Or directly in conversation:
```
Load and follow: `ace-nav wfi://manage-guides`
```

## Tips and Best Practices

### For AI Agents

1. **Always Load Full Workflow**: Don't guess at workflow steps - load complete workflow with `ace-nav wfi://`
2. **Follow Planning Steps First**: Workflows separate planning (*) from execution (-) steps
3. **Use Embedded Templates**: All templates are embedded in workflows per ADR-002
4. **Verify Before Executing**: Review workflow requirements and prerequisites
5. **Test After Completion**: Use embedded TEST blocks to validate results

### For Developers

1. **Install Locally First**: Use Gemfile path for development, gem install for production
2. **Keep Workflows Updated**: Update gem version to get latest workflow improvements
3. **Validate After Editing**: If modifying workflows, use ace-lint for markdown validation
4. **Check Discovery**: Verify workflows appear in `ace-nav --sources` after installation
5. **Use Protocol URLs**: Reference workflows via `wfi://` for portability

### Common Pitfalls

❌ **Don't**: Reference workflows by file path
✅ **Do**: Use `wfi://manage-guides` protocol URL

❌ **Don't**: Modify workflows directly in gem installation
✅ **Do**: Fork gem, modify, and create PR or local development copy

❌ **Don't**: Assume workflow steps without reading
✅ **Do**: Load complete workflow and follow all steps

❌ **Don't**: Skip template embedding validation
✅ **Do**: Verify all workflows have `<documents>` sections

## Troubleshooting

### Workflow Not Found

**Problem**: `ace-nav wfi://manage-guides` returns "not found"

**Diagnosis**:
```bash
# Check if gem is installed
gem list | grep ace-handbook

# Check if ace-nav sees the gem
ace-nav --sources | grep ace-handbook

# Verify handbook directory exists
find $(gem environment gemdir)/gems/ace-handbook-* -name "handbook" -type d
```

**Solutions**:
1. Install gem: `gem install ace-handbook` or `bundle install`
2. Verify gem has `handbook/workflow-instructions/` directory
3. Restart shell to reload gem paths

### Workflow Discovery Issues

**Problem**: ace-handbook workflows not appearing in `ace-nav --sources`

**Diagnosis**:
```bash
# Check gem structure
ls -la $(gem environment gemdir)/gems/ace-handbook-*/handbook/

# Verify RubyGems can find it
gem spec ace-handbook
```

**Solutions**:
1. Ensure gem has `handbook/workflow-instructions/` directory
2. Check gem is properly installed: `bundle exec gem list`
3. Try re-installing: `gem uninstall ace-handbook && gem install ace-handbook`

### Template Embedding Errors

**Problem**: Workflow references external templates that don't exist

**Diagnosis**:
```bash
# Check for template references in workflows
ace-search "dev-handbook/templates" --content --glob "**/ace-handbook/**/*.wf.md"

# Verify embedded templates exist
ace-search "<documents>" --content --glob "**/ace-handbook/**/*.wf.md"
```

**Solutions**:
1. All templates should be embedded in `<documents>` sections
2. Report issue if external references found - this violates ADR-002
3. Verify you have latest gem version with embedded templates

## Migration Notes

### From dev-handbook Workflows

**Legacy Access** (before ace-handbook gem):
```bash
# Old workflow location
ace-nav wfi://meta-manage-guides
# Resolved from: dev-handbook/.meta/wfi/manage-guides.wf.md
```

**New Access** (after ace-handbook gem):
```bash
# New workflow location
ace-nav wfi://manage-guides
# Resolved from: gem/ace-handbook/handbook/workflow-instructions/manage-guides.wf.md
```

**Key Differences**:
1. **Naming**: "meta-" prefix removed for cleaner names
2. **Location**: Workflows now in installed gem, not project directory
3. **Portability**: Available system-wide or per-project via Gemfile
4. **Versioning**: Workflows versioned with gem releases

**Transition Period**:
- Both old and new workflows may coexist
- ace-nav priority system: project (dev-handbook) > gem (ace-handbook)
- Update references to use new names when ready
- Legacy workflows can be removed after migration complete

### Updating Slash Commands

Claude Code slash commands may reference old workflow names:

**Old** (.claude/commands/meta-manage-guides.md):
```markdown
Load and follow: `dev-handbook/.meta/wfi/manage-guides.wf.md`
```

**New** (updated to use protocol):
```markdown
Load and follow: `ace-nav wfi://manage-guides`
```

Benefits of protocol-based approach:
- Automatically resolves to correct source (gem vs project)
- No hard-coded paths
- Works across different environments

## Internal Implementation Notes

### Gem Structure

```
ace-handbook/
├── lib/
│   └── ace/
│       └── handbook/
│           └── version.rb          # VERSION = "0.1.0"
│       handbook.rb                 # Module definition only
├── handbook/
│   └── workflow-instructions/
│       ├── manage-guides.wf.md
│       ├── review-guides.wf.md
│       ├── manage-workflow-instructions.wf.md
│       ├── review-workflows.wf.md
│       ├── manage-agents.wf.md
│       ├── update-handbook-docs.wf.md
│       ├── update-tools-docs.wf.md
│       └── update-integration-claude.wf.md
├── ace-handbook.gemspec
├── README.md
├── CHANGELOG.md
├── Rakefile
└── LICENSE.txt
```

### Discovery Mechanism

ace-nav discovers workflows through:

1. **Gem Scanner** (`Ace::Nav::Molecules::HandbookScanner#scan_gem_sources`):
   - Finds all installed gems starting with "ace-"
   - Checks for `handbook/` directory in gem
   - Creates source entry with `@ace-handbook` alias

2. **Protocol Resolution** (`Ace::Nav::Molecules::ProtocolScanner`):
   - Maps `wfi://` protocol to `workflow-instructions/` directory
   - Looks for `.wf.md` files in discovered sources
   - Returns full path when workflow requested

3. **Priority System**:
   - Project sources (priority 10) override gem sources (priority 100+)
   - Allows local workflow overrides during development
   - Enables testing before publishing gem updates

### No Runtime Dependencies

ace-handbook has **zero runtime dependencies**:
- No `ace-support-core` (no configuration needed)
- No Ruby code execution (pure markdown content)
- No CLI tools (workflows accessed via ace-nav)

This makes the gem:
- Fast to install (no dependency resolution)
- Stable (no version conflicts)
- Portable (works anywhere Ruby and ace-nav are available)

## Further Reading

- **ADR-002**: XML Template Embedding Architecture - Why templates are embedded in workflows
- **ADR-016**: Handbook Directory Architecture - Standard structure for handbook/ directories
- **ace-nav Documentation**: Complete guide to wfi:// protocol and workflow discovery
- **ace-gems.g.md**: Development guide for creating ACE gems
