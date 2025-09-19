# Update Handbook Documentation Workflow

## Goal

Maintain accurate, comprehensive, and well-structured README documentation across the dev-handbook directory hierarchy to ensure all components are properly documented and discoverable.

## Prerequisites

* Understanding of handbook structure and component relationships
* Access to dev-handbook directory and all subdirectories
* Familiarity with handbook conventions and patterns
* Knowledge of agents, commands, guides, and workflow systems

## Project Context Loading

### Load dev-handbook context preset
```bash
context --preset dev-handbook
```

### Review target documentation files
- dev-handbook/README.md (main handbook documentation)
- dev-handbook/.meta/README.md (meta documentation)
- dev-handbook/.integrations/README.md (integration documentation)

### Understand handbook standards
- dev-handbook/.meta/gds/guides-definition.g.md
- dev-handbook/.meta/gds/workflow-instructions-definition.g.md
- dev-handbook/.meta/gds/agents-definition.g.md

## Process Steps

### 1. Audit Current Documentation State

**For each README file:**
* Compare documented items against actual directory contents
* Identify missing, outdated, or incorrect information
* Check for broken links and invalid references
* Note structural inconsistencies

**Validation Commands:**
```bash
# Check for undocumented guides
for guide in dev-handbook/guides/*.g.md; do
  basename "$guide" | xargs -I {} grep -q {} dev-handbook/README.md || echo "Missing: {}"
done

# Check for undocumented workflows
for wf in dev-handbook/workflow-instructions/*.wf.md; do
  basename "$wf" | xargs -I {} grep -q {} dev-handbook/README.md || echo "Missing workflow: {}"
done

# Check for broken links
grep -o '\[.*\](.*.md)' dev-handbook/README.md | grep -o '(.*\.md)' | tr -d '()' | while read link; do
  [ -f "dev-handbook/$link" ] || echo "Broken link: $link"
done
```

### 2. Update Main Handbook README

**Structure to maintain:**
```markdown
# Development Handbook (`dev-handbook`)

[Brief description and purpose]

## Quick Start
[Installation instructions]

## Structure
[Directory organization]

## Development Guides
### [Category]
- [Guide links with descriptions]

## Workflow Instructions
[Key workflows listed]

## Templates
[Available templates]

## Integrations
[AI assistant integrations]

## Contributing
[How to contribute]
```

**Update Process:**
* Scan `guides/` directory for all `.g.md` files
* Group guides by category (Core Process, Technical Standards, Language-Specific, etc.)
* Update guide links with consistent format: `[Guide Name](path) | [Related Guide](path)`
* Include brief inline descriptions where helpful
* Maintain alphabetical ordering within categories

### 3. Update Meta Documentation README

**Focus Areas:**
* `/gds` - Guide Definition Standards listings
* `/wfi` - Meta Workflow Instructions catalog
* `/tpl` - Template inventory
* Relationship diagrams showing how meta components interact
* Quick reference table for finding the right meta resource

**Structure Template:**
```markdown
# Meta Documentation (`.meta`)

[Purpose and overview]

## Structure

### `/gds` - Guide Definition Standards
[List all definition files with descriptions]

### `/wfi` - Meta Workflow Instructions
[Categorized workflow listings]

### `/tpl` - Templates
[Template inventory with use cases]

## Relationships
[ASCII diagram or structured explanation]

## Usage
[Common tasks and how to accomplish them]

## Quick Reference
[Table mapping needs to resources]
```

### 4. Update Integrations README

**Key Sections to Maintain:**
* Current integration status (Claude Code, others)
* Directory structure with file counts
* Agent catalog with descriptions and links
* Command inventory (custom vs generated)
* Installation instructions
* Maintenance procedures
* Relationship dependencies

**Update Checklist:**
```bash
# Count agents
ls -1 dev-handbook/.integrations/claude/agents/*.ag.md | wc -l

# Count commands
ls -1 dev-handbook/.integrations/claude/commands/_custom/*.md | wc -l
ls -1 dev-handbook/.integrations/claude/commands/_generated/*.md | wc -l

# Verify agent links
for agent in dev-handbook/.integrations/claude/agents/*.ag.md; do
  name=$(basename "$agent" .ag.md)
  grep -q "$name" dev-handbook/.integrations/README.md || echo "Missing agent doc: $name"
done
```

### 5. Synchronize Cross-References

**Ensure consistency across:**
* Links between README files
* References to guides, workflows, and templates
* Agent and command documentation
* Version numbers and counts
* Directory structure descriptions

**Cross-reference validation:**
```bash
# Check that all workflows mentioned in READMEs exist
grep -h "\.wf\.md" dev-handbook/README.md dev-handbook/.meta/README.md | 
  grep -o '[a-z-]*\.wf\.md' | sort -u | while read wf; do
    find dev-handbook -name "$wf" | grep -q . || echo "Referenced but missing: $wf"
done
```

### 6. Update Quick Reference Tables

**For each README, maintain tables for:**
* Component counts (guides, workflows, agents, commands)
* Category mappings
* Tool/workflow/guide relationships
* Common task → resource mappings

**Table Format:**
```markdown
| Type | Count | Location | Definition |
|------|-------|----------|------------|
| Guides | XX | guides/ | .meta/gds/guides-definition.g.md |
| Workflows | XX | workflow-instructions/ | .meta/gds/workflow-instructions-definition.g.md |
| Agents | XX | .integrations/claude/agents/ | .meta/gds/agents-definition.g.md |
```

## Embedded Templates

<templates>
<template path="readme-section-template.md">
## [Section Name]

[Brief description of section purpose]

### Available [Items]

**[Category]:**
- **[Item Name](./path/to/item.md)** - [One-line description]
- **[Item Name](./path/to/item.md)** - [One-line description]

**[Another Category]:**
- **[Item Name](./path/to/item.md)** - [One-line description]

### Usage

```bash
# Example command or workflow invocation
```

### Related Resources
- [Related Section](#section-anchor)
- [External Doc](./path/to/doc.md)
</template>

<template path="relationship-diagram-template.md">
## Relationships

```
Component A provides [what] for →
  └─ Component B (specific items)
  └─ Component C (specific items)
  
Component B maintains →
  └─ Component D via [mechanism]
  └─ Component E via [mechanism]
```

### Dependencies
- **[Component]** requires **[Other Component]** for [purpose]
- **[Component]** generates **[Output]** used by **[Consumer]**
</template>
</templates>

## Validation Checklist

### Content Accuracy
- [ ] All existing files are documented
- [ ] No references to deleted files
- [ ] Counts and statistics are current
- [ ] Categories match actual content

### Link Integrity
- [ ] All internal links resolve correctly
- [ ] Relative paths are accurate
- [ ] No broken anchor links
- [ ] Cross-references between READMEs work

### Structure Consistency
- [ ] Consistent heading hierarchy
- [ ] Uniform list formatting
- [ ] Table formatting matches standards
- [ ] Code block syntax highlighting

### Completeness
- [ ] All directories have README files
- [ ] New components are documented
- [ ] Deprecated items are marked or removed
- [ ] Examples and usage instructions included

## Success Criteria

* All README files accurately reflect current directory contents
* No broken links or missing references
* Consistent formatting and structure across all documentation
* Clear navigation paths between related components
* Quick reference sections enable fast discovery
* Counts and statistics are accurate
* Relationship diagrams correctly show dependencies

## Error Handling

**Missing Files:**
* **Symptoms:** Documentation references non-existent files
* **Solution:** Either remove reference or locate/recreate missing file

**Inconsistent Information:**
* **Symptoms:** Same item described differently in multiple places
* **Solution:** Standardize description and update all references

**Broken Links:**
* **Symptoms:** Links return 404 or point to wrong location
* **Solution:** Update paths or find correct targets

**Outdated Counts:**
* **Symptoms:** Documented counts don't match actual files
* **Solution:** Recount and update all statistics

## Usage Example

> "Update the handbook documentation after adding new workflow instructions and agents"

Following this workflow would:
1. Audit current state of all three README files
2. Update main README with new workflow listings
3. Update meta README if meta-workflows were added
4. Update integrations README with new agent information
5. Synchronize all cross-references
6. Update quick reference tables with new counts
7. Validate all changes for accuracy and completeness