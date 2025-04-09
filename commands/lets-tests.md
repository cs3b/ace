# Let's Test Command

For writing missing tests. See [Testing Guide](../guides/testing.md) for details.

## Process Steps

1. Review Coverage:
   ```bash
   bin/rspec
   ```
   Create tasks in docs-dev/1-next/ for any missing tests from coverage/index.html

2. Write Tests:
   - For each task, identify:
     - Required inputs/outputs
     - Edge cases
     - Error scenarios
   - Implement tests following patterns in spec/

3. Verify Tests:
   - Run reliably
   - Cover edge cases
   - Match requirements

## Success Criteria

- All tests pass
- Coverage targets met
- Clear test names
