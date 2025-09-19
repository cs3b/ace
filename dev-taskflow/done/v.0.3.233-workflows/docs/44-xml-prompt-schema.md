# XML Prompt Schema Design for Reviews

## Schema Overview

Transform current markdown-based prompts to structured XML format with semantic containers:

```xml
---
generated: 2024-07-03T12:00:00Z
target: file.rb
focus: code
context: auto
---

<review-prompt>
  <project-context>
    <document type="blueprint">
      <![CDATA[
      # Project Blueprint content
      ]]>
    </document>
    <document type="vision">
      <![CDATA[
      # What we build content
      ]]>
    </document>
  </project-context>
  
  <review-target type="file">
    <![CDATA[
    Full file content or diff
    ]]>
  </review-target>
  
  <focus-areas type="code">
    <area>Code quality, architecture, security, performance</area>
    <area>ATOM architecture compliance</area>
    <area>Ruby best practices and conventions</area>
  </focus-areas>
</review-prompt>
```

## Semantic Tags

- `<project-context>`: Container for project knowledge documents
- `<document type="...">`: Specific project documents with CDATA content
- `<review-target type="...">`: Content to be reviewed (file/diff)
- `<focus-areas type="...">`: Structured focus items for review type

## Benefits

1. **Structured parsing**: LLMs can better understand content sections
2. **CDATA protection**: Preserves original document formatting
3. **Type attributes**: Clear content categorization
4. **Complete content**: No truncation of input materials
5. **YAML metadata**: Maintains session information compatibility
