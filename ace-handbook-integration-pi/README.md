---
doc-type: user
title: ace-handbook-integration-pi
purpose: Documentation for ace-handbook-integration-pi/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-handbook-integration-pi

PI-specific provider integration for ACE handbook skills.

## Purpose

This package provides PI-native provider manifests for ACE handbook integrations.

It projects canonical skill definitions from package-owned `handbook/skills` into PI assets,
while shared sync/runtime behavior remains in `ace-handbook`.

## Installation

`gem install ace-handbook-integration-pi`

## What It Provides

- PI provider manifests for handbook integrations.
- PI-native workflow/projection assets for ACE tooling.
- Alignment with canonical skill definitions managed by owning packages.

## Part of ACE

This package is part of [ACE (Agentic Coding Environment)](https://github.com/cs3b/ace).

Shared handbook sync/runtime behavior is provided by
[ace-handbook](https://github.com/cs3b/ace/tree/main/ace-handbook).
