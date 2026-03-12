---
name: onboard
description: Load onboarding context and summarize the current project state
allowed-tools: Bash, Read
argument-hint: "[preset]"
doc-type: workflow
purpose: onboarding context workflow
---

# Onboard Workflow

## Variables

- `$preset`: project

## Instructions

1. Run `ace-bundle $preset`.
2. Read the complete output, including any referenced files.
3. Summarize the current state of the project, focusing on architecture, active work, and conventions.
