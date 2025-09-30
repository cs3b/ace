---
id: v.0.9.0+task.048
status: draft
priority: medium
estimate: TBD
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

## References

- Task structure: `.ace-taskflow/*/t/*/task.*.md` files
- Release structure: `.ace-taskflow/*/release.md` files
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
- Note: If update-roadmap.wf.md doesn't exist in dev-handbook, this task defines its expected behavior
