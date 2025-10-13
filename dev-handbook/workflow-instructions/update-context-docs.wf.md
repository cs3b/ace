# Workflow Instruction: Update Context Documents

**Goal:** Analyze repository changes and update the core context documents ensuring they remain accurate, focused, and free of duplication.

> **Note:** This workflow can now be enhanced with the `ace-docs` tool for automated document management.
> See `ace-docs/handbook/workflow-instructions/update-docs.wf.md` for the tooling-based approach.
> Use `/update-docs` command for the automated workflow.

## Prerequisites

* Write access to context documents in `docs/` directory
* Understanding of each document's specific purpose
* Access to Git for analyzing changes

## Project Context Loading

- Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`

## Core Context Documents

This workflow maintains five essential project documents, each with a distinct purpose.

**IMPORTANT: Update documents in this exact order to prevent duplication:**

1. **`docs/what-do-we-build.md`** - Vision & Goals (UPDATE FIRST)
   - Brief project overview (1 paragraph)
   - Current capabilities (one line each)
   - Coming soon features (one line each)
   - Vision statement
   **Target**: ~30 lines maximum

   **MUST NOT CONTAIN:**
   - Technical implementation details
   - Architecture or design principles
   - Directory structures or file paths
   - Tool usage instructions
   - User personas or use cases
   - Verbose descriptions

2. **`docs/blueprint.md`** - Navigation Guide (UPDATE SECOND)
   - Simple top-level directory list
   - Read-only paths for AI agents
   - Ignored paths for normal operations
   **Target**: ~50 lines

   **MUST NOT CONTAIN:**
   - Project vision or goals (in what-do-we-build.md)
   - Architecture patterns or decisions
   - Tool usage instructions
   - References to `git ls-files` or `eza`
   - Detailed file listings

3. **`docs/architecture.md`** - Technical Design (UPDATE THIRD)
   - ATOM architecture pattern
   - Component types (tools, workflows, agents, guides)
   - Key architectural decisions with ADR references
   - AI integration architecture
   - Reference to blueprint.md for file structure
   **Target**: ~150 lines

   **MUST NOT CONTAIN:**
   - Project vision (in what-do-we-build.md)
   - Directory trees (in blueprint.md)
   - Setup instructions (move to mise tasks)
   - Tool usage examples
   - Performance metrics or implementation details

4. **`docs/tools.md`** - Command Reference (UPDATE FOURTH)
   - Current tools only with practical examples
   - Brief usage examples (2-4 per tool)
   - Table of available commands
   **Target**: ~30 lines

   **MUST NOT CONTAIN:**
   - Future/planned tools (in what-do-we-build.md)
   - Architecture explanations (in architecture.md)
   - Setup instructions
   - Configuration details

5. **`docs/decisions.md`** - Actionable Decisions (UPDATE LAST)
   - Condensed, actionable decisions from ADRs
   - Behavioral impacts for AI agents and developers
   - Links to full ADR documents

   **MUST NOT CONTAIN:**
   - Content from any previous document
   - Full ADR content
   - Implementation details

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
- `docs/blueprint.md`
- `docs/architecture.md`
- `docs/tools.md`
- `docs/decisions.md` (if exists)

### 3. Identify Required Updates

Based on repository analysis, determine updates needed for each document:

| Change Type | Affected Documents |
|------------|-------------------|
| New features/capabilities | what-do-we-build.md |
| Directory/file reorganization | blueprint.md |
| Architecture/design changes | architecture.md |
| New tools or commands | tools.md |
| New ADRs or decisions | decisions.md |
| Technology stack updates | architecture.md |
| Build/setup changes | Remove from docs, create mise task |

### 4. Update what-do-we-build.md (FIRST)

Keep ultra-compact:
- One paragraph overview
- Current capabilities (one line each)
- Coming soon features (one line each)
- Vision statement

**Remove if present:**
- User personas and use cases
- Verbose descriptions
- Any content that will appear in subsequent documents
- Keep under 30 lines total

### 5. Update blueprint.md (SECOND)

Navigation guidance only:
- Simple top-level directory list
- Read-only paths
- Ignored paths

**Check against what-do-we-build.md:**
- Remove any duplicated content
- Keep under 50 lines total

### 6. Update architecture.md (THIRD)

Focus on patterns and decisions:
- ATOM architecture explanation
- Component types
- Key architectural decisions
- AI integration patterns

**Check against previous documents:**
- Remove any content from what-do-we-build.md
- Remove any content from blueprint.md
- Reference blueprint.md for structure
- Keep under 150 lines total

### 7. Update tools.md (FOURTH)

Current tools only:
- Table of available commands
- 2-4 practical examples per tool
- No future/planned tools

**Check against previous documents:**
- Remove any content covered in previous docs
- Keep under 30 lines total

### 8. Generate/Update decisions.md (LAST)

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

### 9. Eliminate Duplication

**Critical: Check each document against all previous ones:**
- No content should appear in multiple documents
- Use cross-references instead of repeating
- Later documents must not duplicate earlier ones
- Each document must serve its distinct purpose

### 10. Validate Updates

Verify each document:
- [ ] what-do-we-build.md is ultra-compact (~30 lines)
- [ ] blueprint.md has navigation guidance only (~50 lines)
- [ ] architecture.md focuses on patterns/decisions (~150 lines)
- [ ] tools.md has current tools only (~30 lines)
- [ ] decisions.md contains actionable ADR summaries
- [ ] NO content is duplicated across documents
- [ ] Update order was followed: vision → blueprint → architecture → tools → decisions

### 11. Run Ownership Validation

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

### 12. Commit Changes

Create atomic commits for each document (in update order):
```bash
git add docs/what-do-we-build.md
git commit -m "docs: update project vision and features"

git add docs/blueprint.md
git commit -m "docs: update navigation and restrictions"

git add docs/architecture.md
git commit -m "docs: update technical architecture"

git add docs/tools.md
git commit -m "docs: update command reference"

git add docs/decisions.md
git commit -m "docs: update actionable decisions from ADRs"
```

## Success Criteria

- All five context documents are current and accurate
- Documents are compact: what-do-we-build (~30), blueprint (~50), architecture (~150), tools (~30)
- Update order was followed: vision → blueprint → architecture → tools → decisions
- NO duplication exists between documents
- Each document maintains its specific focus
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
