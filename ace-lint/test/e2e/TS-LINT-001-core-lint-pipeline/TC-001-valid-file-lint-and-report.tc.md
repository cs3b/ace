---
tc-id: TC-001
title: Valid File Lint and Report Generation
mode: goal
---

## Objective

Verify that linting a valid Ruby file exits 0, generates a well-structured report.json, and produces ok.md with correct format.

## Available Tools

- `ace-lint`
- `jq`
- standard shell tools (`bash`, `grep`, `sed`, `cat`, `test`)

## Success Criteria

- Exit code: 0
- report.json exists with top-level keys: `["report_metadata", "results", "summary"]`
- Metadata contains: `compact_id`, `generated_at`, `ace_lint_version`, `scan_options`
- Summary contains: `total_files`, `scanned`, `skipped`, `fixed`, `failed`, `passed`, `total_errors`, `total_warnings`
- Results contains: `fixed`, `failed`, `warnings_only`, `passed`, `skipped`
- ok.md exists with "# Lint: Passed Files" header, Generated timestamp, and file list

## Hints

- Use runtime output from `ace-lint` to locate the report directory; do not hardcode internal cache paths.
- Capture both stdout and stderr so failure evidence is explicit.
