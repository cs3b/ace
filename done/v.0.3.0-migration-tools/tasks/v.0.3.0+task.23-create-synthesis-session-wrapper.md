---

id: v.0.3.0+task.23
status: completed
priority: medium
estimate: 6h
dependencies: [v.0.3.0+task.18, v.0.3.0+task.21]
---

# Create Reflection Synthesize Command

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-tools/exe/reflection-synthesize 2>/dev/null || echo "Executable created" | sed 's/^/    /'
```

_Result excerpt:_

```
    -rwxr-xr-x  1 user  staff  1847 Dec  7 15:30 dev-tools/exe/reflection-synthesize
```

## Objective

Create a reflection synthesize command similar to code-review-synthesize that processes multiple reflection notes and creates unified improvement analysis using LLM synthesis.

## Scope of Work

* Create dev-tools/exe/reflection-synthesize executable
* Implement CLI command for reflection synthesis
* Support synthesis of multiple reflection notes
* Provide formatted output options with timestamp-based naming
* Create specialized system prompt for reflection analysis

### Deliverables

#### Create

* dev-tools/exe/reflection-synthesize ✅
* lib/coding_agent_tools/cli/commands/reflection/synthesize.rb ✅
* lib/coding_agent_tools/molecules/reflection/report_collector.rb ✅
* lib/coding_agent_tools/molecules/reflection/timestamp_inferrer.rb ✅
* lib/coding_agent_tools/molecules/reflection/synthesis_orchestrator.rb ✅
* dev-handbook/templates/reflection-note-synthesizer/system.prompt.md ✅

#### Modify

* lib/coding_agent_tools/cli.rb (added reflection command registration) ✅

#### Delete

* None

## Phases

1. ✅ Create system prompt template for reflection synthesis
2. ✅ Design and implement CLI command structure  
3. ✅ Create supporting molecule classes
4. ✅ Add CLI registration and executable wrapper
5. ✅ Complete implementation with proper error handling

## Implementation Plan

### Planning Steps

* [x] ✅ Analyze existing code-review-synthesize pattern
  > TEST: Pattern Understanding
  > Type: Analysis Check
  > Assert: Command structure understood
  > Command: ls dev-tools/lib/coding_agent_tools/cli/commands/code/review_synthesize.rb
* [x] ✅ Design reflection synthesis workflow interface
* [x] ✅ Plan timestamp-based output naming format

### Execution Steps

- [x] ✅ Create reflection-synthesize executable
- [x] ✅ Implement CLI command class with proper dry-cli structure
- [x] ✅ Create report collector molecule for reflection note validation
  > TEST: Report Collection
  > Type: Integration Test
  > Assert: Reflection notes can be collected and validated
  > Command: ruby -e "require './lib/coding_agent_tools/molecules/reflection/report_collector'; puts 'OK'"
- [x] ✅ Implement timestamp inferrer for output file naming
- [x] ✅ Create synthesis orchestrator for LLM integration
- [x] ✅ Add CLI registration for reflection commands
  > TEST: CLI Registration
  > Type: Integration Test
  > Assert: Command is registered and accessible
  > Command: dev-tools/exe/reflection-synthesize --help 2>&1 | grep -c "Synthesize multiple reflection notes"
- [x] ✅ Create specialized system prompt for reflection analysis
- [x] ✅ Add comprehensive error handling and debug support

## Acceptance Criteria

* [x] ✅ Reflection synthesize command provides clean CLI interface
* [x] ✅ LLM integration is fully implemented through synthesis orchestrator
* [x] ✅ Multiple output formats supported (text, json, markdown)
* [x] ✅ Help documentation is clear and follows established patterns
* [x] ✅ Timestamp-based output file naming implemented
* [x] ✅ System prompt specialized for reflection note analysis
* [x] ✅ Command follows ATOM architecture and dry-cli patterns

## Out of Scope

* ❌ Creating new LLM synthesis features beyond reflection analysis
* ❌ Modifying existing code review synthesis logic
* ❌ Additional shell script extractions (task.69 was reinterpreted)

## References

* Dependencies: v.0.3.0+task.18, task.21 (CLI infrastructure tasks)
* Target: dev-tools/exe/reflection-synthesize ✅
* Pattern source: dev-tools/exe/code-review-synthesize
* System prompt: dev-handbook/templates/reflection-note-synthesizer/system.prompt.md ✅

## Command Usage

The created command provides this interface:

```bash
reflection-synthesize REFLECTION_NOTES [options]

Arguments:
  REFLECTION_NOTES                  # REQUIRED Reflection note files to synthesize (minimum 2 files)

Options:
  --model=VALUE                     # LLM model to use (default: google:gemini-2.5-pro)
  --output=VALUE                    # Output file path (default: timestampfrom-timestampto-reflection-synthesis.md)
  --format=VALUE                    # Output format (default: markdown): (text/json/markdown)
  --system-prompt=VALUE             # Custom system prompt file path (default: dev-handbook/templates/reflection-note-synthesizer/system.prompt.md)
  --[no-]force                      # Force overwrite existing files without confirmation
  --[no-]dry-run                    # Show what would be done without executing synthesis
  --[no-]debug                      # Enable debug output for verbose error information
```