---
id: v.0.9.0+task.005
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Create ace-taskflow-retro package

## Behavioral Specification

### User Experience
- **Input**: User invokes retrospective commands via ace-taskflow CLI (e.g., `ace-taskflow retro create`, `ace-taskflow retro synthesize`)
- **Process**: System captures reflection notes during development or synthesizes multiple reflections into insights
- **Output**: Structured reflection documents capturing learnings, decisions, and insights for future reference

### Expected Behavior

Users experience seamless retrospective workflows that capture and synthesize development learnings. The system provides:

**Create Reflection Note**: Captures a single reflection during or after development work
- Prompts for reflection title and context
- Guides user through structured reflection format
- Stores reflection with timestamp and metadata
- Links reflection to relevant tasks or releases

**Synthesize Reflection Notes**: Analyzes multiple reflections to extract patterns and insights
- Reads all reflection notes from a specified period or release
- Identifies common themes, recurring challenges, and key learnings
- Generates synthesis document with actionable insights
- Highlights process improvements and successful patterns

The workflows integrate with .ace-taskflow structure, storing reflections organized by release or time period, making retrospective insights easily accessible for project planning and process improvement.

### Interface Contract

```bash
# Create a new reflection note
ace-taskflow retro create [--title <title>] [--release <version>]
# Executes: wfi://create-reflection-note
# Interactive prompts for reflection content
# Output: Reflection note in .ace-taskflow/<release>/docs/reflections/

# Synthesize multiple reflection notes
ace-taskflow retro synthesize [--release <version>] [--since <date>]
# Executes: wfi://synthesize-reflection-notes
# Reads: .ace-taskflow/<release>/docs/reflections/*.md
# Output: Synthesis document highlighting patterns and insights

# List reflection notes
ace-taskflow retro list [--release <version>]
# Output: List of reflection notes with titles and dates
```

**Error Handling:**
- No reflections found: Report empty state, suggest creating first reflection
- Invalid release specified: List available releases, prompt for correction
- Malformed reflection files: Skip invalid files, log warnings

**Edge Cases:**
- Single reflection to synthesize: Generate simple summary without pattern analysis
- Reflection without release context: Store in backlog or current release
- Empty reflection content: Prompt user or save with placeholder

### Success Criteria

- [ ] **Reflection Capture**: Users can quickly create structured reflection notes during development
- [ ] **Synthesis Quality**: Synthesized documents provide actionable insights from multiple reflections
- [ ] **Pattern Recognition**: System identifies recurring themes and learnings across reflections
- [ ] **Integration**: Reflections integrate with release and task management workflows
- [ ] **Accessibility**: Past reflections are easily discoverable and searchable

### Validation Questions

- [ ] **Reflection Structure**: What sections should reflection notes contain (Context, Learnings, Actions, etc.)?
- [ ] **Storage Organization**: Should reflections be per-release, time-based, or topic-based?
- [ ] **Synthesis Triggers**: When should synthesis happen - manually, per release, or periodically?
- [ ] **Task Linking**: How should reflections link to specific tasks or issues?
- [ ] **Privacy Concerns**: Are there reflection types that should be kept private or excluded from synthesis?

## Objective

Create a dedicated retrospective package (ace-taskflow-retro) that enables teams to capture development learnings and synthesize insights, supporting continuous process improvement and knowledge retention across releases.

## Scope of Work

### Package Structure
New package: **ace-taskflow-retro** (Ruby gem)
- Location: `dev-tools/ace-taskflow-retro/`
- CLI namespace: `ace-taskflow retro`
- Workflows to integrate:

### Workflows to Migrate
1. **create-reflection-note** (ace-taskflow → ace-taskflow-retro)
   - Source: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/create-reflection-note.wf.md`
   - Integration: `ace-taskflow-retro` calls wfi://create-reflection-note
   - Command: `ace-taskflow retro create`

2. **synthesize-reflection-notes** (dev-handbook → ace-taskflow-retro)
   - Source: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/synthesize-reflection-notes.wf.md`
   - Integration: `ace-taskflow-retro` calls wfi://synthesize-reflection-notes
   - Command: `ace-taskflow retro synthesize`

### Interface Scope
- CLI commands under `ace-taskflow retro` namespace
- wfi:// protocol integration for workflow delegation
- Reflection file management (create, read, list)
- Pattern analysis and synthesis logic
- Release and task context integration

### Deliverables

#### Behavioral Specifications
- Reflection capture user experience
- Synthesis algorithm behavior
- Storage and organization patterns
- Integration with ace-taskflow core

#### Package Structure
- Ruby gem structure with CLI interface
- Workflow integration layer
- Configuration management
- Documentation and examples

## Out of Scope

- ❌ **Implementation Details**: Ruby class hierarchy, file parsing, pattern matching algorithms
- ❌ **Advanced Analytics**: Statistical analysis, sentiment tracking, team velocity metrics
- ❌ **Collaboration Features**: Real-time reflection editing, commenting, team voting
- ❌ **Export Formats**: PDF generation, presentation slides, dashboard visualizations

## References

- Workflow files: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/create-reflection-note.wf.md`
- Workflow files: `/Users/mc/Ps/ace-meta/dev-handbook/workflow-instructions/synthesize-reflection-notes.wf.md`
- Package pattern: Existing ace-taskflow gem structure
- Template: `/Users/mc/Ps/ace-meta/ace-taskflow/handbook/workflow-instructions/draft-task.wf.md`
