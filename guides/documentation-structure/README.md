# Documentation Structure Guide

This guide clarifies the purpose and scope of each major documentation file in the Coding Agent Tools project. Following these guidelines helps maintain consistency and prevents content duplication.

## Core Documentation Files

### 1. README.md (Project Root)
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

### 2. docs/what-do-we-build.md
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

### 3. docs/architecture.md
**Purpose**: Technical design and implementation details

**Contains**:
- System architecture overview
- Technology stack with justifications
- ATOM architecture pattern details
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

### 4. docs/blueprint.md
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

### 5. docs/SETUP.md
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

### 6. docs/DEVELOPMENT.md
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

### 7. docs-project/roadmap.md
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

## Specialized Documentation

### docs/llm-integration/
**Purpose**: Feature-specific user guides

**Example**: `gemini-query-guide.md`
- Comprehensive usage instructions
- Configuration options
- Examples and use cases
- Troubleshooting
- Integration patterns

### docs/dev-guides/
**Purpose**: Technical deep-dives and development guides

**Contains**:
- Implementation case studies (e.g., `refactoring_api_credentials.md`)
- Testing guides (e.g., `testing-with-vcr.md`)
- Technical investigations (e.g., `ansi-color-stringio-behavior.md`)
- Best practices for specific technologies

### docs-project/current/, backlog/, done/
**Purpose**: Task and release management

**Contains**:
- Task definitions with acceptance criteria
- Release planning documents
- Code review artifacts
- Sprint/iteration planning

### docs-project/decisions/
**Purpose**: Architecture Decision Records (ADRs)

**Contains**:
- Technical decisions with context
- Alternatives considered
- Consequences and trade-offs
- Decision rationale

## Content Placement Quick Reference

| Content Type | Primary Location | Secondary References OK |
|-------------|------------------|------------------------|
| Product vision | what-do-we-build.md | README (brief), roadmap |
| User personas | what-do-we-build.md | - |
| Installation | README, SETUP.md | - |
| Usage examples | README (basic), feature guides | - |
| Directory structure | blueprint.md | architecture.md (technical) |
| ATOM pattern details | architecture.md | blueprint.md (navigation) |
| Dependencies | architecture.md (detailed) | blueprint.md (summary) |
| Development workflow | DEVELOPMENT.md | - |
| Task management | docs-project/* | - |
| Release planning | roadmap.md | - |
| API documentation | Feature guides | architecture.md (design) |

## Guidelines for New Documentation

1. **Check existing documents first** - Don't create new files if the content belongs in an existing document
2. **Link, don't duplicate** - Reference other documents rather than copying content
3. **Keep scope focused** - Each document should have a clear, single purpose
4. **Update the blueprint** - When adding new key documents, update blueprint.md
5. **Consider the audience** - Technical details for developers, business context for stakeholders
6. **Maintain consistency** - Follow the established patterns in each document type

## Cross-Reference Patterns

### When to Link
- From README to detailed guides
- From blueprint to all major documents
- From overview documents to detailed implementations
- From guides to related ADRs

### How to Link
- Use relative paths from the document location
- Include section anchors for specific topics
- Verify links work after moving documents
- Update links when reorganizing

## Maintenance

This guide should be updated when:
- New major documentation files are added
- Document purposes significantly change
- Patterns of duplication emerge
- Team agrees on new documentation standards