---
description: Example showing mixed content and presets in a single section
context:
  params:
    output: stdio
    format: markdown-xml
    max_size: 10485760
    timeout: 30
    embed_document_source: true

  sections:
    comprehensive_review:
      title: "Comprehensive Project Review"
      description: "Complete review combining presets with mixed content types"
      presets:
        - "code-review"
        - "security-review"
      files:
        - "src/**/*.js"
        - "README.md"
        - "package.json"
      commands:
        - "npm test"
        - "npm run lint"
        - "npm audit"
      diffs:
        - "origin/main...HEAD"
      content: |
        This comprehensive review demonstrates the full power of the section system by combining:

        ## Preset Content
        - **code-review**: Code analysis patterns and review guidelines
        - **security-review**: Security scanning and vulnerability assessment

        ## Direct Content
        - Source files for manual code review
        - Test execution and quality checks
        - Security audit and dependency scanning
        - Recent changes via git diff
        - Manual analysis notes and observations

        ### Review Focus Areas
        1. **Code Quality**: Style, patterns, maintainability
        2. **Security**: Vulnerabilities, dependencies, best practices
        3. **Performance**: Potential bottlenecks and optimizations
        4. **Testing**: Coverage and test quality
        5. **Documentation**: Completeness and accuracy

        The content from presets and direct sources is merged intelligently, with deduplication of files and commands while preserving all relevant information.

    quick_check:
      title: "Quick Health Check"
      description: "Lightweight review with minimal presets"
      presets:
        - "base"
      commands:
        - "npm test"
        - "npm run build"
      content: |
        Quick validation of project health without extensive analysis.

---

This example demonstrates advanced section capabilities:

## Features Demonstrated

1. **Preset-in-Section Integration**
   - Multiple presets combined within a single section
   - Preset content merged with direct content
   - Automatic deduplication of files and commands

2. **Mixed Content Types**
   - Files, commands, diffs, and content in same section
   - No content_type or priority fields required
   - YAML order determines processing sequence

3. **Content Hierarchy**
   - Preset content provides foundation
   - Direct content adds project-specific elements
   - Intelligent merging maintains all relevant information

## Usage

```bash
# Load comprehensive review with all content
ace-context load mixed-content-example

# Content from code-review and security-review presets
# + local files, commands, diffs, and notes
# = complete project context
```

This approach enables modular, reusable context creation while maintaining flexibility for project-specific customization.