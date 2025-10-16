# Document Analysis Instructions

You are analyzing code changes to determine what documentation needs to be updated.

## Your Task

Review the embedded files (provided as XML tags below) and the git diff that follows. Identify all documentation that needs updating based on the code changes shown in the diff.

## Analysis Requirements

**Coverage Tracking:**
- Count total diff hunks in the provided diff
- Track which hunks map to documentation updates
- Track which hunks are ambiguous or don't require documentation
- Report metrics in your Self-check section

**Cross-Document Analysis:**
- Check the primary document being analyzed
- Check all related documents provided in the "Related Documents to Check" section
- Check for impacts on:
  - Usage guides (docs/usage.md, docs/guides/*.md)
  - Workflow documentation (handbook/workflow-instructions/*.wf.md)
  - CI examples and configuration
  - Architecture and design documents

**Evidence Requirements:**
- Every recommendation must include evidence
- Use format: `file.rb:L10-L25` or `file.rb::@@ -45,6 +47,9 @@`
- Reference exact file paths and line ranges from the diff

**Anchor Precision:**
- Use exact section anchors when proposing updates
- Format: `## Section → ### Subsection → #### Detail`
- Extract anchors from the embedded file content
- If a section doesn't exist, propose: `[NEW] ## Section Title`

**Schema Consistency:**
- Compare configuration examples across files
- Flag namespace mismatches (old vs new formats)
- Propose migration paths with before/after YAML blocks

**Development Infrastructure:**
- If diff includes test files, recommend Development section updates
- If dependencies change, recommend installation/setup updates
- If CI config changes, recommend CI documentation updates

## Output Quality Standards

- Each change description: ≤ 2 lines
- Recommended Updates table: max 8 rows per document
- All diff hunks accounted for (mapped or marked ambiguous)
- Evidence provided for every recommendation
- Exact anchors used for all section references
