# ADR-006: ATOM Architecture House Rules for Component Classification

## Status

Accepted
Date: 2025-01-27

## Context

During the development of the Coding Agent Tools Ruby gem, confusion arose regarding the proper classification of components within the ATOM (Atoms, Molecules, Organisms, Ecosystems) architecture. Specifically, the code review process for task 4 highlighted a critical misclassification: the `Molecules::Model` class was implemented as a pure data carrier but placed in the `molecules/` directory, which is intended for behavior-oriented helpers.

The confusion became apparent when:

1. **Inconsistent Classification**: `Molecules::Model` was essentially a `Struct` with no behavior, making it a data object rather than a behavior-oriented helper
2. **Developer Uncertainty**: Team members expressed uncertainty about when to place classes in `models/`, `molecules/`, or `organisms/`
3. **Architecture Drift**: Without clear rules, components risk being misclassified, leading to coupling issues and violation of separation of concerns
4. **Onboarding Challenges**: New team members need clear guidance on component classification to maintain architectural consistency

The `LlmModelInfo` refactoring serves as the primary example of this issue. Originally implemented as `Molecules::Model`, it was identified during code review as a pure data carrier that should be reclassified as `Models::LlmModelInfo` to align with ATOM principles.

This architectural decision establishes clear "house rules" for component classification to prevent future misclassification and ensure consistent application of ATOM principles throughout the codebase.

## Decision

We establish the following classification rules for components in the ATOM architecture:

### Models (`lib/coding_agent_tools/models/`)
**Definition**: Pure data carriers with no behavior or external dependencies
**Characteristics**:
- Plain Old Ruby Objects (POROs), typically implemented as `Struct` or simple classes
- Immutable data structures focused solely on data representation
- No I/O operations, external dependencies, or complex business logic
- May include trivial helper methods for data access or formatting
- Act as value objects or data transfer objects

**Examples**:
- `Models::LlmModelInfo` - Metadata about language models (provider, name, context_window, etc.)
- `Models::Task` - Task representation with attributes like id, status, priority
- `Models::LLMResponse` - API response data containers

### Molecules (`lib/coding_agent_tools/molecules/`)
**Definition**: Behavior-oriented helpers that perform focused operations
**Characteristics**:
- Simple compositions of Atoms that form meaningful, reusable operations
- Encapsulate single, focused pieces of logic or behavior
- May depend on Atoms and Models but not on other Molecules or Organisms
- Stateless or minimal state management
- Reusable across different contexts

**Examples**:
- `Molecules::ExecutableWrapper` - Centralizes CLI script execution logic
- `Molecules::APICredentials` - Manages authentication details and credential logic
- `Molecules::HTTPRequestBuilder` - Constructs HTTP requests from parameters
- `Molecules::APIResponseParser` - Processes and validates API responses

### Organisms (`lib/coding_agent_tools/organisms/`)
**Definition**: Complex components that orchestrate Molecules and Atoms for business functions
**Characteristics**:
- Perform specific business-related functions or features
- Compose multiple Molecules and Atoms to achieve distinct goals
- May maintain state and coordinate complex workflows
- Often correspond to Service Objects in the application layer
- Represent cohesive business capabilities

**Examples**:
- `Organisms::GoogleClient` - Orchestrates API communication with Google Gemini
- `Organisms::LMStudioClient` - Manages local LLM interactions and configuration
- `Organisms::PromptProcessor` - Coordinates prompt preparation, processing, and parsing

### Classification Decision Tree

When creating a new component, follow this decision process:

1. **Is it primarily data?** → Models
   - Pure data structure with minimal or no behavior
   - Focus on representing information or state

2. **Does it perform a focused operation?** → Molecules
   - Single responsibility with clear behavioral purpose
   - Composes Atoms to create reusable functionality
   - Stateless or minimal state

3. **Does it orchestrate complex business logic?** → Organisms
   - Coordinates multiple components for business goals
   - May manage state and complex workflows
   - Represents significant business capabilities

## Consequences

### Positive

- **Clear Classification Guidelines**: Developers have unambiguous criteria for component placement
- **Consistent Architecture**: Reduces architectural drift and maintains ATOM principles
- **Improved Maintainability**: Clear separation of concerns makes code easier to understand and modify
- **Better Onboarding**: New team members can quickly understand and apply classification rules
- **Reduced Coupling**: Proper classification prevents inappropriate dependencies between layers
- **Scalable Design**: Well-classified components support system growth and evolution
- **Code Review Efficiency**: Reviewers can easily identify misclassified components

### Negative

- **Initial Refactoring Overhead**: Existing misclassified components may need to be moved and updated
- **Learning Curve**: Team members need to internalize the new classification rules
- **Potential Over-Engineering**: Developers might over-analyze simple components

### Neutral

- **Documentation Maintenance**: Architecture documentation needs updates to reflect these rules
- **Tooling Opportunities**: Could benefit from automated tooling to validate component classification
- **Example Evolution**: The `LlmModelInfo` example will serve as the primary reference case

## Alternatives Considered

### Flexible Classification Without Strict Rules
- **Why rejected**: Led to the current confusion and inconsistent classification
- **Trade-offs**: Would have been easier short-term but created long-term architectural debt

### Complex Multi-Tier Classification System
- **Why rejected**: Would have added unnecessary complexity for the project's current scale
- **Trade-offs**: Might provide more granular control but would complicate developer decision-making

### Directory-Based Validation Tooling First
- **Why rejected**: Tooling without clear rules would still leave classification decisions ambiguous
- **Trade-offs**: Automation is valuable but requires clear rules as a foundation

### Case-by-Case Review Process
- **Why rejected**: Not scalable and would slow development velocity
- **Trade-offs**: Might catch all edge cases but would create bottlenecks

## Related Decisions

- ATOM-based code structure implementation (documented in architecture.md)
- Integration test strategy and VCR configuration (ADR-001)
- Zeitwerk autoloading configuration (ADR-002)
- Observability with dry-monitor (ADR-003)
- Centralized CLI error reporting (ADR-004)
- HTTP client strategy with Faraday (ADR-005)
- Future ADRs on component lifecycle management and dependency injection

## References

- [LlmModelInfo Refactoring Example](docs-project/current/v.0.2.0-synapse/code-review/task-4/code-review-combined.md) - Primary example of Model vs Molecule classification
- [Architecture Documentation](docs/architecture.md) - ATOM structure definition and component examples
- [ATOM Component Classification House Rules](docs-dev/guides/atom-house-rules.md) - Practical implementation guide for these rules
- [Code Review Guidelines](docs-dev/guides/code-review/README.md) - Review process for architectural decisions
- [ATOM Architecture Principles](https://atomicdesign.bradfrost.com/) - Original inspiration for component hierarchy
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - Separation of concerns principles
