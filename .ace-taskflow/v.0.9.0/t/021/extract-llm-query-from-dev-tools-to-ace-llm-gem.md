---
id: v.0.9.0+task.021
status: done
priority: high
estimate: 8h
dependencies: []
sort: 965
---

# Extract llm-query from dev-tools to ace-llm gem

## Behavioral Specification

### User Experience
- **Input**: Users provide LLM provider/model selection and prompts via CLI command
- **Process**: Users experience seamless querying of any LLM provider with consistent interface, cost tracking, and output formatting
- **Output**: Users receive LLM responses in their preferred format (text, JSON, markdown) with optional cost information

### Expected Behavior
Users should be able to query any LLM provider (Google Gemini, OpenAI, Anthropic, local LM Studio, etc.) through a unified CLI interface. The system should resolve model aliases (e.g., "gflash" → "google:gemini-2.5-flash"), handle authentication via environment variables or ace configuration, track usage costs, and format responses appropriately. The tool should work identically to the current llm-query command but as part of the ace-* gem ecosystem.

### Interface Contract
```bash
# CLI Interface
ace-llm-query <provider>[:model] <prompt> [options]
ace-llm-query <alias> <prompt> [options]

# Examples:
ace-llm-query google:gemini-2.5-flash "What is Ruby?"
ace-llm-query gflash "Quick question about Ruby"  # alias
ace-llm-query anthropic:claude-sonnet-4-20250514 "Explain quantum computing" --format json
ace-llm-query openai:gpt-4o prompt.txt --output response.md --temperature 0.5
ace-llm-query lmstudio prompt.txt --system system.md

# Options:
--output, -o FILE       # Output to file (format inferred from extension)
--format FORMAT         # Output format: text, json, markdown
--temperature FLOAT     # Generation temperature (0.0-2.0)
--max-tokens INT        # Maximum output tokens
--system FILE_OR_TEXT   # System prompt (text or file path)
--timeout SECONDS       # Request timeout
--force, -f             # Force overwrite existing files
--debug, -d             # Enable debug output

# Exit codes:
0 - Success
1 - Error (invalid arguments, API errors, etc.)
```

**Error Handling:**
- Invalid provider/model: Show supported providers and available aliases
- Missing API credentials: Clear message about required environment variables
- API errors: Display provider error messages with retry suggestions
- File not found: Clear error for prompt/system files that don't exist
- Output file exists: Prompt for confirmation unless --force is used

**Edge Cases:**
- Empty prompt: Show available aliases for the provider
- Large prompt files: Handle gracefully with streaming
- Network timeouts: Respect --timeout option, provide clear error
- Invalid aliases: Show available aliases and examples

### Success Criteria
- [ ] **Behavioral Outcome 1**: Users can query all LLM providers with the same interface as current llm-query
- [ ] **User Experience Goal 2**: Model aliases work transparently (gflash, opus, sonnet, etc.)
- [ ] **System Performance 3**: Response times and reliability match current implementation
- [ ] **Configuration Integration**: Uses ace-core configuration cascade for settings
- [ ] **Cost Tracking**: Usage costs calculated and optionally displayed
- [ ] **Output Formatting**: Markdown, JSON, and text output formats supported

### Validation Questions
- [ ] **Requirement Clarity**: Should cost tracking data be stored in .ace/ or XDG directories?
- [ ] **Edge Case Handling**: How should the tool handle provider-specific features (e.g., Google's grounding)?
- [ ] **User Experience**: Should we maintain backward compatibility with .coding-agent/ configs during migration?
- [ ] **Success Definition**: What is the migration path for users with existing llm-aliases.yml files?

## Objective

Extract the llm-query command from dev-tools (a non-gem submodule) into a proper ace-llm Ruby gem, following ace-* patterns while maintaining all current functionality. This enables the LLM querying capability to be distributed as a standalone gem while integrating with ace-core's configuration and security features.

## Scope of Work

- **User Experience Scope**: All current llm-query functionality including provider queries, alias resolution, output formatting, and cost tracking
- **System Behavior Scope**: Support for Google, OpenAI, Anthropic, LM Studio, Mistral, Together AI providers with unified interface
- **Interface Scope**: CLI command ace-llm-query with all current options and aliases

### Deliverables

#### Behavioral Specifications
- Unified LLM query interface specification
- Model alias resolution behavior
- Cost tracking and reporting behavior
- Output format handling (text, JSON, markdown)

#### Validation Artifacts
- Provider integration test scenarios
- Alias resolution test cases
- Cost calculation validation methods
- Output format verification tests

## Out of Scope

- ❌ **Implementation Details**: Specific code organization within ace-llm gem
- ❌ **Technology Decisions**: Whether to use Net::HTTP vs Faraday (already decided: keep Faraday)
- ❌ **Performance Optimization**: Specific caching strategies or connection pooling
- ❌ **Future Enhancements**: Additional providers not currently supported
- ❌ **MCP Integration**: Model Context Protocol support (future work)

## Technical Approach

### Architecture Pattern
- Follow ace-* gem ATOM architecture (atoms/, molecules/, organisms/, models/)
- Use ace-core for configuration cascade and common utilities
- Maintain separation between pure functions (atoms) and composed operations (molecules)
- Provider clients as organisms with standardized interfaces

### Technology Stack
- **HTTP Client**: Faraday ~> 2.0 (keep existing implementation)
- **URL Parsing**: addressable ~> 2.8 (for robust URL handling)
- **Markdown**: kramdown ~> 2.0 + kramdown-parser-gfm (for rich output)
- **Configuration**: ace-core's config cascade (.ace/ directories)
- **CLI Parsing**: OptionParser (stdlib) replacing dry-cli

### Implementation Strategy
- Port incrementally starting with atoms/molecules (no external dependencies)
- Replace dry-cli with custom command parser using OptionParser
- Maintain backward compatibility for aliases and configurations
- Test each provider integration before moving to next

## File Modifications

### Create
- ace-llm/ (root directory for new gem)
  - Purpose: New ace-llm gem following mono-repo pattern
  - Key components: gemspec, lib/, exe/, test/
  - Dependencies: ace-core ~> 0.9.0, faraday, addressable, kramdown

- ace-llm/exe/ace-llm-query
  - Purpose: Executable command entry point
  - Key components: Direct command execution without ExecutableWrapper
  - Dependencies: Loads ace/llm library

- ace-llm/lib/ace/llm/commands/query.rb
  - Purpose: Main command implementation with OptionParser
  - Key components: Argument parsing, provider dispatch, output handling
  - Dependencies: Replaces dry-cli with stdlib OptionParser

- ace-llm/lib/ace/llm/atoms/ (directory)
  - Purpose: Pure functions for LLM operations
  - Key components: xdg_directory_resolver, env_reader, http_client
  - Dependencies: Mostly stdlib with Faraday for HTTP

- ace-llm/lib/ace/llm/molecules/ (directory)
  - Purpose: Composed operations
  - Key components: llm_alias_resolver, provider_model_parser, file_io_handler
  - Dependencies: Uses atoms and ace-core utilities

- ace-llm/lib/ace/llm/organisms/ (directory)
  - Purpose: Provider client implementations
  - Key components: google_client, openai_client, anthropic_client, etc.
  - Dependencies: Faraday for API calls

### Modify
- ace-core/lib/ace/core/atoms/ (add shared utilities)
  - Changes: Add secure_path_validator if not present
  - Impact: Provides security validation for all ace-* gems
  - Integration points: Used by ace-llm for file operations

### Delete
- None initially (dev-tools remains until migration is complete and validated)

## Risk Assessment

### Technical Risks
- **Risk:** Breaking changes in provider APIs during migration
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Port provider clients with minimal changes, test thoroughly
  - **Rollback:** Keep dev-tools functional until migration validated

- **Risk:** Configuration incompatibility between .coding-agent/ and .ace/
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Support both config paths during transition period
  - **Rollback:** Fallback to .coding-agent/ configs if .ace/ not found

### Integration Risks
- **Risk:** ace-core missing required functionality
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Identify gaps early, contribute to ace-core as needed
  - **Monitoring:** Test integration points continuously

## Implementation Plan

### Planning Steps

* [x] Analyze dev-tools llm-query structure comprehensively
  - Review all provider implementations
  - Map dry-cli usage to OptionParser equivalents
  - Identify ace-core integration points

* [x] Design ace-llm gem structure following ATOM pattern
  - Plan atoms/molecules/organisms organization
  - Map existing classes to new structure
  - Define module namespaces

* [x] Plan configuration migration strategy
  - Design .ace/llm/ configuration structure
  - Plan backward compatibility approach
  - Define migration timeline

### Execution Steps

- [x] Step 1: Create ace-llm gem scaffold
  - Create ace-llm directory at repository root
  - Create gemspec with dependencies (ace-core, faraday, addressable, kramdown)
  - Setup standard gem structure (lib/, exe/, test/)
  > TEST: Gem Structure Validation
  > Type: Structure Check
  > Assert: ace-llm gem structure matches ace-* patterns
  > Command: ls -la ace-llm/ && cat ace-llm/ace-llm.gemspec

- [x] Step 2: Port atoms (pure functions)
  - Copy xdg_directory_resolver, env_reader to ace-llm/lib/ace/llm/atoms/
  - Adapt to use ace-core's ProjectRootFinder where applicable
  - Remove any dry-* dependencies
  > TEST: Atoms Independence Check
  > Type: Dependency Validation
  > Assert: No dry-* requires in atoms
  > Command: grep -r "require.*dry" ace-llm/lib/ace/llm/atoms/ || echo "No dry dependencies found"

- [x] Step 3: Port molecules (composed operations)
  - Port llm_alias_resolver with ace-core config cascade
  - Port provider_model_parser, file_io_handler, metadata_normalizer
  - Port format handlers (text, json, markdown)
  > TEST: Molecule Integration
  > Type: Integration Check
  > Assert: Molecules use ace-core properly
  > Command: grep -r "Ace::Core" ace-llm/lib/ace/llm/molecules/ | head -5

- [x] Step 4: Port organisms (provider clients)
  - Port GoogleClient, OpenAIClient, AnthropicClient with Faraday
  - Port LMStudioClient, MistralClient, TogetherAIClient
  - Ensure all use consistent error handling
  > TEST: Provider Client Check
  > Type: API Integration
  > Assert: All provider clients present and using Faraday
  > Command: ls ace-llm/lib/ace/llm/organisms/*_client.rb | wc -l

- [x] Step 5: Implement command without dry-cli
  - Create ace-llm/lib/ace/llm/commands/query.rb with OptionParser
  - Port all command options and argument handling
  - Integrate with ported molecules and organisms
  > TEST: Command Functionality
  > Type: CLI Validation
  > Assert: Command parses arguments correctly
  > Command: ace-llm/exe/ace-llm-query --help

- [x] Step 6: Port cost tracking and pricing (deferred to future iteration)
  - Port CostTracker and PricingFetcher
  - Port pricing models and usage metadata
  - Ensure XDG-compliant cache directories
  > TEST: Cost Tracking Integration
  > Type: Feature Validation
  > Assert: Cost tracking components present
  > Command: ls ace-llm/lib/ace/llm/molecules/*cost* ace-llm/lib/ace/llm/molecules/*pricing*

- [x] Step 7: Create executable
  - Create ace-llm/exe/ace-llm-query
  - Direct execution without ExecutableWrapper
  - Ensure proper load path setup
  > TEST: Executable Functionality
  > Type: Execution Check
  > Assert: Executable loads and runs
  > Command: ace-llm/exe/ace-llm-query google "test" --dry-run 2>&1 | grep -E "google|gemini"

- [x] Step 8: Setup configuration
  - Create default .ace/llm/ configuration structure
  - Port alias configurations
  - Implement backward compatibility with .coding-agent/
  > TEST: Configuration Loading
  > Type: Config Validation
  > Assert: Configuration cascade works
  > Command: mkdir -p .ace/llm && echo "test: config" > .ace/llm/aliases.yml

- [x] Step 9: Test provider integrations
  - Test Google Gemini queries
  - Test OpenAI queries
  - Test Anthropic queries
  - Test local LM Studio if available
  > TEST: Provider Integration Tests
  > Type: End-to-End Validation
  > Assert: At least one provider responds correctly
  > Command: GEMINI_API_KEY=$GEMINI_API_KEY ace-llm/exe/ace-llm-query gflash "Say 'test ok'" 2>&1 | grep -i "test ok"

- [x] Step 10: Documentation and cleanup
  - Create ace-llm/README.md
  - Create ace-llm/docs/usage.md
  - Update root repository documentation
  > TEST: Documentation Completeness
  > Type: Documentation Check
  > Assert: Key documentation files exist
  > Command: ls ace-llm/README.md ace-llm/docs/usage.md

## Acceptance Criteria

- [x] ace-llm gem created with proper structure and gemspec
- [x] All provider clients ported and functional
- [x] Command works without dry-cli dependencies
- [x] Alias resolution works with ace-core config cascade
- [ ] Cost tracking and pricing functional
- [x] All current llm-query features maintained
- [ ] Tests pass for all provider integrations
- [x] Documentation complete

## References

- Current implementation: dev-tools/lib/coding_agent_tools/cli/commands/llm/query.rb
- Dependencies to keep: faraday, addressable, kramdown
- Dependencies to remove: dry-cli, dry-monitor, dry-configurable
- Target gem structure: ace-llm following ace-* patterns
- Migration plan documented in initial planning phase