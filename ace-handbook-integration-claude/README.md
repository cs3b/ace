---
doc-type: user
title: ace-handbook-integration-claude
purpose: Documentation for ace-handbook-integration-claude/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-handbook-integration-claude

Claude-specific provider integration for ACE handbook skills.

## Purpose

This package is the replacement target for the legacy `ace-integration-claude` package.

It owns Claude-native workflows and provider manifests, while canonical skill definitions remain in
the owning package `handbook/skills` directories and shared sync/runtime behavior lives in
`ace-handbook`.

## Installation

`gem install ace-handbook-integration-claude`

## What It Provides

- Claude provider manifests for handbook integrations.
- Claude-native workflow/projection assets for ACE tooling.
- Alignment with canonical skill definitions managed by the owning package `handbook/skills`.

## Part of ACE

This package is part of [ACE (Agentic Coding Environment)](https://github.com/cs3b/ace).

Shared handbook sync/runtime behavior is provided by
[ace-handbook](https://github.com/cs3b/ace/tree/main/ace-handbook).
