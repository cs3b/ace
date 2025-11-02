# Config Discovery Architecture: Solving Directory-Independent Tool Execution

*January 2025 - Technical Reflection*

## The Problem We Set Out to Solve

The ace-test-suite was failing when executed from subdirectories within the project, even though other ace tools worked correctly. The immediate symptom was simple: `ace-test-suite` would work from the project root but fail with "Configuration file not found" when run from subdirectories like `ace-core/` or `ace-context/`.

This seemed like a straightforward path resolution issue at first glance.

## The Journey to Understanding

### Initial Hypothesis: Simple Path Resolution
Our first assumption was that this was merely a matter of the tool not finding the `.ace/test-suite.yml` file when run from a subdirectory. This led to an initial fix that added bundle context loading and basic config discovery to the ace-test-suite executable.

### The Deeper Issue: Architectural Inconsistency
However, as we dug deeper, we discovered the real issue wasn't just about finding the config file—it was about **where the logic for config discovery belonged** in our architecture. Each tool was implementing its own ad-hoc config loading, leading to:

1. **Duplication of Discovery Logic**: Multiple tools reimplementing file traversal and config loading
2. **Inconsistent Behavior**: Different tools handling path resolution differently
3. **Fragility**: Tools breaking when directory context changed
4. **Maintenance Burden**: Config loading logic scattered across the codebase

## The Architectural Insight

The breakthrough came when we realized that **config discovery and path resolution is a core infrastructure concern**, not a tool-specific implementation detail. This led to a fundamental design principle:

> **ace-core should be the single source of truth for configuration loading and path resolution across all ace tools.**

This insight drove us toward centralization rather than tool-by-tool fixes.

## The Solution Pattern: Centralized Config Infrastructure

### 1. Enhanced ConfigDiscovery Class
We built a comprehensive `Ace::Core::ConfigDiscovery` class that handles:
- **Hierarchical Config Discovery**: Finds config files by traversing up the directory tree
- **Config Merging**: Properly merges configurations from multiple sources in priority order
- **Intelligent Path Resolution**: Automatically resolves relative paths in configs relative to their containing file
- **Project-Aware Paths**: Resolves simple paths (like `ace-core`) relative to project root

### 2. Molecular Architecture
The implementation follows our ATOM architecture pattern:
- **Atoms**: `ProjectRootFinder`, `ConfigFinder`, `DirectoryTraverser` - single-purpose components
- **Molecules**: Combined functionality for specific discovery tasks
- **Organism**: `ConfigDiscovery` - high-level API orchestrating the molecules

### 3. Smart Path Resolution Logic
The path resolution algorithm implements sophisticated heuristics:

```ruby
def resolve_relative_paths(obj, base_dir, project_root = nil)
  case obj
  when String
    if obj.start_with?('./') || obj.start_with?('../')
      # Explicit relative paths resolve against config file directory
      File.expand_path(File.join(base_dir, obj))
    elsif project_root && looks_like_project_path?(obj)
      # Simple paths like "ace-core" resolve against project root
      File.join(project_root, obj)
    else
      obj
    end
  # ... handle nested structures
  end
end
```

This allows configs to use clean, readable paths like `ace-core` instead of brittle relative paths like `./ace-core` or `../ace-core`.

### 4. Tool Simplification
Tools now use a simple, high-level API:

```ruby
# Old approach: manual file loading and path juggling
config_path = find_config_file(options[:config])
raw_config = YAML.load_file(config_path)
# ... manual path resolution logic

# New approach: centralized discovery with automatic path resolution
config = Ace::Core::ConfigDiscovery.load("test-suite.yml")
```

## Design Decisions and Trade-offs

### 1. Centralization vs. Tool Independence
**Decision**: Centralize in ace-core despite creating a dependency.
**Rationale**: The benefits of consistency, maintainability, and robustness outweigh the cost of the dependency. All tools already depend on ace-core for other infrastructure.

### 2. Automatic vs. Explicit Path Resolution
**Decision**: Automatic resolution with intelligent heuristics.
**Rationale**: Reduces config verbosity and eliminates directory-dependent path issues. The heuristics are conservative—only paths that clearly look like project paths are auto-resolved.

### 3. API Design: Class Methods vs. Instance Methods
**Decision**: Provide both instance API and class method shortcuts.
**Rationale**: Class methods (`ConfigDiscovery.load()`) for simple cases, instance API for advanced use cases requiring custom start paths or multiple operations.

### 4. Error Handling Strategy
**Decision**: Fail gracefully with informative error messages.
**Rationale**: Config discovery is often the first point of failure users encounter. Clear error messages with suggested fixes improve the developer experience.

## Key Implementation Details

### The Config Search Cascade
1. Start from current directory (or specified start_path)
2. Traverse up the directory tree looking for `.ace/` directories
3. Check each `.ace/` directory for the requested config file
4. Include home directory (`~/.ace`) as fallback
5. Merge all found configs with proper precedence

### Path Resolution Algorithm
The system distinguishes between:
- **Explicit relative paths** (`./`, `../`): Resolved relative to config file location
- **Project paths** (`ace-core`, `lib/something`): Resolved relative to project root
- **Absolute paths** (`/`, `~/`, `http://`): Left unchanged
- **Special values**: Non-path strings left unchanged

### Project Root Detection
Uses multiple strategies:
1. Git repository root (`.git` directory)
2. Bundler project root (`Gemfile`)
3. Other project markers (extensible)

## Lessons Learned

### 1. Infrastructure Concerns Should Be Centralized Early
What started as a simple tool fix revealed the need for proper infrastructure. The lesson: **identify and centralize cross-cutting concerns before they proliferate across tools**.

### 2. Path Resolution Is More Complex Than It Appears
Simple relative path resolution isn't sufficient for developer tools. Users expect intuitive behavior:
- Config files should work regardless of execution directory
- Paths in configs should be readable and maintainable
- The system should "just work" without requiring deep path knowledge

### 3. Heuristics Can Simplify User Experience
The intelligent path detection (recognizing `ace-core` as a project path) eliminates the need for users to write fragile relative paths in configs. Conservative heuristics that err on the side of not transforming are safer than aggressive ones.

### 4. Testing Infrastructure Code Is Critical
Config discovery is foundational—bugs here affect all tools. Comprehensive testing with various directory structures, edge cases, and path types is essential.

### 5. Migration Strategy Matters
We maintained backward compatibility during the transition:
- Old config formats continued working
- Tools gracefully handled missing configs
- Clear error messages guided users to new patterns

## Impact and Future Considerations

### Immediate Benefits
- **Robust Execution**: All ace tools now work from any directory within a project
- **Simplified Tool Implementation**: Tools focus on their core logic rather than config plumbing
- **Consistent Behavior**: Uniform config loading across all tools
- **Better Error Messages**: Centralized error handling with actionable guidance

### Architectural Foundation
This implementation establishes patterns for other infrastructure concerns:
- **Logging**: Centralized logging configuration
- **Plugin Discovery**: Using similar traversal patterns for plugin loading
- **Environment Detection**: Project-aware environment configuration

### Future Enhancements
- **Config Validation**: Schema validation for config files
- **Dynamic Config**: Runtime config updates and reloading
- **Config Generation**: Tools to bootstrap standard config files
- **Plugin Integration**: Allowing plugins to extend config discovery

## Conclusion

What began as a simple directory execution issue revealed the need for foundational infrastructure. By centralizing config discovery in ace-core, we've created a robust, maintainable foundation that eliminates a whole class of directory-dependent execution issues.

The key insight—that config discovery is infrastructure, not tool-specific logic—will guide future architectural decisions. This pattern of identifying and centralizing cross-cutting concerns early should be applied to other aspects of the ace toolkit.

The implementation demonstrates that thoughtful infrastructure investment pays dividends in tool reliability, developer experience, and maintainability. The molecular architecture pattern also proved effective for complex, multi-step infrastructure components.

---

*This reflection documents the evolution from ad-hoc tool-specific config loading to centralized, robust config discovery infrastructure in the ace toolkit.*