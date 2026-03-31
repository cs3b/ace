# DEVELOPMENT.md

Development setup requirements for the Coding Agent Workflow Toolkit (Meta).

## Ruby Environment

- **Ruby versions**: 3.2, 3.3, or 3.4
- **Bundler**: Install with `gem install bundler`
- **Dependencies**: Run `bundle install` in repository root

## New Project Onboarding Contract

When validating onboarding docs or reproducing plain-project setup, use this exact full-stack path:

1. Add gems:

```bash
bundle add --group "development, test" \
  ace-idea ace-task ace-sim \
  ace-overseer ace-assign ace-git-worktree ace-tmux \
  ace-bundle ace-handbook ace-search ace-docs \
  ace-review ace-lint ace-test-runner ace-test-runner-e2e ace-retro ace-demo \
  ace-git-commit ace-git-secrets ace-git \
  ace-handbook-integration-claude ace-handbook-integration-codex
# Also available: ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi
```

Dependencies like `ace-llm`, `ace-git`, `ace-tmux`, and all `ace-support-*` gems are pulled in automatically.

2. Install and initialize:

```bash
bundle install
ace-framework init
ace-handbook sync
```

3. Verify first-use commands:

```bash
ace-llm --list-providers
ace-bundle project
```

If install fails immediately after a large release, apply temporary RubyGems propagation mitigation:

```bash
bundle install --full-index
```

## Core Dependencies

These tools are required for full test suite functionality:

### gitleaks
- **Purpose**: Secret scanning (ace-git-secrets)
- **Installation**:
  - macOS: `brew install gitleaks`
  - Linux: `brew install gitleaks` or download from [releases](https://github.com/gitleaks/gitleaks/releases)

### git-filter-repo
- **Purpose**: Git history rewriting (ace-git-secrets)
- **Installation**:
  - macOS: `brew install git-filter-repo`
  - Linux: `apt install git-filter-repo` or `pip install git-filter-repo`

### ripgrep (rg)
- **Purpose**: Fast code search (ace-search)
- **Installation**:
  - macOS: `brew install ripgrep`
  - Linux: `apt install ripgrep`

### fd
- **Purpose**: Fast file discovery (ace-search)
- **Installation**:
  - macOS: `brew install fd`
  - Linux: `apt install fd-find`

## Optional Dependencies

These tools enhance functionality but aren't required:

### fzf
- **Purpose**: Interactive fuzzy search (ace-search)
- **Installation**:
  - macOS: `brew install fzf`
  - Linux: `apt install fzf`

### claude CLI
- **Purpose**: Anthropic Claude LLM access (ace-llm-providers-cli)
- **Installation**: Follow [Anthropic CLI docs](https://github.com/anthropics/claude-code)

### rubocop/standard
- **Purpose**: Code linting (ace-lint)
- **Installation**: Included in bundle dependencies

### Additional LLM CLIs
- **codex**: OpenAI Codex access
- **gemini**: Google Gemini access
- **opencode**: OpenAI access
- **pi**: Inflection Pi access

## Platform-Specific Notes

### macOS
- **Clipboard support**: ace-support-mac-clipboard uses FFI for NSPasteboard access
- All tests should pass with required dependencies installed

### Linux
- **Clipboard tests**: ace-support-mac-clipboard tests automatically skip on Linux
- Use `fd-find` command instead of `fd` on some distributions

## Verification

Run the full test suite to verify your setup:

```bash
ace-test-suite
```

Individual package tests:

```bash
ace-test
```

## Next Steps

For detailed contribution workflows, code standards, and taskflow processes, see:

- [docs/contributing/README.md](docs/contributing/README.md)
- Project context: `ace-bundle project`
- Available tools: [docs/tools.md](docs/tools.md)
