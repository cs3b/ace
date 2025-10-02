---
id: v.0.9.0+task.048
status: pending
priority: medium
estimate: 8h
dependencies: []
---

# Migrate roadmap workflow to ace-taskflow

## Behavioral Specification

### User Experience

**Agent Workflow (Write Operations):**
- **Input**: Agent invokes `/ace:update-roadmap` Claude command or `ace-nav wfi://update-roadmap`
- **Process**: Agent executes workflow to analyze releases and update roadmap documentation
- **Output**: Updated `.ace-taskflow/roadmap.md` with synchronized release information

**CLI Query (Read Operations):**
- **Input**: User runs `ace-taskflow roadmap` to view upcoming releases
- **Process**: CLI reads and displays planned releases from roadmap.md
- **Output**: Formatted list of planned releases with version, codename, and target window

### Expected Behavior

**Three Distinct Interfaces:**

1. **Workflow** (`ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`)
   - Agent instructions for updating roadmap
   - Analyzes release state from `.ace-taskflow/` structure
   - Updates Planned Major Releases table
   - Synchronizes cross-release dependencies
   - Commits changes

2. **Claude Command** (`/ace:update-roadmap`)
   - Triggers the update-roadmap workflow
   - Provides agent-friendly interface
   - Part of ace-taskflow command namespace

3. **CLI Tool** (`ace-taskflow roadmap`)
   - Read-only query of planned releases
   - Lists releases from roadmap.md in short format
   - Similar to `ace-taskflow tasks` (display, not modify)
   - Optional `--limit N` to show first N releases

### Interface Contract

```bash
# AGENT WORKFLOW (Write - updates roadmap)
/ace:update-roadmap
# Executes: ace-nav wfi://update-roadmap
# Reads: .ace-taskflow/roadmap.md, .ace-taskflow/v.*/release.md
# Output: Updates .ace-taskflow/roadmap.md and commits

# Alternative workflow invocation
ace-nav wfi://update-roadmap
# Same behavior as Claude command

# CLI QUERY (Read - displays releases)
ace-taskflow roadmap
# Reads: .ace-taskflow/roadmap.md
# Output: Displays planned releases in short format
# Example output:
#   v.0.9.0  "Mono-Repo Multiple Gems"  Q4 2025
#   v.0.10.0 "Spark"                    Q2 2026
#   v1.0.0   "Keystone"                 Q3 2026

# CLI with limit
ace-taskflow roadmap --limit 3
# Output: Shows first 3 planned releases
```

**Role Separation:**
- **Workflows**: Complex operations requiring analysis and updates (agent-executed)
- **Claude Commands**: Shortcuts to invoke workflows (`/ace:*` prefix)
- **CLI Tools**: Simple read-only queries for data display (human-friendly)

**Error Handling:**
- No tasks found: Generate minimal roadmap with placeholder sections
- Malformed task files: Skip invalid tasks, log warnings
- Missing roadmap template: Create from default template

**Edge Cases:**
- Empty release: Include in roadmap with "No tasks" indicator
- Circular dependencies: Detect and report in roadmap notes
- Stale task data: Include last-updated timestamps for verification

### Success Criteria

- [ ] **Workflow Created**: Agent can update roadmap via `/ace:update-roadmap` command
- [ ] **Agent Instructions Clear**: Workflow document provides complete step-by-step process
- [ ] **Format Validation**: Workflow validates against roadmap-definition.g.md structure
- [ ] **Release Synchronization**: Workflow detects and syncs release state changes
- [ ] **Claude Integration**: `/ace:update-roadmap` command invokes workflow correctly

### Scope Clarification

**In Scope (This Task):**
- ✅ Create workflow instruction document (`update-roadmap.wf.md`)
- ✅ Create Claude command (`/ace:update-roadmap`)
- ✅ Define behavioral specifications for roadmap updates
- ✅ Document integration with draft-release and publish-release workflows

**Out of Scope (Future Tasks):**
- ❌ `ace-taskflow roadmap` CLI implementation (read-only query)
- ❌ Ruby code for roadmap parsing/generation
- ❌ Automated roadmap updates on task changes
- ❌ LLM-based roadmap content generation

## Objective

Provide automated roadmap maintenance that keeps high-level project planning synchronized with detailed task management, giving users consistent visibility into project direction and progress.

## Scope of Work

### Workflow to Create
1. **update-roadmap workflow** (new in ace-taskflow/handbook)
   - Location: `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
   - Purpose: Agent instructions for updating roadmap from release state
   - Integration: Invoked via `/ace:update-roadmap` Claude command
   - Note: No existing workflow to migrate; creating new behavioral specification

### Interface Scope
- **Workflow document**: Complete agent instructions for roadmap updates
- **Claude command**: `/ace:update-roadmap` trigger
- **wfi:// protocol**: `ace-nav wfi://update-roadmap` integration
- **Validation**: Format checking against roadmap-definition.g.md
- **Synchronization**: Release state detection and table updates

### Deliverables

#### Workflow Document
- `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
- Self-contained with embedded templates (ADR-001, ADR-002)
- Step-by-step process for roadmap updates
- Error handling and validation procedures

#### Claude Command
- `.claude/commands/ace/update-roadmap.md`
- Maps `/ace:update-roadmap` to workflow invocation
- Part of ace-taskflow command namespace

#### Documentation
- UX/usage guide for workflow execution
- Integration patterns with draft-release and publish-release
- Troubleshooting and best practices

## Out of Scope

- ❌ **Ruby CLI Implementation**: `ace-taskflow roadmap` command (read-only query - future task)
- ❌ **CLI Update Commands**: No `ace-taskflow roadmap update` or `sync` subcommands (agents use workflows, not CLI)
- ❌ **Automated Triggers**: Automatic roadmap updates on task/release changes
- ❌ **Ruby Code**: File parsing logic, roadmap generators, template engines
- ❌ **Visual Roadmaps**: Graphical timeline representations, Gantt charts
- ❌ **Interactive Features**: Web-based roadmap viewers, real-time updates
- ❌ **Historical Tracking**: Roadmap version history, change diffs

## 0. Directory Audit ✅

_Command run:_

```bash
ace-nav guide://
```

_Result excerpt:_

```
ace-taskflow/
├── exe/ace-taskflow
├── lib/ace/taskflow/
│   ├── cli.rb
│   ├── commands/
│   │   ├── task_command.rb
│   │   ├── tasks_command.rb
│   │   ├── release_command.rb
│   │   └── releases_command.rb
│   ├── molecules/
│   ├── organisms/
│   └── atoms/
└── handbook/workflow-instructions/
    ├── draft-task.wf.md
    ├── plan-task.wf.md
    └── ...

dev-handbook/
├── guides/roadmap-definition.g.md
├── templates/project-docs/roadmap/roadmap.template.md
└── .integrations/claude/commands/_generated/update-roadmap.md

.ace-taskflow/
├── roadmap.md (existing roadmap following the guide structure)
└── v.0.9.0/t/048-migrate-roadmap-workflow/
```

## Technical Approach

### Architecture Pattern

**Three-Layer Architecture (Distinct Roles):**

1. **Workflow Layer** (Agent Instructions)
   - Purpose: Define HOW agents update roadmaps
   - Location: `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
   - Consumer: AI agents executing roadmap updates
   - Operations: Write (analyze, update, commit)

2. **Command Layer** (Workflow Triggers)
   - Purpose: Provide shortcuts to invoke workflows
   - Location: `.claude/commands/ace/update-roadmap.md`
   - Consumer: AI agents using Claude Code
   - Invocation: `/ace:update-roadmap` → `ace-nav wfi://update-roadmap`

3. **CLI Layer** (Data Queries) - **OUT OF SCOPE**
   - Purpose: Display roadmap data (read-only)
   - Future Location: `ace-taskflow/lib/ace/taskflow/commands/roadmap_command.rb`
   - Consumer: Humans and agents needing roadmap info
   - Operations: Read (list releases, show targets)

**This Task's Scope:**
- ✅ Layer 1: Create workflow document
- ✅ Layer 2: Create Claude command
- ❌ Layer 3: CLI implementation (future task)

**Integration Strategy:**
- Workflow follows self-contained principle (ADR-001)
- Embeds templates using XML format (ADR-002)
- References roadmap-definition.g.md for validation rules
- Accessible via `ace-nav wfi://update-roadmap` protocol
- Invokable via `/ace:update-roadmap` Claude command

**Rationale:**
- **Separation of Concerns**: Workflows for complex write operations, CLI for simple reads
- **Agent-First Design**: Workflows optimized for AI execution, not CLI arguments
- **Human Accessibility**: CLI provides quick roadmap queries without running workflows
- **Consistency**: Follows ace-taskflow patterns (task/tasks, release/releases, roadmap pattern)

### Technology Stack

**No Code Dependencies:**
- Pure Markdown workflow instruction document
- YAML front matter for metadata
- Embedded XML templates following ADR-002

**Workflow Integration:**
- ace-nav for wfi:// protocol discovery
- Claude Code command integration via `.claude/commands/ace/`
- Future: ace-taskflow CLI `roadmap` read-only query (separate task)

**Document Format:**
- Markdown (.wf.md extension)
- YAML front matter (name, allowed-tools, description, argument-hint)
- Self-contained with embedded templates
- Reference to roadmap-definition.g.md for validation rules

### Implementation Strategy

**Phase 1: Workflow Document Creation**
1. Create update-roadmap.wf.md with complete behavioral specification
2. Embed roadmap template in XML format (ADR-002)
3. Define step-by-step process for roadmap updates (load, validate, update, commit)
4. Include error handling and recovery procedures
5. Add integration guidance for draft-release and publish-release workflows

**Phase 2: Claude Command Integration**
6. Create Claude command in `.claude/commands/ace/update-roadmap.md`
7. Map `/ace:update-roadmap` to `ace-nav wfi://update-roadmap` invocation
8. Follow ace-taskflow command namespace convention

**Phase 3: Validation**
9. Test workflow discoverability via `ace-nav wfi://update-roadmap`
10. Verify template embedding follows ADR-002 XML format
11. Validate workflow self-containment (ADR-001)
12. Test `/ace:update-roadmap` command invocation

**Note:** This task creates workflow documentation only. CLI implementation is a future task.

## File Modifications

### Create

- `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
  - Purpose: Self-contained workflow instruction for roadmap updates
  - Key components: Process steps, validation rules, embedded templates
  - Dependencies: References roadmap-definition.g.md, roadmap.template.md

- `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md` (detailed structure)
  - YAML front matter with workflow metadata
  - Goal and Prerequisites sections
  - Process Steps (8-10 detailed steps)
  - Success Criteria and validation checklist
  - Embedded roadmap template in XML format
  - Integration with ace-nav wfi:// protocol

- `.claude/commands/ace/update-roadmap.md`
  - Purpose: `/ace:update-roadmap` Claude command integration
  - Key components: Command metadata, ace-nav wfi:// invocation
  - Dependencies: ace-nav, update-roadmap.wf.md

### Modify

- None (this task creates new documentation only)

### Delete

- None

## Implementation Plan

### Planning Steps

* [x] Analyze roadmap guide structure and validation requirements
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Roadmap structure requirements, section specifications, and validation criteria identified
  > Command: # Verify roadmap-definition.g.md sections and validation rules understood

* [x] Research existing ace-taskflow workflows for pattern consistency
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Workflow instruction patterns from draft-task.wf.md and plan-task.wf.md analyzed
  > Command: # Confirm workflow document structure and XML template embedding understood

* [x] Design roadmap update process workflow
  > TEST: Process Design Validation
  > Type: Design Check
  > Assert: Complete process steps defined covering load, validate, update, commit cycles
  > Command: # Verify process covers all scenarios from roadmap-definition.g.md

### Execution Steps

- [ ] Create update-roadmap.wf.md with YAML front matter and goal section
  > TEST: Workflow Document Structure
  > Type: Format Validation
  > Assert: YAML front matter valid, goal section clear and actionable
  > Command: # ace-nav wfi://update-roadmap --verify-format

- [ ] Write Prerequisites section referencing required tools and context
  > TEST: Prerequisites Complete
  > Type: Content Validation
  > Assert: All required tools (ace-taskflow, ace-nav) and context files listed
  > Command: # grep -E "(ace-taskflow|ace-nav|roadmap)" update-roadmap.wf.md

- [ ] Document Process Steps with detailed instructions
  - Step 1: Load current roadmap and validate format
  - Step 2: Analyze releases from .ace-taskflow structure
  - Step 3: Update Planned Major Releases table
  - Step 4: Synchronize cross-release dependencies
  - Step 5: Add update history entry
  - Step 6: Validate updated roadmap structure
  - Step 7: Commit roadmap changes
  > TEST: Process Steps Complete
  > Type: Workflow Validation
  > Assert: All 7 process steps documented with clear instructions
  > Command: # grep -c "^[0-9]\+\. \*\*" update-roadmap.wf.md | test >= 7

- [ ] Embed roadmap template in XML format per ADR-002
  > TEST: Template Embedding Valid
  > Type: Format Validation
  > Assert: Template embedded in <documents><template> tags with proper path attribute
  > Command: # grep -A 5 "<template path=\"tmpl://project-docs/roadmap\">" update-roadmap.wf.md

- [ ] Add validation criteria and error handling sections
  > TEST: Error Handling Complete
  > Type: Content Validation
  > Assert: Error scenarios and recovery procedures documented
  > Command: # grep -E "(Error|Validation|Recovery)" update-roadmap.wf.md | test >= 5

- [ ] Write Success Criteria and output format specification
  > TEST: Success Criteria Defined
  > Type: Completion Check
  > Assert: Clear success criteria with measurable outcomes
  > Command: # grep "Success Criteria" update-roadmap.wf.md -A 10

- [ ] Create Claude Code command file with wfi:// integration
  > TEST: Command Integration
  > Type: Integration Validation
  > Assert: Command file references ace-nav wfi://update-roadmap protocol
  > Command: # grep "wfi://update-roadmap" .claude/commands/ace/update-roadmap.md

- [ ] Verify workflow discoverability via ace-nav
  > TEST: Workflow Discovery
  > Type: Integration Validation
  > Assert: Workflow discoverable through ace-nav wfi:// protocol
  > Command: ace-nav wfi://update-roadmap --verify

- [ ] Validate workflow against self-containment principle (ADR-001)
  > TEST: Self-Containment Validation
  > Type: Compliance Check
  > Assert: Workflow contains all necessary templates and context, no external dependencies except core docs
  > Command: # Verify no external workflow dependencies beyond roadmap-definition.g.md reference

## Acceptance Criteria

- [ ] AC 1: Workflow instruction document created at `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
- [ ] AC 2: Workflow is self-contained with embedded roadmap template following ADR-002 XML format
- [ ] AC 3: Process steps cover complete roadmap update cycle (load, validate, update, commit)
- [ ] AC 4: Workflow discoverable via `ace-nav wfi://update-roadmap` protocol
- [ ] AC 5: Claude Code command `/ace:update-roadmap` created at `.claude/commands/ace/update-roadmap.md`
- [ ] AC 6: Claude command correctly invokes `ace-nav wfi://update-roadmap`
- [ ] AC 7: Workflow references roadmap-definition.g.md for validation rules (not duplicating them)
- [ ] AC 8: Error handling and validation procedures documented
- [ ] AC 9: Integration with draft-release and publish-release workflows documented
- [ ] AC 10: Three-layer architecture (workflow/command/CLI) clearly explained in technical approach

## Out of Scope

- ❌ **Ruby CLI Implementation**: `ace-taskflow roadmap` command implementation (future task)
- ❌ **Automated Roadmap Generation**: LLM-based content generation from tasks
- ❌ **Real-time Synchronization**: Automatic roadmap updates on task changes
- ❌ **Visual Roadmaps**: Graphical timeline representations, Gantt charts
- ❌ **Interactive Features**: Web-based roadmap viewers, real-time updates
- ❌ **Historical Tracking**: Roadmap version history, change diffs

## References

- Existing roadmap: `.ace-taskflow/roadmap.md`
- Roadmap guide: `dev-handbook/guides/roadmap-definition.g.md`
- Roadmap template: `dev-handbook/templates/project-docs/roadmap/roadmap.template.md`
- Workflow template: `ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
- ADR-001: Workflow Self-Containment Principle
- ADR-002: XML Template Embedding Architecture
- ace-nav wfi:// protocol for workflow discovery
