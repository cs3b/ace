# Create User Documentation Workflow Instruction

## Goal

Create or update user-facing documentation (e.g., README additions, tutorials, usage examples) for a new feature or significant change, ensuring users can effectively understand and utilize the functionality.

## Prerequisites

- Feature/change is implemented or well-defined
- Understanding of the target audience and their needs
- Access to relevant code, examples, and task descriptions
- Knowledge of the feature's use cases and limitations

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps
- [ ] Identify documentation scope and target audience
- [ ] Analyze feature functionality and use cases
- [ ] Create appropriate documentation structure for the content type

### Execution Steps

- [ ] Write clear, comprehensive user documentation
- [ ] Include practical examples and code snippets
- [ ] Add troubleshooting guidance and FAQs
- [ ] Review and test all documentation content
- [ ] Organize documentation in appropriate location

## Process Steps

1. **Identify Scope & Audience:**
   - Determine documentation needs:
     - What feature/change needs documenting?
     - Who will use this documentation?
     - What is their technical level?
     - What are their goals?

   - Common audience types:
     - **End Users**: Need task-focused guides
     - **Developers**: Need API references and integration guides
     - **Administrators**: Need configuration and deployment guides
     - **Contributors**: Need development setup and architecture docs

2. **Analyze Feature:**
   - Review the feature to understand:
     - Core functionality and purpose
     - Configuration options and defaults
     - Common use cases and workflows
     - Integration points with other features
     - Prerequisites and dependencies
     - Known limitations or constraints
     - Error scenarios and troubleshooting

3. **Create Documentation Structure:**

   **Standard User Documentation Template:**

   ```markdown
   # [Feature Name]
   
   ## Overview
   Brief description of what this feature does and why users would want it.
   
   ## Quick Start
   Minimal steps to get started with the most common use case.
   
   ```bash
   # Example commands or code
   ```

   ## Prerequisites

   - Required dependencies
   - System requirements
   - Access permissions needed

   ## Installation/Setup

   Step-by-step setup instructions with examples.

   ## Basic Usage

   ### [Common Task 1]

   How to accomplish the most common task.

   ```javascript
   // Code example with annotations
   const result = feature.doSomething({
     option1: 'value',  // Explanation of option
     option2: true      // Why this is needed
   });
   ```

   ### [Common Task 2]

   Another common use case with examples.

   ## Configuration

   | Option | Type | Default | Description |
   |--------|------|---------|-------------|
   | timeout | number | 30 | Request timeout in seconds |
   | retries | number | 3 | Number of retry attempts |
   | debug | boolean | false | Enable debug logging |

   ## Advanced Usage

   ### [Advanced Feature 1]

   More complex scenarios and patterns.

   ### Custom Extensions

   How to extend or customize the feature.

   ## Troubleshooting

   ### Common Issues

   **Problem**: Error message appears
   **Solution**: Steps to resolve

   **Problem**: Feature doesn't work as expected
   **Solution**: Debugging steps

   ## Examples

   ### Example 1: [Use Case]

   Complete working example with explanation.

   ### Example 2: [Integration]

   How to integrate with other tools/features.

   ## API Reference

   Link to generated API documentation or inline reference.

   ## Migration Guide

   (If applicable) How to migrate from previous versions.

   ## FAQ

   **Q: Question users often ask?**
   A: Clear, helpful answer.

   ## Related Resources

   - Link to related features
   - External documentation
   - Video tutorials

   ```

4. **Write Clear Content:**

   **Writing Guidelines:**
   - **Start with why**: Explain the value before the how
   - **Use active voice**: "Click the button" not "The button should be clicked"
   - **Be concise**: Get to the point quickly
   - **Show, don't just tell**: Include examples and visuals
   - **Progressive disclosure**: Start simple, add complexity gradually

   **Code Example Best Practices:**

   ```javascript
   // BAD: No context or explanation
   config.set('key', value);
   
   // GOOD: Clear context and explanation
   // Configure the API endpoint for production
   config.set('apiEndpoint', 'https://api.example.com/v2');
   
   // You can also use environment variables
   config.set('apiEndpoint', process.env.API_ENDPOINT || 'https://api.example.com/v2');
   ```

5. **Include Practical Examples:**

   **Example Types to Include:**
   - **Minimal Example**: Simplest possible usage
   - **Real-World Example**: Common production scenario
   - **Integration Example**: Using with other features
   - **Error Handling Example**: Proper error management

   ```python
   # Minimal Example
   from feature import Client
   client = Client()
   result = client.process("data")
   
   # Real-World Example with Error Handling
   from feature import Client, FeatureError
   import logging
   
   logger = logging.getLogger(__name__)
   client = Client(timeout=60, retries=3)
   
   try:
       result = client.process(
           data="production data",
           validate=True,
           callback=lambda x: logger.info(f"Processed: {x}")
       )
       print(f"Success: {result.status}")
   except FeatureError as e:
       logger.error(f"Processing failed: {e}")
       # Fallback logic here
   ```

6. **Add Visual Aids (if applicable):**

   ```markdown
   ## Architecture Overview
   ```mermaid
   graph LR
       A[User] --> B[Feature API]
       B --> C[Processing Engine]
       C --> D[Database]
       C --> E[External Service]
   ```

   ## Workflow Diagram

   ![Feature Workflow](./images/feature-workflow.png)

   ```

7. **Review and Test:**

   **Documentation Review Checklist:**
   - [ ] Accuracy: All information is correct
   - [ ] Completeness: All features are documented
   - [ ] Clarity: Easy to understand for target audience
   - [ ] Examples: Code examples work as written
   - [ ] Structure: Logical flow and organization
   - [ ] Grammar: No spelling or grammar errors
   - [ ] Links: All links work correctly
   - [ ] Formatting: Consistent markdown formatting

   **Test the Documentation:**
   1. Follow your own quickstart guide
   2. Try all code examples
   3. Verify configuration options
   4. Test troubleshooting steps

8. **Save and Organize:**

   **Documentation Locations:**
   - **Project README**: High-level overview and quickstart
   - **docs/ directory**: Detailed guides and tutorials
   - **examples/ directory**: Complete working examples
   - **API docs**: Generated from code comments
   - **Wiki**: Collaborative documentation
   - **Release notes**: Version-specific changes

   **File Naming Conventions:**
   - `getting-started.md` - Initial setup guide
   - `user-guide.md` - Comprehensive user manual
   - `api-reference.md` - API documentation
   - `troubleshooting.md` - Problem-solving guide
   - `examples/` - Working code examples

9. **Commit Documentation:**

   ```bash
   git add docs/
   git commit -m "docs(user): add comprehensive guide for new feature
   
   - Add quickstart guide
   - Include configuration reference
   - Provide troubleshooting section
   - Add real-world examples"
   ```

## User Documentation Types

### README

- Project overview
- Quick installation
- Basic usage example
- Links to detailed docs

### Tutorials

- Step-by-step guides
- Learning-oriented
- Complete projects
- Explanatory narrative

### How-To Guides

- Task-oriented
- Specific problems
- Assume some knowledge
- Multiple approaches

### Reference

- Complete information
- Structured format
- Technical accuracy
- Quick lookup

### Explanation

- Understanding-oriented
- Background context
- Design decisions
- Conceptual clarity

## Success Criteria

- Documentation is created for the specified feature
- Content is accurate, clear, and complete
- Examples are tested and working
- Appropriate for target audience's technical level
- Follows consistent formatting and style
- Organized in logical location
- Reviewed for quality

## Common Pitfalls to Avoid

**DON'T:**

- Assume prior knowledge without stating prerequisites
- Use jargon without explanation
- Provide examples that don't actually work
- Mix reference and tutorial content
- Forget to update docs when code changes
- Write walls of text without structure

**DO:**

- Start with the user's goal
- Provide copy-paste examples
- Explain the why, not just the how
- Use consistent terminology
- Include troubleshooting guidance
- Keep it scannable with headers and lists

## Common Patterns

### Feature Introduction Documentation

Create comprehensive guides when introducing new features that require user adoption.

### Integration Guide Documentation

Provide step-by-step integration instructions for features that connect with external systems.

### Migration Guide Documentation

Help users transition from old to new versions when making breaking changes.

### Tutorial-Style Documentation

Create learning-oriented guides that walk users through complete workflows.

## Usage Example
>
> "I've implemented a new authentication feature that supports OAuth and API keys. Create user documentation that helps developers integrate this into their applications."

---

This workflow ensures comprehensive, user-friendly documentation that enables successful adoption and use of your features.
