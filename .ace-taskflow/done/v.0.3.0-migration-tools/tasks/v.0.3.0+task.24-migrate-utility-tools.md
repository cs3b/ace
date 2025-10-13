---

id: v.0.3.0+task.24
status: blocked
priority: low
estimate: 6h
dependencies: [v.0.3.0+task.06]
---

# Migrate Remaining Utility Tools

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la .ace/tools/exe-old/{diff-list-modified-files.rb,fetch-github-pr-data.rb} 2>/dev/null | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/exe-old/diff-list-modified-files.rb
    .ace/tools/exe-old/fetch-github-pr-data.rb
```

## Objective

Migrate the remaining utility tools (diff-list-modified-files.rb and fetch-github-pr-data.rb) to the gem architecture, completing the tool migration effort.

## Scope of Work

* Analyze both utility tools
* Create appropriate organisms/molecules
* Implement CLI commands
* Support original functionality
* Update any dependent workflows

### Deliverables

#### Create

* lib/coding_agent_tools/organisms/utilities/diff_analyzer.rb
* lib/coding_agent_tools/organisms/utilities/github_pr_fetcher.rb
* lib/coding_agent_tools/cli/commands/project/diff_files.rb
* lib/coding_agent_tools/cli/commands/project/fetch_pr.rb
* Corresponding spec files

#### Modify

* lib/coding_agent_tools/cli.rb (register new commands)

#### Delete

* None

## Phases

1. Analyze utility tool requirements
2. Design organism structure
3. Implement diff analyzer
4. Implement GitHub PR fetcher
5. Create CLI commands

## Implementation Plan

### Planning Steps

* [ ] Analyze diff-list-modified-files.rb logic
  > TEST: Diff Tool Analysis
  > Type: Pre-condition Check
  > Assert: Tool logic understood
  > Command: wc -l .ace/tools/exe-old/diff-list-modified-files.rb
* [ ] Study fetch-github-pr-data.rb implementation
* [ ] Design organism interfaces

### Execution Steps

- [ ] Create utilities directory in organisms/
- [ ] Implement DiffAnalyzer organism
  > TEST: Diff Analyzer
  > Type: Unit Test
  > Assert: Analyzes diffs correctly
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/utilities/diff_analyzer_spec.rb
- [ ] Implement GitHubPRFetcher organism
- [ ] Add GitHub API integration
- [ ] Create CLI command for diff-files
- [ ] Create CLI command for fetch-pr
  > TEST: CLI Commands
  > Type: Integration Test
  > Assert: Commands are available
  > Command: cd .ace/tools && bundle exec exe/coding_agent_tools project --help | grep -E "diff-files|fetch-pr"
- [ ] Update any dependent workflows

## Acceptance Criteria

* [ ] Both utility tools migrated successfully
* [ ] Original functionality preserved
* [ ] GitHub API integration works
* [ ] CLI commands available
* [ ] Tests provide adequate coverage

## Out of Scope

* ❌ Adding new utility features
* ❌ Modifying tool behavior
* ❌ Creating binstubs (if not currently used)

## References

* Dependency: v.0.3.0+task.06 (molecules implementation)
* Source tools: .ace/tools/exe-old/diff-list-modified-files.rb
* Source tools: .ace/tools/exe-old/fetch-github-pr-data.rb
* Final tools from migration plan
