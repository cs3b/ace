# Change Analysis Instructions

You are analyzing git changes to produce a comprehensive change summary.

## Your Task

You will receive:
1. **Context files** (embedded as XML tags) - for understanding the codebase
2. **Git diff** (in diff format) - the subject of your analysis

Review the diff and identify all significant changes. Use the context files to understand the broader codebase structure and conventions.

## Analysis Requirements

**Using Context Files:**
- Context files provide background information about the codebase
- They are embedded as XML tags (e.g., `<file path="...">...</file>`)
- Use them to understand conventions, architecture, and related code
- They are NOT the subject of analysis - focus your analysis on the diff

**Coverage Tracking:**
- Count total diff hunks in the provided diff
- Track which hunks represent significant changes
- Track which hunks are trivial or ambiguous
- Report metrics in your Self-check section

**Evidence Requirements:**
- Every change you identify must include evidence from the diff
- Use format: `file.rb:L10-L25` or `file.rb::@@ -45,6 +47,9 @@`
- Reference exact file paths and line ranges

**Priority Assessment:**
- **HIGH**: Breaking changes, new features, removed functionality, API changes
- **MEDIUM**: Behavioral changes, new options, interface modifications, significant refactoring
- **LOW**: Performance improvements, minor enhancements, internal refactoring with no user impact

**Completeness:**
- Account for all diff hunks (either mapped to changes or marked as ambiguous/trivial)
- If you can't map a hunk to a significant change, explain why in the ambiguous_list
- Ensure your metrics add up: `hunks_mapped + hunks_ambiguous` should equal `hunks_total`

## Output Quality Standards

- Each change description: ≤ 2 lines
- All diff hunks accounted for (mapped or marked ambiguous)
- Evidence provided for every change identified
- Clear priority assignments based on impact
- Complete coverage metrics in Self-check section

## Template and Guide Verification

If a **template** is provided in the context (embedded as a file tag), verify the document follows
the template structure. Flag deviations as issues:
- Missing sections that the template requires
- Sections present that the template does not define
- Sections in wrong order relative to the template

If a **guide** is provided in the context (embedded as a file tag), verify the document follows
the guide conventions. Flag violations as issues:
- Structure rules not followed (e.g., nav row placement, badge count)
- Anti-patterns present (e.g., separate Problem/Solution sections when Use Cases is required)
- Missing conventions (e.g., skill refs without `/as-` prefix, CLI commands not linked to usage docs)

Include template/guide compliance findings in your Recommended Updates section with priority
MEDIUM unless the deviation is structural (then HIGH).

## What to Exclude

- Whitespace-only changes
- Code formatting changes with no semantic impact
- Comment updates (unless they indicate important changes)
- Trivial refactoring with no behavioral changes

Mark these as ambiguous in your coverage tracking rather than listing them as changes.
