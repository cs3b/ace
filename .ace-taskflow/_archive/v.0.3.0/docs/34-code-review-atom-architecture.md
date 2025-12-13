# Code Review Module - ATOM Architecture Design

## Overview

This document outlines the ATOM (Atoms, Molecules, Organisms) architecture design for the code review module, following established patterns from the taskflow_management implementation.

## Component Hierarchy and Data Flow

### Data Flow Pattern

```
CLI Commands (code-review, code-review-prepare)
     ↓
Organisms (ReviewManager orchestrates the workflow)
     ↓
Molecules (SessionDirectoryBuilder, GitDiffExtractor, etc.)
     ↓
Atoms (SessionTimestampGenerator, GitCommandExecutor, etc.)
     ↓
Models (ReviewSession, ReviewTarget, ReviewContext, ReviewPrompt)
```

### Bash Module Integration

The Ruby components will interact with bash modules for shell logic:

```
Ruby Atoms/Molecules
     ↓
ExecutableWrapper / ShellCommandExecutor
     ↓
Bash Module Loader (lib/bash/module-loader.sh)
     ↓
Bash Modules (session-management.sh, content-extraction.sh, context-loading.sh)
```

## Component Definitions

### Models (Data Structures)

#### ReviewSession
```ruby
module CodingAgentTools
  module Models
    module Code
      ReviewSession = Struct.new(
        :session_id,
        :session_name,
        :timestamp,
        :directory_path,
        :focus,           # 'code', 'tests', 'docs', or combination
        :target,          # git range, file pattern, or special keyword
        :context_mode,    # 'auto', 'none', or custom path
        :metadata,
        keyword_init: true
      )
    end
  end
end
```

#### ReviewTarget
```ruby
ReviewTarget = Struct.new(
  :type,            # 'git_diff', 'file_pattern', 'single_file'
  :target_spec,     # original target string
  :resolved_paths,  # array of resolved file paths
  :content_type,    # 'diff' or 'xml'
  :size_info,       # lines, words, file count
  keyword_init: true
)
```

#### ReviewContext
```ruby
ReviewContext = Struct.new(
  :mode,            # 'auto', 'none', 'custom'
  :documents,       # array of {type, path, content}
  :loaded_at,
  keyword_init: true
)
```

#### ReviewPrompt
```ruby
ReviewPrompt = Struct.new(
  :session_id,
  :focus_areas,     # array of focus areas
  :system_prompt_path,
  :combined_content,
  :metadata,
  keyword_init: true
)
```

### Atoms (Basic Operations)

#### SessionTimestampGenerator
- **Purpose**: Generate timestamp strings for session naming
- **Methods**: `generate()` → "20240106-143052"
- **Dependencies**: None

#### SessionNameBuilder
- **Purpose**: Build session directory names from components
- **Methods**: `build(focus, target, timestamp)` → "code-HEAD~1..HEAD-20240106-143052"
- **Dependencies**: None

#### GitCommandExecutor
- **Purpose**: Execute git commands and return output
- **Methods**: `execute(command, args)` → {output, success, error}
- **Dependencies**: ShellCommandExecutor atom

#### FileContentReader
- **Purpose**: Read file contents with error handling
- **Methods**: `read(path)` → {content, success, error}
- **Dependencies**: None

#### DirectoryCreator
- **Purpose**: Create directories with proper permissions
- **Methods**: `create(path)` → {success, error}
- **Dependencies**: None

### Molecules (Composed Operations)

#### SessionDirectoryBuilder
- **Purpose**: Create and structure session directories
- **Composition**: DirectoryCreator, SessionTimestampGenerator, SessionNameBuilder
- **Methods**: `build_session_directory(focus, target, base_path)`
- **Returns**: ReviewSession model

#### GitDiffExtractor
- **Purpose**: Extract git diffs for various target types
- **Composition**: GitCommandExecutor, FileContentReader
- **Methods**: `extract_diff(target_spec)` → {content, metadata}
- **Handles**: commit ranges, staged/unstaged/working changes

#### FilePatternExtractor
- **Purpose**: Extract file contents matching patterns
- **Composition**: FileSystemScanner, FileContentReader
- **Methods**: `extract_files(pattern)` → {xml_content, file_list}
- **Returns**: XML-formatted content with CDATA sections

#### ProjectContextLoader
- **Purpose**: Load project context based on mode
- **Composition**: FileContentReader, YamlFrontmatterParser
- **Methods**: `load_context(mode, custom_path)` → ReviewContext
- **Handles**: auto/none/custom modes

#### PromptCombiner
- **Purpose**: Combine all elements into final prompt
- **Composition**: FileContentReader, YamlFrontmatterParser
- **Methods**: `build_prompt(session, target_content, context, focus)`
- **Returns**: ReviewPrompt model

### Organisms (Business Logic)

#### ReviewManager
- **Purpose**: Main orchestrator for code review workflow
- **Composition**: All molecules, integration with LLM organisms
- **Methods**: 
  - `create_review_session(focus, target, context)`
  - `execute_review(session)`
  - `finalize_session(session)`

#### SessionManager
- **Purpose**: Manage review session lifecycle
- **Composition**: SessionDirectoryBuilder, FileIOHandler
- **Methods**:
  - `create_session(params)`
  - `load_session(session_id)`
  - `list_sessions()`

#### ContentExtractor
- **Purpose**: Extract and format review content
- **Composition**: GitDiffExtractor, FilePatternExtractor
- **Methods**:
  - `extract_content(target)` → ReviewTarget
  - `save_content(target, session_dir)`

#### ContextLoader
- **Purpose**: Load and prepare project context
- **Composition**: ProjectContextLoader, FileIOHandler
- **Methods**:
  - `load_context(mode, session)` → ReviewContext
  - `save_context(context, session_dir)`

#### PromptBuilder
- **Purpose**: Build complete review prompts
- **Composition**: PromptCombiner, all extractors
- **Methods**:
  - `build_review_prompt(session, target, context)`
  - `select_system_prompt(focus)`

### CLI Commands

#### Code::Review
- **Purpose**: Main review command
- **Usage**: `code-review --focus code --target HEAD~1..HEAD`
- **Delegates to**: ReviewManager organism

#### Code::ReviewPrepare
- **Purpose**: Preparation sub-commands
- **Sub-commands**:
  - `session-dir` - Create session directory
  - `project-context` - Extract project context
  - `project-target` - Extract target content
  - `prompt` - Build combined prompt

### Bash Modules

#### module-loader.sh
```bash
#!/bin/bash
# Module loader for bash modules

BASH_MODULES_DIR="${BASH_MODULES_DIR:-$(dirname "$0")/modules}"

load_module() {
  local category="$1"
  local module_name="$2"
  local module_path="${BASH_MODULES_DIR}/${category}/${module_name}.sh"
  
  if [[ -f "$module_path" ]]; then
    source "$module_path"
    return 0
  else
    echo "Error: Module not found: $module_path" >&2
    return 1
  fi
}
```

#### session-management.sh
- Functions extracted from lines 78-95 of review-code.wf.md
- `create_session_directory()`
- `generate_session_name()`
- `write_session_metadata()`

#### content-extraction.sh
- Functions extracted from lines 134-200 of review-code.wf.md
- `extract_git_diff()`
- `extract_file_pattern()`
- `create_xml_container()`

#### context-loading.sh
- Functions for loading project context
- `load_project_context()`
- `load_custom_context()`
- `skip_context_loading()`

## Integration Points

### With Existing Components

1. **LLM Integration**: ReviewManager will use existing LLM client organisms
2. **File Operations**: Use existing FileIOHandler with security components
3. **Shell Execution**: Use existing ShellCommandExecutor atom
4. **Path Validation**: Use existing SecurePathValidator molecule

### Module Autoloading

Update autoloader files:
- `lib/coding_agent_tools/atoms.rb` - Add `code` module
- `lib/coding_agent_tools/molecules.rb` - Add `code` module
- `lib/coding_agent_tools/organisms.rb` - Add `code` module
- `lib/coding_agent_tools/models.rb` - Add `code` module
- `lib/coding_agent_tools/cli.rb` - Register code commands

## Implementation Order

1. **Phase 1**: Models and Bash Modules
   - Create all Model structs
   - Create bash module-loader.sh
   - Extract bash functions into modules

2. **Phase 2**: Atoms
   - Implement basic atoms
   - Test individually

3. **Phase 3**: Molecules
   - Implement molecules using atoms
   - Test compositions

4. **Phase 4**: Organisms
   - Implement business logic organisms
   - Integrate with existing components

5. **Phase 5**: CLI and Executables
   - Create CLI command classes
   - Create executables
   - Register in autoloaders

6. **Phase 6**: Integration Testing
   - End-to-end workflow testing
   - Bash module integration testing