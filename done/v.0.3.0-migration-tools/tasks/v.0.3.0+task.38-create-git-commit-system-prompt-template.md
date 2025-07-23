---
id: v.0.3.0+task.38
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Create Git Commit System Prompt Template

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/.meta | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/.meta
    └── tpl
```

## Objective

Create a proper system prompt template for git commit message generation that embeds the complete version control system message guide using the XML documents embedding format, providing comprehensive context for LLM-generated commit messages that follow conventional commits specification.

## Scope of Work

- Create system prompt template in dev-handbook/.meta/tpl/
- Embed complete version control system message guide using XML documents format
- Structure system prompt for LLM commit message generation
- Update commit message generator to reference the new template file path

### Deliverables

#### Create

- dev-handbook/.meta/tpl/git-commit.system.prompt.md

#### Modify

- dev-tools/lib/coding_agent_tools/molecules/git/commit_message_generator.rb

## Phases

1. Design system prompt template structure
2. Create template file with embedded guidelines
3. Update commit message generator to use template
4. Test LLM-generated commit messages

## Implementation Plan

### Planning Steps

- [x] Review existing commit message generator implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current generator logic identified and system prompt integration points found
  > Command: Read commit_message_generator.rb and understand current prompting approach

- [x] Review version control system message guide content
  > TEST: Content Review
  > Type: Content Analysis
  > Assert: Guidelines and conventions from version-control-system-message.g.md are understood
  > Command: Already reviewed the content in dev-handbook/guides/version-control-system-message.g.md

- [x] Study documents embedding standards for proper XML format
  > TEST: Embedding Format Understanding
  > Type: Standards Review
  > Assert: XML documents embedding format from dev-handbook/guides/documents-embedding.g.md is understood
  > Command: Review and understand the universal <documents> container format requirements

### Execution Steps

- [x] Create git-commit.system.prompt.md template file with embedded version control guide
  > TEST: Template Creation
  > Type: File Creation
  > Assert: Template file exists with system prompt introduction and embedded version-control-system-message.g.md using XML documents format
  > Command: Verify file exists and contains proper XML documents container with embedded guide content

- [x] Update CommitMessageGenerator to reference template file path instead of hardcoded system message
  > TEST: Path Integration
  > Type: Code Integration
  > Assert: Generator uses template file path for --system parameter in llm-query command
  > Command: Test commit message generation with new system prompt template path and verify it raises exception if template missing

- [x] Test commit message generation with various diff scenarios
  > TEST: Message Quality
  > Type: Functional Validation
  > Assert: Generated commit messages follow conventional commits format
  > Command: Generate commits for different types of changes and verify quality

## Acceptance Criteria

- [x] AC 1: System prompt template file created with embedded version-control-system-message.g.md using proper XML documents format
- [x] AC 2: CommitMessageGenerator uses template file path directly with llm-query --system parameter
- [x] AC 3: Generator raises exception if template file is missing (no fallback behavior)
- [x] AC 4: Generated commit messages follow conventional commits specification as defined in the embedded guide
- [x] AC 5: Template follows dev-handbook/.meta/tpl/ structure and naming conventions

## Out of Scope

- ❌ Changes to git command interface
- ❌ LLM provider configuration changes
- ❌ Commit workflow modifications beyond message generation
- ❌ Template loading or caching mechanisms (file path passed directly to llm-query)
- ❌ Fallback behavior for missing templates (should raise exception)
- ❌ Variable substitution in templates (static template with embedded guide)

## References

```
Source: dev-handbook/guides/version-control-system-message.g.md
Target: dev-handbook/.meta/tpl/git-commit.system.prompt.md
Integration: dev-tools/lib/coding_agent_tools/molecules/git/commit_message_generator.rb
```

## Implementation Summary

**Completed:** All planning steps, execution steps, and acceptance criteria have been fulfilled.

**Key Changes:**
- Created comprehensive system prompt template at `dev-handbook/.meta/tpl/git-commit.system.prompt.md`
- Embedded complete version control system message guide using XML documents format
- Updated `CommitMessageGenerator` to use template file path directly with `llm-query --system` parameter
- Implemented proper exception handling for missing template files
- Verified commit message generation follows conventional commits specification

**Testing Results:**
- ✅ All RSpec tests passing (1689 examples, 0 failures)
- ✅ Generated commit messages follow conventional commits format
- ✅ Template file path correctly resolved and used
- ✅ Security requirements satisfied (template accessible from project root)

**Template Location:** `dev-handbook/.meta/tpl/git-commit.system.prompt.md` (as originally planned)