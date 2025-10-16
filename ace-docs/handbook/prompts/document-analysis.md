# Change Analysis Instructions

You are analyzing git changes to produce a comprehensive change summary.

## Your Task

Review the git diff provided below and identify all significant changes. Categorize them by priority and provide clear, actionable analysis.

## Analysis Requirements

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

## What to Exclude

- Whitespace-only changes
- Code formatting changes with no semantic impact
- Comment updates (unless they indicate important changes)
- Trivial refactoring with no behavioral changes

Mark these as ambiguous in your coverage tracking rather than listing them as changes.
