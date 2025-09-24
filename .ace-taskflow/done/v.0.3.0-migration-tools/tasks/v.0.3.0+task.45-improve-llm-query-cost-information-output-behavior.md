---
id: v.0.3.0+task.45
status: done
priority: medium
estimate: 4h
dependencies: []
---

# Improve LLM Query Cost Information Output Behavior

## 0. Directory Audit ✅

_Command run:_

```bash
grep -n "def output_to_stdout" lib/coding_agent_tools/cli/commands/llm/query.rb | sed 's/^/    /'
```

_Result excerpt:_

```
    226:          def output_to_stdout(response, options)
```

## Objective

Improve the llm-query command's cost information output behavior to make it more user-friendly and suitable for different use cases. Currently, cost information is always displayed to stdout in text format, which clutters the output when users only want the AI response. The goal is to only show the message content by default to stdout, and include cost information only when using markdown/json formats or when outputting to files.

## Scope of Work

- Modify llm-query to return only the AI message content to stdout by default (text format)
- Include cost information in stdout only when using markdown or json output formats
- Ensure cost information is always included when outputting to files (all formats)
- Maintain backward compatibility for users who expect cost information in specific formats
- Update help text and documentation to reflect the new behavior

### Deliverables

#### Create

- None (modifying existing functionality)

#### Modify

- lib/coding_agent_tools/cli/commands/llm/query.rb (update output_to_stdout method)
- lib/coding_agent_tools/molecules/format_handlers.rb (update format handlers if needed)
- exe/llm-query help text (if affected by changes)

#### Delete

- None

## Phases

1. **Analysis Phase**: Understand current cost information display logic
2. **Design Phase**: Plan new output behavior for different formats and destinations
3. **Implementation Phase**: Modify output methods to implement new behavior
4. **Testing Phase**: Verify behavior across all formats and output destinations

## Implementation Plan

### Planning Steps

- [x] Analyze current cost information display behavior across all output formats
  > TEST: Current Behavior Analysis
  > Type: Pre-condition Check
  > Assert: Understand when and where cost information is currently displayed
  > Command: exe/llm-query google "test" && exe/llm-query google "test" --format json && exe/llm-query google "test" --format markdown
- [x] Review format handlers to understand how each format includes cost information
  > TEST: Format Handler Analysis
  > Type: Pre-condition Check
  > Assert: Understand how text, json, and markdown formats handle cost information
  > Command: grep -A 10 -B 5 "cost\|usage" lib/coding_agent_tools/molecules/format_handlers.rb
- [x] Plan the new output behavior specification for each format and destination

### Execution Steps

- [x] Modify output_to_stdout method to exclude cost information for text format
  > TEST: Text Format Output
  > Type: Action Validation
  > Assert: llm-query with text format shows only message content to stdout (no cost info)
  > Command: exe/llm-query google "Hello" | grep -v "Token Usage\|Cost Summary" && echo "SUCCESS: No cost info in stdout"
- [x] Ensure markdown and json formats still include cost information in stdout
  > TEST: Markdown Format Cost Information
  > Type: Action Validation
  > Assert: llm-query with markdown format includes cost information in stdout
  > Command: exe/llm-query google "Hello" --format markdown | grep -E "(Token Usage|Cost Summary)" && echo "SUCCESS: Cost info present"
- [x] Verify cost information is always included when outputting to files
  > TEST: File Output Cost Information
  > Type: Action Validation
  > Assert: All formats include cost information when writing to files
  > Command: exe/llm-query google "Hello" --output test.txt && grep -E "(Token Usage|Cost|tokens)" test.txt && rm test.txt
- [x] Update any affected help text or documentation
- [x] Test edge cases and ensure backward compatibility for automation users
  > TEST: Backward Compatibility
  > Type: Final Validation
  > Assert: Scripts expecting cost info in json/markdown formats still work
  > Command: exe/llm-query google "test" --format json | jq '.cost' && exe/llm-query google "test" --format markdown | grep "Cost"

## Acceptance Criteria

- [x] Default text format to stdout shows only the AI message content (no cost information)
- [x] Markdown format to stdout includes cost information in the formatted output
- [x] JSON format to stdout includes cost information in the JSON structure
- [x] All formats include cost information when outputting to files
- [x] File output summaries still show cost information in stdout
- [x] No regression in existing functionality for automation scripts using json/markdown formats
- [x] Help text accurately describes the new output behavior

## Out of Scope

- ❌ Changing the cost information calculation or data structure
- ❌ Adding new output formats beyond text, json, markdown
- ❌ Modifying cost information content or accuracy
- ❌ Changing file output behavior beyond ensuring cost info is included
- ❌ Adding new command-line flags to control cost information display

## References

**User Requirements:**
> "in default stdio we should return only the message (only in mardown or json format we output cost info to stdio or to file)"

**Current Implementation:**
- lib/coding_agent_tools/cli/commands/llm/query.rb:234 - Shows cost info for text format to stdout
- lib/coding_agent_tools/cli/commands/llm/query.rb:239-255 - generate_usage_summary method
- lib/coding_agent_tools/molecules/format_handlers.rb - Format-specific cost handling

**Expected Behavior:**
- **Text format to stdout**: Message only (clean output)
- **Markdown format to stdout**: Message + cost info  
- **JSON format to stdout**: Message + cost info in JSON structure
- **Any format to file**: Message + cost info included
- **File output summary to stdout**: Include cost info summary

**Use Cases:**
- Pipeline usage: `llm-query google "summarize this" | other-command` (should get clean text)
- Automation scripts: `llm-query google "data" --format json | jq '.cost'` (should still work)
- Documentation: `llm-query google "explain" --format markdown` (should include cost)
- File output: `llm-query google "report" --output result.md` (should include cost in file)