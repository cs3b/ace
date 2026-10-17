# Test Report

**Generated:** 2026-10-16 20:21:33
**Status:** ❌ Failed
**Execution failure:** Test execution did not complete successfully

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 7 |
| Passed | 1 |
| Failed | 6 |
| Errors | 0 |
| Skipped | 0 |
| Pass Rate | 14.29% |
| Duration | 1.661847s |

## Failures

### 1. CommandExecutorKernelTest#test_owned_double_fork_setsid_descendant_is_killed_and_reaped_after_normal_exit [test/feat/command_executor_kernel_test.rb:14]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:14`
- **Message:** 

### 2. CommandExecutorKernelTest#test_lost_bind_and_claim_replay_never_execute [test/feat/command_executor_kernel_test.rb:56]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:56`
- **Message:** Expected: "SecurityError"
  Actual: "NoMethodError"
- **Fix:** Check the assertion values. Expected and actual don't match.

### 3. CommandExecutorKernelTest#test_real_identity_pipes_eof_and_nonzero [test/feat/command_executor_kernel_test.rb:42]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:42`
- **Message:** Expected "NoMethodError" to be nil.

### 4. CommandExecutorKernelTest#test_real_pty_and_signal [test/feat/command_executor_kernel_test.rb:66]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:66`
- **Message:** Expected "NoMethodError" to be nil.

### 5. CommandExecutorKernelTest#test_getpass_no_echo_and_exact_resize [test/feat/command_executor_kernel_test.rb:72]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:72`
- **Message:** Expected "NoMethodError" to be nil.

### 6. CommandExecutorKernelTest#test_owned_detached_descendant_is_killed_and_reaped_after_transport_loss [test/feat/command_executor_kernel_test.rb:14]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:14`
- **Message:** 

## Files Tested

- test/feat/command_executor_kernel_test.rb
