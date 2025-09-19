# YAML Frontmatter Integration Plan

## Current Structure

```markdown
# Code Review Prompt - ${focus} Focus

Generated: $(date -Iseconds)
Target: ${target}
Focus: ${focus}
Context: ${context:-auto}
```

## New XML Structure with YAML

```yaml
---
generated: 2024-07-03T12:00:00Z
target: file.rb
focus: code
context: auto
type: review-prompt
---

<review-prompt>
  <!-- XML content -->
</review-prompt>
```

## Implementation Strategy

1. **Keep YAML metadata**: Session information in frontmatter
2. **XML body**: Structured content below frontmatter  
3. **Backward compatibility**: LLM tools can still parse prompts
4. **Date format**: Use ISO 8601 format for consistency

## Benefits

- **Metadata separation**: Clear distinction between session data and content
- **Tool parsing**: Standard YAML parsing for metadata extraction
- **Content structure**: XML provides semantic meaning to content sections
