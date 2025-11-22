---
id: v.0.9.0+task.118
status: in-progress
priority: high
estimate: 8-12h
dependencies:
- v.0.9.0+task.119
---

# ace-prompt-queue: Simple Queue Workflow for AI Prompts

## Behavioral Specification

### User Experience

- **Input**: Developers write prompts in a single file `.cache/ace-prompt/prompts/the-prompt.md` using their full-featured editor, optionally with YAML frontmatter for context specification
- **Process**: Run `ace-prompt` command which automatically archives the prompt, optionally loads context via ace-context, optionally enhances via LLM, and outputs the result
- **Output**: Complete prompt content (with context and/or enhancement if configured) ready to pipe to Claude Code or other AI tools

### Expected Behavior

The system provides a queue-based prompt workflow where developers:

1. Write prompts in their editor (not Claude's input box)
2. Run a simple command with no arguments required
3. Get automatic archiving with timestamp history
4. Access previous prompt via symlink
5. Optionally aggregate context from files/commands/presets
6. Optionally enhance prompts for clarity via LLM
7. Use task-specific prompts when working in task context

The workflow is intentionally simple - one active prompt at a time, like a print queue. This is NOT a prompt template library or discovery system.

### Interface Contract

```bash
# Primary Interface - Default command (no arguments)
ace-prompt
# → Reads .cache/ace-prompt/prompts/the-prompt.md
# → Archives to .cache/ace-prompt/prompts/archive/YYYYMMDD-HHMMSS.md
# → Updates _previous.md symlink
# → Outputs prompt content

# Template Management
ace-prompt setup               # Initialize with base template
ace-prompt setup --template tmpl://custom/template  # Use custom template
ace-prompt reset               # Reset to base template (archives current)

# Context Loading (when frontmatter present)
ace-prompt --ace-context       # Load context specified in frontmatter
ace-prompt -c                  # Short form

# Enhancement
ace-prompt --enhance           # Enhance prompt via LLM
ace-prompt -e                  # Short form

# Skip configured defaults
ace-prompt --raw               # Skip enhancement even if configured
ace-prompt --no-context        # Skip context even if configured

# Task-specific
ace-prompt --task 117          # Use task-specific prompt location
ace-prompt -t 117              # Short form

# Combinations
ace-prompt --ace-context --enhance    # Both features
ace-prompt -ce                        # Short form
ace-prompt --task 117 --ace-context   # Task + context
```

**File Structure**:
```
.cache/ace-prompt/prompts/
├── the-prompt.md              # THE active prompt (only one!)
├── _previous.md               # Symlink → archive/TIMESTAMP.md
└── archive/
    ├── 20251119-120000.md
    ├── 20251119-143000.md
    └── 20251119-155500.md
```

**Task-specific Structure**:
```
.ace-taskflow/v.0.9.0/tasks/117-*/
└── prompts/
    ├── the-prompt.md
    ├── _previous.md → archive/TIMESTAMP.md
    └── archive/
```

**Optional Frontmatter Format**:
```yaml
---
context:
  files:
    - path/to/file.rb
  commands:
    - git diff HEAD~1
  presets:
    - project
---
[Prompt content here]
```

**Base Template Format** (from `tmpl://ace-prompt/base-prompt`):
```markdown
---
context:
  presets: []
  files: []
  commands: []
---

# Prompt

[Your prompt here]

## Context Requirements

[Describe what context is needed]

## Expected Output

[Describe expected results]
```

**Error Handling**:
- File not found: Clear error message with setup instructions
- Archive failure: Warning but continue (output still works)
- Symlink failure: Warning but continue (output still works)
- Enhancement failure: Warning, output raw prompt
- Context loading failure: Warning, output prompt without context

**Edge Cases**:
- Empty prompt file: Output empty (valid use case)
- No archive directory: Create automatically
- Corrupt frontmatter: Skip context loading, warn user
- Task not found: Clear error with available tasks
- Multiple task matches: Use most recent version

### Success Criteria

- [ ] **Queue Workflow**: Single active prompt file (`the-prompt.md`) with no naming or discovery
- [ ] **Archive Mechanism**: Automatic copy to `archive/YYYYMMDD-HHMMSS.md` preserving original
- [ ] **Previous Link**: `_previous.md` symlink always points to last archived prompt
- [ ] **Default Command**: `ace-prompt` works with zero arguments for common case
- [ ] **Template System**: `setup` and `reset` commands with tmpl:// protocol support
- [ ] **Task Support**: `--task N` resolves to task-specific prompt location
- [ ] **Context Loading**: Optional frontmatter triggers ace-context integration when flagged
- [ ] **Enhancement**: Optional LLM enhancement with caching for performance
- [ ] **Protocol Integration**: Uses tmpl:// for templates and prompt:// for system prompts
- [ ] **Configuration**: Project and user configs with CLI flag overrides
- [ ] **Error Resilience**: Archive/symlink failures don't stop execution
- [ ] **Claude Integration**: `/prompt` slash command works seamlessly

### Validation Questions (Resolved)

- [x] **Context Merge Strategy**: No separator needed - context flows naturally before prompt
- [x] **Enhancement Scope**: Enhancement applies to final output (context+prompt if context enabled)
- [x] **Cache Key**: Based on content hash of what's being enhanced
- [x] **Task Discovery**: Use latest version when multiple exist
- [x] **Frontmatter Validation**: Warn on invalid YAML but continue with raw prompt
- [x] **Template Protocol**: Use tmpl:// for templates, prompt:// for system prompts
- [x] **Model Alias**: Use `glite` as default (resolves to google:gemini-2.0-flash-lite)

## Objective

Replace the complex prompt library system built in task 117 with a simple queue-based workflow tool that solves the actual problem: Claude Code's in-editor prompt writing is limited. Developers need to write prompts in their full-featured editor with automatic history tracking and optional enhancements.

**Lesson from Task 117**: The original `.claude/commands/prompt.md` had the right idea - simple read, archive, execute. We overcomplicated it by adding named prompts, protocols, and discovery. This task returns to the original simple vision with thoughtful additions (context loading, enhancement) that don't compromise simplicity.

## Scope of Work

### User Experience Scope
- Command-line interface with sensible defaults
- Zero-argument default command for common use
- Task-specific context when working on tasks
- Optional context aggregation via frontmatter
- Optional prompt enhancement for clarity

### System Behavior Scope
- Queue-based single-file workflow
- Automatic archiving with timestamps
- Symlink management for previous prompt
- Context loading via ace-context gem
- LLM enhancement with caching
- Configuration cascade (project overrides user)

### Interface Scope
- Primary `ace-prompt` command with flags
- Configuration via `.ace/prompt/config.yml`
- Integration with `/prompt` Claude Code command
- Support for task-specific workflows

### Deliverables

#### Behavioral Specifications
- Complete interface contract documentation
- Usage guide with flow diagrams
- Configuration schema documentation

#### Validation Artifacts
- Test scenarios for all command variations
- Archive mechanism verification
- Context loading validation
- Enhancement caching tests

## Out of Scope

- ❌ **Named Prompts**: No prompt naming or categorization (just `the-prompt.md`)
- ❌ **Discovery System**: No searching or listing prompts (only one active file)
- ❌ **Protocol Registration**: No `prompt://` protocol (ace-nav already handles that)
- ❌ **Template Variables**: No variable substitution or templating
- ❌ **Multiple Active Prompts**: No queue management (one file only)
- ❌ **Complex Metadata**: Frontmatter only for context, not categorization
- ❌ **Import/Export**: No prompt sharing or synchronization features
- ❌ **Version Control**: Archive is timestamp-based, not git-based

## References

- **Original requirement**: `.claude/commands/prompt.md` (2025-11-02) - Simple read, archive, run
- **Task 117 lessons**: Over-engineered prompt library that missed the core requirement
- **Task 117 behavioral spec**: `.ace-taskflow/v.0.9.0/tasks/117-llm-feat/usage.md` - What should have been built
- **ace-context integration**: Use existing context aggregation instead of rebuilding
- **ace-llm integration**: For optional prompt enhancement feature

## Technical Research

### Architecture Pattern Analysis

**ATOM Architecture** (from ACE patterns):
- **Atoms**: Pure functions for data transformation (timestamp generation, path resolution)
- **Molecules**: Operations with side effects (file operations, context loading)
- **Organisms**: Business logic orchestration (prompt processing workflow)
- **Models**: Data structures (configuration, prompt data)

**Queue Pattern**:
- Single active item (the-prompt.md)
- Process and archive on read
- No management interface needed
- Similar to print spooler or task queue

### Technology Stack Research

**Required Dependencies**:
- `ace-support-core` (~> 0.10): Configuration cascade, file operations
- `ace-context` (~> 0.5): Context aggregation from frontmatter
- `ace-llm` (~> 0.5): Optional prompt enhancement
- `thor` (~> 1.2): CLI framework
- `yaml`: Frontmatter parsing (stdlib)

**File System Operations**:
- Ruby `FileUtils` for copy operations
- Ruby `File.symlink` for symlink management
- Directory creation with `FileUtils.mkdir_p`

### Lessons from Task 117

**What to Reuse**:
- Basic gem structure and setup
- Test patterns and fixtures
- Configuration cascade pattern
- LLM integration approach

**What to Avoid**:
- Complex discovery mechanisms
- Protocol registration
- Multiple search paths
- Named prompt system
- Over-abstraction

## Architectural Approach

### Component Design

**Atoms** (Pure Functions):
```ruby
module Ace::Prompt::Atoms
  TimestampGenerator    # Generate YYYYMMDD-HHMMSS format
  TaskPathResolver      # Resolve task ID to prompt path
  ContentHasher         # MD5 hash for cache key
  FrontmatterExtractor  # Extract YAML frontmatter
  ModelAliasResolver    # Resolve model aliases (glite → full name)
end
```

**Molecules** (Operations):
```ruby
module Ace::Prompt::Molecules
  PromptReader          # Read the-prompt.md with frontmatter parsing
  PromptArchiver        # Copy to archive + update symlink
  ContextLoader         # Simple delegation to ace-context --embed-source
  EnhancementTracker    # Track enhancement chains in archive
  ConfigLoader          # Load configuration cascade
  TemplateResolver      # Resolve tmpl:// protocols via ace-nav
  TemplateManager       # Load and apply templates
end
```

**Organisms** (Business Logic):
```ruby
module Ace::Prompt::Organisms
  PromptEnhancer        # LLM enhancement with chain tracking
  PromptProcessor       # Main workflow orchestration (simplified)
  PromptInitializer     # Setup/reset with templates
  # REMOVED: ContentMerger - Not needed with ace-context delegation
end
```

**CLI** (Interface):
```ruby
class Ace::Prompt::CLI < Thor
  default_task :process

  desc "process", "Process prompt (default)"
  option :ace_context, aliases: "-c", type: :boolean
  option :enhance, aliases: "-e", type: :boolean
  option :raw, type: :boolean
  option :no_context, type: :boolean
  option :task, aliases: "-t", type: :numeric
  def process
    # Orchestrate via PromptProcessor
  end

  desc "setup", "Initialize prompt with base template"
  option :template, type: :string, desc: "Template to use (default: tmpl://ace-prompt/base-prompt)"
  option :force, type: :boolean, desc: "Overwrite existing prompt"
  def setup
    # Orchestrate via PromptInitializer
  end

  desc "reset", "Reset prompt to base template"
  option :template, type: :string, desc: "Template to use (default: from config)"
  def reset
    # Archive current and setup fresh
  end
end
```

### Data Flow (Simplified)

1. **Input Phase**: Read prompt file, extract frontmatter
2. **Archive Phase**: Copy to timestamped file (with enhancement suffix if enhancing), update symlink
3. **Context Phase**: If context needed, delegate to `ace-context --embed-source` (no merging)
4. **Enhance Phase**: Optionally enhance via LLM with chain tracking
5. **Output Phase**: Write final content to stdout

**Key Simplification**: No merging logic - ace-context returns complete output when context is needed

## File Modification Planning

### Create Files

**Core Library** (`ace-prompt/lib/ace/prompt/`):
- `version.rb` - Version constant
- `cli.rb` - Thor CLI implementation
- `atoms/timestamp_generator.rb` - YYYYMMDD-HHMMSS generation
- `atoms/task_path_resolver.rb` - Task ID to path resolution
- `atoms/content_hasher.rb` - MD5 hashing
- `atoms/frontmatter_extractor.rb` - YAML frontmatter parsing
- `atoms/model_alias_resolver.rb` - Resolve model aliases (glite → full)
- `molecules/prompt_reader.rb` - File reading with frontmatter
- `molecules/prompt_archiver.rb` - Archive copy + symlink (with _e001 support)
- `molecules/context_loader.rb` - Simple delegation to ace-context
- `molecules/enhancement_tracker.rb` - Track enhancement chains
- `molecules/config_loader.rb` - Configuration loading
- `molecules/template_resolver.rb` - Resolve tmpl:// protocols
- `molecules/template_manager.rb` - Load and apply templates
- `organisms/prompt_enhancer.rb` - LLM enhancement with chain tracking
- `organisms/prompt_processor.rb` - Main orchestration (simplified)
- `organisms/prompt_initializer.rb` - Setup/reset with templates

**Handbook** (`ace-prompt/handbook/`):
- `prompts/base/enhance.md` - Enhancement system prompt
- `templates/base-prompt.md` - Base template for new prompts

**Protocol Sources** (`.ace/nav/protocols/`):
- `prompt-sources/ace-prompt.yml` - Prompt protocol registration
- `tmpl-sources/ace-prompt.yml` - Template protocol registration

**Documentation** (`ace-prompt/docs/`):
- `usage.md` - Complete usage guide with flow diagrams
- `configuration.md` - Configuration reference

**Task Documentation**:
- `.ace-taskflow/v.0.9.0/tasks/118-task-prompt-ace/ux/usage.md` - Task usage examples

### Modify Files

- Task 117 status update (mark as superseded)
- `.claude/commands/prompt.md` - Update to use ace-prompt

### Delete Files

None (starting fresh, not modifying task 117 implementation)

## Test Case Planning

### Happy Path Scenarios
- Default command with simple prompt
- Prompt with frontmatter and context loading
- Enhancement with caching
- Task-specific prompt processing
- Combined flags (context + enhancement)

### Edge Cases
- Empty prompt file
- Missing archive directory
- Corrupt frontmatter YAML
- Task not found
- Multiple task versions
- Symlink on non-supporting filesystem

### Error Scenarios
- Prompt file not found
- Archive operation failure
- Context loading failure
- Enhancement LLM timeout
- Invalid configuration

### Integration Tests
- ace-context integration
- ace-llm integration
- Configuration cascade
- CLI flag combinations

## Implementation Plan

### Planning Steps

* [ ] Review task 117 implementation for reusable components
* [ ] Design configuration schema with all options
* [ ] Plan cache key strategy for enhanced prompts
* [ ] Research symlink compatibility across filesystems
* [ ] Design error recovery strategies

### Execution Steps

- [ ] Create gem structure and basic files
  > TEST: Gem Structure Validation
  > Type: Action Validation
  > Assert: ace-prompt gem directory exists with proper structure
  > Command: ls -la ace-prompt/lib/ace/prompt/

- [ ] Implement atoms layer (pure functions)
  - [ ] TimestampGenerator for YYYYMMDD-HHMMSS
  - [ ] TaskPathResolver for task directory finding
  - [ ] ContentHasher for MD5 generation
  - [ ] FrontmatterExtractor for YAML parsing

- [ ] Implement molecules layer (operations)
  - [ ] PromptReader with frontmatter support
  - [ ] PromptArchiver with copy and symlink
    > TEST: Archive Mechanism
    > Type: Action Validation
    > Assert: File copied to archive/ and symlink updated
    > Command: ace-prompt && ls -la .cache/ace-prompt/prompts/archive/
  - [ ] ContextLoader for ace-context integration
  - [ ] CacheManager for enhancement caching
  - [ ] ConfigLoader for configuration cascade

- [ ] Implement organisms layer (business logic)
  - [ ] PromptEnhancer with LLM and caching
  - [ ] ContentMerger with merge strategies
  - [ ] PromptProcessor for main workflow
    > TEST: Complete Workflow
    > Type: Integration Test
    > Assert: Prompt processed with all phases
    > Command: echo "Test prompt" > .cache/ace-prompt/prompts/the-prompt.md && ace-prompt

- [ ] Implement CLI with Thor
  - [ ] Default task configuration
  - [ ] Flag parsing and validation
  - [ ] Error handling and user feedback
    > TEST: CLI Interface
    > Type: Action Validation
    > Assert: All flags work correctly
    > Command: ace-prompt --help

- [ ] Create handbook content
  - [ ] Enhancement system prompt
  - [ ] Configuration examples

- [ ] Write comprehensive documentation
  - [ ] Usage guide with examples
  - [ ] Flow diagrams (mermaid)
  - [ ] Configuration reference
  - [ ] Task-specific usage examples

- [ ] Implement test suite
  - [ ] Unit tests for atoms
  - [ ] Integration tests for molecules
  - [ ] End-to-end tests for organisms
  - [ ] CLI command tests

- [ ] Update Claude Code integration
  - [ ] Update /prompt command
  - [ ] Test integration workflow

- [ ] Mark task 117 as superseded
  - [ ] Update task 117 status
  - [ ] Add reference to task 118

- [ ] Final validation
  > TEST: Success Criteria
  > Type: Acceptance Test
  > Assert: All behavioral requirements met
  > Command: ace-prompt && ace-prompt --task 117 && ace-prompt --ace-context --enhance

## Risk Analysis

### Technical Risks

**Symlink Compatibility**:
- Risk: Some filesystems don't support symlinks
- Mitigation: Graceful degradation with warnings

**Frontmatter Parsing**:
- Risk: Malformed YAML could crash process
- Mitigation: Rescue and continue without context

**LLM Enhancement Timeouts**:
- Risk: Slow or failed LLM calls
- Mitigation: Timeout configuration, fallback to raw

### Performance Risks

**Context Loading**:
- Risk: Large context files slow processing
- Mitigation: Streaming and size limits

**Enhancement Caching**:
- Risk: Cache grows unbounded
- Mitigation: Cache size limits or TTL

## Success Metrics

- Zero-argument command works immediately
- Archive mechanism never loses prompts
- Enhancement adds <2 seconds to workflow
- Context loading is transparent to user
- Configuration is simple and discoverable

## Preserved Assets from Cleanup

### Enhancement System Prompt

The following system prompt should be saved as `ace-prompt/handbook/prompts/enhance-system.md`:

```markdown
---
title: Prompt Enhancement System Prompt
description: System prompt for Haiku to enhance user prompts for clarity
---

You are an expert at refining and clarifying prompts for LLM interactions. Your task is to enhance the user's prompt to make it more clear, specific, and unambiguous while preserving the original intent.

## Instructions

1. **Preserve Intent**: Keep the original goal and requirements intact
2. **Add Clarity**: Make vague instructions specific and concrete
3. **Remove Ambiguity**: Clarify any unclear or ambiguous language
4. **Maintain Brevity**: Keep enhancements concise and focused
5. **Add Structure**: Organize complex prompts with clear sections

## Guidelines

- Break down complex requests into numbered steps
- Specify expected output formats explicitly
- Clarify any assumptions or constraints
- Add examples where helpful
- Remove redundancy and wordiness

## Format

Output only the enhanced prompt - no meta-commentary or explanations.

## Examples

**Before:**
"Make the code better"

**After:**
"Refactor the code to improve:
1. Readability: Add clear variable names and comments
2. Performance: Optimize repeated operations
3. Structure: Extract reusable functions
Maintain existing functionality and tests."

**Before:**
"Write tests"

**After:**
"Write unit tests covering:
1. Happy path: Valid inputs produce expected outputs
2. Edge cases: Boundary values and empty inputs
3. Error handling: Invalid inputs raise appropriate exceptions
Use the existing test framework and maintain >90% coverage."
```

### Lessons Learned from Task 117

**What went wrong:**
- Implemented complex prompt library with named prompts, protocols, discovery
- Added YAML frontmatter for metadata (not just context)
- Created multiple CLI commands instead of single default
- Built hierarchical search paths instead of single file
- Over-abstracted with preset merging and protocol resolution

**Root cause:**
- Interpreted "prompt management" as template library system
- Lost sight of original simple requirement from `.claude/commands/prompt.md`
- Common patterns bias led to over-engineering

**What was actually needed:**
- Simple queue workflow (like print queue)
- Single file (`the-prompt.md`) processing
- Automatic archiving with timestamps
- `_previous.md` symlink for history
- Optional enhancements, not complex features

### Configuration Specification

**Default Configuration** (embedded in gem):
```yaml
prompt:
  # File locations
  default_dir: .cache/ace-prompt/prompts
  default_file: the-prompt.md
  archive_subdir: archive  # Single archive for everything

  # Template using tmpl:// protocol
  template: tmpl://ace-prompt/base-prompt

  # Enhancement (optional, disabled by default)
  enhancement:
    enabled: false                # CLI flag overrides
    model: glite                  # Simple alias
    temperature: 0.3
    system_prompt: prompt://ace-prompt/base/enhance
    # No separate cache - uses main archive with _e001, _e002 suffixes

  # Context loading (fully delegated to ace-context)
  context:
    enabled: false                # CLI flag overrides
    # No merging - ace-context handles everything via --embed-source
```

**Model Aliases** (built-in):
- `glite` → `google:gemini-2.0-flash-lite`
- `claude` → `anthropic:claude-3.5-sonnet`
- `haiku` → `anthropic:claude-3-haiku`

### Enhancement Tracking Design

**Unified Archive Structure**:
```
.cache/ace-prompt/prompts/archive/
├── 20251119-143000.md           # Original prompt A
├── 20251119-143100_e001.md      # Enhancement 1 of A
├── 20251119-143200_e002.md      # Enhancement 2 of A
├── 20251119-150000.md           # New prompt B (no enhancement_of)
└── 20251119-150100_e001.md      # Enhancement 1 of B
```

**Enhancement Frontmatter**:
```yaml
---
enhancement_of: archive/20251119-143000.md
enhancement_iteration: 1
context_used: true  # If context was loaded
---
[Enhanced prompt content]
```

**Behavior**:
- First enhancement: Adds frontmatter, saves as `{timestamp}_e001.md`
- Subsequent enhancements: Increment `_e002.md`, `_e003.md`, etc.
- `_previous.md` always points to latest version (enhanced or original)
- `ace-prompt reset` clears enhancement tracking, starts fresh
- Single archive shows complete refinement history

### Context Delegation Pattern

**When context is requested**:
```bash
# ace-prompt detects frontmatter with context key
# Delegates entirely to ace-context:
ace-context --embed-source --stdin < the-prompt.md

# ace-context returns complete output
# No merging needed in ace-prompt
```

**Dependency**: Requires Task 119 (ace-context --embed-source flag)

**Protocol Registrations**:

`.ace/nav/protocols/prompt-sources/ace-prompt.yml`:
```yaml
source:
  name: ace-prompt
  gem: ace-prompt
  paths:
    - handbook/prompts
  categories:
    base:
      enhance: "Enhancement system prompt for clarity improvements"
```

`.ace/nav/protocols/tmpl-sources/ace-prompt.yml`:
```yaml
source:
  name: ace-prompt
  gem: ace-prompt
  paths:
    - handbook/templates
  templates:
    base-prompt: "Base template for new prompts with structure"
```

### Implementation Starting Points

**Gem Structure:**
```ruby
# ace-prompt.gemspec
Gem::Specification.new do |spec|
  spec.name = "ace-prompt"
  spec.version = "0.1.0"
  spec.summary = "Simple queue-based prompt workflow for AI development"
  spec.authors = ["ACE Framework"]
  spec.files = Dir["lib/**/*.rb", "exe/*", "handbook/**/*"]
  spec.executables = ["ace-prompt"]
  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "ace-support-core", "~> 0.10"
  spec.add_dependency "ace-context", "~> 0.5"
  spec.add_dependency "ace-llm", "~> 0.5"
end
```

**Executable:**
```ruby
#!/usr/bin/env ruby
# exe/ace-prompt
require_relative "../lib/ace/prompt"
Ace::Prompt::CLI.start(ARGV)
```

**Main Module:**
```ruby
# lib/ace/prompt.rb
require_relative "prompt/version"
require_relative "prompt/cli"

module Ace
  module Prompt
    # Simple queue-based prompt workflow
  end
end
```