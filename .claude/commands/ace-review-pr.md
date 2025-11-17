---
description: Perform Code Review of origin/main..HEAD - using two models
allowed-tools: Bash, Read
last_modified: '2025-11-17'
---

# Goal

Prepare plan for implementation based on output of below reviews

## Run in background following commands

- `ace-review --preset code-pr --model gpro --auto-execute`
- `ace-review --preset code-pr --model claude:sonnet --auto-execute`

## Wait till all end (up to 5 minutes)

## After all finished

- read all the reviews
- combine plan to review them all

## Result

Present comprehensive plan what we can improve and how we can implement this.
