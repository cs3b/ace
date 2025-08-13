# Command Verification & Execution Agent

## Intention

Create a robust command verification and execution tool that validates prerequisites, handles errors intelligently, and provides detailed diagnostics for AI agents executing CLI commands.

## Problem It Solves

**Current Issues:**
- Commands fail without clear prerequisite checking
- No standardized error handling across tools
- Difficult to diagnose command execution failures
- Inconsistent execution environments

**Impact:**
- Unpredictable workflow failures
- Time-consuming debugging
- Reduced AI agent autonomy
- Poor error recovery

## Solution Direction

### 1. New Executable: `dev-tools/exe/command-verify`

```ruby
# dev-tools/exe/command-verify
module CodingAgentTools::CLI::Commands
  class CommandVerify < Dry::CLI::Command
    desc "Verify and execute commands with comprehensive checks"
    
    argument :command, required: true, desc: "Command to execute"
    option :check_prerequisites, type: :boolean, default: true
    option :sandbox, type: :boolean, desc: "Run in sandboxed environment"
    option :timeout, type: :integer, default: 120
    option :retry_count, type: :integer, default: 3
    option :verbose, type: :boolean, desc: "Detailed output"
  end
end
```

### 2. ATOM Architecture Components

**New Organism:**
```ruby
# dev-tools/lib/coding_agent_tools/organisms/command_verifier.rb
module CodingAgentTools::Organisms
  class CommandVerifier
    def initialize(prerequisites_checker:, executor:, diagnostics:)
      @prerequisites = prerequisites_checker
      @executor = executor
      @diagnostics = diagnostics
    end
    
    def verify_and_execute(command, options = {})
      # 1. Check prerequisites
      prereq_result = @prerequisites.check(command)
      return prereq_result unless prereq_result.success?
      
      # 2. Execute with monitoring
      execution_result = @executor.run_with_monitoring(command, options)
      
      # 3. Diagnose if failed
      if execution_result.failed?
        diagnosis = @diagnostics.analyze(command, execution_result)
        return enhanced_error(execution_result, diagnosis)
      end
      
      execution_result
    end
  end
end
```

**New Molecules:**
```ruby
# dev-tools/lib/coding_agent_tools/molecules/prerequisites_checker.rb
class PrerequisitesChecker
  COMMAND_PREREQUISITES = {
    'git' => { commands: ['git'], files: ['.git'] },
    'npm' => { commands: ['node', 'npm'], files: ['package.json'] },
    'bundle' => { commands: ['ruby', 'bundle'], files: ['Gemfile'] },
    'rspec' => { commands: ['rspec'], files: ['spec/'] }
  }
  
  def check(command)
    base_cmd = extract_base_command(command)
    prereqs = COMMAND_PREREQUISITES[base_cmd] || {}
    
    check_commands(prereqs[:commands])
    check_files(prereqs[:files])
    check_environment(base_cmd)
  end
end

# dev-tools/lib/coding_agent_tools/molecules/command_diagnostics.rb
class CommandDiagnostics
  def analyze(command, result)
    diagnosis = {
      exit_code: result.exit_code,
      stderr: result.stderr,
      suggestions: []
    }
    
    # Analyze common patterns
    case result.stderr
    when /command not found/
      diagnosis[:suggestions] << suggest_installation(command)
    when /permission denied/
      diagnosis[:suggestions] << suggest_permissions(command)
    when /no such file/
      diagnosis[:suggestions] << suggest_paths(command)
    end
    
    diagnosis
  end
end
```

### 3. Integration with Existing Tools

**Leverage existing components:**
- Use `SystemCommandExecutor` atom for execution
- Use `ErrorReporter` for standardized error output
- Integrate with `dry-monitor` for instrumentation
- Use existing `SecurePathValidator` for path checks

### 4. Workflow Integration

Update workflows to use verification:
```bash
# dev-handbook/workflow-instructions/fix-tests.wf.md

# Before: Direct execution
Bash bin/test

# After: Verified execution
command-verify "bin/test" --retry-count 2
```

## Implementation Plan

### Phase 1: Core Verifier (Day 1-2)
1. Create `command-verify` executable
2. Implement `CommandVerifier` organism
3. Add prerequisite checking logic

### Phase 2: Diagnostics (Day 3-4)
1. Implement `CommandDiagnostics` molecule
2. Add pattern-based analysis
3. Generate actionable suggestions

### Phase 3: Integration (Day 5)
1. Update existing workflows
2. Add comprehensive tests
3. Document usage patterns

## Expected Benefits

- **80% reduction** in unexplained failures
- **Automatic recovery** from common errors
- **Clear prerequisites** before execution
- **Actionable diagnostics** for failures

## Success Metrics

- Command success rate: 70% → 95%
- Mean time to diagnose: 10 min → 2 min
- Retry success rate: > 60%
- Prerequisites caught: > 90%

## Dependencies

- Existing `SystemCommandExecutor`
- `ErrorReporter` infrastructure
- dry-monitor instrumentation
- Shell command availability

## Testing Strategy

**Unit Tests:**
- Mock command execution
- Test prerequisite checking
- Verify diagnostic patterns

**Integration Tests:**
- Real command execution
- Error scenario testing
- Retry mechanism validation