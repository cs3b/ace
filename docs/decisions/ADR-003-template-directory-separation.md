# ADR-003: Template Directory Separation

## Status

Accepted
Date: 2025-06-30

## Context

The Coding Agent Workflow Toolkit contained 27 template files scattered throughout the `dev-handbook/guides/` directory, mixed with instructional guides and documentation. These templates served various purposes including system prompts for code review, document templates for project initialization, and task templates for release management.

### Problems with Templates Mixed in Guides Directory

1. **Discoverability Issues**: Template files were buried within guide directories, making them difficult to locate when needed for workflow instructions or system automation.

2. **Naming Confusion**: Template files used inconsistent naming patterns (prefixed with `_`, `TEMPLATE-`, or embedded in guide directories), making it unclear which files were templates versus actual documentation.

3. **Search Interference**: When searching for guides or documentation, results included template files, creating noise and confusion about which files contained actual instructional content.

4. **Unclear Purpose Distinction**: No clear separation between files meant as reusable templates versus files serving as examples, guides, or documentation.

5. **Maintenance Complexity**: Template updates required navigation through multiple guide directories, and it was unclear which files were templates requiring synchronization with embedded content.

### Analysis from Template Extraction Work

Survey of `dev-handbook/guides/` revealed:
- **27 template files** scattered across 8 different directories
- **5 different naming conventions** used inconsistently
- **No clear categorization** by template type or purpose  
- **Mixed file types**: System prompts, document templates, task templates, and examples all intermixed
- **Template references in workflow instructions** pointing to guide paths rather than dedicated template locations

## Decision

All template files must be extracted from `dev-handbook/guides/` and organized in a dedicated `dev-handbook/templates/` directory with the following structure and naming conventions:

### Directory Structure

```
dev-handbook/templates/
├── project-docs/           # Project initialization templates
│   ├── adr.template.md
│   ├── architecture.template.md
│   ├── blueprint.template.md
│   ├── prd.template.md
│   └── vision.template.md
├── release-tasks/          # Task management templates
│   ├── task.template.md
│   └── example.md
├── release-planning/       # Release management templates
│   └── release-readme.template.md
├── review-code/           # Code review system prompts
│   ├── system.prompt.md
│   └── diff.prompt.md
├── review-docs/           # Documentation review prompts
│   ├── system.prompt.md
│   └── diff.prompt.md
└── [other categories]/    # Additional template categories
```

### Naming Conventions

1. **Template Files**: Use `.template.md` suffix for reusable document templates
2. **System Prompts**: Use `.prompt.md` suffix for LLM system prompts
3. **Examples**: Use `.md` suffix with descriptive names for example files
4. **Directory Names**: Use kebab-case with descriptive category names

### Separation Principles

1. **Clear Purpose Distinction**: Template files are reusable patterns; guide files are instructional content
2. **Categorical Organization**: Templates grouped by purpose (project-docs, release-management, code-review, etc.)
3. **Consistent Naming**: File suffixes clearly indicate template type and purpose
4. **Centralized Location**: All templates in single directory hierarchy for easy discovery

## Consequences

### Positive

- **Improved Discoverability**: All templates located in single, well-organized directory structure with clear categorization.

- **Clear Purpose Separation**: Unambiguous distinction between reusable templates and instructional guides eliminates confusion.

- **Better Search Results**: Searching for guides no longer returns template files, and searching for templates provides focused results.

- **Consistent Naming**: Standardized file suffixes (`.template.md`, `.prompt.md`) make file purposes immediately clear.

- **Easier Maintenance**: Template updates can be performed efficiently within centralized directory structure.

- **Enhanced Template Management**: Automated synchronization tools can easily identify and process template files based on directory location and naming conventions.

### Negative

- **Reference Updates Required**: All workflow instructions and scripts referencing old template paths needed updating (66 references across multiple files).

- **Migration Effort**: Required systematic movement and renaming of 27 template files from various guide directories.

- **Learning Curve**: Users must learn new template directory structure and understand the separation from guides.

- **Potential Link Breakage**: Risk of broken internal links if references were not updated comprehensively.

### Neutral

- **Changed File Locations**: Template file paths changed from `dev-handbook/guides/*/` to `dev-handbook/templates/*/`, requiring path updates in referencing documents.

- **Directory Structure Evolution**: The `dev-handbook/guides/` directory becomes purely instructional while `dev-handbook/templates/` becomes purely functional.

## Alternatives Considered

### Alternative 1: Status Quo (Mixed Templates and Guides)

- **Description**: Keep templates embedded within guide directories where they were logically related
- **Why it wasn't chosen**:
  - Continued discoverability and searchability problems
  - Maintained naming inconsistencies and purpose confusion
  - Made automated template processing more complex
  - Conflicted with self-contained workflow requirements

### Alternative 2: Template Subdirectories Within Guides

- **Description**: Create template subdirectories within each guide directory (e.g., `guides/code-review/templates/`)
- **Why it wasn't chosen**:
  - Still scattered templates across multiple locations
  - Didn't solve search interference problems
  - Made centralized template management more difficult
  - Increased complexity for automated tooling

### Alternative 3: Flat Template Directory Structure

- **Description**: Move all templates to `dev-handbook/templates/` without categorical subdirectories
- **Why it wasn't chosen**:
  - Would create a single directory with 27+ files of different types
  - Made template discovery difficult without clear organization
  - Didn't provide logical grouping by template purpose
  - Hindered maintenance by mixing different template categories

## Related Decisions

- **ADR-001**: Workflow Self-Containment Principle - requires embedded templates, making template file organization crucial for synchronization
- **ADR-002**: XML-Based Template Embedding Architecture - requires path attributes pointing to organized template file locations

## References

- **Implementation Task**: v.0.3.0+task.17: Extract Templates to dev-handbook/templates Directory
- **Original Requirement**: improve-the-workflow-structure.md
- **Validation**: `bin/lint` link checking after migration
- **Update Tasks**: Reference updates in dev-handbook and dev-tools directories

## Examples

### Before: Templates Mixed in Guides

```
dev-handbook/guides/
├── code-review/
│   ├── _code-review-system.md          # Template mixed with guide
│   ├── _doc-review-system.md           # Template mixed with guide
│   └── README.md                       # Actual guide
├── draft-release/
│   └── v.x.x.x/
│       ├── tasks/_template.md          # Template in guide structure
│       └── reflections/_template.md    # Template in guide structure
└── initialize-project-templates/
    ├── PRD.md                          # Template file
    ├── architecture.md                 # Template file
    └── what-do-we-build.md             # Template file
```

### After: Separated Template Directory

```
dev-handbook/templates/
├── project-docs/
│   ├── prd.template.md                 # Clear template naming
│   ├── architecture.template.md        # Clear template naming
│   └── vision.template.md              # Clear template naming
├── review-code/
│   └── system.prompt.md                # Clear prompt naming
├── review-docs/
│   └── system.prompt.md                # Clear prompt naming
└── release-tasks/
    └── task.template.md                # Clear template naming

dev-handbook/guides/
├── code-review/
│   └── README.md                       # Pure instructional content
└── draft-release/
    └── README.md                       # Pure instructional content
```

This architectural decision establishes clear separation of concerns between reusable templates and instructional content, enabling better organization, discoverability, and automated template management while supporting the self-contained workflow architecture.