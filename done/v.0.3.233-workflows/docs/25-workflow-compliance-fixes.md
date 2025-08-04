# Workflow Compliance Fixes Action Plan

**Date:** 2025-06-30  
**Task:** v.0.3.0+task.25 - Validate Workflow Instruction Compliance  
**Scope:** Fix 2 non-compliant workflow files

## Overview

This document outlines the specific actions required to fix compliance issues in 2 workflow files that contain deprecated four-tick markdown template embedding format.

## Files Requiring Fixes

### 1. `initialize-project-structure.wf.md`

**Issues Found:**

- 10 instances of deprecated `````markdown` format
- No XML `<templates>` section
- Embedded templates not extracted to separate files

**Fix Actions:**

#### Step 1: Identify Embedded Templates

Lines with `````markdown` format (from grep analysis):

- Line 213: Template block 1
- Line 253: Template block 2  
- Line 323: Template block 3
- Line 366: Template block 4
- Line 449: Template block 5
- Line 624: Template block 6
- Line 674: Template block 7
- Line 720: Template block 8
- Line 772: Template block 9
- Line 828: Template block 10

#### Step 2: Extract Templates to Template Files

Create new template files in `dev-handbook/templates/`:

- `dev-handbook/templates/project-docs/readme.template.md`
- `dev-handbook/templates/project-docs/blueprint.template.md` (if different from existing)
- `dev-handbook/templates/release-planning/roadmap.template.md`
- Additional templates as identified during extraction

#### Step 3: Convert to XML Format

Replace each `````markdown` block with:

```xml
<template path="dev-handbook/templates/category/template-name.template.md">
[template content]
</template>
```

#### Step 4: Add Templates Section

Add `<templates>` section at end of document with all extracted templates.

### 2. `save-session-context.md`

**Issues Found:**

- 1 instance of deprecated `````markdown` format at line 231
- No XML `<templates>` section

**Fix Actions:**

#### Step 1: Identify Embedded Template

- Line 231: Session context template

#### Step 2: Extract Template

Create: `dev-handbook/templates/session-management/session-context.template.md`

#### Step 3: Convert to XML Format

Replace `````markdown` block with XML template reference.

#### Step 4: Add Templates Section

Add `<templates>` section at end of document.

## Implementation Steps

### Phase 1: Template Extraction

1. **Create Template Directories** (if needed):

   ```bash
   mkdir -p dev-handbook/templates/session-management
   mkdir -p dev-handbook/templates/project-setup
   ```

2. **Extract Template Content**:
   - Identify each embedded template in the source files
   - Create corresponding `.template.md` files
   - Copy template content to separate files

### Phase 2: XML Conversion

1. **Replace Deprecated Format**:
   - Remove `````markdown` and closing`````
   - Wrap content in `<template path="...">` tags
   - Use proper template file paths

2. **Add Templates Section**:
   - Add `<templates>` section at end of each file
   - Include all embedded templates in XML format

### Phase 3: Validation

1. **Verify XML Structure**:
   - Check template paths are valid
   - Ensure proper XML formatting
   - Confirm templates are at document end

2. **Test Template References**:
   - Verify template files exist at specified paths
   - Check content matches embedded versions

## Detailed Fix Specifications

### Template Path Naming Conventions

**For `initialize-project-structure.wf.md`:**

- Project documentation templates: `dev-handbook/templates/project-setup/`
- README template: `readme.template.md`
- Blueprint template: `blueprint.template.md`
- Roadmap template: `roadmap.template.md`

**For `save-session-context.md`:**

- Session management templates: `dev-handbook/templates/session-management/`
- Session context template: `session-context.template.md`

### XML Template Structure

Each converted template should follow:

```xml
<template path="dev-handbook/templates/category/name.template.md">
[Original template content without modification]
</template>
```

## Validation Commands

After applying fixes, run these commands to verify compliance:

```bash
# Check for remaining deprecated format
grep -r "````markdown" dev-handbook/workflow-instructions/

# Verify XML template sections
grep -r "<templates>" dev-handbook/workflow-instructions/

# Check template positioning
for file in dev-handbook/workflow-instructions/*.md; do 
  if grep -q "<templates>" "$file"; then 
    echo "=== $file ==="; 
    tail -3 "$file"; 
  fi; 
done

# Validate template paths
grep -r "template path=" dev-handbook/workflow-instructions/ | \
  grep -v "dev-handbook/templates/" || echo "All paths valid"
```

## Success Criteria

### Before Fix

- ❌ 2 files with deprecated format
- ❌ 89% compliance rate
- ❌ Blocks automated synchronization

### After Fix

- ✅ 0 files with deprecated format
- ✅ 100% compliance rate  
- ✅ Ready for automated synchronization
- ✅ All templates in standardized XML format
- ✅ Template files exist at specified paths

## Risk Mitigation

### Backup Strategy

- Create backup copies before modification
- Use version control to track changes
- Test fixes on copies before applying to originals

### Validation Strategy

- Verify each template extraction preserves content
- Check XML syntax is valid
- Ensure no content is lost during conversion

## Timeline

**Estimated Duration:** 2-3 hours

1. **Template Extraction:** 1 hour
2. **XML Conversion:** 1 hour  
3. **Validation & Testing:** 30-60 minutes

---

*Action plan created as part of v.0.3.0+task.25 - Validate Workflow Instruction Compliance*
