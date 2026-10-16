# Test Report

**Generated:** 2026-10-16 20:20:59
**Status:** ❌ Failed
**Execution failure:** Test execution did not complete successfully

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 7 |
| Passed | 5 |
| Failed | 2 |
| Errors | 0 |
| Skipped | 0 |
| Pass Rate | 71.43% |
| Duration | 3.760978s |

## Failures

### 1. CommandExecutorKernelTest#test_owned_double_fork_setsid_descendant_is_killed_and_reaped_after_normal_exit [test/feat/command_executor_kernel_test.rb:25]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:25`
- **Message:** detached descendant outlived command cleanup

### 2. CommandExecutorKernelTest#test_owned_detached_descendant_is_killed_and_reaped_after_transport_loss [test/feat/command_executor_kernel_test.rb:31]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:31`
- **Message:** detached descendant outlived disconnected command

7 runs, 64 assertions, 2 failures, 0 errors, 0 skips

## Files Tested

- test/feat/command_executor_kernel_test.rb
