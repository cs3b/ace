# Goal

This guide defines the standards and best practices for documenting code and project artifacts within this
toolkit, ensuring clarity, maintainability, and effective knowledge sharing for both human developers and
AI agents.

## 1. Code Documentation

1. **API Documentation (using standard tools/conventions)**:
    Use standard documentation tools and conventions for your language/framework to document public APIs (classes,
    methods, modules, functions).
    - Include a clear summary of the item's purpose.
    - Document parameters (`@param name [Type] description`).
    - Document return values (`@return [Type] description`).
    - Provide clear usage examples (`@example`).
    - Note any exceptions or errors raised (`@raise [ErrorType] description`).
    - Indicate important notes like thread-safety (`@note`).

```javascript
// Example API documentation structure (adapt to your language/tool)

/**
 * @summary Executes an AI agent task with given tools.
 *
 * @param {object} task - The task configuration.
 * @param {string} task.prompt - The task prompt.
 * @param {string[]} task.tools - Available tools.
 * @returns {Result} Task execution result.
 * @throws {ConfigError} If configuration is invalid.
 * @throws {ToolError} If a tool fails during execution.
 * @note This method is thread-safe.
 */
function execute(task) {
  // Implementation
}
```

1. **Class and Module Documentation**:
    Document the purpose and usage of classes, modules, or other major code structures.
    - Include examples of instantiation or typical usage.
    - Note important characteristics like thread-safety if applicable.

```javascript
// Example class documentation structure (adapt to your language)
/**
 * @summary Manages the registration and lookup of agent tools.
 *
 * @example Registering a custom tool
 *   const registry = new ToolRegistry();
 *   registry.register('browser', new BrowserTool());
 *
 * @thread-safety This class is thread-safe.
 */
class ToolRegistry {
  /** @property {Map<string, Tool>} tools - The registered tools */
  get tools() { /* ... */ }

  /** @private */
  constructor() {
    // ...
  }
}
```

1. **Performance Documentation**:
    Document performance-critical sections of code.
    - Note algorithmic complexity (e.g., `@complexity O(n)`).
    - Specify performance characteristics (e.g., `@performance Processes up to X items concurrently`).
    - Indicate expected memory usage (e.g., `@memory Uses ~Y MB per item`).

```javascript
// Example performance documentation (adapt as needed)
/**
 * Processes items in parallel with controlled concurrency.
 *
 * @complexity O(n) where n is the number of items.
 * @performance Processes up to 10 items concurrently.
 * @memory Uses ~10MB per item being processed.
 */
function processItems(items) {
  // Implementation
}
```

### 2. Project Documentation Structure

This section clarifies the purpose and scope of each major documentation file. Following these guidelines helps maintain consistency and prevents content duplication.

#### Core Documentation Files

##### README.md (Project Root)
**Purpose**: Entry point for new users and quick reference

**Contains**:
- Project badges and status
- Brief project description (1-2 paragraphs)
- Quick start installation instructions
- Key features list (high-level)
- Basic usage examples
- Links to detailed documentation
- Contributing quick start
- License information

**Does NOT contain**:
- Detailed technical architecture
- Comprehensive feature documentation
- Development environment setup details
- Internal implementation details

**Example Structure**:

Refer to the [README.md template](dev-handbook/guides/initialize-project-templates/README.md)

##### docs/what-do-we-build.md
**Purpose**: Product vision and business context

**Contains**:
- Product vision statement
- Key features and capabilities (business perspective)
- User personas and their needs
- Use cases and scenarios
- Success metrics
- Value proposition
- Future vision (product roadmap perspective)
- Market positioning

**Does NOT contain**:
- Technical implementation details
- Code structure or patterns
- Development workflows
- Directory structures
- Dependencies lists

##### docs/architecture.md
**Purpose**: Technical design and implementation details

**Contains**:
- System architecture overview
- Technology stack with justifications
- ATOM architecture pattern details (or your pattern)
- Component descriptions and interactions
- Data flow diagrams
- File organization (technical perspective)
- Development patterns and principles
- Security and performance considerations
- Technical dependencies with versions
- Decision records references

**Does NOT contain**:
- Business goals or user personas
- Installation instructions
- Navigation guides for developers
- Task management information

##### docs/blueprint.md
**Purpose**: Project navigation guide (especially for AI agents)

**Contains**:
- Brief description of what a blueprint is
- Links to core documents (what-we-build, architecture)
- Project organization (directory structure)
- Key file locations and purposes
- Technology stack summary (with link to architecture for details)
- Entry points and common workflows
- Read-only and ignored paths for AI agents
- Quick reference commands

**Does NOT contain**:
- Detailed technical explanations
- Business vision or goals
- Implementation patterns
- Comprehensive dependency analysis

##### docs/SETUP.md
**Purpose**: Development environment setup

**Contains**:
- System requirements
- Installation prerequisites
- Step-by-step setup instructions
- Environment configuration
- Dependency installation
- Verification steps
- Common setup issues and solutions

**Does NOT contain**:
- Development workflows
- Architecture details
- Testing strategies
- Contributing guidelines

##### docs/DEVELOPMENT.md
**Purpose**: Development workflow and practices

**Contains**:
- Daily development workflow
- Testing strategies and examples
- Build system commands
- Code quality standards
- Debugging techniques
- Performance optimization tips
- Release workflow
- Links to specialized guides (e.g., VCR testing)

**Does NOT contain**:
- Initial setup instructions
- Product vision
- Architecture decisions
- Basic usage examples

##### dev-taskflow/roadmap.md
**Purpose**: Strategic planning and release management

**Contains**:
- Project vision summary
- Strategic objectives with metrics
- Release timeline and milestones
- Major features by release
- Cross-release dependencies
- Update history

**Does NOT contain**:
- Technical implementation details
- Current task lists
- Development setup instructions
- Architecture patterns

#### Specialized Documentation

##### docs/llm-integration/
**Purpose**: Feature-specific user guides

**Example**: `gemini-query-guide.md`
- Comprehensive usage instructions
- Configuration options
- Examples and use cases
- Troubleshooting
- Integration patterns

##### docs/architecture-decisions/
**Purpose**: Architecture Decision Records (ADRs)

**Contains**:
- Technical decisions with context
- Alternatives considered
- Consequences and trade-offs
- Decision rationale

#### Content Placement Quick Reference

| Content Type | Primary Location | Secondary References OK |
|-------------|------------------|------------------------|
| Product vision | what-do-we-build.md | README (brief), roadmap |
| User personas | what-do-we-build.md | - |
| Installation | README, SETUP.md | - |
| Usage examples | README (basic), docs/examples/ | - |
| Directory structure | blueprint.md | architecture.md (technical) |
| ATOM pattern details | architecture.md | blueprint.md (navigation) |
| Dependencies | architecture.md (detailed) | blueprint.md (summary) |
| Development workflow | DEVELOPMENT.md | - |
| API documentation | Feature guides | architecture.md (design) |

#### Guidelines for New Documentation

1. **Check existing documents first** - Don't create new files if the content belongs in an existing document
2. **Link, don't duplicate** - Reference other documents rather than copying content
3. **Keep scope focused** - Each document should have a clear, single purpose
4. **Update the blueprint** - When adding new key documents, update blueprint.md
5. **Consider the audience** - Technical details for developers, business context for stakeholders
6. **Maintain consistency** - Follow the established patterns in each document type

#### Cross-Reference Patterns

##### When to Link
- From README to detailed guides
- From blueprint to all major documents
- From overview documents to detailed implementations
- From guides to related ADRs

##### How to Link
- Use relative paths from the document location
- Include section anchors for specific topics
- Verify links work after moving documents
- Update links when reorganizing

### 3. Documenting for AI Collaboration

Clear documentation is crucial for effective AI collaboration.

- **Task Definitions:** Use the structured `.md` format for tasks (see `dev-handbook/guides/project-management.g.md`)
    with clear descriptions, implementation notes, and acceptance criteria.
- **Workflow Instructions:** Write clear, specific workflow instructions (`dev-handbook/workflow-instructions/*.wf.md`)
    outlining processes for the AI to follow for common tasks. Follow guidelines similar to writing good code:
    focused, clear inputs/outputs, examples. (See Task 04 for creating a dedicated guide on this).
- **Cross-Referencing:** Link related documents (guides, tasks, ADRs, code files) to create a connected
    knowledge base that the AI can potentially navigate or be guided through. For example, a task file might link
    to a relevant ADR or guide section using root-relative paths like `docs/architecture-decisions/ADR-001.md` or
    `dev-handbook/guides/coding-standards.g.md`.

## Code Comments

Code comments should explain the *why*, not the *what* (unless the *what* is particularly complex or
non-obvious). Well-written code should be largely self-documenting regarding *what* it does.

**Good Comment (Explains Why):**

```javascript
// Reset the counter due to edge case X discovered during testing.
counter = 0;
```

**Bad Comment (Explains What):**

```javascript
// Increment the counter by one.
counter++;
```

## Language/Environment-Specific Examples

For specific examples of documentation generation tools, comment styles, or conventions tailored to particular
languages or frameworks (e.g., JSDoc, RDoc, Sphinx, JavaDoc), please refer to the examples in the
[./documentation/](./documentation/) sub-directory.

- [Coding Standards](dev-handbook/guides/coding-standards.g.md)
- [Project Management Guide](dev-handbook/guides/project-management.g.md) (Task format, ADRs)
- [ADR Template](dev-handbook/guides/draft-release/v.x.x.x/decisions/_template.md)
