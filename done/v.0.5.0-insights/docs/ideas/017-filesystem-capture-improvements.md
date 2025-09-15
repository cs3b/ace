---
:input_tokens: 45589
:output_tokens: 1087
:total_tokens: 46676
:took: 6.36
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-08-02T00:25:53Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45589
:cost:
  :input: 0.004559
  :output: 0.000435
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.004994
  :currency: USD
---

# Refactor `ideas_manager` to `capture-it` or `capture_it`

## Intention

Refactor all filesystem references related to "ideas_manager" to either "capture-it" or "capture_it" to ensure consistency with the new command name.

## Problem It Solves

**Observed Issues:**
- Filesystem paths and references within the codebase and documentation still refer to "ideas_manager".
- This inconsistency could lead to confusion, broken functionality, and incorrect assumptions about the system's naming conventions.
- Inconsistent naming hinders the discoverability and maintainability of the codebase.

**Impact:**
- Potential for runtime errors if "ideas_manager" paths are accessed and no longer exist or are incorrectly referenced.
- Reduced clarity and maintainability of the codebase due to mixed naming conventions.
- Difficulty for new developers to understand the project's current naming structure.

## Key Patterns from Reflections

- **Multi-Repository Coordination**: The project structure involves multiple repositories (`handbook-meta`, `.ace/handbook`, `.ace/tools`, `.ace/taskflow`) that need to be considered during refactoring.
- **ATOM Architecture**: The `.ace/tools` gem utilizes ATOM (Atoms, Molecules, Organisms, Ecosystems) for component organization. Renaming should be considered across these layers if `ideas_manager` is referenced within them.
- **CLI Tool Patterns**: The project has a large number of CLI tools. Renaming must be applied consistently across all relevant executables and their internal logic.
- **Security-First Development**: Path validation and sanitization are critical. Renaming should ensure that new paths are correctly handled by existing security mechanisms.
- **Workflow Instructions**: AI workflows (`.wf.md` files) might reference filesystem paths. These need to be updated if they are impacted by the renaming.
- **Template Synchronization**: XML-based embedding of templates might contain filesystem paths that need updating.
- **Project Standards**: XDG compliance and general Ruby best practices should be maintained during the refactoring.

## Solution Direction

1. **Filesystem Path Renaming**: Systematically rename directories, files, and any configuration entries that use "ideas_manager" to either "capture-it" or "capture_it".
2. **Codebase Search and Replace**: Perform a comprehensive search and replace operation across the entire codebase (including all submodules) for all occurrences of "ideas_manager" in file paths, variable names, class names, method calls, and string literals.
3. **Documentation Update**: Update all relevant documentation files (READMEs, ADRs, guides, workflow instructions, tool references) to reflect the new naming convention for filesystem paths.

## Critical Questions

**Before proceeding, we need to answer:**
1. Should the new filesystem path be "capture-it" (hyphenated) or "capture_it" (underscored)? (This decision needs to be made and consistently applied.)
2. Which specific directories and files are currently using the "ideas_manager" naming convention that need to be refactored?
3. What is the scope of impact? Does "ideas_manager" appear in CLI commands, internal configuration files, workflow instructions, or only in internal code/file paths?

**Open Questions:**
- Are there any automated scripts or workflows that specifically rely on the "ideas_manager" path that will need to be updated or reconfigured?
- What is the strategy for handling case sensitivity in file paths across different operating systems?
- How will this change be communicated to users and other developers?

## Assumptions to Validate

**We assume that:**
- "ideas_manager" is a distinct entity that can be consistently renamed without breaking core functionality. - *Needs validation*
- A single, consistent naming convention ("capture-it" or "capture_it") will be chosen and applied universally. - *Needs validation*
- All references to "ideas_manager" are directly related to the context of the "capture-it" command. - *Needs validation*
- The refactoring can be performed with minimal disruption to ongoing development. - *Needs validation*

## Expected Benefits

- **Naming Consistency**: Ensures all filesystem references align with the "capture-it" or "capture_it" naming convention.
- **Improved Maintainability**: Simplifies code navigation and reduces confusion for developers.
- **Reduced Risk of Errors**: Eliminates potential runtime errors caused by outdated or incorrect path references.
- **Enhanced Discoverability**: Makes it easier to locate relevant files and directories.

## Big Unknowns

**Technical Unknowns:**
- The exact location and number of all "ideas_manager" filesystem references across all repositories and submodules.
- Potential conflicts or unintended side effects of a global search and replace operation.

**User/Market Unknowns:**
- How users might currently interact with or rely on the "ideas_manager" filesystem structure (if at all).

**Implementation Unknowns:**
- The most effective strategy for performing a multi-repository, cross-file-type search and replace operation.
- The best approach for testing the impact of these changes across all affected components and workflows.