---
id: v.0.2.0+task.57
status: pending
priority: medium
estimate: 3h
dependencies: ["v.0.2.0+task.54"]
---

# Refactor ClientFactory to Use Dynamic Client Loading

## Objective / Problem

The current `ClientFactory#ensure_clients_loaded` method uses a hardcoded list of client class names. This creates a maintenance burden where adding a new LLM provider requires updating both the new client file and the factory's hardcoded list. A more dynamic approach would automatically discover and load all client classes, making the system more scalable and adhering better to the Open/Closed Principle.

## Directory Audit

```bash
tree -L 2 lib/coding_agent_tools | grep -E "(molecules|organisms)" | sed 's/^/    /'

    ├── molecules
    │   ├── api_credentials.rb
    │   ├── client_factory.rb
    │   ├── http_client.rb
    │   ├── http_request_builder.rb
    │   ├── metadata_normalizer.rb
    │   └── provider_model_parser.rb
    ├── organisms
    │   ├── anthropic_client.rb
    │   ├── base_client.rb
    │   ├── google_client.rb
    │   ├── lm_studio_client.rb
    │   ├── mistral_client.rb
    │   ├── openai_client.rb
    │   └── together_ai_client.rb
```

## Scope of Work

- Refactor `ClientFactory#ensure_clients_loaded` to dynamically discover client classes
- Maintain backward compatibility with existing functionality
- Ensure Zeitwerk autoloading continues to work properly
- Add appropriate error handling for malformed client files

## Deliverables / Manifest

| File | Action | Purpose |
|------|--------|---------|
| `lib/coding_agent_tools/molecules/client_factory.rb` | Modify | Replace hardcoded client list with dynamic discovery |
| `spec/coding_agent_tools/molecules/client_factory_spec.rb` | Modify | Update tests to verify dynamic loading behavior |

## Phases

1. **Analysis** - Study current loading mechanism and Zeitwerk integration
2. **Design** - Design dynamic discovery approach
3. **Implementation** - Replace hardcoded list with dynamic loading
4. **Testing** - Verify all clients load correctly

## Implementation Plan

### Planning Steps
* [ ] Research Zeitwerk's constant loading patterns and best practices
* [ ] Analyze current directory structure and naming conventions for clients
* [ ] Design approach that respects Zeitwerk's autoloading without eagerly loading all constants
* [ ] Consider edge cases (malformed files, non-client files in organisms directory)

### Execution Steps
- [ ] Refactor `ensure_clients_loaded` method to use dynamic discovery:
  ```ruby
  def ensure_clients_loaded
    return if @clients_loaded
    
    # Dynamically discover client files
    client_files = Dir.glob(File.expand_path("../organisms/*_client.rb", __dir__))
    
    client_files.each do |file|
      # Extract class name from filename
      class_name = File.basename(file, ".rb").split('_').map(&:capitalize).join
      
      begin
        # Trigger Zeitwerk autoloading by referencing the constant
        client_class = CodingAgentTools::Organisms.const_get(class_name)
        
        # Verify it's actually a client class (inherits from BaseClient)
        if client_class < CodingAgentTools::Organisms::BaseClient
          # Registration happens automatically via inherited hook
        end
      rescue NameError => e
        # Log warning but don't fail - file might not match a valid class
        warn "Warning: Could not load client class #{class_name}: #{e.message}" if ENV["DEBUG"]
      end
    end
    
    @clients_loaded = true
  end
  ```
- [ ] Add defensive checks to ensure only valid client classes are processed
- [ ] Update any comments or documentation in the file
- [ ] Add tests for edge cases:
  > TEST: Dynamic Discovery
  >   Type: Action Validation
  >   Assert: New client files are automatically discovered without code changes
  >   Command: bundle exec rspec spec/coding_agent_tools/molecules/client_factory_spec.rb
- [ ] Test with a mock client file to verify dynamic loading
- [ ] Ensure performance is not significantly impacted by directory scanning
- [ ] Verify that non-client files in organisms directory don't cause issues

## Acceptance Criteria

- [ ] ClientFactory no longer contains a hardcoded list of client class names
- [ ] All existing clients continue to load and function correctly
- [ ] New client classes are automatically discovered without factory modifications
- [ ] Tests verify dynamic loading behavior
- [ ] No performance regression in client loading
- [ ] Edge cases handled gracefully (malformed files, non-clients)

## Out of Scope

- Changing the client registration mechanism
- Modifying BaseClient or its inherited hook
- Restructuring the organisms directory
- Changing client naming conventions

## References & Risks

- Task 54: [Refactor build_client Method to Use Factory Pattern](v.0.2.0+task.54-refactor-build-client-factory-pattern.md)
- [Zeitwerk Documentation](https://github.com/fxn/zeitwerk)
- Risk: Dynamic loading might impact startup time - mitigate with caching
- Risk: Filesystem operations might behave differently across platforms - test on multiple OS