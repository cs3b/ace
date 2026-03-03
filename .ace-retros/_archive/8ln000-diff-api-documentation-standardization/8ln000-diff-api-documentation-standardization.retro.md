---
id: 8ln000
title: 'Retro: diff/diffs API Documentation Standardization'
type: conversation-analysis
tags: []
created_at: '2025-10-24 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ln000-diff-api-documentation-standardization.md"
---

# Retro: diff/diffs API Documentation Standardization

**Date**: 2025-10-24
**Context**: Discovered and fixed inconsistent API documentation across ace-git-diff, ace-context, ace-docs, and ace-review packages. The documentation showed old array format (`diffs: ["range"]`) instead of the new ace-git-diff hash format (`diff: {ranges: ["range"]}`).
**Author**: Development Team
**Type**: Conversation Analysis

## What Went Well

- **Comprehensive search and fix**: Successfully updated 7 documentation files across 4 packages
- **Systematic approach**: Used TodoWrite tool to track progress through 8 distinct update tasks
- **Complete release workflow**: Successfully executed full ace-release workflow including version bumps for 4 packages
- **Coordinated commits**: Created 6 well-structured commits following conventional commit format
- **Workflow adherence**: Properly followed ace-bump-version and ace-update-changelog workflows

## What Could Be Improved

- **Discovery delay**: Documentation inconsistency existed since ace-git-diff integration but wasn't caught until user pointed it out
- **Search coverage**: Initial grep searches didn't find all instances (missed ace-docs usage.md examples)
- **Test coverage gap**: No automated tests validate documentation examples
- **API migration communication**: No clear migration guide or deprecation warnings in documentation initially

## Key Learnings

### Why Tests Didn't Catch This

1. **Documentation is not tested**: No automated validation of code examples in markdown files
2. **Integration tests focus on code**: Tests verify that both `diff:` and `diffs:` keys work, but don't validate documentation consistency
3. **Example validation gap**: No CI check to ensure documentation examples match current API patterns

### Why Search Didn't Find Everything Initially

1. **Multiple search passes needed**: First search for `diffs: [` found most instances, but `filters:` in ace-docs required domain knowledge
2. **Context-dependent patterns**: ace-docs used `filters:` which should be `paths:` - this required understanding the ace-git-diff API
3. **Cached context issue**: The `.cache/ace-context/project.md` was stale and needed regeneration

### What We Can Do About It

**Immediate Actions:**
1. **Documentation linting**: Create lint rules to validate API examples in markdown
2. **Migration guide**: Add clear migration section to ace-git-diff README
3. **Deprecation warnings**: Add clear deprecation notices in code comments

**Process Improvements:**
1. **Documentation review checklist**: When changing APIs, systematically check all documentation
2. **Cross-package search**: Develop search patterns that check all package docs when APIs change
3. **Integration tests for docs**: Add tests that parse markdown examples and validate syntax

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **API Format Confusion**: Documentation showed two conflicting formats without clear guidance
  - Occurrences: 12+ instances across 4 packages
  - Impact: User confusion about correct API usage, potential production code using deprecated format
  - Root Cause: API evolved from simple array to structured hash, documentation not updated systematically

- **Search Incompleteness**: Initial searches missed some documentation files
  - Occurrences: 2 files (ace-docs usage.md, workflow file)
  - Impact: Required multiple search passes and user guidance
  - Root Cause: Different terminology (`filters:` vs `paths:`) and multiple documentation locations

#### Medium Impact Issues

- **Cached Context Staleness**: Generated context file contained outdated examples
  - Occurrences: 1 instance
  - Impact: Users loading context got incorrect information
  - Root Cause: Context cache not automatically regenerated after documentation changes

#### Low Impact Issues

- **Git lock file conflicts**: Multiple `index.lock` errors during rapid commits
  - Occurrences: 3 instances during version bumps
  - Impact: Minor delays requiring lock file removal
  - Root Cause: Rapid sequential git operations

### Improvement Proposals

#### Process Improvements

1. **API Change Checklist**: When changing an API:
   ```markdown
   - [ ] Update primary package README
   - [ ] Update workflow instructions
   - [ ] Update example configurations
   - [ ] Update integration package docs
   - [ ] Regenerate cached context
   - [ ] Add migration guide section
   - [ ] Mark old format as deprecated
   ```

2. **Documentation Validation**:
   - Add CI job to extract and validate code examples from markdown
   - Use tool like `markdown-code-runner` to test embedded code blocks
   - Validate YAML examples against schema

3. **Cross-Package Documentation Review**:
   - When changing ace-X, search for references in ace-Y, ace-Z
   - Maintain a "which packages depend on this API" matrix
   - Automate cross-package grep in CI

#### Tool Enhancements

1. **ace-docs validate command**:
   ```bash
   ace-docs validate --check-examples
   # Parse markdown files, extract code blocks, validate syntax
   ```

2. **ace-search enhancement**: Add `--packages` flag to search across specific packages:
   ```bash
   ace-search "diffs:" --packages "ace-context,ace-review,ace-docs"
   ```

3. **Documentation diff tool**: Show what documentation changed between versions:
   ```bash
   ace-docs diff v0.15.0..v0.15.1
   # Shows doc changes, highlights API changes
   ```

#### Communication Protocols

1. **API Deprecation Standard**:
   - Always show both old and new format with clear labels
   - Include "⚠️ DEPRECATED" warnings
   - Provide migration script or clear steps
   - Set deprecation timeline

2. **Release Notes Enhancement**:
   - Dedicated "API Changes" section
   - Include before/after examples
   - Link to migration guide

### Token Limit & Truncation Issues

- **Large Output Instances**: None in this session
- **Truncation Impact**: None observed
- **Mitigation Applied**: N/A
- **Prevention Strategy**: Used targeted greps with head limits to avoid large outputs

## Action Items

### Stop Doing

- Assuming documentation is correct after code changes
- Single-pass searches for documentation updates
- Treating documentation as "just comments" that don't need testing

### Continue Doing

- Using TodoWrite for tracking multi-step tasks
- Systematic approach to cross-package updates
- Following structured workflows (ace-bump-version, ace-release)
- Creating atomic commits with clear messages
- Regenerating cached context after documentation changes

### Start Doing

1. **Documentation Testing**:
   - Extract code examples from markdown
   - Validate YAML syntax in documentation
   - Test that documented commands actually work

2. **API Change Protocol**:
   - Create API change checklist workflow
   - Document which packages reference each API
   - Automated cross-package documentation search

3. **Deprecation Management**:
   - Add clear deprecation warnings in code
   - Create migration guides for API changes
   - Version documentation to show current vs deprecated

4. **Search Improvements**:
   - Use multiple search terms (`diffs:`, `diff:`, `filters:`, `paths:`)
   - Search across all packages when changing shared APIs
   - Verify cached context reflects current state

## Technical Details

**Files Updated:**
- docs/tools.md
- ace-git-diff/README.md
- ace-context/README.md
- ace-review/README.md
- ace-review/handbook/workflow-instructions/review.wf.md
- ace-docs/docs/usage.md
- ace-docs/handbook/workflow-instructions/update-docs.wf.md

**Version Bumps:**
- ace-git-diff: 0.1.0 → 0.1.1
- ace-context: 0.15.0 → 0.15.1
- ace-docs: 0.6.0 → 0.6.1
- ace-review: 0.11.0 → 0.11.1

**Root Cause Analysis:**

The inconsistency arose because:
1. ace-git-diff was created to extract and centralize diff functionality
2. The API evolved from simple arrays to structured hashes to support more options
3. Documentation in dependent packages (ace-context, ace-review, ace-docs) was not systematically updated
4. No automated validation of documentation examples
5. Tests verify code works but not that documentation matches implementation

**Prevention Strategy:**

Future API changes should:
- Include documentation update checklist
- Use automated tools to find all references
- Add deprecation warnings in code and docs
- Create migration guides
- Validate documentation examples in CI