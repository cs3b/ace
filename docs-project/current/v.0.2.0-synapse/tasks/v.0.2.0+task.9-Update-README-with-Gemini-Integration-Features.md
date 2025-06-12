---
id: v.0.2.0+task.9
status: pending
priority: high
estimate: 3h
dependencies: [v.0.2.0+task.1]
---

# Update README with Gemini Integration Features

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 . | grep -E '(README|exe|docs)' | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── README.md
    ├── docs
    │   ├── DEVELOPMENT.md
    │   ├── refactoring_api_credentials.md
    │   ├── SETUP.md
    │   └── testing-with-vcr.md
    ├── exe
    │   ├── coding_agent_tools
    │   └── llm-gemini-query
```

## Objective

Update the main README.md file to reflect the new Google Gemini LLM integration features that were implemented in task.1, including the new `exe/llm-gemini-query` command, API key configuration, and updated requirements. This is critical documentation that users will encounter first when discovering the project.

## Scope of Work

- Update README.md with new Gemini integration features
- Add documentation for the new standalone `exe/llm-gemini-query` command
- Document GEMINI_API_KEY environment variable configuration
- Update Ruby version requirements to 3.4.2
- Add brief mentions of new architectural components (Faraday, Zeitwerk, VCR)

### Deliverables

#### Modify

- README.md

## Phases

1. Audit current README.md structure and content
2. Update "Key Features" section with Gemini integration
3. Add new standalone commands section
4. Update configuration section with API keys
5. Update requirements and development setup
6. Add brief architecture mentions

## Implementation Plan

### Planning Steps

* [ ] Review current README.md structure and identify all sections that need updates
  > TEST: README Structure Analysis
  > Type: Pre-condition Check
  > Assert: All relevant sections are identified for updates
  > Command: bin/test --check-readme-sections-identified
* [ ] Review suggestions-gemini.md specifications for exact content requirements
* [ ] Plan content organization to maintain README readability

### Execution Steps

- [ ] Update "Key Features" section to include "Google Gemini LLM Integration via `exe/llm-gemini-query`"
- [ ] Add new "Available Commands" or "New Standalone Commands" section with `exe/llm-gemini-query` usage
  > TEST: Command Documentation Complete
  > Type: Action Validation
  > Assert: exe/llm-gemini-query is properly documented with usage examples
  > Command: bin/test --check-command-docs-complete README.md
- [ ] Update "Configuration" section to include GEMINI_API_KEY setup with .env file example
- [ ] Update "Requirements" section to specify Ruby >= 3.4.2 (from .tool-versions)
- [ ] Update "Development" section to mention spec/.env.example for API key setup during VCR recording
- [ ] Add brief "Architecture" mention of new core components (Faraday, Zeitwerk, VCR) with link to architecture.md
  > TEST: README Content Validation
  > Type: Action Validation
  > Assert: All required sections are updated with accurate information
  > Command: bin/test --validate-readme-updates README.md

## Acceptance Criteria

- [ ] README.md includes new Gemini integration in "Key Features" section
- [ ] New standalone `exe/llm-gemini-query` command is documented with usage examples
- [ ] GEMINI_API_KEY configuration is clearly explained with .env file setup
- [ ] Ruby version requirement is updated to 3.4.2
- [ ] Development setup mentions API key configuration for VCR testing
- [ ] Brief architecture section mentions new core components with proper links
- [ ] All content follows existing README.md style and formatting
- [ ] Cross-references to other documentation are accurate and functional

## Out of Scope

- ❌ Creating the detailed Gemini query guide (separate task)
- ❌ Updating other documentation files
- ❌ Modifying the actual command implementation
- ❌ Creating new ADR documents

## References

- `coding-agent-tools/docs-project/current/v.0.2.0-synapse/code-review/task.1.reviewed/suggestions-gemini.md` (lines 183-200)
- `docs-dev/guides/task-definition.g.md`
- Current `.tool-versions` file for Ruby version
- `.env.example` files for API key setup examples