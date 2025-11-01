---
id: v.0.9.0+task.094
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Enhance ace-review with context.md pattern and PR workflow

## Behavioral Specification

### User Experience

**Input**: Users invoke ace-review commands with existing CLI interface (no changes required)
**Process**: System internally creates context.md with ace-context configuration, loads context via ace-context, and generates reviews with enhanced reproducibility
**Output**: Review sessions include context.md artifact enabling exact session reproduction, plus optional workflow guidance for PR creation

### Expected Behavior

#### Context Management Enhancement (ace-docs Pattern Adoption)

**Context Creation Workflow:**
1. User runs ace-review with any preset (e.g., `ace-review --preset pr --subject 'diff: {...}' --auto-execute`)
2. System creates context.md with YAML frontmatter containing:
   - ace-context configuration (`context:` key with `files:`, `presets:`, `diffs:`, `commands:`)
   - Format specification (`params: {format: markdown-xml}`)
   - Base instructions and review scope
3. System saves context.md to session directory
4. System invokes `Ace::Context.load_file_as_preset(context_md_path)` to embed all content
5. Embedded content becomes the user prompt sent to LLM
6. Review completes with context.md preserved for reproducibility

**Context.md Structure:**
```markdown
---
context:
  params:
    format: markdown-xml
  presets: [project]  # From --context or preset config
  files:
    - /path/to/additional/file.md
  diffs:
    - range: origin/main...HEAD
      filter: "lib/**/*.rb"
  commands:
    - git log --oneline -5
---

# Code Review Instructions

[Base instructions from preset and composition]

## Review Scope

**Context files** (for understanding the codebase):
- Loaded from preset: `project`

**Subject of review** (git diff filtered to):
- `lib/**/*.rb`
- `spec/**/*_spec.rb`

**Focus areas**: [From preset configuration]
```

**System Behavior:**
- ContextExtractor completely replaced with ace-context integration
- All context extraction delegated to ace-context (no direct file reading, git operations)
- Session artifacts enhanced:
  - `context.md` - Frontmatter + instructions (NEW, replaces context.md.tmp)
  - `prompt-system.md` - System prompt
  - `prompt-user.md` - Embedded content from ace-context
  - `subject.diff` - Subject diffs (if applicable)
  - `review-report.md` - LLM output
  - `metadata.yml` - Session metadata

**Benefits:**
- **Reproducibility**: Anyone can re-run exact review by loading context.md
- **Transparency**: All context sources visible in single file
- **Consistency**: Same pattern across ace-docs and ace-review
- **Simplicity**: Eliminates code duplication (FileReader, GitExtractor no longer needed)
- **Extensibility**: Leverages full ace-context capabilities (presets, commands, diffs)

#### PR Creation Workflow (Documentation)

**Workflow Documentation:**
New workflow instruction file documents the PR creation process:

**File**: `ace-review/handbook/workflow-instructions/review-create-pr.wf.md`

**Documented Steps:**
1. **Generate PR Description**:
   ```bash
   ace-review --preset pr-description \
     --subject 'diff: {ranges: ["origin/main...HEAD"]}' \
     --context 'presets: [project]' \
     --auto-execute
   ```

2. **Extract Title and Body**:
   ```bash
   # Parse review output from session directory
   review_file=".ace-taskflow/v.0.9.0/reviews/review-<timestamp>/review-report.md"

   # Extract title (first heading)
   title=$(grep -m1 "^# " "$review_file" | sed 's/^# //')

   # Extract body (everything after title)
   body=$(sed '1,/^# /d' "$review_file")
   ```

3. **Create PR**:
   ```bash
   gh pr create --title "$title" --body "$body"
   ```

4. **Output**: PR URL returned by gh CLI

**Preset Configuration:**
New or enhanced preset for PR description generation:

**File**: `.ace/review/presets/pr-description.yml` (or enhance existing `pr` preset)

```yaml
composition:
  base: base
  format: pr-description
  focus: [changes-summary, impact-analysis]
  guidelines: [pr-best-practices]

subject:
  diff:
    ranges: ["origin/main...HEAD"]  # Default to current branch

context:
  presets: [project]  # Load project context for understanding

options:
  auto_execute: true  # Default to immediate execution
```

**Workflow Integration:**
- Users can manually follow workflow steps
- No new CLI commands required (keeps ace-review focused on review generation)
- Leverages existing ace-review preset system
- Compatible with any git hosting (GitHub, GitLab, etc.) via documented pattern

### Interface Contract

**CLI Interface (No Breaking Changes):**

```bash
# Existing commands work identically (context.md creation is internal)
ace-review --preset pr --subject 'diff: {ranges: ["origin/main...HEAD"]}' --auto-execute
ace-review --preset security --subject 'files: ["lib/**/*.rb"]' --context 'presets: [project]'
ace-review --preset ruby-atom --subject 'recent-commits: 5'

# PR creation via workflow (manual steps documented)
# Step 1: Generate description
ace-review --preset pr-description --auto-execute

# Step 2: Extract and create PR (user executes)
gh pr create --title "..." --body "$(extract_from_review)"
```

**Session Artifacts:**

```
.ace-taskflow/v.0.9.0/reviews/review-20251101-153000/
├── context.md              # YAML frontmatter + instructions + config
├── prompt-system.md        # System prompt (review focus, guidelines)
├── prompt-user.md          # Embedded content from ace-context
├── subject.diff            # Extracted diffs (if applicable)
├── review-report.md        # LLM-generated review output
└── metadata.yml            # Session metadata (timestamp, preset, model, etc.)
```

**Error Handling:**

- **ace-context fails to load preset**: Report error, show which preset/file failed
- **context.md invalid YAML**: Report parsing error, show line number
- **ace-context not available**: Report dependency error, suggest installation
- **gh CLI not available** (for PR workflow): Report tool missing, provide installation link

**Edge Cases:**

- **No context specified**: Create context.md with empty context config, proceed with subject only
- **Large diffs**: ace-context handles truncation, report in metadata.yml
- **Missing subject**: Error before creating context.md (existing behavior)
- **PR workflow on non-git repo**: Workflow fails at `gh pr create`, user sees git error
- **Multiple ranges in diff**: ace-context combines all ranges, noted in context.md

### Success Criteria

**Context Management:**
- [ ] **Context.md Always Created**: Every ace-review session creates context.md with YAML frontmatter
- [ ] **ace-context Integration**: Context loading uses `Ace::Context.load_file_as_preset()`
- [ ] **ContextExtractor Removed**: Old extraction logic completely replaced
- [ ] **Session Reproducibility**: Running `ace-context /path/to/session/context.md` reproduces exact context
- [ ] **Preset Compatibility**: All existing presets work with new context.md pattern
- [ ] **Format Flexibility**: context.md supports markdown-xml, markdown, yaml, json formats

**PR Creation Workflow:**
- [ ] **Workflow Documented**: review-create-pr.wf.md provides clear step-by-step process
- [ ] **Preset Available**: pr-description preset generates structured PR descriptions
- [ ] **Integration Examples**: Workflow shows examples with different git hosts
- [ ] **Error Guidance**: Workflow documents common errors and solutions

### Validation Questions

**Context Management:**
- [ ] **Frontmatter Content**: Should context.md include base instructions below frontmatter, or only YAML config?
- [ ] **Preset Migration**: Should we update existing presets to leverage ace-context features (e.g., preset composition)?
- [ ] **Error Reporting**: How should ace-context errors be surfaced to users? (inline, separate error file, stderr)
- [ ] **Backward Compatibility**: Should we support reading old session formats for reproduction?

**PR Creation Workflow:**
- [ ] **Preset Configuration**: Should pr-description be a new preset or enhancement to existing `pr` preset?
- [ ] **Output Format**: What structure should PR descriptions follow? (conventional commits, custom format, configurable)
- [ ] **Title Extraction**: How should title be determined? (first commit message, inferred from changes, user prompt)
- [ ] **Multi-commit PRs**: How should workflow handle PRs with many commits? (summarize all, group by type, list individually)

## Objective

Transform ace-review's context management to match ace-docs' proven pattern, enhancing reproducibility and consistency across ACE tools, while adding documented workflow guidance for common PR creation use case.

**Why**:
- **Current Context Management**: ContextExtractor duplicates logic already in ace-context, lacks reproducibility
- **Current PR Creation**: Users must manually piece together reviews into PRs, no clear guidance
- **ace-docs Pattern**: Proven approach with context.md + ace-context provides transparency and reproducibility

**Benefits**:
- **Reproducibility**: context.md captures complete session configuration for exact reproduction
- **Consistency**: Same pattern across ace-docs and ace-review reduces learning curve
- **Simplicity**: Eliminates code duplication, leverages ace-context capabilities fully
- **Transparency**: All context sources visible in single human-readable file
- **Extensibility**: PR workflow demonstrates review-to-action pattern for other use cases

## Scope of Work

### User Experience Scope

**Context Management:**
- Internal context.md creation (transparent to users)
- Enhanced session artifacts for reproducibility
- No changes to CLI interface
- Improved error messages from ace-context

**PR Creation:**
- Workflow documentation for manual PR creation
- Preset configuration for PR description generation
- Integration examples with gh CLI
- Error guidance and troubleshooting

### System Behavior Scope

**Context Management:**
- context.md file generation with YAML frontmatter
- ace-context integration replacing ContextExtractor
- Session artifact management (save context.md, embedded prompts)
- Error handling for ace-context failures

**PR Creation:**
- Workflow instruction creation
- Preset configuration (pr-description)
- Output format specification for PR descriptions
- Integration pattern documentation

### Interface Scope

- No CLI changes (context.md creation is internal)
- Enhanced session directory structure
- Workflow documentation (review-create-pr.wf.md)
- Preset configuration (pr-description.yml)

### Deliverables

#### Behavioral Specifications
- User experience flows for context.md creation and PR workflow
- System behavior for ace-context integration
- Interface contracts for session artifacts and workflow steps

#### Validation Artifacts
- Success criteria for context management and PR workflow
- Validation questions for implementation decisions
- Error handling scenarios and edge cases

## Out of Scope

- ❌ **CLI Command for PR Creation**: No new `ace-review create-pr` command (workflow documentation only)
- ❌ **Automatic PR Creation**: No automated PR creation (users execute `gh pr create` manually)
- ❌ **Git Host Integration**: No direct GitHub/GitLab API integration (uses gh CLI pattern)
- ❌ **ContextExtractor Preservation**: Old extraction logic will be completely removed (not maintained)
- ❌ **Legacy Session Format Support**: No reading old session formats (forward-only migration)
- ❌ **Multiple Format Support**: context.md uses markdown-xml format only (not configurable)

## References

- Source ideas:
  - `.ace-taskflow/v.0.9.0/ideas/done/20251023-210928-ace-review-should-use-contextmd-similar-to-how-ac.md`
  - `.ace-taskflow/v.0.9.0/ideas/done/20251025-104802-ace-review-should-have-a-workflow-for-create-pr-i.md`
- ace-docs context.md pattern: `/Users/mc/Ps/ace-meta/ace-docs/lib/ace/docs/prompts/document_analysis_prompt.rb`
- ace-context implementation: `/Users/mc/Ps/ace-meta/ace-context/exe/ace-context`
- Current ace-review: `/Users/mc/Ps/ace-meta/ace-review/exe/ace-review`
- ContextExtractor: `/Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/context_extractor.rb`
- ReviewManager: `/Users/mc/Ps/ace-meta/ace-review/lib/ace/review/organisms/review_manager.rb`
