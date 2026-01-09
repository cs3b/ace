---
id: v.0.3.0+task.44
status: done
priority: high
estimate: 5h
dependencies: [v.0.3.0+task.43]
---

# Implement XML Prompt Structure for Reviews

## 0. Directory Audit ✅

_Command run:_

```bash
grep -n "prompt.md" .ace/handbook/workflow-instructions/review-code.wf.md | head -5
```

_Result excerpt:_

```
216: cat > "${SESSION_DIR}/prompt.md" <<EOF
229: cat ".ace/handbook/templates/review-${focus}/system.prompt.md" >> "${SESSION_DIR}/prompt.md"
231: echo -e "\n\n## Project Context\n" >> "${SESSION_DIR}/prompt.md"
```

## Objective

Transform review prompt construction from plain markdown to structured XML format with semantic tags for better LLM processing and structured context handling. Replace current markdown-based prompt building with XML structure using project-context, focus-areas, and review-target containers.

## Scope of Work

* Design XML schema for review prompts with semantic tags
* Update prompt construction logic in review-code.wf.md
* Implement project context as XML documents with CDATA sections
* Structure focus areas and review targets in XML format
* Maintain compatibility with existing LLM query patterns

### Deliverables

#### Modify

* .ace/handbook/workflow-instructions/review-code.wf.md

#### Create

* Example XML prompt templates for different review types

## Phases

1. Design XML schema for review prompts
2. Update prompt construction logic
3. Transform project context embedding to XML documents
4. Test XML prompt generation

## Implementation Plan

### Planning Steps

* [x] Analyze current prompt construction patterns in review-code.wf.md
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current markdown prompt structure is documented
  > Command: grep -A 20 "Combined Prompt Construction" .ace/handbook/workflow-instructions/review-code.wf.md
* [x] Design XML schema with semantic tags (project-context, focus-areas, review-target)
* [x] Plan YAML frontmatter integration with XML structure

### Execution Steps

* [x] Replace plain markdown headers with YAML frontmatter in prompt construction
  > TEST: Verify YAML Frontmatter
  > Type: Action Validation
  > Assert: Generated prompts include proper YAML metadata
  > Command: head -10 example-prompt.md | grep -E '^(---|\w+:)'
* [x] Transform project context loading to XML document format
* [x] Update focus areas to use structured XML tags instead of markdown lists
* [x] Implement complete input content append (not truncated embedding)
  > TEST: Verify Complete Content Inclusion
  > Type: Content Validation
  > Assert: Full input.xml content is included in prompt
  > Command: diff -q input.xml <(tail -c +$(grep -n "<?xml" prompt.md | cut -d: -f1 | head -1) prompt.md)
* [x] Create example XML prompts for code/tests/docs focus areas

## Acceptance Criteria

* [x] AC 1: Prompts use YAML frontmatter for metadata
* [x] AC 2: Project context embedded as XML documents with CDATA
* [x] AC 3: Focus areas structured with semantic XML tags
* [x] AC 4: Complete input content included without truncation
* [x] AC 5: Generated prompts are valid XML and processable by LLMs

## Out of Scope

* ❌ Changing LLM query tool to parse XML differently
* ❌ Modifying system prompt templates
* ❌ Adding new XML validation tools

## References

* Session feedback: "prompt can be xml with project-context, focus-to-review tags"
* Current prompt.md example with proper XML document embedding
* User requirement: "let it be xml (just ensure you don't read the prompt.md back)"
