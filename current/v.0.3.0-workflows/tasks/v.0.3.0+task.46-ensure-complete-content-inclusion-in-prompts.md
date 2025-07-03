---
id: v.0.3.0+task.46
status: pending
priority: medium
estimate: 3h
dependencies: [v.0.3.0+task.44]
---

# Ensure Complete Content Inclusion in Prompts

## 0. Directory Audit ✅

_Command run:_

```bash
ls -lh dev-taskflow/current/v.0.3.0-workflows/code_review/*/input.xml dev-taskflow/current/v.0.3.0-workflows/code_review/*/prompt.md
```

_Result excerpt:_

```
-rw-r--r--@ 1 michalczyz  staff   217K Jul  3 23:25 input.xml
-rw-r--r--@ 1 michalczyz  staff   225K Jul  4 00:16 prompt.md
```

## Objective

Fix truncated input content in review prompts by ensuring full input.xml content is completely appended to prompt.md files, providing LLMs with complete context for accurate analysis instead of partial content with truncation notices.

## Scope of Work

* Remove content truncation patterns from prompt construction
* Implement full content concatenation using `cat input.xml >> prompt.md`
* Update review-code.wf.md to handle large content files properly
* Verify content completeness in generated prompts
* Add file size validation to ensure full content inclusion

### Deliverables

#### Modify

* dev-handbook/workflow-instructions/review-code.wf.md

## Phases

1. Audit current content truncation patterns
2. Replace truncated embedding with full concatenation
3. Add content validation checks
4. Test with large input files

## Implementation Plan

### Planning Steps

* [ ] Analyze current content embedding patterns in review-code.wf.md
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current truncation patterns are identified
  > Command: grep -n "truncated\|excerpt" dev-handbook/workflow-instructions/review-code.wf.md
* [ ] Review session feedback about missing complete content
* [ ] Plan file size handling and validation approach

### Execution Steps

* [ ] Remove content truncation and partial embedding patterns
  > TEST: Verify Truncation Removal
  > Type: Content Validation
  > Assert: No truncation notices remain in prompt construction
  > Command: grep -i "truncated\|excerpt\|partial" review-code.wf.md
* [ ] Implement full content concatenation using `cat input.xml >> prompt.md`
* [ ] Add file size validation to ensure complete content inclusion
  > TEST: Verify Complete Content
  > Type: Size Validation
  > Assert: prompt.md includes full input.xml content
  > Command: diff <(tail -c +$(wc -c < input.xml) prompt.md) input.xml
* [ ] Update documentation to reflect complete content inclusion approach
* [ ] Test with large handbook content (200K+ files)
  > TEST: Verify Large File Handling
  > Type: Performance Test
  > Assert: Large files are completely included without timeout
  > Command: timeout 30s cat large-input.xml >> test-prompt.md

## Acceptance Criteria

* [ ] AC 1: No content truncation in generated prompts
* [ ] AC 2: Full input.xml content appended to prompt.md files
* [ ] AC 3: File size validation confirms complete content inclusion
* [ ] AC 4: Large content files (200K+) handled properly
* [ ] AC 5: LLMs receive complete context for accurate analysis

## Out of Scope

* ❌ Adding content compression or optimization
* ❌ Implementing streaming or chunked content delivery
* ❌ Modifying LLM query tool timeout handling

## References

* Session feedback: "you only add part of input.xml (small part) to prompt.md"
* User instruction: "cat input.xml >> prompt.md"
* Current prompt.md example showing complete content (225K vs 217K input.xml)