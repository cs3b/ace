---
id: v.0.6.0+task.008
status: pending
priority: low
estimate: 2h
dependencies: [v.0.6.0+task.005, v.0.6.0+task.006, v.0.6.0+task.007]
---

# Package and Release v0.6.0

## Objective

Package the migrated codebase as v0.6.0 release, publish the new `ace-tools` gem, and communicate the changes to users.

## Scope of Work

- Build and test gem package
- Publish to RubyGems
- Create GitHub release
- Update version numbers
- Communicate changes

### Deliverables

#### Create

- `ace-tools-0.6.0.gem` - Built gem package
- GitHub release with notes
- Release announcement

#### Modify

- `.ace/tools/lib/ace_tools/version.rb` - Update version to 0.6.0
- `CHANGELOG.md` - Finalize release notes

#### Delete

- None

## Implementation Plan

### Planning Steps

* [ ] Verify all previous tasks completed
* [ ] Check RubyGems account access
* [ ] Prepare release announcement

### Execution Steps

- [ ] Update version number:
  ```ruby
  # lib/ace_tools/version.rb
  module AceTools
    VERSION = "0.6.0"
  end
  ```
  > TEST: Version Check
  > Type: Ruby Test
  > Assert: Version constant is correct
  > Command: ruby -e "require '.ace/tools/lib/ace_tools/version'; puts AceTools::VERSION"

- [ ] Build gem package:
  ```bash
  cd .ace/tools
  gem build ace_tools.gemspec
  ```
  > TEST: Gem Build
  > Type: Build Test
  > Assert: Gem builds without warnings
  > Command: cd .ace/tools && gem build ace_tools.gemspec

- [ ] Test local installation:
  ```bash
  gem install ./ace-tools-0.6.0.gem --local
  ace-tools --version
  ```
  > TEST: Local Install
  > Type: Installation Test
  > Assert: Gem installs and runs
  > Command: gem install ./ace-tools-*.gem --local && ace-tools --version

- [ ] Publish to RubyGems:
  ```bash
  gem push ace-tools-0.6.0.gem
  ```
  Note: Requires RubyGems.org credentials

- [ ] Create GitHub release:
  - Tag: v0.6.0
  - Title: "v0.6.0 - ACE Migration"
  - Release notes from CHANGELOG.md
  - Attach gem file
  - Mark as latest release

- [ ] Update documentation sites:
  - Update any external documentation
  - Update gem badges in README
  - Ensure docs reflect new gem name

- [ ] Communicate release:
  - Post in project discussions
  - Update any integration documentation
  - Notify users of breaking changes

## Acceptance Criteria

- [ ] Gem published to RubyGems.org
- [ ] GitHub release created with notes
- [ ] Version number correctly updated
- [ ] Installation works from RubyGems
- [ ] Documentation updated

## Out of Scope

- ❌ Marketing campaigns
- ❌ Conference announcements
- ❌ Paid advertising