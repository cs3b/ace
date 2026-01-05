# ace-review CLI Interface

## Current Implementation

- **Framework**: OptionParser (custom CLI class with subcommand)
- **Entry Point**: `ace-review/lib/ace/review/cli.rb`
- **Lines of Code**: 524
- **Migration Needed**: Yes

## Commands

### review (default)

Execute code review using presets or custom configuration.

**Usage**: `ace-review [options]`

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--preset NAME` | | string | Review preset from configuration |
| `--output-dir DIR` | | string | Custom output directory |
| `--output FILE` | | string | Specific output file path |
| `--context CONFIG` | | string | Context configuration (preset or YAML) |
| `--subject CONFIG` | | string | Subject configuration (repeatable, merged) |
| `--prompt-base MODULE` | | string | Base prompt module |
| `--prompt-format MODULE` | | string | Format module |
| `--prompt-focus MODULES` | | string | Focus modules (comma-separated) |
| `--add-focus MODULES` | | string | Add focus modules to preset |
| `--prompt-guidelines MODULES` | | string | Guideline modules (comma-separated) |
| `--model MODELS` | | string | LLM models (comma-separated or multiple flags) |
| `--no-synthesize` | | flag | Skip synthesis for multi-model |
| `--synthesis-model MODEL` | | string | Model for synthesis |
| `--dry-run` | | flag | Prepare without executing |
| `--verbose` | `-v` | flag | Verbose output |
| `--auto-execute` | | flag | Execute LLM query automatically |
| `--[no-]save-session` | | boolean | Save session files (default: true) |
| `--session-dir DIR` | | string | Custom session directory |
| `--task TASKREF` | | string | Save to task directory |
| `--no-auto-save` | | flag | Disable auto-save |
| `--pr IDENTIFIER` | | string | Review GitHub PR |
| `--[no-]pr-comments` | | boolean | Include PR comments |
| `--post-comment` | | flag | Post review as PR comment |
| `--gh-timeout SECONDS` | | integer | Timeout for gh CLI (default: 30) |
| `--list-presets` | | flag | List available presets |
| `--list-prompts` | | flag | List available prompt modules |
| `--help` | `-h` | flag | Show help |

### synthesize

Synthesize multiple review reports into consolidated report.

**Usage**: `ace-review synthesize [options]`

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--session DIR` | string | Session directory containing reports |
| `--reports FILES` | array | Explicit report files (comma-separated) |
| `--synthesis-model MODEL` | string | Model for synthesis |
| `--output FILE` | string | Output file path |
| `--verbose` | flag | Verbose output |

**Examples**:
```bash
ace-review --preset code-pr
ace-review --preset security --auto-execute
ace-review --pr 123 --auto-execute
ace-review --preset code --subject diff:HEAD~3 --subject files:docs/**/*.md
ace-review --preset code-pr --model "gemini,gpt-4" --auto-execute
ace-review synthesize --session .cache/ace-review/sessions/review-20251201/
ace-review --list-presets
```

## Multi-Subject Behavior

- Multiple `--subject` flags are accumulated and merged
- Same types concatenate (e.g., multiple files merge into array)
- Duplicates are removed

## Multi-Model Behavior

- Comma-separated or multiple `--model` flags
- Generates separate reports per model
- Optional synthesis with `--synthesis-model`

## Proposed Thor Migration

### Thor CLI Structure

```ruby
# lib/ace/review/cli.rb
class CLI < Thor
  desc "review", "Execute review using presets or custom configuration"
  option :preset, type: :string
  option :output_dir, type: :string
  option :output, type: :string
  option :context, type: :string
  option :subject, type: :array, desc: "Subject configs (repeatable)"
  option :prompt_base, type: :string
  option :prompt_format, type: :string
  option :prompt_focus, type: :string
  option :add_focus, type: :string
  option :prompt_guidelines, type: :string
  option :model, type: :array, desc: "LLM models"
  option :no_synthesize, type: :boolean
  option :synthesis_model, type: :string
  option :dry_run, type: :boolean
  option :verbose, type: :boolean, aliases: "-v"
  option :auto_execute, type: :boolean
  option :save_session, type: :boolean, default: true
  option :session_dir, type: :string
  option :task, type: :string
  option :no_auto_save, type: :boolean
  option :pr, type: :string
  option :pr_comments, type: :boolean, default: true
  option :post_comment, type: :boolean
  option :gh_timeout, type: :numeric
  option :quiet, type: :boolean, aliases: "-q"
  def review
    require_relative "commands/review_command"
    Commands::ReviewCommand.new(options).execute
  end
  default_task :review

  desc "synthesize", "Synthesize multiple review reports"
  option :session, type: :string, desc: "Session directory"
  option :reports, type: :array, desc: "Report files"
  option :synthesis_model, type: :string
  option :output, type: :string
  option :verbose, type: :boolean
  def synthesize
    require_relative "commands/synthesize_command"
    Commands::SynthesizeCommand.new(options).execute
  end

  desc "list_presets", "List available presets"
  def list_presets
    require_relative "commands/list_presets_command"
    Commands::ListPresetsCommand.new(options).execute
  end

  desc "list_prompts", "List available prompt modules"
  def list_prompts
    require_relative "commands/list_prompts_command"
    Commands::ListPromptsCommand.new(options).execute
  end
end
```

### Migration Notes

- Complex migration due to:
  - Subcommand (synthesize) handling
  - Repeatable options (--subject, --model)
  - Boolean options with defaults (--save-session, --pr-comments)
- Use Thor arrays for repeatable options
- Create separate commands for list operations
- Handle subject merging in ReviewCommand
- Add ConfigSummary integration
