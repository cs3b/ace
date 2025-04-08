## Release Management Guidelines

### 1. Version Control

1. **Semantic Versioning**:
   ```ruby
   # lib/ruby_ai_agent/version.rb
   module RubyAIAgent
     VERSION = "1.2.3"  # MAJOR.MINOR.PATCH
     # MAJOR: Breaking changes
     # MINOR: New features, backwards compatible
     # PATCH: Bug fixes, backwards compatible
   end
   ```

2. **Git Flow Model**:
   ```bash
   # Feature development
   git checkout -b feature/new-tool develop
   git commit -m "feat: Add new browser tool"
   git push origin feature/new-tool

   # Release preparation
   git checkout -b release/1.2.0 develop
   git commit -m "chore: Bump version to 1.2.0"
   git tag -a v1.2.0 -m "Release version 1.2.0"
   ```

### 2. Release Process

1. **Pre-Release Checklist**:
   ```markdown
   ## Release 1.2.0 Checklist
   
   ### Code Quality
   - [ ] All tests passing
   - [ ] Code coverage >= 90%
   - [ ] StandardRB checks pass
   - [ ] Security audit complete
   
   ### Documentation
   - [ ] CHANGELOG.md updated
   - [ ] README.md reviewed
   - [ ] API documentation current
   - [ ] Examples updated
   
   ### Dependencies
   - [ ] Gemfile.lock reviewed
   - [ ] CI pipeline green
   - [ ] Compatibility tested
   ```

2. **Version Update**:
   ```ruby
   # Update version.rb
   VERSION = "1.2.0"
   
   # Update gemspec
   s.version = RubyAIAgent::VERSION
   
   # Update CHANGELOG.md
   ## [1.2.0] - 2024-01-20
   
   ### Added
   - New browser tool implementation
   - Enhanced error handling
   
   ### Fixed
   - Thread safety in tool registry
   - Memory leak in long-running tasks
   ```

3. **Release Commands**:
   ```bash
   # Build and verify gem
   gem build ruby_ai_agent.gemspec
   gem install ./ruby_ai_agent-1.2.0.gem
   
   # Run final tests
   bundle exec rake test
   
   # Push to RubyGems
   gem push ruby_ai_agent-1.2.0.gem
   
   # Create git tag
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

### 3. Post-Release

1. **Monitoring**:
   ```ruby
   # Example monitoring setup
   require 'appsignal'
   
   AppSignal.monitor_transaction(
     'gem.release',
     'v1.2.0',
     environment: ENV['RACK_ENV']
   )
   ```

2. **Communication**:
   ```markdown
   ## Release Announcement
   
   RubyAIAgent v1.2.0 is now available!
   
   ### Highlights
   - New browser tool
   - Improved performance
   - Better error handling
   
   ### Installation
   ```bash
   gem install ruby_ai_agent
   ```
   
   ### Documentation
   - [Release Notes](CHANGELOG.md)
   - [Migration Guide](docs/migrations/1.2.0.md)
   - [API Reference](https://rubydoc.info/gems/ruby_ai_agent)
   ```

3. **Issue Tracking**:
   ```markdown
   ## v1.2.0 Issue Template
   
   ### Environment
   - Ruby version:
   - RubyAIAgent version:
   - OS:
   
   ### Expected Behavior
   
   ### Actual Behavior
   
   ### Steps to Reproduce
   ```

### 4. Release Automation

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and test
        run: |
          bundle install
          bundle exec rake test
          
      - name: Build gem
        run: gem build *.gemspec
        
      - name: Push to RubyGems
        run: |
          mkdir -p $HOME/.gem
          echo -e "---\n:rubygems_api_key: ${RUBYGEMS_API_KEY}" > $HOME/.gem/credentials
          chmod 0600 $HOME/.gem/credentials
          gem push *.gem
        env:
          RUBYGEMS_API_KEY: ${{secrets.RUBYGEMS_API_KEY}}
```