---
id: 8m9000
title: Finding Bugs and Working on the Right Problem
type: conversation-analysis
tags: []
created_at: '2025-11-10 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8m9000-finding-bugs-and-working-on-right-problem.md"
---

# Reflection: Finding Bugs and Working on the Right Problem

**Date**: 2025-11-10
**Context**: Debugging ace-review error and learning to verify root cause before proposing solutions
**Author**: Claude + User
**Type**: Conversation Analysis

## What Went Well

- User caught premature solution-jumping: "are we sure what is real problem and we are solving the real problem?"
- Systematic investigation using multiple tools (Grep, Read, Bash testing) to understand the error
- Found the actual configuration error in docs.yml (missing `context:` wrapper)
- User fixed the problem immediately by correcting the preset configuration
- Verified the fix works: `ace-review --preset docs` now succeeds

## What Could Be Improved

- **Premature Solution Proposal**: Jumped to "fix TemplateParser" before verifying if there was actually a TemplateParser bug
- **Incomplete Root Cause Analysis**: Should have tested with the corrected config BEFORE proposing code changes
- **Missing Validation Step**: Didn't verify whether the error was a bug or a configuration issue
- **Over-engineering Risk**: Almost made TemplateParser more lenient to work around a configuration error

## Key Learnings

### Core Lesson: Verify Before You Code

The error message "Content cannot be empty" was **working correctly** - it caught a malformed preset configuration. The real problem was:

**Broken Config** (docs.yml line 35):
```yaml
subject:
  sections:      # Missing 'context:' wrapper!
    review-that:
      files: ["ace-context/**/*.md"]
```

**Fixed Config**:
```yaml
subject:
  context:       # Properly wrapped ✅
    sections:
      review-that:
        files: ["ace-context/**/*.md"]
```

### Why It Failed Before

1. ace-review generated file with top-level `sections:` key (malformed)
2. ace-context's `load_template()` checked condition: `frontmatter['context'].is_a?(Hash)`
3. Condition was FALSE (no 'context' key)
4. Fell through to TemplateParser.parse() which validates content
5. TemplateParser correctly rejected empty content body
6. Error message was accurate but **misleading** - suggested TemplateParser bug

### Why It Works Now

1. Proper `context:` wrapper in config
2. ace-review generates file with `context:` key in frontmatter
3. Condition `frontmatter['context'].is_a?(Hash)` = TRUE
4. Takes "new pattern" path (line 405-460)
5. Processes sections directly, never calls TemplateParser
6. Works perfectly ✅

### Technical Insight: Two Processing Paths

ace-context's `load_template()` has two paths:

**Path 1 - New Pattern** (lines 405-460):
- Triggered when: `frontmatter['context'].is_a?(Hash)`
- Processes: sections, base content, sections content
- Never calls TemplateParser
- **This is the path that should be used**

**Path 2 - Legacy Template** (lines 463-484):
- Triggered when: condition FALSE
- Calls: `TemplateParser.parse(template_content)`
- Requires non-empty body content
- **This is a fallback for old-style templates**

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Premature Solution Without Root Cause Verification**: 1 occurrence
  - Occurrences: Once (proposing TemplateParser fix)
  - Impact: Almost led to unnecessary code changes and masked the real issue
  - Root Cause: Didn't verify if error indicated a bug or configuration problem
  - **User Intervention**: Critical question stopped incorrect work

#### Medium Impact Issues

- **Missing "Test First" Mindset**: 1 occurrence
  - Occurrences: Proposed solution before testing with corrected config
  - Impact: Wasted time on investigation after solution was already found
  - Root Cause: Didn't think to test the user's fix immediately

### Improvement Proposals

#### Process Improvements

**Stop-Think-Verify Protocol**:
1. **Error Occurs** → Identify symptoms
2. **Investigate** → Understand the code path
3. **Identify Suspects** → Is it a bug or config error?
4. **Verify Root Cause** → Test with correct configuration
5. **Only Then** → Propose code changes if needed

**Question Checklist Before Proposing Code Changes**:
- [ ] Is this a bug in the code or a configuration error?
- [ ] Have I tested with a known-good configuration?
- [ ] Does the error message accurately reflect the problem?
- [ ] Would fixing this mask a user error?

#### Communication Protocols

**User Feedback Integration**:
- When user questions the approach: **STOP and re-evaluate**
- User's "are we solving the right problem?" is a critical signal
- Respond to user skepticism with verification, not justification

**Better Status Communication**:
- Before: "The problem is X, we should fix Y"
- Better: "The error suggests X. Let me verify if it's a bug or config issue"

## Action Items

### Stop Doing

- Proposing code solutions before verifying root cause
- Assuming error messages indicate bugs without checking configuration
- Proceeding with implementation when user questions the approach

### Continue Doing

- Systematic investigation using multiple tools
- Testing hypotheses with executable code
- Asking clarifying questions when uncertainty exists

### Start Doing

- **Always test with corrected configuration before proposing code changes**
- **Verify whether error indicates bug or user error**
- **When user questions approach, pause and re-verify assumptions**
- **Use "Stop-Think-Verify" protocol for all debugging**

## Technical Details

### Error Flow Analysis

```
User runs: ace-review --preset docs
  ↓
ace-review loads docs.yml
  ↓
docs.yml has subject.sections (missing context: wrapper)
  ↓
ace-review generates user.context.md:
  ---
  sections:      # TOP-LEVEL! (wrong)
    review-that:
      files: [...]
  ---

  ↓
ace-context.load_file(user.context.md)
  ↓
load_template() parses frontmatter
  ↓
Checks: frontmatter['context'].is_a?(Hash)
  ↓
Result: FALSE (no 'context' key)
  ↓
Falls through to TemplateParser.parse(body)
  ↓
Body is empty (just frontmatter)
  ↓
TemplateParser: "Content cannot be empty" ✅ Correct error!
```

### Configuration Schema

Correct ace-review preset format requires:
```yaml
instructions:
  context:    # Required wrapper
    base: "..."
    sections: {...}

subject:
  context:    # Required wrapper ✅
    sections: {...}
```

## Additional Context

- Related Files:
  - `.ace/review/presets/docs.yml` (fixed by user)
  - `ace-context/lib/ace/context/organisms/context_loader.rb:405-460` (new pattern path)
  - `ace-support-core/lib/ace/core/atoms/template_parser.rb:23` (validation)

- Key Realization: TemplateParser's strict validation is **correct** - it catches malformed configs
- User's fix: Added `context:` wrapper to subject config
- Outcome: No code changes needed, configuration error resolved