# ACE Tools Migration Plan - October 8, 2025

## Executive Summary

This document analyzes the legacy dev-tools system and provides strategic recommendations for what must be migrated before ACE's public release, what can wait, and what should be dropped entirely.

## Migration Priority Analysis

### 🔴 **ESSENTIAL** (Must Have Before Public Release)

#### 1. **ace-lint** (from code-lint)
**Why Essential**:
- Code quality is fundamental for any serious development toolkit
- Users expect linting in modern dev workflows
- Currently no ace-* gem provides this capability
- Frequently used, high impact on code quality

**Scope**:
- Start with Ruby + Markdown support
- Add other languages post-release
- Include autofix capabilities from day one

**Migration Path**:
- Extract from `dev-tools/lib/coding_agent_tools/cli/commands/code_lint/`
- Follow ATOM architecture pattern
- Preserve multi-phase quality management approach

#### 2. **ace-handbook** (from handbook + agent-lint)
**Why Essential**:
- Self-contained workflows are core to ACE philosophy (ADR-001)
- Template sync is critical for workflow integrity
- Agent validation ensures quality AI integration
- Documentation/workflow management is foundational

**Scope**:
- Template synchronization (from handbook)
- Workflow management
- Agent validation (from agent-lint)
- Guide management

**Migration Path**:
- Combine handbook sync-templates and agent-lint functionality
- New capabilities for workflow and guide management
- Central hub for all documentation artifacts

#### 3. **Documentation & Onboarding** (NEW - Not in legacy)
**Why Essential**:
- Public release needs excellent getting-started experience
- Clear installation guides
- Tutorial workflows
- API documentation

**Missing Pieces that Must Be Created**:
- `ace-init` - Project initialization wizard
- `ace-doctor` - Diagnostic/health check tool
- Interactive tutorials
- Comprehensive guides

### 🟡 **NICE-TO-HAVE** (Can Ship v1.0 Without)

#### 1. **ace-coverage** (from coverage-analyze)
**Why Can Wait**:
- Useful but not core to ACE value proposition
- Can integrate with ace-test-runner later
- Users can use SimpleCov directly initially
- Complex implementation for non-critical feature

**Timeline**: v1.1 or v1.2

**Alternative**: Document how to use SimpleCov with ACE projects

#### 2. **ace-mcp-server** (from mcp-proxy)
**Why Can Wait**:
- MCP is cutting-edge but niche
- Only needed for advanced Claude Desktop integration
- Most users will use direct CLI tools initially
- Protocol still evolving

**Timeline**: v1.2+ as MCP adoption grows

**Alternative**: Provide documentation for manual MCP setup if needed

#### 3. **Git Operations Beyond Commit** (from coding-agent-tools git subcommands)
**Why Can Wait**:
- ace-git-commit covers the main AI use case
- Users can use native git for other operations
- Not differentiating for ACE
- Would duplicate standard git functionality

**Timeline**: v1.x as specific needs arise

**Alternative**: Focus on git operations that benefit from AI assistance

### 🟢 **DROP/DEPRIORITIZE** (Not Needed)

#### 1. **coding-agent-tools Monolith**
**Why Drop**:
- Being replaced by focused ace-* gems
- Monolithic approach contradicts ACE philosophy
- Already mostly migrated
- Maintenance burden without benefit

**Action**:
- Continue decomposition
- Remove entirely by v1.0
- Provide migration guide for users

#### 2. **create-path Command** (from coding-agent-tools)
**Why Drop**:
- Overlaps with other tools
- Not clearly scoped
- Can be part of other gems as needed
- Low usage in current form

**Action**:
- Integrate file creation into relevant gems
- ace-taskflow for task-related files
- ace-test-runner for test files

#### 3. **reflection synthesize** (from coding-agent-tools)
**Why Drop**:
- Too specific/niche use case
- Better as part of ace-taskflow retro features
- Low usage
- Complex implementation for minimal value

**Action**:
- Absorb into ace-taskflow retro command if needed
- Otherwise deprecate without replacement

### 🚀 **MISSING ESSENTIALS** (Not in Legacy, But Needed)

#### 1. **ace (Meta Package)**
```ruby
# Gemfile
gem 'ace'  # Installs all essential ace-* gems
```

**Why Needed**:
- Simple installation story
- Bundle all core gems
- Version compatibility management

**Implementation**:
- Meta gem with dependencies on essential ace-* gems
- No code, just dependencies
- Clear versioning strategy

#### 2. **ace-init** (Project Bootstrapper)
```bash
ace-init new my-project  # Initialize ACE project
ace-init doctor          # Diagnose setup issues
ace-init upgrade         # Upgrade ACE components
```

**Why Needed**:
- Smooth onboarding experience
- Project structure setup
- Configuration initialization
- Health checks

**Features**:
- Interactive project setup
- Template selection
- Configuration wizard
- Dependency checking

#### 3. **ace-bundle** (Gem Bundle Manager)
```bash
ace-bundle list          # List installed ace-* gems
ace-bundle update        # Update all ace-* gems
ace-bundle add ace-lint  # Add specific gem
```

**Why Needed**:
- Manage ace-* ecosystem
- Version compatibility
- Easy updates

**Features**:
- List installed/available ace-* gems
- Coordinated updates
- Compatibility checking
- Optional gem installation

#### 4. **Better Error Handling & Recovery**
**Why Needed**:
- Professional user experience
- Reduce support burden
- Aid debugging

**Implementation**:
- Unified error formats across all gems
- Recovery suggestions
- Debug helpers
- Clear error messages with solutions

#### 5. **ace-config** (Global Configuration)
```bash
ace-config set editor nvim
ace-config get llm.default_model
ace-config list
```

**Why Needed**:
- Consistent configuration across tools
- User preferences
- Environment management

**Features**:
- Hierarchical configuration
- User/project/global settings
- Environment variable management
- Secure credential storage

## Migration Priority Matrix

| Priority | Component | Legacy Source | Status | Timeline | Effort | Impact |
|----------|-----------|---------------|--------|----------|--------|--------|
| **P0** | ace-lint | code-lint | Not started | Before v1.0 | High | Critical |
| **P0** | ace-handbook | handbook + agent-lint | Not started | Before v1.0 | High | Critical |
| **P0** | ace meta package | NEW | Not started | Before v1.0 | Low | Critical |
| **P0** | ace-init | NEW | Not started | Before v1.0 | Medium | Critical |
| **P0** | Documentation | NEW | In progress | Before v1.0 | High | Critical |
| **P1** | ace-config | NEW | Not started | v1.0 | Medium | High |
| **P1** | ace-bundle | NEW | Not started | v1.0 | Low | Medium |
| **P2** | ace-coverage | coverage-analyze | Not started | v1.1 | Medium | Medium |
| **P2** | Error handling | NEW | Not started | v1.1 | Medium | High |
| **P3** | ace-mcp-server | mcp-proxy | Not started | v1.2+ | High | Low |
| **P3** | Extended git ops | git subcommands | Not started | As needed | Low | Low |

## Recommended Action Plan

### Phase 1: Core Essentials (Before v1.0 Public Release)

**Week 1-2: Foundation**
1. Create `ace-lint` gem structure
2. Extract code-lint functionality
3. Implement Ruby and Markdown linting
4. Write comprehensive tests

**Week 3-4: Handbook**
1. Create `ace-handbook` gem structure
2. Migrate template synchronization
3. Integrate agent validation
4. Add workflow management features

**Week 5-6: Onboarding**
1. Create `ace-init` for project bootstrapping
2. Build `ace` meta package
3. Write getting-started documentation
4. Create tutorial workflows

**Week 7-8: Polish**
1. Integration testing across gems
2. Documentation review and completion
3. Example projects
4. Migration guides from dev-tools

### Phase 2: Polish (v1.0 Release)

1. **ace-config** - Global configuration management
2. **ace-bundle** - Ecosystem management
3. **Unified error handling** - Consistent UX across gems
4. **Performance optimization** - Speed improvements

### Phase 3: Enhancement (v1.1 - Post-Release)

1. **ace-coverage** - Testing enhancement with coverage analysis
2. **Extended language support** - ace-lint for JavaScript, Python, etc.
3. **Advanced templates** - More project templates for ace-init
4. **Workflow marketplace** - Share and discover workflows

### Phase 4: Advanced Features (v1.2+ - Future)

1. **ace-mcp-server** - MCP protocol support
2. **Cloud integrations** - Remote execution, storage
3. **Team features** - Shared configurations, workflows
4. **AI model management** - Model selection, fallbacks

## Success Criteria for v1.0 Public Release

### Must Have
- [ ] ace-lint operational with Ruby + Markdown
- [ ] ace-handbook with template sync and agent validation
- [ ] ace-init for project setup
- [ ] ace meta package for easy installation
- [ ] Comprehensive documentation
- [ ] Migration guide from dev-tools
- [ ] 10+ example workflows
- [ ] All existing ace-* gems stable

### Should Have
- [ ] ace-config for configuration management
- [ ] ace-bundle for ecosystem management
- [ ] Unified error handling
- [ ] Performance benchmarks
- [ ] CI/CD integration examples

### Nice to Have
- [ ] Video tutorials
- [ ] VS Code extension
- [ ] GitHub Actions
- [ ] Community workflow repository

## Risk Assessment

### High Risk
- **Timeline**: Aggressive schedule for essential migrations
- **Mitigation**: Focus on MVP features, iterate post-release

### Medium Risk
- **User adoption**: Moving from monolith to many gems
- **Mitigation**: ace meta package, clear migration guides

### Low Risk
- **Technical complexity**: Most code already exists
- **Mitigation**: Careful extraction and testing

## Key Insights from Analysis

### Must-Have Pattern
Tools that enable the core ACE value proposition:
- AI-assisted development workflows
- Task and release management
- Code quality and testing
- Self-contained, reproducible processes

### Can-Wait Pattern
Tools that enhance but don't define ACE:
- Advanced integrations (MCP)
- Coverage analysis details
- Redundant git operations
- Niche workflow tools

### Should-Drop Pattern
Tools that:
- Duplicate existing functionality
- Are too niche/specific
- Don't fit ACE's focused gem philosophy
- Have low usage or unclear value

### Missing Pattern
Tools for:
- Ecosystem management (ace, ace-bundle)
- User onboarding (ace-init)
- Configuration consistency (ace-config)
- Error recovery and debugging

## Conclusion

The migration to ACE v1.0 should prioritize delivering a **cohesive, well-documented toolkit** that solves real development workflow problems. Essential migrations (ace-lint, ace-handbook) combined with missing pieces (ace-init, documentation) will create a compelling public release.

Features like coverage analysis and MCP support, while valuable, can wait for post-release iterations. The monolithic coding-agent-tools should be fully deprecated, with its useful features absorbed into focused gems.

Success depends on:
1. Excellent onboarding experience (ace-init)
2. Simple installation (gem install ace)
3. Core workflow tools (lint, handbook, existing ace-* gems)
4. Comprehensive documentation and examples

This focused approach will deliver a powerful, user-friendly toolkit ready for public adoption while leaving room for future enhancements based on user feedback.

---

*Document created: October 8, 2025*
*Based on analysis of legacy dev-tools system*
*For ACE v1.0 public release planning*