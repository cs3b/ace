---
doc-type: user
title: ace-handbook-integration-opencode
purpose: Documentation for ace-handbook-integration-opencode/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-handbook-integration-opencode

OpenCode-specific provider integration for ACE handbook skills.

## Purpose

This package provides OpenCode-native provider manifests for ACE handbook integrations.

It projects canonical skill definitions from package-owned `handbook/skills` into OpenCode assets,
while shared sync/runtime behavior remains in `ace-handbook`.

## Installation

`gem install ace-handbook-integration-opencode`

## What It Provides

- OpenCode provider manifests for handbook integrations.
- OpenCode-native workflow/projection assets for ACE tooling.
- Alignment with canonical skill definitions managed by owning packages.

## Part of ACE

This package is part of [ACE (Agentic Coding Environment)](https://github.com/cs3b/ace).

Shared handbook sync/runtime behavior is provided by
[ace-handbook](https://github.com/cs3b/ace/tree/main/ace-handbook).
