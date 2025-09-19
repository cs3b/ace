# Manage Guides

## Goal

Create, update, and maintain development guide files following established standards and patterns. This meta-workflow guides handbook maintainers through the systematic creation of conceptual guides that explain principles, standards, and best practices while maintaining consistency across the handbook.

## Prerequisites

* Understanding of guide definition principles and standards
* Access to dev-handbook/.meta/gds/ definition files
* Knowledge of existing guide patterns and structure
* Understanding of language modularity principles

## Project Context Loading

* Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`
* Load guide standards: `dev-handbook/.meta/gds/guides-definition.g.md`
* Load markdown standards: `dev-handbook/.meta/gds/markdown-definition.g.md`
* Load example guides: `dev-handbook/guides/project-management.g.md`
* Load guide organization: `dev-handbook/guides/README.md`

## Process Steps

1. **Define Guide Scope and Purpose:**
   * Identify the conceptual area or standard the guide will cover
   * Determine the "why" focus (principles, concepts, standards)
   * Define target audience (developers, AI agents, or both)
   * Establish boundaries: what concepts are included and excluded
   * Gather requirements from users or project standards

2. **Design Guide Structure:**
   * Plan guide sections following conceptual organization:
     - Introduction with purpose and scope
     - Core principles and concepts
     - Standards and best practices
     - Examples that illustrate concepts (not procedures)
     - Cross-references to related guides and workflows
   * Design for scanability with clear headings and sections
   * Plan language-specific modularity if needed

3. **Analyze Language-Specific Requirements:**
   * Identify if the guide mixes general principles with language-specific details
   * If language-specific content exists:
     - Keep main guide language-agnostic
     - Create sub-guides for each language in subdirectory
     - Use naming pattern: `guide-topic/language.md`
   * Examples of modular structure:
     - `testing.g.md` (general principles)
     - `testing/ruby-rspec.md` (Ruby-specific)
     - `testing/typescript-bun.md` (TypeScript-specific)

4. **Create Guide File:**
   * Create file in `dev-handbook/guides/` with `.g.md` extension
   * Use noun-phrase naming convention (e.g., `coding-standards.g.md`)
   * Implement standard guide structure:

     ```markdown
     # Guide Title
     
     [Brief introduction paragraph explaining purpose and scope]
     
     ## Core Principles
     
     1. **Principle Name**: Explanation of concept and rationale
     2. **Principle Name**: Why this matters and how it applies
     
     ## Standards and Best Practices
     
     ### Standard Category
     
     * [Standard with explanation]
     * [Best practice with rationale]
     
     ## Examples
     
     [Concrete examples that illustrate concepts]
     
     ## Related Resources
     
     * [Link to related guide]
     * [Link to workflow for implementation]
     ```

5. **Create Language-Specific Sub-Guides (if needed):**
   * Create subdirectory: `dev-handbook/guides/[topic]/`
   * Create language-specific files: `[language].md` (not `.g.md`)
   * Focus on implementation details specific to that language
   * Structure language sub-guides:

     ```markdown
     # [Topic] - [Language]
     
     Language-specific implementation of [topic] principles.
     
     ## [Language] Specifics
     
     ### Tools and Libraries
     * [Language-specific tools]
     
     ### Code Examples
     [Actual code samples]
     
     ### Common Patterns
     [Language-specific patterns]
     
     ## Integration with [Language] Ecosystem
     [How principles apply in this language context]
     ```

6. **Develop Content Following Guide Principles:**
   * **Conceptual Focus:** Explain "why" rather than "how"
   * **Clarity:** Use simple, direct language
   * **Examples for Illustration:** Show concepts, not procedures
   * **Consistency:** Use established terminology and patterns
   * **Actionability:** Provide context for decision-making

7. **Update Guide Organization:**
   * Add new guide to `dev-handbook/guides/README.md`
   * Place in appropriate category (Core Development Process, Standards, etc.)
   * Provide clear description of guide's purpose
   * Update any cross-references in related guides

8. **Validate Guide Standards Compliance:**
   * Verify `.g.md` naming convention used
   * Check conceptual focus (principles vs procedures)
   * Ensure language modularity if mixed content exists
   * Validate cross-references and links
   * Review for consistency with existing guides

9. **Quality Review and Integration:**
   * Review guide content for accuracy and completeness
   * Test that examples and code samples are correct
   * Verify integration with guide organization
   * Check for proper cross-references to workflows
   * Ensure consistency with project terminology

## Guide Types and Patterns

### Process Guides
For development processes and workflows:
* Focus on principles and decision-making
* Link to specific workflow instructions for implementation
* Examples: `project-management.g.md`, `version-control-system.g.md`

### Standards Guides
For coding and quality standards:
* Define principles and rationale
* Provide concrete examples of good/bad practices
* Include language-specific sub-guides as needed
* Examples: `coding-standards.g.md`, `security.g.md`

### Technical Guides
For technical concepts and approaches:
* Explain architectural principles
* Provide conceptual examples
* Link to implementation workflows
* Examples: `testing-tdd-cycle.g.md`, `performance.g.md`

### Meta Guides
For handbook and documentation standards:
* Define content creation principles
* Explain organizational structure
* Examples: `documentation.g.md`, guides in `.meta/gds/`

## Language Modularity Examples

### Main Guide Structure (testing.g.md)
```markdown
# Testing and Quality Assurance

This guide establishes testing principles and quality standards.

## Core Testing Principles

1. **Test-Driven Development**: Write tests before implementation
2. **Test Pyramid**: Unit tests > Integration tests > E2E tests

## Language-Specific Implementation

See language-specific guides for implementation details:
* [Ruby Testing with RSpec](./testing/ruby-rspec.md)
* [TypeScript Testing with Bun](./testing/typescript-bun.md)
* [Rust Testing](./testing/rust.md)
```

### Language Sub-Guide Structure (testing/ruby-rspec.md)
```markdown
# Testing - Ruby RSpec

Ruby-specific implementation of testing principles using RSpec.

## RSpec Configuration

[Specific configuration examples]

## Common Patterns

[Ruby/RSpec specific testing patterns]

## Integration with Rails

[Framework-specific guidance]
```

## Quality Standards

### Content Standards
* **Conceptual Clarity:** Focus on understanding over execution
* **Principle-Based:** Explain rationale behind standards
* **Example-Driven:** Use concrete examples to illustrate concepts
* **Cross-Referenced:** Link appropriately to related content

### Structural Standards
* **Consistent Organization:** Follow established section patterns
* **Language Modularity:** Separate general principles from specific implementations
* **Scannable Format:** Use headings and lists effectively
* **Naming Compliance:** Use noun-phrase `.g.md` convention

### Integration Standards
* **README Updates:** Include new guides in organization
* **Cross-References:** Maintain accurate links between guides
* **Workflow Links:** Connect guides to implementation workflows
* **Terminology Consistency:** Use established project language

## Success Criteria

* Guide file created with proper `.g.md` naming and structure
* Content focuses on principles and concepts (not procedures)
* Language modularity applied if mixed content exists
* Integration with `dev-handbook/guides/README.md` complete
* Cross-references accurate and helpful
* Quality review completed and standards met
* Consistency with existing guide patterns maintained

## Common Patterns

### Creating Standard Guides
1. Define principles first
2. Provide rationale for each standard
3. Include positive and negative examples
4. Link to implementation workflows
5. Consider language-specific needs

### Updating Existing Guides
1. Review current content for accuracy
2. Maintain consistency with new information
3. Update cross-references as needed
4. Preserve established patterns
5. Consider impact on related guides

### Language-Specific Extension
1. Keep main guide language-agnostic
2. Create subdirectory for language variants
3. Focus sub-guides on implementation details
4. Cross-reference between main and sub-guides
5. Maintain consistency across languages

## Error Handling

**Guide becomes too procedural:**
* Refactor procedural content into workflow instructions
* Keep guide focused on principles and rationale
* Link to workflows for implementation steps

**Mixed language content in main guide:**
* Extract language-specific content to sub-guides
* Keep main guide technology-agnostic
* Create clear navigation between variants

**Inconsistent with existing guides:**
* Review established patterns and terminology
* Update for consistency or document intentional differences
* Consider impact on related guides and workflows

## Usage Example

> "Create a guide for API design principles that covers REST standards, documentation requirements, and language-specific implementation patterns for Ruby and TypeScript"