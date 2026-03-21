---
doc-type: guide
title: Markdown Usage Standards
purpose: Documentation for ace-handbook/handbook/guides/meta/markdown-definition.g.md
ace-docs:
  last-updated: 2026-01-08
  last-checked: 2026-03-21
---

# Markdown Usage Standards

This guide establishes standards for markdown formatting within the development handbook system, focusing on proper code block escaping and markdown-within-markdown examples.

## Goal

Define clear principles for:
- When to use three-tick vs four-tick code block escaping
- How to properly demonstrate markdown syntax within documentation
- Markdown formatting consistency across guides and workflows

## Core Principles

1. **Appropriate Escaping**: Use the right level of escaping for the content being demonstrated
2. **Clarity**: Examples should clearly show the intended markdown syntax
3. **Consistency**: Uniform application of escaping rules across all documentation
4. **Readability**: Markdown demonstrations should be easy to follow and understand

## Code Block Escaping Standards

### Three-Tick Escaping (```): Standard Code Examples

Use standard three-tick escaping for:
- Command examples
- Code snippets
- Configuration examples
- Any code that is NOT markdown demonstration

```markdown
## Example Commands

```bash
git status
git add .
git commit -m "feat: add new feature"
```

## Configuration Example

```yaml
version: 1.0
settings:
  debug: false
```
```

### Four-Tick Escaping (````): ONLY for Markdown-within-Markdown

Reserve four-tick escaping **exclusively** for demonstrating markdown syntax within documentation:

````markdown
To show markdown examples in guides:

````markdown
# This is a markdown example
Content here demonstrates markdown syntax.
````
````

## Markdown Demonstration Examples

### Showing Markdown Headers

````markdown
Use this format to demonstrate header syntax:

````markdown
# Main Title
## Section Header
### Subsection Header
````
````

### Showing Markdown Lists

````markdown
Example of list formatting:

````markdown
- First item
- Second item
  - Nested item
  - Another nested item

1. Numbered list
2. Second item
   1. Nested numbered item
````
````

### Showing Markdown Links and References

````markdown
Link examples:

````markdown
[Link Text](https://example.com)
[Internal Link](path/to/file.md)
[Reference Link][ref-id]

[ref-id]: https://example.com "Reference title"
````
````

### Showing Markdown Code Blocks

````markdown
Code block examples:

````markdown
Inline `code` formatting.

```javascript
function example() {
    return "code block";
}
```
````
````

## Common Validation Issues

### ❌ Incorrect: Four-tick for regular code examples

````markdown
````bash
git status  # This should use three ticks
````
````

### ✅ Correct: Three-tick for regular code examples

````markdown
```bash
git status  # Proper three-tick escaping
```
````

### ❌ Incorrect: Three-tick for markdown demonstrations

````markdown
```markdown
# This markdown example won't render properly
```
````

### ✅ Correct: Four-tick for markdown demonstrations

````markdown
````markdown
# This markdown example renders correctly
````
````

## Validation Patterns

### Find incorrect four-tick usage (should be three-tick for code examples)
```regex
^````(?!markdown).*$
```
This finds four-tick blocks that aren't for markdown-within-markdown demonstrations.

### Find orphaned four-tick blocks (should only be for markdown demonstrations)
```regex
````(?!markdown)[\s\S]*?````
```
This finds four-tick blocks not used for markdown-within-markdown examples.

### Find three-tick markdown blocks (should be four-tick)
```regex
^```markdown[\s\S]*?^```
```
This finds markdown demonstrations using three-tick escaping instead of four-tick.

## Best Practices

### Markdown Documentation
- Use four-tick escaping when showing markdown syntax examples
- Always specify the language for code blocks
- Provide clear context for what the example demonstrates
- Keep examples focused and relevant to the documentation purpose

### Code Examples
- Use three-tick escaping for all non-markdown code examples
- Always specify the language (bash, yaml, json, etc.)
- Keep examples concise and functional
- Test command examples before including them

### Consistency
- Apply escaping rules uniformly across all documentation
- Review examples to ensure they render as intended
- Use validation patterns to catch incorrect escaping usage
- Update examples when markdown standards change

## Related Documentation

- [Template Embedding Guide](./template-embedding.g.md) - For template-specific formatting
- [Guides Definition](./guides-definition.g.md) - For guide writing standards
- [Writing Development Guides](./writing-guides-guide.md) - For comprehensive guide creation

This standardized approach ensures markdown consistency and proper rendering across the entire development handbook system.