# Update Tools Documentation Workflow Instruction

## Goal

Maintain and update the comprehensive tools documentation (dev-tools/docs/tools.md) when new tools are added or existing tools are modified, ensuring accurate and complete documentation for all development tools and gem executables.

## Prerequisites

- New tool has been added to bin/ or dev-tools/exe/ directories
- Existing tool functionality has been modified or enhanced
- Understanding of tool's purpose, usage, and integration
- Access to the tool's source code and help documentation
- Write access to dev-tools/docs/tools.md

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`
- Review current tools documentation: `dev-tools/docs/tools.md`
- Understand tool functionality through testing and source review

## High-Level Execution Plan

### Planning Steps

- [ ] Identify tool type and category (bin/ or dev-tools/exe/)
- [ ] Analyze tool functionality and usage patterns
- [ ] Determine appropriate documentation section placement

### Execution Steps

- [ ] Create or update tool documentation entry using template
- [ ] Add tool to appropriate category section
- [ ] Include usage examples and common workflows
- [ ] Update tool listing and categorization sections
- [ ] Validate documentation completeness and accuracy

## Process Steps

1. **Identify Tool Category and Purpose:**

   **Tool Type Classification:**
   - **Development tools**: Used for project development workflows
     - Git workflow tools (gc, gl, gp, gpull)
     - Task management tools (tn, tr, tal, tnid, rc)
     - Quality & testing tools (test, lint, build)
     - Development utilities (console, tree, cr*)
   - **Gem executables**: Available globally after gem installation
     - LLM integration tools (llm-query, llm-models, llm-usage-report)
     - Main CLI interface (coding_agent_tools)
     - Code review & analysis tools (task-manager, generate-review-prompt)

   **Purpose Analysis:**
   ```bash
   # Test tool functionality directly (fish integration makes exe/ tools available)
   tool-name --help
   
   # For development tools, test from project root
   bin/tool-name --help
   
   # Check tool source for additional context
   cat bin/tool-name
   cat dev-tools/exe/tool-name
   ```

2. **Locate Correct Documentation Section:**

   **Current dev-tools/docs/tools.md structure:**
   - Overview
   - Setup Requirements  
   - Development Tools (bin/)
   - Gem Executables (available via fish integration)
   - Tool Categories
   - Common Workflows
   - Migration Status
   - Notes

3. **Create Tool Documentation Entry:**

   Use the tool documentation template:

## Template

### Tool Documentation Entry Template

```markdown
#### `tool-name` - Brief Description

Brief explanation of what the tool does and its primary use case.

```bash
# Most common usage pattern with useful options
tool-name --most-useful-option "example value"

# Alternative usage for different scenario
tool-name --other-useful-flag
```

**Key Features:**
- Main feature that users care about
- Secondary important feature
- Integration capability (if applicable)
```

**Template Notes:**
- **No --help duplication**: Provide brief, focused information instead of repeating help output
- **Tool name only**: Use `tool-name` not `dev-tools/exe/tool-name` (fish integration handles paths)
- **Practical examples**: Show real-world usage with most useful options
- **Concise descriptions**: Focus on what users need to know, not implementation details

### Category Entry Template

```markdown
- **Tool Name**: Brief description
```

4. **Add New Tool Documentation:**

   **For New Tools:**
   1. Create tool entry using the template
   2. Place in appropriate category section  
   3. Add to tool categories listing
   4. Include in workflow examples if applicable
   5. Update migration status if relevant

   **Location Guidelines:**
   - **Development tools**: Add to "Development Tools" section with `bin/` prefix for invocation
   - **Gem executables**: Add to "Gem Executables" section using tool name only (fish integration available)
   - Use appropriate subsection (Git Workflow, Task Management, LLM Integration, etc.)

5. **Update Existing Tool Documentation:**

   **For Modified Tools:**
   1. Locate existing documentation entry
   2. Update description, usage, or examples as needed
   3. Add new features or options
   4. Update workflow examples if affected
   5. Maintain backward compatibility notes

   **Update Guidelines:**
   - Preserve existing structure and formatting
   - Add new information without removing useful existing content
   - Update version-specific information
   - Note breaking changes clearly

6. **Update Category and Workflow Sections:**

   **Tool Categories Section:**
   ```markdown
   ### By Function
   - **Category Name**: tool1, tool2, tool3
   
   ### By Target Users
   - **AI Coding Agents**: agent-focused tools
   - **Human Developers**: developer-focused tools
   - **Both**: universal tools
   ```

   **Common Workflows Section:**
   - Update workflow examples to include new tools
   - Add new workflow patterns if tool enables them
   - Maintain existing workflow examples

7. **Validation and Quality Checks:**

   Run the comprehensive validation checklist:

## Validation Checklist

### Content Completeness
- [ ] Tool name and brief description provided
- [ ] Clear purpose statement explaining what and why
- [ ] Basic usage syntax documented
- [ ] At least 2-3 practical examples included
- [ ] Key features or options listed
- [ ] Integration notes with other tools (if applicable)

### Documentation Quality
- [ ] Description is clear and concise
- [ ] Examples are practical and realistic
- [ ] Usage syntax follows consistent format
- [ ] Code blocks are properly formatted
- [ ] Language is appropriate for target audience

### Structural Integration
- [ ] Tool placed in correct category section
- [ ] Added to tool categories listing
- [ ] Included in workflow examples (if applicable)
- [ ] Follows established formatting patterns
- [ ] Maintains document structure consistency

### Technical Accuracy
- [ ] Usage examples tested and verified
- [ ] Help output reviewed for accuracy
- [ ] Options and flags documented correctly
- [ ] Integration behavior verified
- [ ] Version-specific information current

### User Experience
- [ ] Examples progress from simple to complex
- [ ] Common use cases covered first
- [ ] Error scenarios or limitations noted
- [ ] Related tools referenced appropriately
- [ ] Target user needs addressed

## Examples

### Example 1: Adding a New Development Tool

**Tool:** `bin/code-validator`

**Documentation Entry:**
```markdown
#### `bin/code-validator` - Multi-Language Code Quality Validator

Validates code quality across multiple dimensions including style, security, and best practices before commits.

```bash
# Validate current changes with security focus
bin/code-validator --rules security,style

# Quick validation with auto-fix
bin/code-validator --fix
```

**Key Features:**
- Multi-language support (Ruby, JavaScript, etc.)
- Configurable rule sets with security focus
- Git hook integration for automated validation
```

**Category Update:**
```markdown
### Quality & Testing Tools
- **code-validator**: Multi-language code quality validation with security focus
```

### Example 2: Adding a New Gem Executable

**Tool:** `task-analyzer` (new exe/ tool)

**Documentation Entry:**
```markdown
#### `task-analyzer` - Project Task Analysis Tool

Analyzes task complexity, dependencies, and estimates across project releases.

```bash
# Analyze current release tasks with complexity metrics
task-analyzer --complexity --current

# Generate dependency graph for specific task
task-analyzer --deps v.0.3.0+task.15
```

**Key Features:**
- Task complexity analysis with estimation accuracy
- Dependency graph visualization
- Release progress tracking with bottleneck identification
```

### Example 3: Updating Existing Tool (Simplified Approach)

**Tool:** `llm-query` (adding new provider support)

**Update to existing entry:**
```markdown
#### `llm-query` - Unified LLM Query Interface

Query multiple LLM providers with unified syntax and cost tracking.

```bash
# Query with cost tracking and provider selection
llm-query anthropic "Explain ATOM architecture" --track-cost

# Local model with specific model selection  
llm-query local "Write a function" --model llama-7b
```

**Key Features:**
- Multi-provider support: Google, OpenAI, Anthropic, Local models
- Real-time cost tracking across all providers
- Response caching with performance optimization
```

## Error Handling

### Common Issues and Solutions

**Missing Tool Information:**
- **Issue**: Tool exists but lacks documentation
- **Solution**: Run `tool-name --help`, examine source code, test basic functionality
- **Prevention**: Document tools immediately upon creation

**Incorrect Category Placement:**
- **Issue**: Tool documented in wrong section
- **Solution**: Review tool purpose, move to appropriate category, update references
- **Prevention**: Follow tool type classification guidelines

**Outdated Examples:**
- **Issue**: Documentation examples no longer work
- **Solution**: Test all examples, update syntax, verify current behavior
- **Prevention**: Include version notes, test examples during updates

**Inconsistent Formatting:**
- **Issue**: New documentation doesn't match existing style
- **Solution**: Review existing entries, follow template structure, maintain consistency
- **Prevention**: Use provided templates, review similar entries before writing

**Integration Gaps:**
- **Issue**: Tool relationships not documented
- **Solution**: Identify related tools, document workflows, note dependencies
- **Prevention**: Consider integration points during initial documentation

## Integration Testing

### Workflow Integration Validation

**Test 1: Documentation Structure Integrity**
```bash
# Verify markdown structure is valid
markdownlint dev-tools/docs/tools.md

# Check for broken links (if markdown-link-check available)
markdown-link-check dev-tools/docs/tools.md 2>/dev/null || echo "Link checker not available"
```

**Test 2: Tool Availability Verification**
```bash
# Check that documented gem executables are available (fish integration)
grep -o '#### `[^`]*`' dev-tools/docs/tools.md | grep -v 'bin/' | while read line; do
  tool=$(echo $line | sed 's/#### `\([^`]*\)`.*/\1/')
  command -v "$tool" >/dev/null || echo "Tool not available: $tool"
done

# Check development tools exist
grep -o '#### `bin/[^`]*`' dev-tools/docs/tools.md | while read line; do
  tool=$(echo $line | sed 's/#### `\([^`]*\)`.*/\1/')
  [ -f "$tool" ] || echo "Development tool missing: $tool"
done
```

**Test 3: Category Completeness**
```bash
# Ensure all bin/ tools are documented
for tool in bin/*; do
  basename_tool=$(basename "$tool")
  grep -q "bin/$basename_tool" dev-tools/docs/tools.md || echo "Missing bin/ tool: $basename_tool"
done

# Ensure all exe/ tools are documented  
for tool in dev-tools/exe/*; do
  basename_tool=$(basename "$tool")
  grep -q "#### \`$basename_tool\`" dev-tools/docs/tools.md || echo "Missing exe/ tool: $basename_tool"
done
```

**Test 4: Workflow Example Validation**
```bash
# Test that examples use correct tool naming (no full paths for exe/ tools)
if grep -q "dev-tools/exe/" dev-tools/docs/tools.md; then
  echo "WARNING: Found full paths to exe/ tools - should use tool name only"
  grep -n "dev-tools/exe/" dev-tools/docs/tools.md
fi
```

### Integration Points Verification

- [ ] All tools in bin/ are documented with `bin/` prefix
- [ ] All tools in dev-tools/exe/ are documented using tool name only
- [ ] Tool categories are complete and accurate
- [ ] Workflow examples use correct tool naming conventions
- [ ] Cross-references between tools are maintained
- [ ] No full paths to exe/ tools (fish integration handles this)

## Usage Example

> **Scenario:** Adding documentation for new gem executable `dependency-analyzer`
>
> 1. Identify tool type: gem executable (dev-tools/exe/)
> 2. Test tool functionality: `dependency-analyzer --help`
> 3. Create documentation entry using simplified template
> 4. Use tool name only: `dependency-analyzer` (not `dev-tools/exe/dependency-analyzer`)
> 5. Place in "Gem Executables" section under appropriate subsection
> 6. Add to tool categories under target user type
> 7. Include useful examples with practical options
> 8. Run validation checklist
> 9. Verify fish integration works correctly

---

This workflow ensures consistent, accurate, and comprehensive documentation of all development tools, maintaining the quality and usefulness of the tools reference for both human developers and AI coding agents.