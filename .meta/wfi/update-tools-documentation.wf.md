# Update Tools Documentation Workflow Instruction

## Goal

Maintain and update the comprehensive tools documentation (docs/tools.md) when new tools are added or existing tools are modified, ensuring accurate and complete documentation for all development tools and gem executables.

## Prerequisites

- New tool has been added to bin/ or dev-tools/exe/ directories
- Existing tool functionality has been modified or enhanced
- Understanding of tool's purpose, usage, and integration
- Access to the tool's source code and help documentation
- Write access to docs/tools.md (symlinked to dev-tools/docs/tools.md)

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`
- Review current tools documentation: `docs/tools.md`
- Check tool help output: `tool-name --help`

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
   - **`bin/` tools**: Development tools for working on the project
     - Git workflow tools (gc, gl, gp, gpull)
     - Task management tools (tn, tr, tal, tnid, rc)
     - Quality & testing tools (test, lint, build)
     - Development utilities (console, tree, cr*)
   - **`dev-tools/exe/` tools**: Gem executables for end users
     - LLM integration tools (llm-query, llm-models, llm-usage-report)
     - Main CLI interface (coding_agent_tools)
     - Code review & analysis tools

   **Purpose Analysis:**
   ```bash
   # Get tool help and usage information
   tool-name --help
   tool-name -h
   
   # Check tool source for additional context
   cat bin/tool-name
   cat dev-tools/exe/tool-name
   ```

2. **Locate Correct Documentation Section:**

   **Current tools.md structure:**
   - Overview
   - Setup Requirements
   - Development Tools (`bin/`)
   - Gem Executables (`dev-tools/exe/`)
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

**Purpose:** Clear explanation of what the tool does and why it exists.

**Usage:**
```bash
# Basic usage example
tool-name [options] [arguments]

# Common use case 1
tool-name --example "sample input"

# Common use case 2 with explanation
tool-name --flag value  # Explanation of this usage
```

**Key Features:**
- Feature 1: Description
- Feature 2: Description
- Feature 3: Description

**Options:**
- `--option1`: Description of option
- `--option2 VALUE`: Description of option with value
- `--help`: Show help information

**Examples:**
```bash
# Example 1: Most common usage
tool-name --common-flag

# Example 2: Advanced usage
tool-name --advanced-option "complex value"

# Example 3: Integration with other tools
tool-name | other-tool
```

**Integration Notes:**
- Works with: List of related tools or workflows
- Required by: List of dependent processes
- Part of: Workflow or category description
```

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
   - `bin/` tools: Add to "Development Tools (`bin/`)" section
   - `dev-tools/exe/` tools: Add to "Gem Executables (`dev-tools/exe/`)" section
   - Use appropriate subsection (Git Workflow, Task Management, etc.)

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

### Example 1: Adding a New bin/ Tool

**Tool:** `bin/new-validator`

**Documentation Entry:**
```markdown
#### `bin/new-validator` - Code Quality Validator

**Purpose:** Validates code quality across multiple dimensions including style, security, and best practices before commits.

**Usage:**
```bash
# Validate current changes
bin/new-validator

# Validate specific files
bin/new-validator path/to/file.rb path/to/other.js

# Validate with specific rules
bin/new-validator --rules security,style
```

**Key Features:**
- Multi-language support (Ruby, JavaScript, etc.)
- Configurable rule sets
- Integration with git hooks
- Detailed violation reports

**Examples:**
```bash
# Quick validation before commit
bin/new-validator

# Security-focused validation
bin/new-validator --rules security

# Validate and auto-fix issues
bin/new-validator --fix
```
```

**Category Update:**
```markdown
### Quality & Testing Tools
- **new-validator**: Multi-language code quality validation
```

### Example 2: Updating an Existing dev-tools/exe/ Tool

**Tool:** `llm-query` (adding new provider support)

**Update to existing entry:**
```markdown
#### `llm-query` - Unified LLM Query Interface
```bash
# NEW: Claude/Anthropic support
dev-tools/exe/llm-query anthropic "Explain ATOM architecture"

# NEW: Local model support
dev-tools/exe/llm-query local "Write a function" --model llama-7b
```

**Key Features:**
- Multi-provider support: Google, OpenAI, Anthropic, Local models
- Cost tracking across providers (NEW)
- Response caching for efficiency
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
markdownlint docs/tools.md

# Check for broken links
markdown-link-check docs/tools.md
```

**Test 2: Tool Functionality Verification**
```bash
# Test documented examples work
grep -A 5 -B 5 "```bash" docs/tools.md | bash -n

# Verify tool help output matches documentation
for tool in bin/* dev-tools/exe/*; do
  $tool --help > /tmp/help-output.txt
  grep -q "$(basename $tool)" docs/tools.md || echo "Missing: $tool"
done
```

**Test 3: Category Completeness**
```bash
# Ensure all tools are categorized
comm -23 <(ls bin/ dev-tools/exe/ | sort) <(grep -o '`[^`]*`' docs/tools.md | tr -d '`' | sort)
```

**Test 4: Workflow Example Validation**
```bash
# Test workflow examples from Common Workflows section
sed -n '/## Common Workflows/,/## /p' docs/tools.md | grep -A 10 "```bash" | bash -n
```

### Integration Points Verification

- [ ] All tools in bin/ are documented
- [ ] All tools in dev-tools/exe/ are documented  
- [ ] Tool categories are complete and accurate
- [ ] Workflow examples include relevant new tools
- [ ] Cross-references between tools are maintained
- [ ] Migration status reflects current tool locations

## Usage Example

> **Scenario:** Adding documentation for new tool `bin/analyze-dependencies`
>
> 1. Identify tool type: `bin/` development tool
> 2. Test tool functionality: `bin/analyze-dependencies --help`
> 3. Create documentation entry using template
> 4. Place in "Development Utilities" subsection
> 5. Add to tool categories under "Development"
> 6. Include in workflow example for dependency analysis
> 7. Run validation checklist
> 8. Test documentation accuracy

---

This workflow ensures consistent, accurate, and comprehensive documentation of all development tools, maintaining the quality and usefulness of the tools reference for both human developers and AI coding agents.