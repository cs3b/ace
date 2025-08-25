---
id: v.0.5.0+task.060
status: done
priority: medium
estimate: 30m
dependencies: []
---

# Move initialize-project-structure workflow to WFI directory

## Behavioral Context

**Issue**: The initialize-project-structure.wf.md was located in the workflow-instructions directory, which would cause automatic Claude command generation. This workflow should be in the WFI (Workflow File Instructions) directory to prevent command generation.

**Key Behavioral Requirements**:
- Workflow files in .integrations/wfi/ should not generate Claude commands
- Preserve workflow content during relocation
- Update any references to the old location

## Objective

Relocated the initialize-project-structure workflow from dev-handbook/workflow-instructions/ to dev-handbook/.integrations/wfi/ to prevent automatic command generation while preserving its functionality.

## Scope of Work

- Moved workflow file to new WFI directory location
- Ensured file content preserved during move
- Verified no Claude command would be generated

### Deliverables

#### Create

- dev-handbook/.integrations/wfi/initialize-project-structure.wf.md (moved from old location)

#### Delete

- dev-handbook/workflow-instructions/initialize-project-structure.wf.md (old location)

## Implementation Summary

### What Was Done

- **Problem Identification**: Workflow was in wrong directory causing unwanted command generation
- **Investigation**: Confirmed that .integrations/wfi/ is the correct location for non-command workflows
- **Solution**: Moved the file from workflow-instructions to .integrations/wfi/
- **Validation**: Verified file moved successfully and content preserved

### Technical Details

Simple file relocation operation:

```bash
mv dev-handbook/workflow-instructions/initialize-project-structure.wf.md \
   dev-handbook/.integrations/wfi/initialize-project-structure.wf.md
```

### Testing/Validation

```bash
# Verified file exists at new location
ls dev-handbook/.integrations/wfi/initialize-project-structure.wf.md

# Confirmed old location no longer exists
ls dev-handbook/workflow-instructions/initialize-project-structure.wf.md
```

**Results**: File successfully relocated without content loss

## References

- User request: "this dev-handbook/workflow-instructions/initialize-project-structure.wf.md should be in dev-handbook/.integrations/wfi/initialize-project-structure.wf.md we don't need to generate claude command for this workflow"
- Related to overall integrate command improvements