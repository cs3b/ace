---
doc-type: guide
title: Goal
purpose: Documentation for ace-docs/handbook/guides/documentation.g.md
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

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

##### README.md (Package)

**Purpose**: Selling page - quickly convey what the package is and why it matters

A README is the first thing someone sees. Lead with value, not feature lists.

**Structure** (in order):

| Section | Purpose | Length |
|---------|---------|--------|
| Title + logo | Identity with ACE branding | Title + centered logo block |
| Badges | Status indicators | 3 badges: gem version, Ruby 3.2+, MIT license |
| Tagline | What it IS (blockquote) | `> one sentence` |
| Agent compatibility | Trust signal | "Works with: ..." 1 line |
| Nav row | Quick access to docs | Pipe-separated links, above demo |
| GIF | Visual hook | CLI tools only |
| Intro paragraph | Value proposition in context | 2-4 sentences |
| How It Works | Mental model | Optional - Mermaid diagram or 3-step list |
| Use Cases | Real workflows with tool refs | 3-6 entries |
| Footer | ACE link | 1 line separator |

**Logo**: Place a centered logo block (`<p align="center">`) between title and badges.
Use the standard ACE logo path: `../docs/brand/AgenticCodingEnvironment.Logo.S.png`.

**Nav row**: Pipe-separated links placed above the demo GIF, not in a bottom section.
Always use three links: Getting Started, Usage Guide, and Handbook. Expand the Handbook
link with a subtitle: `[Handbook - Skills, Agents, Templates](docs/handbook.md)` so
readers know what it contains without clicking.

**No Quick Start section**: Getting Started is linked in the nav row. A separate Quick
Start section duplicates it. Remove it.

**Intro paragraph**: 2-4 sentences that describe the problem space and what the package
does about it. Do not split into separate Problem/Solution sections. Do not list
subcommands or features — let Use Cases do that. Frame through what the package enables,
not what it replaces.

**Use Cases** (replaces Problem/Solution/Ecosystem/Agent Skills):

Each entry: **bold title** followed by a description paragraph. Weave in:
- Skill references with `/as-` prefix (e.g., `/as-task-draft`)
- CLI commands linked to usage docs (e.g., [`ace-task create`](docs/usage.md#ace-task-create-title))
- Ecosystem package links inline (e.g., [ace-overseer](../ace-overseer))

This replaces separate Ecosystem and Agent Skills sections. Related packages and skills
appear naturally within the use cases where they add value.

Additional Use Cases rules:
- CLI examples in code blocks should include all meaningful flags (e.g., `--preset`)
- Do not repeat in prose what a nearby code block already shows
- When describing customization, link config files and presets in other packages
  using relative paths (e.g., `[preset](../ace-assign/.ace-defaults/assign/presets/work-on-task.yml)`)

**Badges**: Use shields.io. Always use these 3: gem version, Ruby 3.2+ (with logo),
MIT license. Do not add CI, coverage, downloads, or social badges.

**Tagline**: Use a blockquote (`> one sentence`). The `>` creates a visual box on
GitHub that draws the eye to the selling line. Place immediately after badges.

**Agent compatibility line**: Place below the tagline, above the nav row. Use the
standard text: "Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent,
and more." Keep the agent list current as new agents gain traction.

**Implementation rule**: Read the implementation code before describing features. Do not
write from plan notes or spec documents alone.

**Package category variants**:

| Section | CLI Tool | Support Library | Integration | Infrastructure |
|---------|----------|-----------------|-------------|----------------|
| Logo | Yes | Yes | Yes | Yes |
| GIF | Yes | No | No | If available |
| How It Works | Optional | Optional | Skip | Optional |
| Use Cases | 4-6 entries | 2-4 entries | 2-3 entries | 3-5 entries |

**Root README differs**: The monorepo root uses "What ACE Does" (value bullets) and
a "Tools" table instead of Use Cases. See the root README for the pattern.

**Anti-patterns** (never include in a README):

- Full API documentation (belongs in docs/)
- Development setup (belongs in docs/SETUP.md)
- Contributing guidelines beyond a link (belongs in docs/contributing/)
- Separate Problem/Solution sections (weave into intro paragraph)
- Separate Ecosystem or Agent Skills sections (inline in Use Cases)
- Quick Start section (redundant with Getting Started in nav row)
- Feature bullet lists without workflow context
- More than 3 badges
- Decorative emojis (follow markdown-style guide)
- Describing features from plan notes without reading implementation code

**Template**: `ace-docs/handbook/templates/project-docs/README.template.md`

##### docs/vision.md

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
| Product vision | vision.md | README (brief), roadmap |
| User personas | vision.md | - |
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

- **Task Definitions:** Use the structured `.md` format for tasks (see `guide://project-management`)
    with clear descriptions, implementation notes, and acceptance criteria.
- **Workflow Instructions:** Write clear, specific workflow instructions (workflow instructions (`wfi://` protocol))
    outlining processes for the AI to follow for common tasks. Follow guidelines similar to writing good code:
    focused, clear inputs/outputs, examples. (See Task 04 for creating a dedicated guide on this).
- **Cross-Referencing:** Link related documents (guides, tasks, ADRs, code files) to create a connected
    knowledge base that the AI can potentially navigate or be guided through. For example, a task file might link
    to a relevant ADR or guide section using root-relative paths like `docs/architecture-decisions/ADR-001.md` or
    `guide://coding-standards`.

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

## Formatting Conventions

For markdown typography and formatting standards (em-dashes, file trees, emoji usage), see the [Markdown Style Guide](guide://markdown-style).

## Related Documentation

- [Coding Standards](guide://coding-standards)
- [Project Management Guide](guide://project-management) (Task format, ADRs)
- [ADR Template](tmpl://project-docs/adr)
