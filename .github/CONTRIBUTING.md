# Contributing to Coding Agent Tools

Thank you for your interest in contributing to Coding Agent Tools! This guide will help you get started with contributing to the project.

## 🚀 Quick Start

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/coding-agent-tools.git
   cd coding-agent-tools
   ```

2. **Set Up Development Environment**
   ```bash
   bin/setup
   ```

3. **Verify Setup**
   ```bash
   bin/test
   bin/lint
   ```

## 📋 Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 2. Make Your Changes

- Follow the [coding standards](#coding-standards)
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
bin/test

# Run linter
bin/lint

# Build gem to verify no issues
bin/build
```

### 4. Commit Your Changes

We use [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
# Use the commit message template
git config commit.template .gitmessage

# Make your commit
git commit
```

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation
- `style`: Code style/formatting
- `refactor`: Code improvements
- `test`: Testing
- `chore`: Maintenance

**Examples:**
```
feat(cli): add JSON output support for task commands
fix(agent): handle timeout errors gracefully
docs(readme): update installation instructions
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub using our [PR template](.github/pull_request_template.md).

## 🔧 Coding Standards

This project uses **StandardRB** for Ruby code formatting and linting.

### Running StandardRB

```bash
# Check for style violations
bin/lint

# Auto-fix violations (when possible)
bundle exec standardrb --fix
```

### Key Style Guidelines

- Use 2-space indentation
- Maximum line length: 120 characters
- Follow Ruby naming conventions:
  - `snake_case` for methods and variables
  - `SCREAMING_SNAKE_CASE` for constants
  - `CamelCase` for classes and modules
- Write descriptive method and variable names
- Add comments for complex logic
- Use meaningful commit messages

### Code Organization

The project follows an **ATOM-based hierarchy**:

```
lib/coding_agent_tools/
├── atoms/          # Smallest utility functions
├── molecules/      # Simple compositions of atoms
├── organisms/      # Complex business logic
├── ecosystems/     # Complete subsystems
├── models/         # Data structures (POROs)
└── cli/           # Command-line interface
```

## 🧪 Testing Guidelines

### Running Tests

```bash
# Run all tests
bin/test

# Run specific test file
bundle exec rspec spec/path/to/test_spec.rb

# Run with coverage report
COVERAGE=true bin/test
```

### Writing Tests

- Use RSpec for testing
- Follow the AAA pattern: Arrange, Act, Assert
- Write descriptive test names
- Test both happy path and edge cases
- Mock external dependencies
- Aim for high test coverage (target: 90%+)

**Example Test Structure:**
```ruby
RSpec.describe CodingAgentTools::SomeClass do
  describe "#some_method" do
    context "when given valid input" do
      it "returns expected result" do
        # Arrange
        instance = described_class.new
        
        # Act
        result = instance.some_method("valid_input")
        
        # Assert
        expect(result).to eq("expected_output")
      end
    end
    
    context "when given invalid input" do
      it "raises appropriate error" do
        instance = described_class.new
        
        expect { instance.some_method("invalid") }
          .to raise_error(ArgumentError, /expected message/)
      end
    end
  end
end
```

## 📚 Documentation

### What to Document

- New features and their usage
- API changes and breaking changes
- Configuration options
- Examples and code samples
- Architecture decisions

### Documentation Locations

- **README.md**: Main project overview and quick start
- **docs/**: User-facing documentation
- **docs-dev/**: Development and internal documentation
- **Code comments**: Complex logic and public APIs

## 🐛 Reporting Issues

When reporting bugs or requesting features:

1. **Search existing issues** first
2. **Use issue templates** when available
3. **Provide clear reproduction steps** for bugs
4. **Include relevant system information**:
   - Ruby version
   - Gem version
   - Operating system
   - Error messages and stack traces

### Bug Report Template

```markdown
**Description:**
Brief description of the issue

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Environment:**
- Ruby version:
- Gem version:
- OS:

**Additional Context:**
Any other relevant information
```

## 🔄 Release Process

Releases are managed by maintainers following semantic versioning:

- **Patch** (0.1.1): Bug fixes
- **Minor** (0.2.0): New features, backward compatible
- **Major** (1.0.0): Breaking changes

## 📞 Getting Help

- **Documentation**: Check [docs/](../docs/) and [docs-dev/guides/](../docs-dev/guides/)
- **Issues**: Search or create GitHub issues
- **Discussions**: Use GitHub Discussions for questions

## 🎯 Areas for Contribution

We welcome contributions in these areas:

### High Priority
- CLI command implementations
- LLM provider integrations
- Git workflow automation
- Test coverage improvements

### Medium Priority
- Documentation improvements
- Performance optimizations
- Error handling enhancements
- Code refactoring

### Good First Issues
Look for issues labeled `good first issue` or `help wanted`.

## 📝 Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow the Golden Rule

## 🏆 Recognition

Contributors are recognized in:
- CHANGELOG.md for significant contributions
- README.md contributors section
- Release notes for major features

## 🚫 What Not to Contribute

- Large architectural changes without prior discussion
- Features that don't align with project goals
- Code that doesn't follow our standards
- Breaking changes without migration path
- Proprietary or licensed code

---

Thank you for contributing to Coding Agent Tools! Your efforts help make this project better for everyone. 🎉