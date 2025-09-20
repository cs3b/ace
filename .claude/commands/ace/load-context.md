---
name: read-context
allowed-tools: Bash(context), Read
description: This workflow ensures that the necessary project documentation and configuration are loaded. It includes core docs, architecture, project structure, and recent activity.
argument-hint: [preset] 
model: claude-sonnet-4-20250514
---
# Read Context

## Purpose

Conduct loading of project context to the session.

## Context

- read $PROJECT_ROOT_PATH/docs/context/cached/read-context.md

| if file is missing run `ace-context --preset read-context` and read again

## Variables

$preset: project

## Instructions

- prepare context - run `ace-context --preset $preset
- read the whole file (context will return path)
- prepare summary -  [Summary of project purpose, structure, and conventions]

## Success Criteria

- Project context is fully loaded from the preset.  
- Clear understanding of project purpose, architecture, and conventions.  

## Response Template

**Presets Loaded:** [List of presets]  
**Presents Stats: [The size of the context]

Read the whole file from: [$contextFilePath]
**Understanding Achieved:** [Summary of project purpose, structure, and conventions]  
