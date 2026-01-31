---
name: test-mocking-patterns
description: Advanced mocking patterns for fast-loop tests
doc-type: guide
purpose: Mocking discipline and performance
search_keywords:
  - mocking patterns
  - zombie mocks
  - stub boundary
  - contract tests
  - composite helpers
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Mocking Patterns (Advanced)

## Stub the Outer Boundary

If a guard method runs before the stubbed call, the test still performs IO. Stub the outermost method that can trigger IO (e.g., `available?`).

```ruby
Runner.stub(:available?, true) do
  Open3.stub(:capture3, mock_result) do
    result = Runner.run("file.rb")
    assert result.success?
  end
end
```

## Zombie Mocks

A zombie mock stubs a method the code no longer calls. Tests pass but get slow because the real path runs.

**Detection**: profile tests; any unit test >100ms is suspect.
**Fix**: confirm the current code path and update stubs to match.

## Contract Tests for External APIs

Mocks are only useful if they match the real API. Prefer:
- Snapshot from real API responses
- Schema validation against OpenAPI
- Periodic drift checks

## Composite Helpers

Reduce nested stubs by creating a single helper that covers a full context.

```ruby
def with_mock_repo_load(branch: "main", task_id: "123")
  stub_repo(branch: branch)
  stub_task(task_id: task_id)
  yield
end
```

## Behavior over Interaction

Use stubs to provide data; assert outputs, not calls. Only verify interaction when the interaction is the requirement.
