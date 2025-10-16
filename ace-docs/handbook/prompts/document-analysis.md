# Document Analysis User Prompt Template

This file serves as a template showing the structure of user prompts sent to the LLM for document analysis. The actual prompts are generated programmatically by `Ace::Docs::Prompts::DocumentAnalysisPrompt`.

## Structure

The user prompt consists of three main sections:

1. **Document Information** - Metadata about the document being analyzed
2. **Context** - Background information embedded via ace-context (optional, XML format)
3. **Changes to Analyze** - The git diff subject showing code changes

## Example User Prompt

```markdown
## Document Information

**Path**: ace-docs/README.md
**Type**: reference
**Purpose**: Main documentation for ace-docs gem, including installation, usage, and configuration

**Context Keywords**: documentation, frontmatter, git-diff, update tracking
**Context Preset**: project

## Context

This section contains embedded context using ace-context with XML formatting.
Context is optional and includes related documentation or code files that help
the LLM understand the broader project structure.

<file path="ace-docs/CHANGELOG.md">
# Changelog

All notable changes to ace-docs will be documented in this file.

...
</file>

<file path="docs/architecture.md">
# Architecture

ace-docs follows the ATOM architecture pattern...

...
</file>

## Changes to Analyze

The following git diff shows changes since 2025-10-14.

**Note**: This diff has been filtered to show only changes in:
- `ace-docs/**`
- `CHANGELOG.md`
- `README.md`

\```diff
diff --git a/ace-docs/lib/ace/docs/commands/analyze_command.rb b/ace-docs/lib/ace/docs/commands/analyze_command.rb
index 1234567..abcdefg 100644
--- a/ace-docs/lib/ace/docs/commands/analyze_command.rb
+++ b/ace-docs/lib/ace/docs/commands/analyze_command.rb
@@ -23,6 +23,7 @@ module Ace
       desc "analyze FILE", "Analyze changes for a document with LLM"
       option :since, desc: "Date or commit to analyze from"
+      option :verbose, type: :boolean, desc: "Enable detailed output"
       option :exclude_renames, type: :boolean, desc: "Exclude renamed files from diff"
       option :exclude_moves, type: :boolean, desc: "Exclude moved files from diff"
       def analyze(file)
\```
```

## XML Embedding Format

When context is included via ace-context, it uses XML tags for structured content:

### Files
```xml
<file path="relative/path/to/file.md">
File content here...
</file>
```

### Commands (if included)
```xml
<command name="git status" success="true">
Command output here...
</command>
```

### Diffs (if additional diffs included)
```xml
<diff range="2025-10-14..HEAD" success="true">
Diff output here...
</diff>
```

## Notes

- The system prompt is loaded separately via `ace-nav prompt://document-analysis.system`
- Context embedding is controlled by creating a `context.yml` configuration
- The ace-context integration uses `format: 'markdown-xml'` for XML-embedded content
- Users can customize context by overriding context.yml or using project-specific presets
