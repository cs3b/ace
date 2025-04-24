# Documentation Standards

## Goal
This guide defines the standards and best practices for documenting code and project artifacts within this toolkit, ensuring clarity, maintainability, and effective knowledge sharing for both human developers and AI agents.

# Documentation Standards

### 1. Code Documentation

1. **API Documentation (using standard tools/conventions)**:
   Use standard documentation tools and conventions for your language/framework to document public APIs (classes, methods, modules, functions).
   - Include a clear summary of the item's purpose.
   - Document parameters (`@param name [Type] description`).
   - Document return values (`@return [Type] description`).
   - Provide clear usage examples (`@example`).
   - Note any exceptions or errors raised (`@raise [ErrorType] description`).
   - Indicate important notes like thread-safety (`@note`).

   ```
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

2. **Class and Module Documentation**:
   Document the purpose and usage of classes, modules, or other major code structures.
   - Include examples of instantiation or typical usage.
   - Note important characteristics like thread-safety if applicable.
   - Document public attributes or properties.

   ```
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

3. **Performance Documentation**:
   Document performance-critical sections of code.
   - Note algorithmic complexity (e.g., `@complexity O(n)`).
   - Specify performance characteristics (e.g., `@performance Processes up to X items concurrently`).
   - Indicate expected memory usage (e.g., `@memory Uses ~Y MB per item`).

   ```
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

### 2. Project Documentation

1. **README.md Structure**:

   ~~~markdown
   # Your Project Name

   Briefly describe your project.

   ## Quick Start
   ```
   // Your Quick Start code here
   // Example: Initialize and run a basic task
   ```

   ## Installation
   ```bash
   your-package-manager install your-package-name
   ```

   ## Documentation
   - [API Reference](docs/api.md) <!-- Assuming 'docs' is a root dir for user docs -->
   - [Tutorials](docs/tutorials/) <!-- Assuming 'docs' is a root dir for user docs -->
   - [Examples](examples/) <!-- Assuming 'examples' is a root dir -->

   ~~~

2. **Architecture Documentation**:

   ~~~markdown
   # Architecture Overview

   ## Components
   - Agent: Core execution engine
   - Tools: System capabilities
   - Registry: Tool management

   ## Data Flow
   1. Agent receives task
   2. Tools are loaded
   3. LLM processes task
   4. Results returned

   ## Extension Points
   - Custom tools
   - Prompt templates
   - Result processors
   ~~~

3. **Tutorial Structure**:
   ~~~markdown
   # Building Your First Agent

   1. Create agent
   2. Configure tools
   3. Execute tasks
   4. Handle results

   ## Example Implementation
   ```
   // Complete working example relevant to the tutorial step
   ```

   ## Common Patterns
   - Error handling
   - Tool composition
   - State management
   ~~~

### 3. Documenting for AI Collaboration

Clear documentation is crucial for effective AI collaboration.

- **Structured Project Docs:** Maintain core documents like `docs-project/what-do-we-build.md`, `docs-project/architecture.md`, and `docs-project/blueprint.md`. Keep them up-to-date as they provide essential high-level context for the AI.
- **Task Definitions:** Use the structured `.md` format for tasks (see `docs-dev/guides/project-management.md`) with clear descriptions, implementation notes, and acceptance criteria.
- **ADRs:** Document significant architectural decisions in `docs-dev/decisions/` to provide rationale and context for the AI.
- **Workflow Instructions:** Write clear, specific workflow instructions (`docs-dev/workflow-instructions/*.md`) outlining processes for the AI to follow for common tasks. Follow guidelines similar to writing good code: focused, clear inputs/outputs, examples. (See Task 04 for creating a dedicated guide on this).
- **Code Comments:** Use comments to explain the "why" behind complex logic, not just the "what". This helps the AI understand intent.
- **Cross-Referencing:** Link related documents (guides, tasks, ADRs, code files) to create a connected knowledge base that the AI can potentially navigate or be guided through. For example, a task file might link to a relevant ADR or guide section using root-relative paths like `docs-dev/decisions/ADR-001.md` or `docs-dev/guides/coding-standards.md`.

## Code Comments

Code comments should explain the *why*, not the *what* (unless the *what* is particularly complex or non-obvious). Well-written code should be largely self-documenting regarding *what* it does.

**Good Comment (Explains Why):**
```
// Reset the counter due to edge case X discovered during testing.
counter = 0;
```

**Bad Comment (Explains What):**
```
// Increment the counter by one.
counter++;
```

## Language/Environment-Specific Examples

For specific examples of documentation generation tools, comment styles, or conventions tailored to particular languages or frameworks (e.g., JSDoc, RDoc, Sphinx, JavaDoc), please refer to the examples in the [./documentation/](./documentation/) sub-directory.

## Related Documentation
- [Coding Standards](docs-dev/guides/coding-standards.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Task format, ADRs)
- [ADR Template](docs-dev/guides/prepare-release/v.x.x.x/decisions/_template.md)
- [Writing Guides Guide](docs-dev/guides/writing-guides-guide.md)
