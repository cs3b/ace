# Workflow Instruction: Update Context Documents

**Goal:** Analyze repository changes and update the core context documents ensuring they remain accurate, focused, and free of duplication.

## Prerequisites

* Write access to context documents in `docs/` directory
* Understanding of each document's specific purpose
* Access to Git for analyzing changes

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## Core Context Documents

This workflow maintains four essential project documents, each with a distinct purpose:

1. **`docs/what-do-we-build.md`** - Vision & Goals
   - Project vision and mission
   - High-level features and capabilities (without implementation details)
   - User personas and use cases
   - Value proposition and unique advantages
   - Future vision (high-level, without specific dates)
   
   **MUST NOT CONTAIN:**
   - Technical implementation details
   - Specific version numbers or counts (e.g., "19+ workflows", "25+ tools")
   - Architecture or design principles
   - Technology stack details
   - Dependencies or integration specifics
   - Success metrics with specific numbers

2. **`docs/architecture.md`** - Technical Design
   - Core design principles (system-level and implementation)
   - Technology stack choices and rationale
   - Multi-repository architecture (simple list format)
   - Integration and data flow with concrete examples
   - Agent architecture and compatibility
   - Developer environment setup
   - Reference to decisions.md for actionable decisions
   
   **MUST NOT CONTAIN:**
   - Project vision or business goals
   - User personas or use cases
   - Value propositions
   - Future plans or roadmap items
   - Production deployment (this is developer tooling only)
   - Complex diagrams when simple lists suffice

3. **`docs/blueprint.md`** - File Structure
   - Directory organization and structure
   - Key file locations and purposes
   - Read-only and ignored paths
   - Navigation guidance for developers
   
   **MUST NOT CONTAIN:**
   - Project vision or goals
   - Technical architecture decisions
   - Design principles
   - Tool usage instructions

4. **`docs/decisions.md`** - Actionable Decisions
   - Condensed, actionable decisions from ADRs
   - Behavioral impacts for AI agents and developers
   - Links to full ADR documents
   
   **MUST NOT CONTAIN:**
   - Full ADR content
   - Implementation details
   - Historical context or alternatives

## Process Steps

### 0. Load Ownership Model

Check if ownership model exists and load it for validation:
```bash
# Load ownership rules
ownership_file="docs/context/ownership.yml"
if [[ -f "$ownership_file" ]]; then
    echo "Ownership model found, will validate against it"
fi
```

### 1. Analyze Repository Changes

**Option A: Review Recent Changes**
```bash
# Check recent commits
git log --oneline -20

# View detailed changes
git diff HEAD~5..HEAD --stat

# Examine specific file changes
git diff HEAD~5..HEAD -- <path>
```

**Option B: Full Repository Analysis**
- Review major directories for structural changes
- Check for new features or components
- Identify architectural modifications
- Scan for new or updated ADRs in `docs/decisions/`

### 2. Load Current Context Documents

Read each document to understand current state:
- `docs/what-do-we-build.md`
- `docs/architecture.md`
- `docs/blueprint.md`
- `docs/decisions.md` (if exists)

### 3. Identify Required Updates

Based on repository analysis, determine updates needed for each document:

| Change Type | Affected Documents |
|------------|-------------------|
| New features/capabilities | what-do-we-build.md |
| Architecture/design changes | architecture.md |
| Directory/file reorganization | blueprint.md |
| New ADRs or decisions | decisions.md |
| Technology stack updates | architecture.md |
| User persona changes | what-do-we-build.md |
| Build/setup changes | architecture.md, blueprint.md |

### 4. Update what-do-we-build.md

Focus on vision and goals:
- Update feature list if new capabilities added
- Revise user personas if target audience changed
- Adjust success metrics if goals evolved
- Update future vision section with completed items

**Remove if present:**
- Implementation details
- File paths or directory structures
- Technical architecture decisions
- Tool commands or usage instructions

### 5. Update architecture.md

Focus on technical design:
- Update technology stack if new dependencies added
- Revise architecture patterns if design changed
- Update integration points for new external systems
- Document new security or performance considerations

**Remove if present:**
- Project vision or business goals
- Directory listings or file structures
- Tool usage instructions
- Duplicate feature lists

### 6. Update blueprint.md

Focus on file structure:
- Update directory organization if restructured
- Add new key directories or files
- Update read-only paths if protection changed
- Revise ignored paths if .gitignore modified

**Remove if present:**
- Project purpose or vision
- Technical design decisions
- Tool commands or usage
- Architecture explanations

### 7. Generate/Update decisions.md

Extract actionable decisions from ADRs:

```bash
# List all ADR files
ls -la docs/decisions/ADR-*.md
```

For each ADR, extract:
1. **Core Decision**: The actual rule or decision made
2. **Behavioral Impact**: How this affects development/agent behavior
3. **Reference**: Link to full ADR document

Format each decision as:
```markdown
### [Decision Title]
**Decision**: [Concise statement of what must be done]
**Impact**: [How this affects behavior/development]
**Details**: [ADR-XXX](decisions/ADR-XXX-title.md)
```

### 8. Eliminate Duplication

Check for and remove any duplicated content:
- Ensure submodule descriptions appear in only one place
- Remove repeated feature lists or capabilities
- Consolidate technology stack mentions to architecture.md
- Keep each document focused on its specific purpose

### 9. Validate Updates

Verify each document:
- [ ] what-do-we-build.md contains only vision/goals
- [ ] architecture.md contains only technical design
- [ ] blueprint.md contains only file structure
- [ ] decisions.md contains actionable decisions from ADRs
- [ ] No content is duplicated across documents
- [ ] All documents reflect current repository state

### 10. Run Ownership Validation

If ownership model exists, validate all documents:
```bash
# Run validation script
if [[ -f "$ownership_file" ]]; then
    validate-context --preset project
    if [ $? -eq 0 ]; then
        echo "✅ All documents comply with ownership model"
    else
        echo "❌ Ownership violations detected - review and fix"
    fi
fi
```

### 11. Commit Changes

Create atomic commits for each document:
```bash
git add docs/what-do-we-build.md
git commit -m "docs: update project vision and features"

git add docs/architecture.md
git commit -m "docs: update technical architecture"

git add docs/blueprint.md
git commit -m "docs: update file structure documentation"

git add docs/decisions.md
git commit -m "docs: update actionable decisions from ADRs"
```

## Success Criteria

- All four context documents are current and accurate
- Each document maintains its specific focus without overlap
- No duplication exists between documents
- decisions.md accurately summarizes all ADRs with actionable guidance
- Changes are committed with clear messages

## Common Patterns

### Adding a New Feature
1. Update what-do-we-build.md with high-level feature description
2. Update architecture.md if it introduces new technical patterns
3. Update blueprint.md if new directories/files were added

### New Architecture Decision
1. Scan docs/decisions/ for new ADR files
2. Extract the core decision and its impact
3. Add to decisions.md with proper formatting

### Directory Reorganization
1. Update blueprint.md with new structure
2. Update architecture.md if it affects system design
3. Check if changes reflect completed roadmap items

## Error Handling

**Missing Documents:**
- Create missing documents using appropriate templates
- Focus on extracting relevant information from existing files

**Conflicting Information:**
- Identify source of truth (usually the code itself)
- Update all documents to reflect correct state
- Note conflicts in commit messages

**Large Changes:**
- Break updates into logical sections
- Create separate commits for major changes
- Consider updating documents incrementally

---

This workflow ensures the core context documents remain accurate, focused, and valuable for both human developers and AI agents navigating the project.
