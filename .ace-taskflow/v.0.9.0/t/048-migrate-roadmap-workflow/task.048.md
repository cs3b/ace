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
- **Input**: User invokes `ace-taskflow roadmap update` or `ace-taskflow roadmap sync` to maintain project roadmap
- **Process**: System analyzes current tasks, releases, and goals to generate/update roadmap documentation
- **Output**: Updated ROADMAP.md file reflecting current project state, priorities, and planned work

### Expected Behavior

Users experience automatic roadmap generation and synchronization based on the current state of tasks and releases in .ace-taskflow. When users invoke roadmap commands, the system:

- Analyzes all active tasks across releases
- Identifies priorities and dependencies
- Generates milestone summaries
- Updates roadmap documentation with structured sections (Now, Next, Later, Done)
- Maintains consistency between task files and roadmap representation

The workflow provides a bird's-eye view of project direction without requiring manual roadmap maintenance.

### Interface Contract

```bash
# Update roadmap based on current tasks
ace-taskflow roadmap update
# Executes: wfi://update-roadmap
# Reads: .ace-taskflow/*/t/*/task.*.md
# Output: Updates ROADMAP.md or .ace-taskflow/docs/roadmap.md

# Sync roadmap with releases (if applicable)
ace-taskflow roadmap sync [--release <version>]
# Executes: wfi://update-roadmap with release filter
# Output: Roadmap synchronized with specified release
```

**Error Handling:**
- No tasks found: Generate minimal roadmap with placeholder sections
- Malformed task files: Skip invalid tasks, log warnings
- Missing roadmap template: Create from default template

**Edge Cases:**
- Empty release: Include in roadmap with "No tasks" indicator
- Circular dependencies: Detect and report in roadmap notes
- Stale task data: Include last-updated timestamps for verification

### Success Criteria

- [ ] **Automated Generation**: Roadmap updates automatically from task state without manual editing
- [ ] **Accurate Representation**: Roadmap reflects current priorities, milestones, and task status
- [ ] **Clear Structure**: Roadmap uses consistent sections (Now/Next/Later/Done or similar)
- [ ] **CLI Integration**: Users access roadmap commands through ace-taskflow interface
- [ ] **Change Detection**: System identifies when roadmap is out of sync and needs update

### Validation Questions

- [ ] **Roadmap Location**: Should roadmap be at project root (ROADMAP.md) or in .ace-taskflow/docs/?
- [ ] **Update Frequency**: Should roadmap update automatically on task changes or only on explicit command?
- [ ] **Section Structure**: What roadmap format best serves user needs (Now/Next/Later, Quarterly, Release-based)?
- [ ] **Filtering Options**: Should users be able to generate filtered roadmaps (by priority, category, release)?

## Objective

Provide automated roadmap maintenance that keeps high-level project planning synchronized with detailed task management, giving users consistent visibility into project direction and progress.

## Scope of Work

### Workflow to Migrate
1. **update-roadmap** (dev-handbook → ace-taskflow)
   - Source: Search in dev-handbook for update-roadmap or roadmap-related workflows
   - Destination: `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
   - Command: `ace-taskflow roadmap update`
   - Note: If workflow doesn't exist, create behavioral specification for new implementation

### Interface Scope
- CLI commands under `ace-taskflow roadmap` namespace
- wfi:// protocol integration
- Roadmap generation logic
- Task analysis and prioritization
- Milestone extraction

### Deliverables

#### Behavioral Specifications
- Roadmap generation behavior
- Task-to-roadmap mapping rules
- Section structure and formatting
- Update triggers and conditions

## Out of Scope

- ❌ **Implementation Details**: File parsing logic, template engines, data structures
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

**Documentation-First Approach:**
- This task creates a **workflow instruction document only** - no Ruby code implementation
- The workflow will define behavioral specifications for a future `ace-taskflow roadmap` CLI command
- Follows ACE self-contained workflow principle (ADR-001): all necessary context embedded
- Integrates with existing ace-nav wfi:// protocol for workflow discovery

**Integration Strategy:**
- Workflow document placed in `ace-taskflow/handbook/workflow-instructions/update-roadmap.wf.md`
- References existing roadmap guide (`dev-handbook/guides/roadmap-definition.g.md`)
- Uses existing roadmap template for validation structure
- Accessible via `ace-nav wfi://update-roadmap` protocol
- Future CLI implementation will execute this workflow via wfi:// protocol

**Rationale:**
- Separates behavioral specification (what) from implementation (how)
- Enables immediate use by AI agents via workflow instructions
- Provides complete specification for future Ruby gem implementation
- Maintains consistency with other ace-taskflow workflow instructions

### Technology Stack

**No Code Dependencies:**
- Pure Markdown workflow instruction document
- YAML front matter for metadata
- Embedded XML templates following ADR-002

**Workflow Integration:**
- ace-nav for wfi:// protocol discovery
- Future: ace-taskflow CLI roadmap subcommand (out of scope for this task)
- Claude Code command integration via `.claude/commands/`

**Document Format:**
- Markdown (.wf.md extension)
- YAML front matter (name, allowed-tools, description, argument-hint)
- Self-contained with embedded templates
- Reference to roadmap-definition.g.md for validation rules

### Implementation Strategy

**Phase 1: Workflow Document Creation**
1. Create update-roadmap.wf.md with complete behavioral specification
2. Embed roadmap template and validation rules
3. Define step-by-step process for roadmap updates
4. Include error handling and validation procedures

**Phase 2: Claude Code Integration**
5. Create slash command in `.claude/commands/update-roadmap.md`
6. Map command to workflow via ace-nav wfi:// protocol

**Phase 3: Validation**
7. Test workflow discoverability via ace-nav
8. Verify template embedding follows ADR-002
9. Validate against existing roadmap structure

**Note:** This task is documentation-only. Future task will implement CLI command.

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

- `.claude/commands/update-roadmap.md`
  - Purpose: Claude Code slash command integration
  - Key components: Command metadata, workflow invocation
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
  > Command: # grep "wfi://update-roadmap" .claude/commands/update-roadmap.md

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
- [ ] AC 5: Claude Code slash command `/update-roadmap` created and functional
- [ ] AC 6: Workflow references roadmap-definition.g.md for validation rules (not duplicating them)
- [ ] AC 7: Error handling and validation procedures documented
- [ ] AC 8: Success criteria clearly defined and measurable

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
