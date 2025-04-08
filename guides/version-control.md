## Version Control Guidelines

### 1. Commit Message Structure

```
<type>(<scope>): <subject>

<body>

<footer>
```

Example:
```git
feat(agent): Add browser tool support

Implement browser tool integration with the following features:
- Page navigation
- Element interaction
- Screenshot capture

Breaking: Tool API now requires explicit initialization
Closes #123
```

### 2. Commit Types

| Type     | Description                        | Example |
|----------|------------------------------------|---------|
| feat     | New features                       | `feat(tools): Add file manipulation support` |
| fix      | Bug fixes                          | `fix(agent): Handle nil responses` |
| docs     | Documentation                      | `docs(api): Update method descriptions` |
| style    | Code style/formatting              | `style: Apply StandardRB formatting` |
| refactor | Code improvements                  | `refactor(registry): Simplify tool lookup` |
| test     | Testing                           | `test(agent): Add thread safety specs` |
| chore    | Maintenance                        | `chore(deps): Update RSpec to 3.12` |

### 3. Commit Guidelines

1. **Subject Line**:
   ```git
   # Good
   feat(agent): Add support for concurrent tool execution
   
   # Bad
   Added some new features to make tools run faster
   ```

2. **Body Format**:
   ```git
   feat(registry): Implement thread-safe tool registration

   - Add mutex protection for registry operations
   - Implement atomic tool updates
   - Add specs for concurrent access
   
   This change ensures thread safety when multiple agents
   access the tool registry simultaneously.

   Breaking: Registry.register is now synchronized
   ```

3. **References**:
   ```git
   fix(agent): Handle LLM timeout errors

   - Add retry mechanism
   - Implement exponential backoff
   - Log failed attempts

   Fixes: #234
   Related: #235, #236
   ```

### 4. Branching Strategy

1. **Branch Types**:
   ```bash
   # Feature branches
   git checkout -b feature/browser-tool
   
   # Bug fixes
   git checkout -b fix/memory-leak
   
   # Documentation
   git checkout -b docs/api-reference
   ```

2. **Branch Flow**:
   ```bash
   # Start new feature
   git checkout -b feature/new-tool develop
   
   # Regular commits
   git commit -m "feat(tool): Add basic implementation"
   git commit -m "test(tool): Add integration specs"
   
   # Prepare for PR
   git fetch origin
   git rebase origin/develop
   
   # Push for review
   git push origin feature/new-tool
   ```

### 5. Pull Request Template

```markdown
## Changes
- Implemented new browser tool
- Added thread safety measures
- Updated documentation

## Testing
- [ ] Unit tests added
- [ ] Integration tests updated
- [ ] Thread safety verified

## Documentation
- [ ] API docs updated
- [ ] Examples added
- [ ] CHANGELOG updated

## Breaking Changes
- Tool initialization now requires explicit configuration
```

### 6. Git Hooks

1. **Pre-commit Hook**:
   ```bash
   #!/bin/sh
   
   # Run tests
   bundle exec rspec
   
   # Check style
   bundle exec standardrb
   
   # Verify docs
   bundle exec yard doc --fail-on-warning
   ```

2. **Commit-msg Hook**:
   ```bash
   #!/bin/sh
   
   # Verify conventional commit format
   if ! grep -qE '^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+$' "$1"; then
     echo "Invalid commit message format"
     exit 1
   fi
   ```

### 7. Practical Commit Workflow

1. **Pre-Commit Review**:
   ```bash
   # Review changes
   git status
   git diff
   
   # Run validations
   bundle exec rspec
   bundle exec standardrb
   ```

2. **Stage Changes**:
   ```bash
   # Stage logically related changes
   git add lib/ruby_ai_agent/agent.rb
   git add spec/ruby_ai_agent/agent_spec.rb
   git add docs-dev/guides/agent.md
   
   # Review staged changes
   git diff --staged
   ```

3. **Create Commit**:
   ```bash
   # Use conventional commit format
   git commit
   ```

4. **Post-Commit Steps**:
   - Push changes: `git push origin <branch>`
   - Update project board
   - Open pull request if ready

Common file groupings:
- Core: `lib/ruby_ai_agent/*.rb`
- Tests: `spec/**/*_spec.rb` 
- Docs: `docs-dev/**/*.md`
- Project: `*.gemspec`, `Gemfile`, etc.
### 7. Best Practices

1. **Atomic Commits**:
   - One logical change per commit
   - Group related changes
   - Separate refactoring from features

2. **History Management**:
   - Rebase feature branches regularly
   - Squash fixup commits
   - Write clear commit messages

3. **Code Review**:
   - Review your own changes first
   - Respond to feedback promptly
   - Keep discussions focused

4. **Documentation**:
   - Update docs with code changes
   - Include example updates
   - Keep CHANGELOG current