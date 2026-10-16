# Test Report

**Generated:** 2026-10-16 20:40:24
**Status:** ❌ Failed
**Execution failure:** Test execution did not complete successfully

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 9 |
| Passed | 7 |
| Failed | 2 |
| Errors | 0 |
| Skipped | 0 |
| Pass Rate | 77.78% |
| Duration | 3.783889s |

## Failures

### 1. CommandExecutorKernelTest#test_incoming_ignored_sigchld_cannot_discard_original_child_status [test/feat/command_executor_kernel_test.rb:23]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:23`
- **Message:** {"message" => "No child processes", "backtrace" => ["/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:120:in 'Process.waitpid'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:120:in 'block in Ace::Lab::Organisms::CommandExecutor#launch'", "<internal:kernel>:168:in 'Kernel#loop'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:119:in 'Ace::Lab::Organisms::CommandExecutor#launch'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:42:in 'Ace::Lab::Organisms::CommandExecutor#run'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/test/support/command_executor_probe.rb:158:in 'block (2 levels) in <main>'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/test/support/command_executor_probe.rb:143:in 'Kernel#fork'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/test/support/command_executor_probe.rb:143:in 'block in <main>'"]}.
Expected "Errno::ECHILD" to be nil.

### 2. CommandExecutorKernelTest#test_incoming_custom_reaper_cannot_steal_original_child_status [test/feat/command_executor_kernel_test.rb:28]:

- **Type:** failure
- **Location:** `test/feat/command_executor_kernel_test.rb:28`
- **Message:** {"message" => "No child processes", "backtrace" => ["/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:120:in 'Process.waitpid'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:120:in 'block in Ace::Lab::Organisms::CommandExecutor#launch'", "<internal:kernel>:168:in 'Kernel#loop'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:119:in 'Ace::Lab::Organisms::CommandExecutor#launch'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/lib/ace/lab/organisms/command_executor.rb:42:in 'Ace::Lab::Organisms::CommandExecutor#run'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/test/support/command_executor_probe.rb:158:in 'block (2 levels) in <main>'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/test/support/command_executor_probe.rb:143:in 'Kernel#fork'", "/run/ei9-command-cleanup-r6-red/source/ace-lab/test/support/command_executor_probe.rb:143:in 'block in <main>'"]}.
Expected "Errno::ECHILD" to be nil.

9 runs, 73 assertions, 2 failures, 0 errors, 0 skips

## Files Tested

- test/feat/command_executor_kernel_test.rb
