# Development Workflow Guide

This guide covers the day-to-day development workflow for Coding Agent Tools, including how to use the existing build system tools and follow best practices.

## Overview

The Coding Agent Tools project follows a structured development workflow that emphasizes:
- **Test-Driven Development (TDD)**: Write tests first, then implement features
- **Continuous Integration**: Automated testing and linting on every commit
- **Conventional Commits**: Standardized commit message format
- **Code Quality**: StandardRB linting and comprehensive test coverage

## Quick Start for Contributors

```bash
# Clone and setup
git clone <repository-url>
cd coding-agent-tools
bin/setup

# Run tests and linting
bin/test && bin/lint

# Start developing
git checkout -b feature/your-feature
```

This quick start guide gets you up and running with the development environment. For detailed setup instructions, see the [Setup Guide](SETUP.md).

## Development Dependencies

### Core Development Tools

- **RSpec**: Testing framework for unit, integration, and feature tests
- **StandardRB**: Ruby code style and formatting enforcer
- **SimpleCov**: Code coverage analysis and reporting

### Testing & Quality Assurance

- **VCR**: HTTP interaction recording for testing external API integrations
- **WebMock**: HTTP request stubbing and mocking for isolated tests
- **Aruba**: CLI testing framework for command-line integration tests
- **FactoryBot**: Test data generation and fixture management
- **Pry**: Interactive debugging and REPL for development

### Development Support

- **Zeitwerk**: Code loading and autoloading for development environment
- **Bundler**: Dependency management and gem packaging
- **Rake**: Task automation and build system integration
- **YARD**: Documentation generation from code comments

### Optional Security Tools

- **Gitleaks** _(optional)_: Secrets detection for local development
  - Install: [https://github.com/gitleaks/gitleaks#installation](https://github.com/gitleaks/gitleaks#installation)
  - Usage: Automatically integrated with `bin/lint` when available
  - Fallback: `bin/lint` provides informative message if not installed
  - Purpose: Complements GitHub's native push protection with local scanning

For complete dependency information, see `coding_agent_tools.gemspec` and `Gemfile`.

## API Key Setup for Development

### Environment Configuration

For running tests that interact with real APIs or recording new VCR cassettes:

1. **Copy the example environment files**:
   ```bash
   cp .env.example .env
   cp spec/.env.example spec/.env
   ```

2. **Edit the `.env` files and add your actual API keys** (particularly `GEMINI_API_KEY`):
   ```bash
   # In .env file
   GEMINI_API_KEY="your_actual_gemini_api_key_here"

   # In spec/.env file (for testing)
   GEMINI_API_KEY="your_actual_gemini_api_key_here"
   VCR_RECORD=false  # Set to true when recording new cassettes
   ```

3. **When recording new VCR cassettes**, set `VCR_RECORD=true` in `spec/.env`

### Getting API Keys

- **Google Gemini API Key**: Get this from [Google AI Studio](https://makersuite.google.com/app/apikey)
- **GitHub Token** (if needed): Generate from [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)

## Daily Development Workflow

### 1. Start Working on a Feature

```bash
# Get the latest changes
git checkout main
git pull origin main

# Create a new feature branch
git checkout -b feature/your-feature-name
# or for bug fixes
git checkout -b fix/issue-description
```

### 2. Development Cycle

Follow this cycle for each feature or change:

#### A. Write Tests First (TDD)

```bash
# Create or update test files
# Location: spec/coding_agent_tools/...

# Run tests to see them fail (Red)
bin/test
```

#### B. Implement the Feature

```bash
# Write minimal code to make tests pass
# Location: lib/coding_agent_tools/...

# Run tests to see them pass (Green)
bin/test
```

#### C. Refactor and Clean Up

```bash
# Improve code quality without changing functionality
# Run linter to ensure code style
bin/lint

# Run tests to ensure nothing broke
bin/test
```

#### D. Verify Build

```bash
# Build the gem to ensure no packaging issues
bin/build
```

### 3. Commit Your Changes

```bash
# Review your changes
git status
git diff

# Stage related changes
git add path/to/changed/files

# Commit with conventional format
git commit
# This opens your editor with the .gitmessage template
```

### 4. Push and Create Pull Request

```bash
# Push your branch
git push origin feature/your-feature-name

# Create a pull request on GitHub
# Use the provided PR template
```

## Build System Commands

The project includes several `bin/` scripts for common development tasks:

### Core Development Commands

#### `bin/setup`
**Purpose**: Initial project setup and dependency installation
```bash
bin/setup
```
- Installs Ruby gem dependencies
- Sets up development environment
- Configures local settings
- Verifies installation

#### `bin/test`
**Purpose**: Run the complete test suite
```bash
# Run all tests
bin/test

# Run with progress format
bin/test --format progress

# Run with coverage report
COVERAGE=true bin/test

# Run specific test file
bundle exec rspec spec/path/to/specific_test.rb
```
- Executes RSpec test suite
- Shows test results and failures
- Generates coverage reports when requested
- Validates all functionality

#### `bin/lint`
**Purpose**: Check and fix code style using StandardRB
```bash
# Check for style violations
bin/lint

# Auto-fix violations (when possible)
bundle exec standardrb --fix
```
- Enforces Ruby style guide (StandardRB)
- Reports style violations
- Can automatically fix many issues
- Ensures consistent code formatting

#### `bin/build`
**Purpose**: Build the gem package and verify its local installation
```bash
bin/build
```
- Compiles the gem package
- Validates gemspec configuration
- Creates `.gem` file for distribution
- Verifies packaging integrity by attempting to install the gem locally in a temporary environment
- Provides enhanced build confidence by ensuring the gem can be correctly installed and used

#### `bin/console`
**Purpose**: Interactive development console
```bash
bin/console
```
- Starts IRB with gem loaded
- Allows interactive testing of classes
- Useful for debugging and exploration
- Access to all gem functionality

### Project Management Commands

#### `bin/tn` (Task Next)
**Purpose**: Get the next task to work on
```bash
bin/tn
```
- Shows the next pending task
- Displays task dependencies
- Helps prioritize development work

#### `bin/tal` (Task All List)
**Purpose**: List all available tasks
```bash
bin/tal
```
- Shows complete task backlog
- Displays task status and priorities
- Helps with project planning

### Git Workflow Commands

#### `bin/gc` (Git Commit)
**Purpose**: Enhanced git commit with AI-generated messages
```bash
bin/gc -i "intention of the changes"
```
- Generates descriptive commit messages
- Follows conventional commit format
- Integrates with project workflow

#### `bin/gl` (Git Log)
**Purpose**: Enhanced git log display
```bash
bin/gl
```
- Shows formatted commit history
- Provides better visualization
- Helps track project progress

#### `bin/cr` (Code Review Prompt Generator)
**Purpose**: Generates comprehensive code review prompts from git diff
```bash
# Generate a prompt for the current changes
bin/cr
```
- Wraps the `docs-dev/tools/generate-code-review-prompt` tool
- Useful for preparing context for AI-assisted or peer code reviews
- Analyzes current git diff to create structured review prompts

## Testing Strategy

### Test Organization

```
spec/
├── coding_agent_tools/
│   ├── atoms/          # Unit tests for atomic components
│   ├── molecules/      # Integration tests for molecules
│   ├── organisms/      # Feature tests for organisms
│   └── ecosystems/     # End-to-end tests for ecosystems
├── fixtures/           # Test data and mock files
└── support/           # Test helpers and configurations
```

### Test Types

#### Unit Tests (Atoms)
- Test individual methods and classes
- Fast execution
- Isolated from dependencies
- High coverage target (95%+)

```ruby
RSpec.describe CodingAgentTools::Atoms::FileUtils do
  describe "#read_safely" do
    it "returns file content when file exists" do
      # Test implementation
    end
  end
end
```

#### Integration Tests (Molecules)
- Test component interactions
- Moderate execution time
- Limited external dependencies
- Focus on interface contracts

```ruby
RSpec.describe CodingAgentTools::Molecules::GitOperations do
  describe "#commit_with_message" do
    it "creates commit with proper format" do
      # Test implementation
    end
  end
end
```

#### Feature Tests (Organisms)
- Test complete features
- Slower execution
- May include external calls
- Validate user-facing functionality

```ruby
RSpec.describe CodingAgentTools::Organisms::TaskManager do
  describe "#next_task" do
    it "returns highest priority pending task" do
      # Test implementation
    end
  end
end
```

#### End-to-End Tests (Ecosystems)
- Test complete workflows
- Slowest execution
- Full system integration
- Validate entire user journeys

```ruby
RSpec.describe "CLI Integration" do
  it "completes full task workflow" do
    # Test implementation
  end
end
```

#### Integration Tests with VCR
- Specifically for tests that interact with external APIs (e.g., Google Gemini, GitHub).
- Uses VCR to record and replay HTTP interactions, ensuring tests are fast, deterministic, and don't rely on live external services.
- When recording new cassettes, ensure `VCR_RECORD=true` is set in `spec/.env` and your API keys are configured.
- For detailed setup and usage, refer to the [VCR Testing Guide](docs/dev-guides/testing-with-vcr.md).

```ruby
# Example of a VCR-enabled test
RSpec.describe CodingAgentTools::Molecules::LLMApiClient do
  it "makes an API call and records/replays the response" do
    VCR.use_cassette("llm_response_example") do
      # Test implementation that triggers an external API call
      response = described_class.new.generate_text("test prompt")
      expect(response).to include("expected text")
    end
  end
end
```

#### VCR-Wrapped Localhost Testing Pattern
- **Best Practice for Localhost Services**: When testing integration with localhost services (e.g., LM Studio), use a dedicated VCR-wrapped availability check instead of direct Net::HTTP calls in test `before` blocks.
- **Why**: Direct Net::HTTP calls in test setup cause CI fragility since localhost services aren't available in CI environments.
- **Pattern**: Create a helper method that performs the availability check within a VCR cassette, allowing tests to run deterministically in both local and CI environments.

```ruby
# Example of VCR-wrapped localhost probe pattern
def lm_studio_available?
  VCR.use_cassette("lm_studio_availability_check") do
    begin
      response = Net::HTTP.get_response(URI("http://localhost:1234/v1/models"))
      response.code == "200"
    rescue StandardError
      false
    end
  end
end

# Usage in tests
RSpec.describe CodingAgentTools::Organisms::LMStudioClient do
  before do
    skip "LM Studio not available" unless lm_studio_available?
  end

  it "queries the local LM Studio service" do
    # Test implementation
  end
end
```
- For detailed localhost testing guidance, refer to [ADR-001-CI-Aware-VCR-Configuration](docs/architecture-decisions/ADR-001-CI-Aware-VCR-Configuration.md).

### Running Tests

```bash
# Run all tests
bin/test

# Run with progress format
bin/test --format progress

# Run tests with coverage
COVERAGE=true bin/test

# Run specific test categories
bundle exec rspec spec/coding_agent_tools/atoms/
bundle exec rspec spec/coding_agent_tools/molecules/

# Run tests matching pattern
bundle exec rspec --grep "TaskManager"

# Run failed tests only
bundle exec rspec --only-failures
```

## Code Quality Standards

### StandardRB Configuration

The project uses StandardRB for code formatting and style enforcement:

```yaml
# .standard.yml (if needed for customization)
ruby_version: 3.2
```

### Code Review Checklist

Before submitting code:

- [ ] All tests pass (`bin/test`)
- [ ] Code follows StandardRB style (`bin/lint`)
- [ ] New functionality has tests
- [ ] Documentation is updated
- [ ] Commit messages follow conventional format
- [ ] No hardcoded values or secrets
- [ ] Error handling is appropriate
- [ ] Performance impact considered

### Coverage Requirements

- **Minimum coverage**: 80%
- **Target coverage**: 90%+
- **Critical paths**: 100% coverage required

View coverage reports:
```bash
COVERAGE=true bin/test
open coverage/index.html
```

## Architecture Patterns

### ATOM Hierarchy

```ruby
# Atoms: Simple, pure functions
module CodingAgentTools::Atoms::StringUtils
  def self.snake_case(string)
    # Implementation
  end
end

# Molecules: Compositions of atoms
class CodingAgentTools::Molecules::FileProcessor
  include CodingAgentTools::Atoms::StringUtils

  def process_file(path)
    # Uses atoms to build functionality
  end
end

# Organisms: Business logic components
class CodingAgentTools::Organisms::ProjectManager
  def initialize(file_processor: Molecules::FileProcessor.new)
    @file_processor = file_processor
  end
end

# Ecosystems: Complete subsystems
class CodingAgentTools::Ecosystems::CLI
  def initialize
    @project_manager = Organisms::ProjectManager.new
  end
end
```

### Dependency Injection

Use dependency injection for testability:

```ruby
class SomeClass
  def initialize(dependency: DefaultDependency.new)
    @dependency = dependency
  end
end

# In tests
let(:mock_dependency) { double("dependency") }
let(:instance) { described_class.new(dependency: mock_dependency) }
```

### Zeitwerk Autoloading

The project utilizes Zeitwerk for efficient and performant code autoloading. This means classes and modules are automatically loaded when first referenced, without requiring explicit `require` statements for most of the application's own code.

- **Benefits**: Faster startup times, less boilerplate `require` statements, and a clearer representation of the codebase structure.
- **Convention**: Code is organized into directories matching the module/class hierarchy. For example, `lib/coding_agent_tools/atoms/string_utils.rb` defines `CodingAgentTools::Atoms::StringUtils`.
- **Development**: When adding new files or directories, ensure they follow Zeitwerk's naming conventions to be automatically picked up. Run `bin/console` to confirm autoloading works as expected for new components.

### Dry-Monitor Observability

`dry-monitor` is used to implement an event-based observability pattern. This allows for clear separation of concerns by dispatching events when significant actions occur within the application, which other components can subscribe to.

- **Benefits**: Decoupled components, easier debugging and logging, and the ability to extend functionality without modifying core logic.
- **Usage**: Components publish events (e.g., `monitor.publish(:task_completed, task_id: 123)`), and listeners subscribe to these events to perform actions like logging, metrics collection, or triggering subsequent processes.
- **Example**: Critical operations might publish events that `dry-monitor` listeners can pick up to log detailed information, or update internal state for monitoring dashboards.

## Debugging Workflow

### Using the Console

```bash
bin/console

# In the console:
> require 'pry'; binding.pry  # Set breakpoint
> CodingAgentTools::SomeClass.new.debug_method
```

### Adding Debug Output

```ruby
# Use structured logging
require 'logger'

logger = Logger.new(STDOUT)
logger.debug "Processing file: #{filename}"
logger.info "Operation completed successfully"
logger.error "Failed to process: #{error.message}"
```

### Running Single Tests

```bash
# Run specific test
bundle exec rspec spec/path/to/test_spec.rb:line_number

# Run with debugging
bundle exec rspec spec/path/to/test_spec.rb --pry
```

## Performance Considerations

### Benchmarking

```ruby
require 'benchmark'

Benchmark.bm do |x|
  x.report("method_a") { 1000.times { method_a } }
  x.report("method_b") { 1000.times { method_b } }
end
```

### Profiling

```ruby
require 'ruby-prof'

RubyProf.start
# Your code here
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
```

## Common Development Tasks

### Adding a New Feature

1. **Plan the feature**:
   - Define requirements and scope
   - Identify affected components
   - Plan test strategy

2. **Write tests first**:
   ```bash
   # Create test file
   touch spec/coding_agent_tools/path/to/new_feature_spec.rb

   # Write failing tests
   bin/test  # Should show failures
   ```

3. **Implement the feature**:
   ```bash
   # Create implementation file
   touch lib/coding_agent_tools/path/to/new_feature.rb

   # Implement minimal code
   bin/test  # Should pass
   ```

4. **Refactor and optimize**:
   ```bash
   bin/lint  # Check style
   bin/test  # Verify functionality
   ```

### Fixing a Bug

1. **Reproduce the bug**:
   ```bash
   # Write a failing test that demonstrates the bug
   bin/test  # Should fail
   ```

2. **Fix the issue**:
   ```bash
   # Make minimal changes to fix the bug
   bin/test  # Should pass
   ```

3. **Verify the fix**:
   ```bash
   bin/test  # All tests should pass
   bin/lint  # Code should be clean
   ```

### Updating Dependencies

```bash
# Update Gemfile.lock
bundle update

# Run tests to ensure compatibility
bin/test

# Check for security vulnerabilities
bundle audit
```

## Release Workflow

### Preparing for Release

1. **Update version**:
   ```ruby
   # lib/coding_agent_tools/version.rb
   VERSION = "0.2.0"
   ```

2. **Update changelog**:
   ```markdown
   # CHANGELOG.md
   ## [0.2.0] - 2024-01-15
   ### Added
   - New feature description
   ### Fixed
   - Bug fix description
   ```

3. **Final verification**:
   ```bash
   bin/test
   bin/lint
   bin/build
   ```

### Version Tagging

```bash
# Tag the release
git tag -a v0.2.0 -m "Release version 0.2.0"
git push origin v0.2.0
```

## Troubleshooting

### Common Issues

#### Tests Failing Unexpectedly
```bash
# Clear test cache
rm -rf spec/examples.txt

# Reinstall dependencies
bundle clean --force
bundle install

# Run tests again
bin/test
```

#### Linter Errors
```bash
# Auto-fix common issues
bundle exec standardrb --fix

# Check remaining issues
bin/lint
```

#### Build Failures
```bash
# Check gemspec validity
gem build coding_agent_tools.gemspec

# Verify dependencies
bundle check
```

## Best Practices Summary

1. **Always run tests before committing**: `bin/test`
2. **Keep commits small and focused**: One logical change per commit
3. **Write descriptive commit messages**: Follow conventional commits
4. **Update tests with code changes**: Maintain test coverage
5. **Use the build scripts**: Leverage `bin/` commands for consistency
6. **Review your own code first**: Check diff before pushing
7. **Ask for help when stuck**: Use GitHub issues or discussions

## Quick Reference

```bash
# Daily workflow commands
bin/setup     # Initial setup
bin/test      # Run tests
bin/lint      # Check style
bin/build     # Build gem
bin/console   # Interactive shell

# Git workflow
git checkout -b feature/name
# ... make changes ...
bin/test && bin/lint
git commit
git push origin feature/name

# Project management
bin/tn        # Next task
bin/tal       # All tasks
bin/gc -i "intention"  # AI commit
```

Happy coding! 🚀
