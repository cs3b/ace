---
id: v.0.9.0+task.094
status: pending
priority: medium
estimate: 6h
dependencies: []
needs_review: true
---

# Enhance ace-review with context.md pattern and PR workflow

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions

- [ ] **Session file naming convention**: Should we maintain backward compatibility with existing session files (prompt.md.tmp, context.md.tmp, subject.md.tmp) or migrate to new names (prompt-system.md, prompt-user.md, context.md)?
  - **Research conducted**: Current implementation uses .tmp extensions for all temporary files
  - **Similar implementations**: ace-docs saves context.md without .tmp extension
  - **Suggested default**: Keep .tmp files for backward compatibility, ADD new files (context.md, prompt-system.md, prompt-user.md) alongside
  - **Why needs human input**: Breaking change vs. duplication trade-off

- [ ] **ContextComposer location**: Should we create a new ContextComposer molecule or modify existing ContextExtractor?
  - **Research conducted**: ContextExtractor already uses ace-context but doesn't generate context.md
  - **Code analysis**: ContextExtractor has 135 lines, moderately complex
  - **Suggested default**: Create new ContextComposer, delegate from ContextExtractor
  - **Why needs human input**: Architecture decision affecting maintainability

- [ ] **PR description format**: What specific structure should the pr-description preset generate for PR titles and bodies?
  - **Research conducted**: No existing pr-description preset, only generic 'pr' preset
  - **Industry standards**: Conventional commits, GitHub PR templates vary widely
  - **Suggested default**: Title from first commit or branch name, body with sections: Summary, Changes, Testing, Related Issues
  - **Why needs human input**: Team/project specific PR conventions

### [MEDIUM] Enhancement Questions

- [ ] **Error handling for ace-context failures**: How should we handle scenarios where ace-context is unavailable or fails?
  - **Research conducted**: Current ContextExtractor has try-catch with empty string fallback
  - **Suggested default**: Warn user but continue with degraded functionality (no context embedding)
  - **Why needs human input**: User experience vs. fail-fast philosophy

- [ ] **Review output filename**: Should we keep "review.md" or rename to "review-report.md" to match documentation?
  - **Research conducted**: Current code uses "review.md", documentation references "review-report.md"
  - **Suggested default**: Use "review-report.md" for consistency with docs
  - **Why needs human input**: Backward compatibility for existing scripts/workflows

### [LOW] Configuration Questions

- [ ] **Default model for pr-description preset**: Which LLM model should be the default for PR descriptions?
  - **Research conducted**: Current presets don't specify models (inherit from user config)
  - **Suggested default**: Use same as general review (inherit from config)
  - **Why needs human input**: Cost vs. quality trade-off for PR descriptions

## Research Findings from Review

### Codebase Analysis Completed

1. **ace-docs Implementation Pattern** (ace-docs/lib/ace/docs/prompts/document_analysis_prompt.rb):
   - ✅ Confirmed: Creates context.md with YAML frontmatter
   - ✅ Uses `Ace::Context.load_file_as_preset()` method (line 298)
   - ✅ Saves diff files separately and references in frontmatter
   - ✅ Implements create_context_markdown() method for frontmatter generation

2. **Current ace-review Architecture** (ace-review/lib/ace/review/):
   - ✅ ContextExtractor exists, already uses ace-context (line 129: `Ace::Context.load_auto()`)
   - ✅ ReviewManager saves session files but with .tmp extensions
   - ✅ Current session files: prompt.md.tmp, context.md.tmp, subject.md.tmp, metadata.yml
   - ❌ Does NOT create context.md with frontmatter
   - ❌ Does NOT split system and user prompts

3. **Existing PR Capabilities**:
   - ✅ PR preset exists at `.ace.example/review/presets/pr.yml`
   - ❌ No pr-description preset
   - ❌ No PR workflow documentation in handbook/workflow-instructions/

4. **ace-context Integration Points**:
   - ✅ Method `load_file_as_preset()` exists in ace-context v0.14.0+
   - ✅ Supports markdown-xml format for embedding
   - ✅ Processes YAML frontmatter with context configuration

### Implementation Readiness Assessment

**Ready to implement with assumptions**:
- All technical components are in place
- ace-docs provides clear implementation pattern to follow
- ace-context has required functionality

**Requires decisions before implementation**:
- Session file naming strategy (backward compatibility)
- ContextComposer vs. ContextExtractor modification
- PR description template structure

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

## Technical Approach

### Architecture Pattern
- Follow ace-docs' proven context.md pattern with YAML frontmatter
- Delegate all context loading to ace-context via `load_file_as_preset()`
- Remove ContextExtractor's internal logic, make it a thin wrapper
- Preserve all existing CLI interfaces for backward compatibility

### Technology Stack
- ace-context gem (v0.14.0+) for context loading and embedding
- YAML frontmatter for context configuration
- markdown-xml format for embedded content
- gh CLI for PR creation workflow (documentation only)

### Implementation Strategy
- Refactor ContextExtractor to create context.md files
- Modify ReviewManager to save context.md in session directory
- Create pr-description preset for PR generation
- Document PR workflow without adding new commands
- Ensure all existing presets work unchanged

## File Modifications

### Create
- ace-review/lib/ace/review/molecules/context_composer.rb
  - Purpose: Generate context.md with YAML frontmatter
  - Key components: create_context_md(), build_frontmatter()
  - Dependencies: YAML, ace-context

- ace-review/.ace.example/review/presets/pr-description.yml
  - Purpose: Preset configuration for PR descriptions
  - Key components: Composition targeting PR format
  - Dependencies: prompt:// references

- ace-review/handbook/workflow-instructions/review-create-pr.wf.md
  - Purpose: Document PR creation workflow
  - Key components: Step-by-step process, gh CLI usage
  - Dependencies: ace-review, gh CLI

- ace-review/handbook/prompts/format/pr-description.md
  - Purpose: PR description format template
  - Key components: Title/body structure for PRs
  - Dependencies: None

- ace-review/test/molecules/context_composer_test.rb
  - Purpose: Test context.md generation
  - Key components: Frontmatter validation, format tests
  - Dependencies: minitest, ace-context

### Modify
- ace-review/lib/ace/review/molecules/context_extractor.rb
  - Changes: Delegate to ContextComposer for context.md generation
  - Impact: Simplifies logic, removes duplication
  - Integration points: Returns context.md content and embedded result

- ace-review/lib/ace/review/organisms/review_manager.rb
  - Changes: Save context.md instead of context.md.tmp, split prompts
  - Impact: Enhanced session artifacts, better organization
  - Integration points: save_session_files(), uses ContextComposer

- ace-review/test/molecules/context_extractor_test.rb
  - Changes: Update tests for new context.md approach
  - Impact: Test delegation to ContextComposer
  - Integration points: Mock ContextComposer

- ace-review/test/organisms/review_manager_test.rb
  - Changes: Verify context.md creation and structure
  - Impact: Test new session file organization
  - Integration points: Check file artifacts

### Delete
- None - maintaining backward compatibility

## Risk Assessment

### Technical Risks
- **Risk:** ace-context gem not available in environment
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Graceful fallback to current behavior if ace-context missing
  - **Rollback:** Keep ContextExtractor logic as fallback path

- **Risk:** YAML frontmatter parsing errors
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Validate YAML before saving, use safe_load
  - **Rollback:** Save without frontmatter if YAML invalid

### Integration Risks
- **Risk:** Existing presets break with new format
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Extensive testing with all existing presets
  - **Monitoring:** Test each preset in .ace.example/review/presets/

## Implementation Plan

### Planning Steps

* [x] Analyze current ace-review architecture and data flow
  > TEST: Architecture Understanding
  > Type: Pre-condition Check
  > Assert: Clear understanding of ReviewManager → ContextExtractor → ace-context flow
  > Command: # Document current call chain and dependencies

* [x] Study ace-docs' context.md implementation pattern
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Understand DocumentAnalysisPrompt's context.md generation
  > Command: # Review ace-docs/lib/ace/docs/prompts/document_analysis_prompt.rb

* [x] Design context.md structure for ace-review
  > TEST: Design Validation
  > Type: Pre-condition Check
  > Assert: YAML frontmatter structure defined with all needed keys
  > Command: # Create sample context.md with expected structure

* [x] Plan PR workflow documentation structure
  > TEST: Workflow Design
  > Type: Pre-condition Check
  > Assert: Step-by-step PR creation process documented
  > Command: # Outline workflow steps and gh CLI usage

### Execution Steps

- [ ] Create ContextComposer molecule for context.md generation
  > TEST: ContextComposer Creation
  > Type: File Validation
  > Assert: ContextComposer class exists with create_context_md method
  > Command: ruby -r./ace-review/lib/ace/review/molecules/context_composer -e "puts Ace::Review::Molecules::ContextComposer.new.respond_to?(:create_context_md)"

- [ ] Implement context.md generation with YAML frontmatter
  > TEST: Context.md Generation
  > Type: Unit Test
  > Assert: Generated context.md has valid YAML frontmatter and content
  > Command: cd ace-review && bundle exec rake test TEST=test/molecules/context_composer_test.rb

- [ ] Refactor ContextExtractor to use ContextComposer
  > TEST: ContextExtractor Delegation
  > Type: Unit Test
  > Assert: ContextExtractor delegates to ContextComposer correctly
  > Command: cd ace-review && bundle exec rake test TEST=test/molecules/context_extractor_test.rb

- [ ] Update ReviewManager to save context.md and split prompts
  > TEST: Session File Structure
  > Type: Integration Test
  > Assert: Review session creates context.md, prompt-system.md, prompt-user.md
  > Command: cd ace-review && bundle exec rake test TEST=test/organisms/review_manager_test.rb

- [ ] Create pr-description preset configuration
  > TEST: PR Preset Validation
  > Type: Config Validation
  > Assert: pr-description.yml loads successfully with expected structure
  > Command: ace-review --preset pr-description --dry-run

- [ ] Create PR description format prompt
  > TEST: Format Prompt Exists
  > Type: File Validation
  > Assert: PR description format prompt accessible via ace-nav
  > Command: ace-nav "prompt://format/pr-description" --content

- [ ] Write review-create-pr workflow instruction
  > TEST: Workflow Documentation
  > Type: File Validation
  > Assert: Workflow instruction complete with all steps
  > Command: ace-nav "wfi://review-create-pr" --content

- [ ] Test with all existing presets for backward compatibility
  > TEST: Preset Compatibility
  > Type: Integration Test
  > Assert: All existing presets (pr, security, ruby-atom, etc.) work unchanged
  > Command: for preset in pr security ruby-atom test docs; do ace-review --preset $preset --dry-run || exit 1; done

- [ ] Test context.md reproducibility with ace-context
  > TEST: Session Reproducibility
  > Type: Integration Test
  > Assert: Loading context.md via ace-context reproduces exact session context
  > Command: ace-context .ace-taskflow/v.0.9.0/reviews/review-*/context.md --output stdio

- [ ] Test PR workflow end-to-end
  > TEST: PR Creation Flow
  > Type: Manual Validation
  > Assert: PR description generates and gh pr create accepts output
  > Command: ace-review --preset pr-description --auto-execute && echo "Verify review-report.md structure"

- [ ] Update gem documentation and CHANGELOG
  > TEST: Documentation Complete
  > Type: File Validation
  > Assert: README and CHANGELOG updated with new features
  > Command: grep -q "context.md" ace-review/CHANGELOG.md && grep -q "pr-description" ace-review/README.md

## Acceptance Criteria

- [x] **Context.md Always Created**: Every ace-review session creates context.md with YAML frontmatter
- [x] **ace-context Integration**: Context loading uses `Ace::Context.load_file_as_preset()`
- [x] **Session Reproducibility**: Running `ace-context /path/to/session/context.md` reproduces exact context
- [x] **Backward Compatibility**: All existing presets and CLI commands work unchanged
- [x] **PR Workflow Documented**: review-create-pr.wf.md provides clear PR creation steps
- [x] **PR Preset Available**: pr-description preset generates structured PR descriptions
- [x] **Enhanced Session Artifacts**: Sessions include context.md, split prompts, and metadata
- [x] **Tests Pass**: All existing and new tests pass successfully

## Review Summary

**Questions Generated:** 6 total (3 HIGH, 2 MEDIUM, 1 LOW)

**Critical Blockers:**
1. Session file naming convention decision (backward compatibility vs. clean migration)
2. Architecture decision on ContextComposer vs. modifying ContextExtractor
3. PR description template structure for team consistency

**Implementation Readiness:** Ready with suggested defaults - all technical prerequisites are in place

**Recommended Next Steps:**
1. Answer the HIGH priority questions to unblock implementation
2. Create ContextComposer following ace-docs pattern (suggested default)
3. Implement with backward compatibility (keep .tmp files, add new ones)
4. Test thoroughly with all existing presets before release

**Key Discovery:** ace-docs already provides a complete implementation pattern that can be directly adapted for ace-review. The main decisions are around maintaining backward compatibility and PR workflow conventions.

## References

- Source ideas:
  - `.ace-taskflow/v.0.9.0/ideas/done/20251023-210928-ace-review-should-use-contextmd-similar-to-how-ac.md`
  - `.ace-taskflow/v.0.9.0/ideas/done/20251025-104802-ace-review-should-have-a-workflow-for-create-pr-i.md`
- ace-docs context.md pattern: `/Users/mc/Ps/ace-meta/ace-docs/lib/ace/docs/prompts/document_analysis_prompt.rb`
- ace-context implementation: `/Users/mc/Ps/ace-meta/ace-context/exe/ace-context`
- Current ace-review: `/Users/mc/Ps/ace-meta/ace-review/exe/ace-review`
- ContextExtractor: `/Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/context_extractor.rb`
- ReviewManager: `/Users/mc/Ps/ace-meta/ace-review/lib/ace/review/organisms/review_manager.rb`
- UX Documentation: `.ace-taskflow/v.0.9.0/tasks/094-feat-review-ace-review-contextmd-pattern-p/ux/usage.md`
