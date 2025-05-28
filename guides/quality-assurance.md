# Quality Assurance Guidelines

## Goal

This guide outlines the processes, tools, and standards used to ensure the quality, reliability, and
maintainability of the codebase throughout the development lifecycle.

## 1. Code Quality Tools

1. **Static Analysis & Linting Setup**:
   Configure static analysis and linting tools appropriate for your project's language(s).
   - Configuration typically involves specifying language versions, enabling/disabling rules, setting formatting
     preferences, and defining paths to ignore.

   ```yaml
   # Example conceptual configuration (e.g., for a linter)
   language_version: "X.Y"
   fix_on_save: true
   parallel_processing: true
   output_format: "progress"

   ignore_paths:
     - 'bin/*'
     - 'vendor/**/*'
     - 'build/*'
     - 'tmp/*'

   rules:
     # Specific rule configuration...
     rule_name: enabled
   ```

2. **CI Integration**:
   Integrate static analysis, linting, and code coverage checks into the Continuous Integration
   (CI) pipeline (e.g., using GitHub Actions, GitLab CI, Jenkins).
   - Ensure these checks run automatically on pushes and pull requests.
   - Fail the build if quality checks do not pass.

   ```yaml
   # Example conceptual CI workflow snippet
   name: Quality Checks

   on: [push, pull_request]

   jobs:
     quality:
       runs-on: ubuntu-latest # Or your preferred runner
       steps:
         - uses: actions/checkout@vX # Use appropriate version

         # Add steps for setting up the environment (language, dependencies)
         # - name: Setup Language Environment
         #   uses: actions/setup-node@vX # Or setup-ruby, setup-python, etc.
         # - name: Install Dependencies
         #   run: your-package-manager install

         - name: Run Linter
           run: your-linter-command --options # e.g., 

         - name: Run Tests & Coverage
           run: your-test-runner-command --coverage # e.g., 

         # Optional: Upload coverage reports
         # - name: Upload Coverage Report
         #   uses: codecov/codecov-action@vX
   ```

### 2. Code Review Process

1. **Pull Request Template**:

   ```markdown
   ## Changes
   - List key changes
   - Impact on existing features

   ## Testing
   - [ ] Unit tests added
   - [ ] Integration tests updated
   - [ ] Test coverage maintained

   ## Quality
   - [ ] Follows coding standards
   - [ ] Documentation updated
   - [ ] No new security concerns
   ```

2. **Review Checklist**:

   ```markdown
   ### Design
   - [ ] Follows SDK patterns
   - [ ] Error handling complete
   - [ ] Thread safety considered

   ### Implementation
   - [ ] Clean code principles
   - [ ] No code smells
   - [ ] Efficient algorithms

   ### Testing
   - [ ] Test cases cover edge cases
   - [ ] Mocks used appropriately
   - [ ] Performance impacts tested
   ```

### 3. Test Coverage

1. **Coverage Configuration**:
   Configure your code coverage tool to:
   - Exclude test files, vendor directories, and other non-source code paths from the report.
   - Optionally group coverage results by logical components or modules.
   - Define minimum coverage thresholds (overall, per-file) to enforce standards. Failing to meet thresholds
     should ideally fail the build.

   ```javascript
   // Example conceptual coverage tool setup
   configureCoverageTool({
     exclude: [
       '/tests/',
       '/specs/',
       '/vendor/'
     ],
     groups: {
       'Core Logic': 'src/core',
       'Utilities': 'src/utils',
       'API Endpoints': 'src/api'
     },
     thresholds: {
       global: {
         statements: 90,
         branches: 85,
         functions: 90,
         lines: 90
       },
       perFile: {
         statements: 80,
         lines: 80
       }
     }
   });
   ```

2. **Coverage Goals**:
   - Core Components: 95%+ coverage
   - Tools & Extensions: 90%+ coverage
   - Integration Points: 85%+ coverage

3. **Coverage Report Example**:
   (Coverage reports typically show percentage of statements, branches, functions, and lines covered. The exact
   format varies by tool. File paths will reflect project structure.)

   ```text
   --------------------------|----------|----------|----------|----------|
   File                     |  % Stmts |% Branches|  % Funcs |  % Lines |
   --------------------------|----------|----------|----------|----------|
   All files                |    92.34 |    89.47 |    91.82 |    92.34 |
    lib/                    |    100.0 |    100.0 |    100.0 |    100.0 |
     aira.rb              |    100.0 |    100.0 |    100.0 |    100.0 |
    lib/aira/             |     91.8 |     88.4 |     90.9 |     91.8 |
     agent.rb              |     94.3 |     92.1 |     93.7 |     94.3 |
     tools.rb              |     89.2 |     84.7 |     88.1 |     89.2 |
   --------------------------|----------|----------|----------|----------|
   ```

### 4. Continuous Improvement

1. **Code Metrics**:
   Regularly measure code metrics to identify potential areas for refactoring or improvement.
   Use tools appropriate for your stack.
   - **Complexity:** Measure cyclomatic complexity or cognitive complexity using relevant analysis tools.
   - **Code Size:** Track lines of code (LOC) per module/component using code counting tools.
   - **TODO/FIXME Notes:** Use tools or scripts to track outstanding `TODO`, `FIXME`, or similar annotations in
     the codebase.

   ```bash
   # Example conceptual commands
   run-complexity-analyzer src/
   run-lines-of-code-counter src/
   find-todo-notes src/
   ```

2. **Quality Monitoring**:
   - Track code smells over time
   - Monitor test execution times
   - Review dependency updates

3. **Technical Debt**:

   ```markdown
   ## Technical Debt Log

   ### High Priority
   - [ ] Refactor tool registry for better concurrency
   - [ ] Improve error context in agent responses

   ### Medium Priority
   - [ ] Optimize memory usage in large operations
   - [ ] Enhance logging granularity
   ```

## Language/Environment-Specific Examples

For specific examples of tool configurations (e.g., linters, static analyzers, coverage tools), CI/CD
pipeline snippets, or code review checklist details relevant to particular languages or frameworks,
please refer to the examples in the [./quality-assurance/](./quality-assurance/) sub-directory.

## Related Documentation

- [Coding Standards](docs-dev/guides/coding-standards.md)
- [Testing Guidelines](docs-dev/guides/testing.md)
- [Version Control](docs-dev/guides/version-control.md) (PR Templates)
- [Security](docs-dev/guides/security.md)
