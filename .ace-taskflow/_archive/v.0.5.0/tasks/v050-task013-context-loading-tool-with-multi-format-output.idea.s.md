---
id: v.0.5.0+task.013
status: done
priority: high
estimate: 3d
dependencies: []
---

# Context Loading Tool with Multi-Format Output

## Behavioral Specification

### User Experience
- **Input**: YAML templates (files, inline, or from agent definitions), file lists, command lists
- **Process**: Batch loading of files and command execution with progress feedback
- **Output**: Structured context in XML, YAML, or Markdown+XML format

### Expected Behavior
Users can load multiple files and execute commands in a single operation, receiving structured output suitable for both human reading and machine processing. The tool intelligently renders context from templates without requiring AI assistance when the structure is deterministic.

### Interface Contract

```bash
# CLI Interface
context --yaml templates/project-essentials.yaml
context --from-agent .claude/agents/task-manager.md
context --yaml-string 'files: [docs/*.md]'
context --format xml|yaml|markdown-xml  # default: markdown-xml

# Input Template Format (YAML)
files:
  - path/to/file1.md
  - path/to/file2.md
  - glob/pattern/**/*.md
commands:
  - command-to-execute
  - another-command
format: markdown-xml  # optional output hint

# Output Formats
# XML: Pure structured format for machines
# YAML: Configuration format
# Markdown+XML: Human-readable with embedded structure (default)
```

**Error Handling:**
- Missing files: Report in output with error message, continue processing
- Failed commands: Include stderr in output, continue with remaining items
- Invalid template: Clear error message with validation details

**Edge Cases:**
- Empty template: Return empty structured output
- Large files: Truncate with clear indicators
- Binary files: Skip with notification

### Success Criteria
- [x] **Single Operation**: Reduce 4-5 tool calls to 1 for context loading
- [x] **Multi-Format Support**: Output in XML, YAML, or Markdown+XML
- [x] **Template Rendering**: Process templates without AI when deterministic
- [x] **Agent Integration**: Extract context from agent markdown files
- [x] **Performance**: <200ms for cached content, <500ms fresh

### Validation Questions
- [x] **File Size Limits**: 1MB default limit per file, configurable via --max-size
- [x] **Glob Patterns**: Ruby Dir.glob syntax (supports *, ?, [])
- [x] **Command Timeout**: 30 seconds default, configurable via --timeout
- [x] **Cache Strategy**: No caching implemented (stateless operation)

## Objective

Enable efficient context loading for AI agents and developers by consolidating multiple file reads and command executions into a single, structured operation with multiple output formats.

## Scope of Work

- **User Experience Scope**: CLI tool for batch context loading from templates
- **System Behavior Scope**: File reading, command execution, template rendering, format conversion
- **Interface Scope**: CLI with YAML input and multi-format output

### Deliverables

#### Behavioral Specifications
- Template-based context loading
- Multi-format output rendering
- Agent context extraction

#### Validation Artifacts
- Performance benchmarks
- Format validation tests
- Template processing examples

## Out of Scope

- ❌ **Implementation Details**: ATOM architecture specifics
- ❌ **Technology Decisions**: Specific Ruby gems or libraries
- ❌ **Performance Optimization**: Caching implementation details
- ❌ **Future Enhancements**: LLM integration for smart summarization

## References

- Original idea: .ace/taskflow/backlog/ideas/001-context-loading-optimization.md
- Existing code: ProjectContextLoader from code-review
- Similar tools: code-review-prepare project-context

## Implementation Plan

### Planning Steps

* [ ] Research existing ProjectContextLoader implementation in code-review
* [ ] Analyze YAML parsing requirements and libraries (existing YamlReader atom)
* [ ] Design output formatter architecture for XML/YAML/Markdown+XML
* [ ] Research glob pattern support in Ruby (Dir.glob vs File.fnmatch)
* [ ] Investigate command execution safety and timeout strategies

### Execution Steps

#### 1. Create Core Executable and CLI Command

- [ ] Create `.ace/tools/exe/context` executable
  ```ruby
  #!/usr/bin/env ruby
  require_relative "../lib/coding_agent_tools"
  CodingAgentTools::CLI.start(ARGV)
  ```

- [ ] Create `.ace/tools/lib/coding_agent_tools/cli/commands/context.rb`
  - Define CLI options: --yaml, --from-agent, --yaml-string, --format
  - Parse and validate input parameters
  - Call ContextLoader organism

#### 2. Create ATOM Components

- [ ] Create `.ace/tools/lib/coding_agent_tools/atoms/context/template_parser.rb`
  - Parse YAML template structure
  - Validate template format
  - Extract files and commands lists

- [ ] Create `.ace/tools/lib/coding_agent_tools/molecules/context/context_aggregator.rb`
  - Combine file contents and command outputs
  - Handle glob pattern expansion
  - Manage error collection

- [ ] Create `.ace/tools/lib/coding_agent_tools/molecules/context/output_formatter.rb`
  - Format as XML structure
  - Format as YAML structure
  - Format as Markdown with embedded XML
  - Handle truncation for large outputs

- [ ] Create `.ace/tools/lib/coding_agent_tools/molecules/context/agent_context_extractor.rb`
  - Parse agent markdown files
  - Extract YAML from Context Definition section
  - Handle embedded vs external templates

- [ ] Create `.ace/tools/lib/coding_agent_tools/organisms/context_loader.rb`
  - Orchestrate template parsing
  - Execute file reading (reuse FileContentReader)
  - Execute commands (reuse SystemCommandExecutor)
  - Apply output formatting
  - Handle caching with CacheManager

#### 3. Implement Template Processing

- [ ] Support YAML file input
  ```bash
  context --yaml templates/project.yaml
  ```
  > TEST: YAML File Loading
  > Type: Integration Test
  > Assert: Template loaded and processed correctly
  > Command: context --yaml spec/fixtures/test-template.yaml --format yaml | grep "files:"

- [ ] Support agent file context extraction
  ```bash
  context --from-agent .claude/agents/git-commit.md
  ```
  > TEST: Agent Context Extraction
  > Type: Integration Test
  > Assert: Context extracted from markdown
  > Command: context --from-agent spec/fixtures/test-agent.md --format xml | grep "<context>"

- [ ] Support inline YAML
  ```bash
  context --yaml-string 'files: [docs/*.md]'
  ```

#### 4. Implement Output Formats

- [ ] XML output formatter
  ```xml
  <context>
    <files>
      <file path="...">content</file>
    </files>
    <commands>
      <output cmd="...">output</output>
    </commands>
  </context>
  ```

- [ ] YAML output formatter
  ```yaml
  context:
    files:
      - path: ...
        content: ...
    commands:
      - cmd: ...
        output: ...
  ```

- [ ] Markdown+XML formatter (default)
  ```markdown
  # Context
  
  ## Files
  
  <file path="...">
  content
  </file>
  
  ## Commands
  
  <output cmd="...">
  output
  </output>
  ```

#### 5. Add Error Handling and Edge Cases

- [ ] Handle missing files gracefully
  - Continue processing
  - Include error in output
  > TEST: Missing File Handling
  > Type: Unit Test
  > Assert: Processing continues with error noted
  > Command: rspec spec/unit/organisms/context_loader_spec.rb -e "missing files"

- [ ] Handle command failures
  - Capture stderr
  - Include in output with error marker

- [ ] Handle large outputs
  - Implement truncation with indicators
  - Add --max-size option

#### 6. Testing Implementation

- [ ] Create unit tests for atoms
  - TemplateParser specs
  - Individual component validation

- [ ] Create integration tests for molecules
  - ContextAggregator with multiple inputs
  - OutputFormatter for all formats
  - AgentContextExtractor with real agent files

- [ ] Create CLI integration tests
  - Full command execution tests
  - Format verification tests
  - Error handling tests

- [ ] Create performance benchmarks
  - Measure execution time
  - Verify <200ms cached, <500ms fresh

#### 7. Documentation

- [ ] Update `docs/tools.md` with context tool documentation
- [ ] Add usage examples for all input methods
- [ ] Document template format specification
- [ ] Create example templates in `.ace/tools/templates/context/`

### Risk Analysis

**Technical Risks:**
- Command execution security (mitigated by using existing SystemCommandExecutor)
- Large output handling (mitigated by truncation strategy)
- Template parsing errors (mitigated by validation)

**Rollback Strategy:**
- Tool is new addition, no existing functionality affected
- Can be disabled by removing executable
- No data migration required

**Performance Impact:**
- Caching reduces repeated operations
- Batch processing more efficient than individual calls
- Target: 75% reduction in tool calls