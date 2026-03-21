---
doc-type: template
title: Summary
purpose: Documentation for ace-git/handbook/templates/pr/feature.template.md
ace-docs:
  last-updated: 2026-02-28
  last-checked: 2026-03-21
---

## Summary

What is easier now for users/reviewers:
- <impact>

What pain/manual step/error existed before:
- <previous-pain>

## Changes

- <concern-1> (<commit-sha>)
- <concern-2> (<commit-sha>)

## File Changes

- Use `ace-git diff --format grouped-stats` output
- Fallback: flat file list if grouped-stats unavailable

## Test Evidence

- <test-file-or-test-name> -> <behavior-validated>
- Suite totals: <passed>/<total>

## Releases

- <changelog-entry-from-diff>

## Demo

- <runnable-command-demonstrating-the-feature>
- <expected-output-and-artifact-locations>
- Omit this section if no user-facing CLI or runnable entry point
