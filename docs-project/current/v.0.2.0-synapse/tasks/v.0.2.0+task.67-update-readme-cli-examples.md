---
id: v.0.2.0+task.67
status: pending
priority: high
estimate: 2h
dependencies: []
---

# Update README.md CLI Command Examples

## Objective / Problem

All CLI examples in README.md are outdated due to recent changes. The `llm-query` examples don't show cost and usage summaries, `llm-models` examples don't show new `context_size` and `max_output_tokens` fields, and the new `llm usage_report` command is missing entirely. Users following the documentation will see different output than what's documented, creating confusion.

## Directory Audit

Current documentation structure:
```
docs/
├── README.md (contains outdated CLI examples)
└── other docs...

lib/coding_agent_tools/cli/commands/llm/
├── query.rb (updated with new output format)
├── models.rb (updated with new fields)
└── usage_report.rb (new command, not documented)

docs-project/current/v.0.2.1-synapse/doc_review/task-61/
└── dr-report-gpro-final.md (source of this requirement)
```

## Scope of Work

Refresh all CLI command examples in README.md to match current implementation output, add the new `llm usage_report` command, and update the "Key Features" list to reflect new capabilities.

## Deliverables

1. **Updated CLI Examples**:
   - `llm-query` examples showing new cost and usage summary output
   - `llm-models` examples showing `context_size` and `max_output_tokens` fields
   - New `llm usage_report` command examples

2. **Feature List Updates**:
   - Add "Cost Tracking" to "Key Features"
   - Add "Enhanced Security" to "Key Features"
   - Update existing feature descriptions as needed

3. **Command Reference Updates**:
   - Add `llm usage_report` to "Core Commands" section
   - Ensure all command descriptions are current

## Phases

1. **Example Collection**: Run current commands to capture actual output
2. **Documentation Updates**: Replace outdated examples with current output
3. **Feature List Refresh**: Update key features and command listings
4. **Validation**: Ensure all examples are accurate and complete

## Implementation Plan

### Planning Steps
* [ ] Run `llm-query` commands to capture current output format with cost/usage data
* [ ] Run `llm-models` commands to capture current output with new fields 
* [ ] Run `llm usage_report` commands to understand output format and options
* [ ] Review current "Key Features" list to identify needed updates

### Execution Steps
- [ ] Update `llm-query` command examples to show new cost and usage summary output
- [ ] Update `llm-models` command examples to show `context_size` and `max_output_tokens` fields
- [ ] Add new `llm usage_report` command to "Core Commands" section with examples
- [ ] Add "Cost Tracking" to "Key Features" list with appropriate description
- [ ] Add "Enhanced Security" to "Key Features" list with appropriate description
- [ ] Update any other CLI examples that may be affected by recent changes
- [ ] Validate all examples produce the documented output
- [ ] Ensure command descriptions and help text references are accurate

## Acceptance Criteria

- [ ] All `llm-query` examples show current output format including cost/usage data
- [ ] All `llm-models` examples show current output format including new fields
- [ ] `llm usage_report` command is documented with practical examples
- [ ] "Key Features" list includes "Cost Tracking" and "Enhanced Security"
- [ ] "Core Commands" section includes `llm usage_report`
- [ ] All documented examples produce the expected output when executed
- [ ] Command descriptions are accurate and up-to-date
- [ ] No outdated examples remain in the documentation

## Out of Scope

- Changes to command implementations or output formats
- Documentation of internal architecture changes
- SETUP.md or other guide updates (covered by separate tasks)
- Detailed feature guides (covered by separate tasks)

## References & Risks

- **Source**: `docs-project/current/v.0.2.1-synapse/doc_review/task-61/dr-report-gpro-final.md` section 9 (High priority item)
- **Risk**: Outdated examples create user confusion and reduce documentation credibility
- **Risk**: New features may not be discovered without proper documentation visibility
- **Testing**: Manual execution of all documented commands to verify output accuracy