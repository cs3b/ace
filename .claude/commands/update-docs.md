---
description: Update documentation with ace-docs
---

Update project documentation using the ace-docs tool and workflow orchestration.

## Instructions

1. Read and follow the workflow instruction:
   - File: ace-docs/handbook/workflow-instructions/update-docs.wf.md

2. Use ace-docs commands to:
   - Check document status
   - Generate change analysis
   - Update documents iteratively
   - Validate changes

3. Default behavior (if no input provided):
   - Update all documents marked as needing update

4. Accept flexible input:
   - Specific files: "update-docs docs/api.md"
   - By type: "update-docs --type guide"
   - By preset: "update-docs --preset standard"
   - All documents: "update-docs --all"

This workflow combines deterministic tooling with intelligent analysis for comprehensive documentation management.