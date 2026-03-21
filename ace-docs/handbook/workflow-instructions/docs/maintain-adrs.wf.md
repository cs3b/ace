---
doc-type: workflow
title: Maintain Architecture Decision Records
purpose: Maintain ADR lifecycle including evolution, archival, and synchronization
ace-docs:
  last-updated: 2026-02-23
  last-checked: 2026-03-21
---

# Maintain Architecture Decision Records

## Goal

Keep ADRs accurate, relevant, and synchronized with current codebase state through evolution documentation, archival of
obsolete patterns, and maintaining the decisions.md summary.

## Prerequisites

* Existing ADRs in `docs/decisions/`
* Understanding of current codebase architecture
* Access to search codebase for pattern usage
* Ability to modify and commit documentation

## Project Context Loading

* Read and follow: `ace-bundle wfi://bundle`

## Maintenance Actions

### 1. Review ADRs

Periodic review to identify stale, obsolete, or evolved patterns

### 2. Archive Obsolete ADRs

When patterns are no longer used in current codebase

### 3. Document Evolution

When patterns changed but principles remain valid

### 4. Update Scope

When implementation details obsolete but concepts still apply

### 5. Sync with decisions.md

Keep summary document synchronized with all ADRs

### 6. Check for Missing ADRs

Identify gaps between files and summary

## Decision Criteria

### When to Archive Completely

**Indicators:**

* Pattern not used anywhere in current codebase
* Technology/framework no longer in use
* Decision superseded by fundamentally different approach
* Only found in `_legacy/` directories

**Process:**

1.  Research actual usage (grep searches)
2.  Verify only in legacy code
3.  Add deprecation notice to ADR
4.  Move to `docs/decisions/archive/`
5.  Update `docs/decisions.md`

**Examples from Production:**

* **ADR-006**: CI-Aware VCR Configuration (VCR only in `_legacy/dev-tools/spec/support/vcr.rb`)
* **ADR-007**: Zeitwerk Autoloading (only in `_legacy/dev-tools/lib/coding_agent_tools.rb`)
* **ADR-008**: Observability with dry-monitor (only in `_legacy/dev-tools/`)
* **ADR-009**: Centralized CLI Error Reporting (ErrorReporter only in `_legacy/dev-tools/`)

### When to Add Evolution Section

**Indicators:**

* Core principles still valid
* Implementation changed significantly
* Pattern migrated to new architecture
* Original decision provides valuable context

**Process:**

1.  Keep original ADR content intact
2.  Update status line to indicate evolution
3.  Add evolution section at end
4.  Document current state vs original
5.  Provide examples from current codebase

**Examples from Production:**

* **ADR-003**: Template Directory Separation (evolved from the legacy dev-handbook structure to `gem/handbook/`)
* **ADR-004**: Consistent Path Standards (evolved to distributed gem/handbook/ pattern)

### When to Update Scope

**Indicators:**

* General principles still apply
* Specific implementation details outdated
* Technology-specific parts obsolete
* Core concepts remain best practice

**Process:**

1.  Add scope note at document top
2.  Clarify what's still valid vs legacy
3.  Keep original content for context
4.  Reference current implementations

**Examples from Production:**

* **ADR-013**: Class Naming Conventions (naming principles valid, Zeitwerk-specific inflections legacy)

## Research Process

### Verify Pattern Usage in Codebase

Before archiving or evolving, verify actual usage:

    # Search for pattern in current gems
    grep -r "PATTERN_NAME" ace-*/lib/ ace-*/test/
    
    # Check if only in legacy code
    grep -r "PATTERN_NAME" _legacy/dev-tools/
    
    # Count occurrences by location
    grep -c "PATTERN_NAME" ace-*/lib/**/*.rb
    grep -c "PATTERN_NAME" _legacy/**/*.rb
{: .language-bash}

**Example Searches from October 2025 Review:**

    # VCR usage
    grep -r "VCR" ace-*/test/ --type ruby
    # Result: No files found (only in _legacy)
    
    # Zeitwerk usage
    grep -r "Zeitwerk" ace-*/lib/ --type ruby
    # Result: Only in _legacy (current gems use explicit requires)
    
    # Faraday usage
    grep -r "Faraday" ace-*/lib/ --type ruby
    # Result: Found in ace-llm/lib/ace/llm/atoms/http_client.rb (still active!)
{: .language-bash}

### Inspect Current Gem Structure

    # List production gems
    ls -d ace-* | grep -v legacy | grep -v _
    
    # Check specific gem implementation
    ls ace-llm/lib/ace/llm/
    ls ace-core/lib/ace/core/
    
    # Verify pattern in current code
    cat ace-gem/lib/ace/gem/specific_file.rb
{: .language-bash}

## Archival Process

### 1. Create Archive Structure (First Time Only)

    # Create archive directory
    mkdir -p docs/decisions/archive
{: .language-bash}

### 2. Create/Update Archive README

Create `docs/decisions/archive/README.md`:

Use the embedded template below. Update with each new archival.

### 3. Add Deprecation Notice to ADR

At the top of the ADR file, after the status line, use the deprecation notice template embedded below (see
`tmpl://decisions/deprecation-notice`).

**Original ADR (for historical reference):**

    
    Then keep all original content below for historical reference.
    
    ### 4. Move File to Archive
    
    ```bash
    mv docs/decisions/ADR-XXX-title.md docs/decisions/archive/

### 5. Update docs/decisions.md

**Remove from main sections:**

* Delete the entry from whichever section it was in

**Add to "Archived Decisions" section:**

    ## Archived Decisions
    
    The following decisions are **archived** as they apply only to legacy code:
    - **ADR-XXX**: [Title] ([reason for archival])
{: .language-markdown}

## Evolution Process

### 1. Keep Original Content Intact

**DO NOT** modify the original ADR content. Historical context is valuable.

### 2. Update Status Line

Replace the status section:

    ## Status
    
    Accepted - Evolved to [New Pattern Name] (see ADR-XXX)
    Date: YYYY-MM-DD (original)
    Evolution: YYYY-MM-DD
{: .language-markdown}

### 3. Add Evolution Section at End

After all original content, add:

    ## Evolution: [New Pattern Name] (Month Year)
    
    ### Current State
    
    The original [pattern name] has evolved with [context - e.g., mono-repo migration].
{: .language-markdown}

\[Current implementation structure/pattern\]

    
    ### Key Changes
    
    1. **Distribution**: [How pattern is distributed now]
    2. **Implementation**: [New implementation approach]
    3. **Integration**: [How it integrates with current system]
    4. **Discovery**: [How developers find/use it now]
    
    ### Examples in Production Gems
    
    - **gem-name**: `path/to/example.rb` or `path/to/file.md`
    - **gem-name**: `path/to/another-example`
    
    ### Relationship to Original Decision
    
    The **principles remain valid**:
    - ✅ [Core principle 1 still applies]
    - ✅ [Core principle 2 still applies]
    - ✅ [Core principle 3 still applies]
    
    The **implementation evolved**:
    - From: [Old pattern/location]
    - To: [New pattern/location]
    - Reason: [Why it changed - modularity, simplicity, etc.]
    
    See **ADR-XXX: [New Pattern ADR]** for complete details of current pattern.

### 4. Update docs/decisions.md

Add evolution note to the entry:

    ### Decision Title
    **Decision**: [Summary including evolution note]
    **Impact**: [Updated impact statement]
    **Details**: [ADR-XXX](decisions/ADR-XXX-title.md) (evolved to gem pattern, see ADR-YYY)
{: .language-markdown}

## Scope Update Process

### 1. Add Scope Note at Top

After the status section, before original context:

    ## Scope Note (Month Year)
    
    **Current Relevance**: The **[core concept]** in this ADR still applies to current ace-* gems. The **[specific part]** is legacy-only (see ADR-XXX archive).
    
    **Current gems** (ace-llm, ace-core, etc.) use [new approach] instead of [old approach], but the [principle/pattern] remains best practice.
    
    ---
    
    **Original Context:**
{: .language-markdown}

Then keep all original content below.

### 2. Update docs/decisions.md Entry

Add clarification note:

    ### Decision Title
    **Decision**: [Summary]. Note: [Specific parts] are legacy; [principles] still apply.
    **Impact**: [Updated with scope clarification]
    **Details**: [ADR-XXX](decisions/ADR-XXX-title.md)
{: .language-markdown}

## Synchronization with decisions.md

### Check Current State

    # List all active ADRs
    ls docs/decisions/ADR-*.md | grep -v archive | sort
    
    # List archived ADRs
    ls docs/decisions/archive/ADR-*.md 2>/dev/null | sort
    
    # Count ADRs
    echo "Active: $(ls docs/decisions/ADR-*.md | grep -v archive | wc -l)"
    echo "Archived: $(ls docs/decisions/archive/ADR-*.md 2>/dev/null | wc -l)"
{: .language-bash}

### Check for Missing ADRs in decisions.md

Find ADRs that exist as files but aren't in decisions.md:

    # Extract ADR numbers from files
    ls docs/decisions/ADR-*.md | grep -v archive | grep -o 'ADR-[0-9]*' | sort > /tmp/adr-files.txt
    
    # Extract ADR references from decisions.md (active sections only)
    grep -o 'ADR-[0-9]*' docs/decisions.md | grep -v "Archived Decisions" | sort -u > /tmp/adr-refs.txt
    
    # Find missing (in files but not in decisions.md)
    comm -23 /tmp/adr-files.txt /tmp/adr-refs.txt
{: .language-bash}

### Check for Orphaned References

Find ADRs referenced in decisions.md but don't exist as files:

    # Find references without files
    comm -13 /tmp/adr-files.txt /tmp/adr-refs.txt
{: .language-bash}

### Update decisions.md Structure

Ensure proper sectioning:

1.  **Active Decisions** - Currently applicable patterns
2.  **Architecture Decisions** - System design choices
3.  **Gem Architecture Patterns** - Gem-specific patterns
4.  **Development Tool Decisions** - Tool and process patterns
5.  **Archived Decisions** - Obsolete patterns (list only, with reasons)

## Validation

### After Maintenance Actions

    # Validate modified ADRs
    ace-docs validate docs/decisions/ADR-*.md
    
    # Validate decisions.md
    ace-docs validate docs/decisions.md
    
    # Check links (if ace-lint available)
    ace-lint docs/decisions/*.md
{: .language-bash}

### Manual Checks

* All ADR files have proper frontmatter
* All archived ADRs have deprecation
  notices
* All evolved ADRs have evolution sections
* decisions.md entries match file names
* No broken ADR cross-references
* Archive README lists all archived ADRs


## Common Maintenance Scenarios

### Scenario 1: Legacy Pattern Discovered

**Situation**: Found code pattern that might be obsolete

**Process**:

1.  Research usage with grep searches
2.  Check current gems vs \_legacy/
3.  If only in legacy → archive
4.  If in current gems → verify if evolution needed
5.  Update decisions.md accordingly

**Example**: October 2025 review found VCR, Zeitwerk, dry-monitor, ErrorReporter only in `_legacy/dev-tools/`

### Scenario 2: Pattern Evolved to New Architecture

**Situation**: Pattern migrated (e.g., mono-repo migration)

**Process**:

1.  Verify new implementation in current gems
2.  Document both old and new patterns
3.  Add evolution section to original ADR
4.  Consider creating new ADR if fundamentally different
5.  Update decisions.md with evolution note

**Example**: Template patterns evolved from the legacy dev-handbook structure to `gem/handbook/`

### Scenario 3: Quarterly ADR Review

**Checklist**:

* Check all ADRs for staleness
* Verify examples still accurate
* Update technology versions if referenced
* Sync with current gem structure
* Run missing ADR checks
* Update decisions.md if needed


### Scenario 4: New ADR Supersedes Old

**Process**:

1.  Create new ADR (see `create-adr.wf.md`)
2.  Add "Supersedes: ADR-XXX" to new ADR
3.  Archive or evolve old ADR appropriately
4.  Update decisions.md to reflect relationship

## Integration with create-adr Workflow

When creating new ADRs:

**Check for supersession:**

    # Search for related existing ADRs
    grep -i "pattern-name" docs/decisions/ADR-*.md
{: .language-bash}

**If superseding:**

1.  Note in new ADR: "Supersedes: ADR-XXX"
2.  Archive old ADR with deprecation notice
3.  Cross-reference in decisions.md

**Lifecycle:**

* **Creation**: Use `create-adr.wf.md`
* **Maintenance**: Use this workflow
* **Both**: Update decisions.md for consistency

## Success Criteria

* All ADRs reflect current codebase state
* Obsolete patterns clearly marked as
  archived
* Evolution documented with clear examples
* decisions.md synchronized with all ADR
  files
* No orphaned or undocumented decisions
* Archive README up to date
* All cross-references valid


## Troubleshooting

**Cannot determine if pattern is obsolete:**

* Research with grep across entire codebase
* Check both current gems and \_legacy/
* Look for alternative implementations
* Consult recent commits for migration patterns

**Unsure whether to archive or evolve:**

* Archive if: Pattern completely replaced, no longer applicable
* Evolve if: Same problem solved differently, principles still valid
* Update scope if: General concept valid, specific tech obsolete

**decisions.md sync errors:**

* Use comm commands to find mismatches
* Manually review each section
* Ensure archived ADRs only in "Archived Decisions" section

<documents>
    <template path="tmpl://decisions/archive-readme"># Archived Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) that are **deprecated** and no longer applicable to the current codebase.

## Why Archive Instead of Delete?

Archived ADRs preserve historical context and help understand the evolution of the codebase. They document decisions that were valid during specific phases but have been superseded by the current architecture.

## Archived ADRs

### ADR-XXX: Title
- **Archived**: YYYY-MM-DD
- **Reason**: Brief explanation of why archived
- **Current State**: Pointer to current practice or ADR
- **Context**: When this originally applied

## Migration Context

These ADRs were created during [specific phase, e.g., "legacy dev-tools phase"] before [migration event, e.g., "mono-repo migration (ADR-015)"]. The migration introduced new patterns:

- [List key architectural changes]
- [Reference to migration ADRs]
- [Current patterns that replaced archived ones]

## Related Active ADRs

For current architecture decisions, see:
- **docs/decisions.md**: Summary of all active decisions
- **ADR-XXX**: [Relevant current ADR]

---

**Note**: These archived ADRs are kept for historical reference only. Do not implement patterns from archived ADRs in new code.
    </template>

    <template path="tmpl://decisions/deprecation-notice">## Status

**Deprecated - Archived (Month Year)**

Original Status: Accepted
Date: YYYY-MM-DD

## Deprecation Notice

**This ADR is archived and no longer applicable to the current codebase.**

- **Archived**: YYYY-MM-DD
- **Reason**: [Specific reason - pattern not used, technology obsolete, superseded, etc.]
- **Current Practice**: [Pointer to current approach, ADR, or documentation]
- **Context**: [When/why this originally applied - e.g., "applied to legacy dev-tools before mono-repo migration"]

For current patterns, see:
- **ADR-XXX**: [Title and relevance]
- **Documentation**: [Path to current docs if applicable]

---

**Original ADR (for historical reference):**
    </template>

    <template path="tmpl://decisions/evolution-section">## Evolution: [New Pattern Name] (Month Year)

### Current State

The original [pattern/decision] has evolved with [context - architectural change, migration, new requirements].

**Current implementation:**
```
[Code structure, file pattern, or architectural diagram]
```

### Key Changes

1. **[Aspect 1]**: [How this changed]
   - Old: [Original approach]
   - New: [Current approach]

2. **[Aspect 2]**: [How this changed]
   - Old: [Original approach]
   - New: [Current approach]

3. **[Integration/Discovery]**: [How developers use this now]

### Examples in Production

**Current gems implementing this pattern:**
- **gem-name**: `path/to/implementation.rb` - [brief description]
- **gem-name**: `path/to/example.md` - [brief description]

### Relationship to Original Decision

The **principles remain valid**:
- ✅ [Core principle 1 still applies]
- ✅ [Core principle 2 still applies]
- ✅ [Core principle 3 still applies]

The **implementation evolved**:
- From: [Original pattern/location]
- To: [Current pattern/location]
- Reason: [Why it changed - better modularity, simpler architecture, new requirements]

**See ADR-XXX: [New Pattern ADR]** for complete details of the current approach.
    </template>
</documents>