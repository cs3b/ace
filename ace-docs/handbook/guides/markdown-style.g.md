---
doc-type: guide
title: Markdown Style Guide
purpose: Documentation for ace-docs/handbook/guides/markdown-style.g.md
ace-docs:
  last-updated: 2026-02-23
  last-checked: 2026-03-21
---

# Markdown Style Guide

This guide defines typography and formatting conventions for technical markdown documents. These standards optimize readability in monospace environments - terminals, code editors, and documentation tools.

## Goal

Establish consistent markdown styling that:
- Reads well in monospace fonts and terminal displays
- Supports both human and AI-agent consumption
- Creates visual hierarchy without relying on rich rendering
- Maintains clarity when viewed as plain text

## Core Principles

1. **Terminal-First**: Style choices should work in monospace environments
2. **Plain-Text Friendly**: Documents should be readable without rendering
3. **Visual Anchors**: Use emojis sparingly as scannable landmarks
4. **Vertical Rhythm**: Align related elements for visual coherence

## Typography Standards

### Em-Dashes: Use Spaced Hyphens

Em-dashes (`—`) render inconsistently across fonts and terminals. Use space-hyphen-space instead.

**Avoid:**
```
The toolkit—designed for AI agents—supports multiple workflows.
```

**Prefer:**
```
The toolkit - designed for AI agents - supports multiple workflows.
```

This ensures consistent width and readability in monospace displays.

### Quotation Marks

Use straight quotes (`"`, `'`) rather than curly/smart quotes (`"`, `"`, `'`, `'`).

**Avoid:**
```
"Smart quotes" cause encoding issues.
```

**Prefer:**
```
"Straight quotes" work everywhere.
```

### Bullet Characters

Use standard ASCII hyphens (`-`) for unordered lists. Avoid fancy bullets or custom characters.

```markdown
- First item
- Second item
  - Nested item
```

## File Tree Formatting

Use Unicode box-drawing characters in code blocks for file trees. This creates clear visual hierarchy.

### Basic Structure

```
project/
├── src/
│   ├── components/
│   │   ├── Button.tsx         # UI component
│   │   └── Modal.tsx          # Dialog component
│   └── utils/
│       └── helpers.ts         # Utility functions
├── docs/
│   ├── architecture.md        # Technical design
│   └── vision.md              # Project vision
└── README.md                  # Entry point
```

### Box-Drawing Characters

| Character | Name | Usage |
|-----------|------|-------|
| `├──` | Branch | Non-final sibling |
| `└──` | End | Final sibling |
| `│` | Pipe | Continuation |

### Comment Alignment

Align `#` comments vertically within each tree section for scannability.

```
ace-docs/
├── lib/
│   ├── cli.rb                 # Command-line entry
│   ├── config.rb              # Configuration loader
│   └── generator.rb           # Document generator
└── handbook/
    ├── guides/                # How-to documentation
    ├── prompts/               # LLM system prompts
    └── templates/             # Document templates
```

**Tip:** Use a text editor with column selection (block mode) to align comments efficiently.

## Emoji Usage

Emojis serve as **visual anchors** for scannability - not decoration.

### When to Use Emojis

- **Section headers** in lists or principles
- **Status indicators** (completed, in-progress, blocked)
- **Category markers** for quick visual grouping

### Guidelines

1. **One emoji per item** - avoid stacking multiple emojis
2. **Consistent per category** - use the same emoji for the same concept
3. **Meaningful placement** - at the start of headers, not inline
4. **Skip when not scanning** - prose paragraphs rarely need emojis

### Numbered Lists with Emojis

For principles or key concepts, use numbered lists with leading emojis:

```markdown
1. 🖥️ **Terminal-First** - Optimize for monospace display
2. 🔍 **Discoverable** - Easy to find and navigate
3. 🤖 **Agent-Ready** - Structured for AI consumption
4. ✨ **Minimal** - Only what's necessary
```

### Category Markers

```markdown
## Features

- 📦 **Bundling** - Context aggregation
- 🔍 **Search** - Code discovery
- 📝 **Docs** - Documentation generation
```

## Headers and Sections

### Link Preservation

When a header's content moves to a code block, keep the link in the header:

```markdown
## [Project Structure](./docs/architecture.md)

```
project/
├── src/
└── docs/
```
```

This maintains navigation while showing structured content.

### Manifesto-Style Openers

For vision documents, use blockquote openers to set tone:

```markdown
> **Clarity through constraint.** Build tools that make developers faster,
> not tools that require learning curves.
```

## Code Block Conventions

### Language Tags

Always specify language for syntax highlighting:

```markdown
```ruby
def example
  # implementation
end
```
```

### Indentation in Examples

Use 2-space indentation in code examples for compactness.

### Shell Commands

Use `bash` or `sh` for shell examples. Include `$` prompt only when showing interactive sessions:

```bash
ace-bundle project
ace-test atoms
```

## Before/After Examples

### Typography Transformation

**Before (problematic):**
```
The toolkit—designed for AI agents—provides:
• "Smart quotes" for text
• Bullet using special character
```

**After (correct):**
```
The toolkit - designed for AI agents - provides:
- "Straight quotes" for text
- Bullet using hyphen
```

### File Tree Transformation

**Before (plain text):**
```
docs/
  guides/
    style.md
  templates/
    vision.md
```

**After (structured):**
```
docs/
├── guides/
│   └── style.md               # Style guidance
└── templates/
    └── vision.md              # Vision template
```

### Principle List Transformation

**Before (flat):**
```
Core Principles:
- Terminal-First: Optimize for monospace display
- Discoverable: Easy to find and navigate
- Agent-Ready: Structured for AI consumption
```

**After (scannable):**
```
Core Principles:

1. 🖥️ **Terminal-First** - Optimize for monospace display
2. 🔍 **Discoverable** - Easy to find and navigate
3. 🤖 **Agent-Ready** - Structured for AI consumption
```

## Validation

### Manual Checks

1. View document in terminal: `cat docs/example.md`
2. Check for em-dash rendering: search for `—`
3. Verify tree alignment in monospace font
4. Ensure emoji display correctly in target environments

### Automated Checks

ace-lint can detect typography violations (planned feature):

```bash
ace-lint --check typography docs/
```

## Related Documentation

- [Documentation Guide](guide://documentation) - Document structure and placement
- [Vision Template](tmpl://project-docs/vision) - Styled vision document template

---

*These conventions prioritize universal readability over visual richness.*
