# handbook - Template Synchronization Tool

## Overview

`handbook` is a specialized tool for synchronizing XML-embedded template content in workflow instruction files (`.wf.md`) with their corresponding template source files. It ensures workflow self-containment by keeping embedded templates in sync with their canonical sources.

## Purpose

The tool was created to:
- Maintain workflow self-containment per ADR-001
- Synchronize XML-embedded templates with source files
- Support both modern `<documents>` and legacy `<templates>` formats
- Automate template updates across workflow files
- Validate template embedding integrity

## Location

- **Executable**: `/dev-tools/exe/handbook`
- **Primary Command**: `/dev-tools/lib/coding_agent_tools/cli/commands/handbook/sync_templates.rb`
- **Organism**: `/dev-tools/lib/coding_agent_tools/organisms/taskflow_management/template_synchronizer.rb`

## API Reference

### Main Command

```bash
handbook sync-templates [options]
```

### Options

| Option | Aliases | Type | Default | Description |
|--------|---------|------|---------|-------------|
| `--path` | - | string | dev-handbook/workflow-instructions | Directory to scan for workflow files |
| `--dry-run` | - | boolean | false | Preview changes without modifying files |
| `--verbose` | - | boolean | false | Show detailed processing information |
| `--commit` | - | boolean | false | Automatically commit changes after sync |
| `--help` | `-h` | boolean | false | Show help message |

### Legacy Claude Subcommands (Deprecated)

The executable references these commands but they are **no longer available**:
- `handbook claude generate-commands` (removed)
- `handbook claude integrate` (removed)
- `handbook claude validate` (removed)
- `handbook claude list` (removed)
- `handbook claude update-registry` (removed)

These were migrated to other tools or deprecated.

## How It Works

### XML Template Embedding Formats

#### Modern Format (Current)
```markdown
# workflow-name.wf.md

Instructions here...

<documents>
<template path="dev-handbook/templates/example.template.md">
Template content here
</template>

<guide path="dev-handbook/guides/example.g.md">
Guide content here
</guide>
</documents>
```

#### Legacy Format (Backward Compatible)
```markdown
<templates>
<template path="dev-handbook/templates/example.template.md">
Template content here
</template>
</templates>
```

### Synchronization Process

1. **Scan Directory**: Find all `.wf.md` files in target directory
2. **Parse XML Blocks**: Extract `<documents>` or `<templates>` sections
3. **Read Source Files**: Load template/guide content from paths
4. **Compare Content**: Check if embedded content matches source
5. **Update Files**: Replace outdated embedded content
6. **Report Changes**: Show what was synchronized

### Architecture (ATOM Pattern)

#### Atoms
- **XmlParser**: Parse XML template blocks
- **FileReader**: Read template source files
- **ContentComparer**: Compare embedded vs source content
- **PathValidator**: Validate template paths

#### Molecules
- **TemplateExtractor**: Extract templates from workflow files
- **TemplateEmbedder**: Embed templates into workflow files
- **SyncValidator**: Validate sync operations

#### Organisms
- **TemplateSynchronizer**: Orchestrate complete sync workflow
  - Scan for workflow files
  - Extract XML blocks
  - Load source templates
  - Update embedded content
  - Report results

#### Models
- **SyncConfig**: Configuration for sync operation
- **SyncResult**: Results of synchronization
- **TemplateBlock**: Represents an embedded template

### Execution Flow

```
Workflow Directory
        ↓
File Scanner (find .wf.md files)
        ↓
XML Parser (extract <documents>/<templates>)
        ↓
Template Reader (load source files)
        ↓
Content Comparer (check for changes)
        ↓
File Updater (write updated content)
        ↓
Result Reporter (show changes)
        ↓
Optional: Git Commit
```

## Usage Examples

### Basic Synchronization

```bash
# Sync templates in default directory
handbook sync-templates

# Sync templates in custom directory
handbook sync-templates --path custom/workflows
```

### Preview Changes

```bash
# Dry run - see what would change
handbook sync-templates --dry-run

# Dry run with verbose output
handbook sync-templates --dry-run --verbose
```

### Automated Workflow

```bash
# Sync and commit changes
handbook sync-templates --commit

# Full verbose sync with commit
handbook sync-templates --verbose --commit
```

### Custom Directory

```bash
# Sync templates in custom location
handbook sync-templates --path dev-handbook/workflow-instructions

# Preview changes in custom location
handbook sync-templates --path custom/path --dry-run --verbose
```

## Output Examples

### Successful Sync
```
Synchronizing templates...

✓ Scanned 15 workflow files
✓ Found 23 embedded templates
✓ 5 templates updated
✓ 18 templates already in sync

Updated files:
  - dev-handbook/workflow-instructions/task-create.wf.md (2 templates)
  - dev-handbook/workflow-instructions/release-draft.wf.md (1 template)
  - dev-handbook/workflow-instructions/code-review.wf.md (2 templates)

Synchronization complete!
```

### Dry Run Output
```
Dry run - no changes will be made

Would update:
  dev-handbook/workflow-instructions/task-create.wf.md
    - Template: dev-handbook/templates/task.template.md
      Status: Out of sync (15 lines changed)

  dev-handbook/workflow-instructions/release-draft.wf.md
    - Template: dev-handbook/templates/release.template.md
      Status: Out of sync (3 lines changed)

Would sync 2 templates in 2 files
```

### Verbose Output
```
🔍 Scanning directory: dev-handbook/workflow-instructions
  Found: task-create.wf.md
  Found: release-draft.wf.md
  Found: code-review.wf.md
  Total: 3 files

📄 Processing: task-create.wf.md
  Extracting XML blocks...
  Found <documents> block with 2 templates

  Template 1: dev-handbook/templates/task.template.md
    Reading source file...
    Source: 150 lines
    Embedded: 145 lines
    Status: OUT OF SYNC
    Updating embedded content...
    ✓ Updated

  Template 2: dev-handbook/templates/metadata.template.md
    Reading source file...
    Source: 25 lines
    Embedded: 25 lines
    Status: IN SYNC
    No changes needed

✅ Processed 3 files, updated 1 template
```

## Integration with ace-* Architecture

### Current Status

`handbook` is a **specialized tool within dev-tools** focused on template synchronization for workflow self-containment.

### Migration Path: ace-handbook

The natural home for this tool is the planned **ace-handbook** gem.

```ruby
# Future: ace-handbook gem structure
ace-handbook/
├── lib/ace/handbook/
│   ├── atoms/
│   │   ├── xml_parser.rb
│   │   ├── content_comparer.rb
│   │   └── path_validator.rb
│   ├── molecules/
│   │   ├── template_extractor.rb
│   │   ├── template_embedder.rb
│   │   └── sync_validator.rb
│   ├── organisms/
│   │   ├── template_synchronizer.rb
│   │   ├── workflow_manager.rb
│   │   └── agent_validator.rb
│   └── models/
│       ├── workflow.rb
│       ├── template.rb
│       └── agent.rb
├── exe/
│   └── ace-handbook
└── test/
    ├── atoms/
    ├── molecules/
    └── organisms/
```

### Future CLI Interface

```bash
# Template synchronization
ace-handbook sync-templates
ace-handbook sync-templates --dry-run
ace-handbook sync-templates --path custom/

# Workflow management
ace-handbook workflow list
ace-handbook workflow validate [file]
ace-handbook workflow create [name]

# Agent management (from agent-lint)
ace-handbook agent list
ace-handbook agent validate [file]
ace-handbook agent create [name]

# Guide management
ace-handbook guide list
ace-handbook guide validate [file]
```

### Integration Points

#### With Workflow Execution
```bash
# Ensure templates are synced before workflow
ace-handbook sync-templates && ace-taskflow task create
```

#### With Git Hooks
```bash
# Pre-commit hook to sync templates
#!/bin/bash
ace-handbook sync-templates --commit
```

#### With CI/CD
```bash
# Validate templates are in sync
ace-handbook sync-templates --dry-run || exit 1
```

## Configuration

### Current Configuration

Uses `SyncConfig` model passed to TemplateSynchronizer:

```ruby
config = TemplateSynchronizer::SyncConfig.new(
  path: "dev-handbook/workflow-instructions",
  dry_run: false,
  verbose: false,
  commit: false
)
```

### Future Configuration (ace-handbook)

```yaml
# .ace/handbook/config.yml
ace:
  handbook:
    workflows:
      directory: "dev-handbook/workflow-instructions"
      sync:
        auto_sync: true
        auto_commit: false
        include_patterns:
          - "**/*.wf.md"
        exclude_patterns:
          - "**/deprecated/**"

    templates:
      directory: "dev-handbook/templates"
      formats:
        - template  # .template.md
        - guide     # .g.md

    agents:
      directory: "dev-handbook/agents"
      validation:
        strict: true
```

## Exit Codes

- `0` - Success (sync completed or dry run successful)
- `1` - Error occurred during processing

## Architectural Decisions

### ADR-001: Workflow Self-Containment

The `handbook sync-templates` command directly implements **ADR-001: Workflow Self-Containment Principle**:

> All AI workflows must be completely self-contained with embedded templates and context. Workflows cannot depend on other workflows or external files except the three standard context documents.

**Implementation**:
- Workflows embed templates within XML blocks
- `sync-templates` keeps embedded content synchronized
- Ensures workflows can execute without external template files

### ADR-002: XML Template Embedding

Implements **ADR-002: XML Template Embedding Architecture**:

> Use XML format `<documents>` and `<template>` tags for embedding templates within workflow files.

**Implementation**:
- Parses `<documents>` and `<templates>` XML blocks
- Supports `<template>` and `<guide>` document types
- Maintains embedded content from source files

### ADR-005: Universal Document Embedding

Supports **ADR-005: Universal Document Embedding System**:

> Use the universal `<documents>` container format for embedding any type of document.

**Implementation**:
- Handles multiple document types (template, guide)
- Unified XML parsing for all embedded content
- Extensible to new document types

## Limitations

1. **XML-Only**: Only synchronizes XML-embedded templates, not other formats
2. **Manual Trigger**: Requires manual execution, no auto-sync on template changes
3. **Single Directory**: Processes one directory at a time
4. **No Conflict Resolution**: Overwrites embedded content without merge logic
5. **Missing Claude Commands**: Referenced subcommands no longer exist

## Future Enhancements

### For ace-handbook Migration

1. **Watch Mode**:
   ```bash
   ace-handbook sync-templates --watch
   # Auto-sync when templates change
   ```

2. **Selective Sync**:
   ```bash
   ace-handbook sync-templates --file workflow-name.wf.md
   # Sync single workflow
   ```

3. **Validation Mode**:
   ```bash
   ace-handbook sync-templates --validate
   # Check sync status without updating
   ```

4. **Template Management**:
   ```bash
   ace-handbook template create [name]
   ace-handbook template list
   ace-handbook template validate
   ```

5. **Workflow Management**:
   ```bash
   ace-handbook workflow create [name]
   ace-handbook workflow list
   ace-handbook workflow validate
   ```

6. **Integration Hooks**:
   - Git pre-commit hook to auto-sync
   - CI validation to ensure sync
   - Editor plugin for real-time sync

## Related Tools

- **agent-lint**: Agent validation (future: `ace-handbook agent validate`)
- **ace-nav**: Workflow discovery via `wfi://` protocol
- **ace-taskflow**: Workflow execution
- **Template files**: Source of truth in `dev-handbook/templates/`

## Historical Context

Developed to support ADR-001 (Workflow Self-Containment):

1. **Problem**: Workflows referenced external template files
2. **Solution**: Embed templates directly in workflow files
3. **Challenge**: Keeping embedded content synchronized
4. **Tool**: `handbook sync-templates` automates synchronization

The XML embedding format was chosen to:
- Enable automated extraction and updates
- Maintain readability in markdown
- Support multiple document types
- Preserve original formatting

## Migration Timeline

- **Current**: Available as `handbook sync-templates` in dev-tools
- **v0.10.0**: Extract to `ace-handbook` gem with expanded functionality
- **v0.11.0**: Add workflow and agent management commands
- **v0.12.0**: Deprecation warning for standalone `handbook` tool
- **v1.0.0**: Remove from dev-tools, use `ace-handbook sync-templates`

## See Also

- ADR-001: Workflow Self-Containment Principle
- ADR-002: XML Template Embedding Architecture
- ADR-005: Universal Document Embedding System
- Template directory: `dev-handbook/templates/`
- Workflow directory: `dev-handbook/workflow-instructions/`
- Agent validation: `docs/agent-lint.md`
