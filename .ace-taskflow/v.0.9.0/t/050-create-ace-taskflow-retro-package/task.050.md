---
id: v.0.9.0+task.050
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Create retro management commands for ace-taskflow


## 0. Directory Audit ✅

_Command run:_

```bash
ace-nav guide://
```

_Result excerpt:_

```
ace-taskflow/
├── lib/ace/taskflow/
│   ├── cli.rb                    # Main CLI router
│   ├── commands/
│   │   ├── task_command.rb       # Singular: ace-taskflow task
│   │   ├── tasks_command.rb      # Plural: ace-taskflow tasks
│   │   ├── idea_command.rb       # Singular: ace-taskflow idea
│   │   └── ideas_command.rb      # Plural: ace-taskflow ideas
│   ├── organisms/
│   │   ├── task_manager.rb
│   │   └── idea_writer.rb
│   └── molecules/
.claude/commands/ace/
└── create-reflection-note.md     # Claude command (only from agents)
ace-taskflow/handbook/workflow-instructions/
├── create-reflection-note.wf.md  # Workflow file
└── synthesize-reflection-notes.wf.md
.ace-taskflow/v.0.9.0/retro/
├── 2025-09-20-*.md               # Regular reflection notes
└── 20250925-*.rn.md              # One file with .rn.md extension
```

## Objective

Add retrospective (retro) management commands to ace-taskflow CLI following the established singular/plural command pattern (like task/tasks, idea/ideas). Enable users to create reflection notes and synthesize insights through CLI commands that delegate to workflow instructions, maintaining clear separation between CLI tools and Claude commands.

## Scope of Work

### CLI Command Structure
Add **retro** commands to ace-taskflow CLI:
- `ace-taskflow retro` - Operations on single retrospective notes
- `ace-taskflow retros` - Browse and list multiple retrospective notes

### Command Responsibilities

**ace-taskflow retro** (singular - non-interactive file creation):
- `ace-taskflow retro create [title]` - Create new reflection note file with template
  - Creates timestamped file: `YYYY-MM-DD-<slug>.md`
  - Uses template from wfi://create-reflection-note
  - Non-interactive: Just creates file structure for LLM/agent to populate
  - Similar pattern to `ace-taskflow task create` and `ace-taskflow idea create`
- `ace-taskflow retro show <reference>` - Display specific reflection note
- Future: `ace-taskflow retro synthesize` - Trigger synthesis workflow

**ace-taskflow retros** (plural - listing/browsing):
- `ace-taskflow retros` - List all retrospective notes in current release
- `ace-taskflow retros --all` - List from all releases
- `ace-taskflow retros --release <version>` - List from specific release

### Claude Command vs CLI Tool Distinction

**Claude Command** (`/ace:create-reflection-note`):
- Located: `.claude/commands/ace/create-reflection-note.md`
- Usage: Only callable by Claude agents, NOT from bash CLI
- Behavior: Runs workflow via `ace-nav wfi://create-reflection-note`
- Content population: Agent analyzes context and populates content

**CLI Tool** (`ace-taskflow retro create`):
- Located: `ace-taskflow/lib/ace/taskflow/commands/retro_command.rb`
- Usage: Bash command line tool
- Behavior: Creates file with template structure
- Content population: User or LLM manually fills in content later

### Naming Convention Alignment

Follow established patterns:
- **Singular commands** (task/idea/retro): Non-interactive file creation, operations on single items
- **Plural commands** (tasks/ideas/retros): Listing, browsing, filtering multiple items
- NOT "reflection" → Use "retro" for brevity and consistency
- NOT "list" subcommand → Use plural form directly

### File Extension Consistency

Based on audit, standardize to `.md`:
- Current: Mix of `.md` and `.rn.md` extensions
- Decision: Use `.md` for all reflection notes (standard markdown)
- Naming: `YYYY-MM-DD-<descriptive-slug>.md`

### Deliverables

#### Create
- `ace-taskflow/lib/ace/taskflow/commands/retro_command.rb`
- `ace-taskflow/lib/ace/taskflow/commands/retros_command.rb`
- `ace-taskflow/lib/ace/taskflow/organisms/retro_manager.rb`
- `ace-taskflow/lib/ace/taskflow/molecules/retro_loader.rb`
- `ace-taskflow/test/commands/retro_command_test.rb`
- `ace-taskflow/test/commands/retros_command_test.rb`

#### Modify
- `ace-taskflow/lib/ace/taskflow/cli.rb` - Add retro/retros routes
- `ace-taskflow/README.md` - Document new commands

## Implementation Plan

### Planning Steps

* [ ] Analyze existing task and idea command implementations for patterns
  > TEST: Pattern Understanding
  > Type: Pre-condition Check
  > Assert: Identify file creation, template usage, and display patterns
  > Command: # grep -r "create.*args" ace-taskflow/lib/ace/taskflow/commands/

* [ ] Review retro file structure in .ace-taskflow/v.0.9.0/retro/
  > TEST: Structure Validation
  > Type: Pre-condition Check
  > Assert: Understand current file naming and location patterns
  > Command: # ls -la .ace-taskflow/v.0.9.0/retro/

* [ ] Design retro file creation and discovery logic
  - Template loading from wfi://create-reflection-note
  - File naming convention: YYYY-MM-DD-slug.md
  - Release context resolution (current vs specific vs backlog)

### Execution Steps

- [ ] Create RetroCommand class following TaskCommand pattern
  - Implement `create` subcommand for file creation
  - Implement `show` subcommand for displaying retro content
  - Support --release and --current flags for context
  > TEST: Command Creation
  > Type: Unit Test
  > Assert: RetroCommand initializes and routes subcommands correctly
  > Command: # ace-test retro_command_test.rb

- [ ] Create RetrosCommand class following TasksCommand pattern
  - Implement listing with filtering by release
  - Support display modes (formatted, path, content)
  - Add --all flag for cross-release listing
  > TEST: Listing Command
  > Type: Unit Test
  > Assert: RetrosCommand lists and filters retro files correctly
  > Command: # ace-test retros_command_test.rb

- [ ] Implement RetroManager organism
  - create_retro(title, context:) - Create new retro file
  - load_retro(reference) - Load retro by filename or slug
  - list_retros(context:, filters:) - List retros with filtering
  > TEST: Manager Operations
  > Type: Unit Test
  > Assert: RetroManager creates and loads retro files correctly
  > Command: # ace-test organisms/retro_manager_test.rb

- [ ] Implement RetroLoader molecule
  - find_retro_by_reference(reference, context:) - Lookup retro file
  - parse_retro_metadata(file_path) - Extract frontmatter and content
  - resolve_retro_directory(context) - Get release-specific retro/ path
  > TEST: Loader Functionality
  > Type: Unit Test
  > Assert: RetroLoader finds and parses retro files correctly
  > Command: # ace-test molecules/retro_loader_test.rb

- [ ] Update CLI router in cli.rb
  - Add "retro" case routing to Commands::RetroCommand
  - Add "retros" case routing to Commands::RetrosCommand
  - Update show_help with retro command documentation
  > TEST: CLI Routing
  > Type: Integration Test
  > Assert: ace-taskflow retro and retros commands route correctly
  > Command: # ace-taskflow retro --help && ace-taskflow retros --help

- [ ] Create comprehensive tests for retro commands
  - Test file creation with various options
  - Test listing and filtering
  - Test edge cases (no retros, missing release)
  > TEST: Full Command Coverage
  > Type: Integration Test
  > Assert: All retro commands work end-to-end
  > Command: # ace-test test/integration/retro_*_test.rb

- [ ] Update documentation
  - Add retro commands to README.md
  - Document usage examples and patterns
  - Clarify CLI vs Claude command distinction
  > TEST: Documentation Complete
  > Type: Manual Check
  > Assert: README contains clear retro command examples
  > Command: # grep -A 10 "retro" ace-taskflow/README.md

## Acceptance Criteria

- [ ] **CLI Commands Available**: `ace-taskflow retro` and `ace-taskflow retros` commands work
- [ ] **File Creation**: `ace-taskflow retro create <title>` creates properly formatted markdown file
- [ ] **Listing**: `ace-taskflow retros` lists retro notes from current release
- [ ] **Context Handling**: Commands support --release and --current flags
- [ ] **Pattern Consistency**: Implementation follows task/tasks and idea/ideas patterns
- [ ] **Test Coverage**: All new commands have comprehensive test coverage
- [ ] **Documentation**: README and help text clearly explain new commands

## Out of Scope

- ❌ **Workflow Implementation**: Workflow files already exist, not modifying them
- ❌ **Content Analysis**: Synthesis logic stays in workflow, not in CLI
- ❌ **Interactive Content Editing**: Commands create files, LLM/user populates content
- ❌ **Claude Command Changes**: Existing `/ace:create-reflection-note` stays unchanged
- ❌ **Advanced Filtering**: Beyond basic release/status filtering

## References

- Pattern reference: `ace-taskflow/lib/ace/taskflow/commands/task_command.rb`
- Pattern reference: `ace-taskflow/lib/ace/taskflow/commands/idea_command.rb`
- Workflow source: `ace-taskflow/handbook/workflow-instructions/create-reflection-note.wf.md`
- Template source: See tmpl://release-reflections/retro in workflow file
- CLI router: `ace-taskflow/lib/ace/taskflow/cli.rb`
