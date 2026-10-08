# Protected service request/status source checkpoint

## Held input prerequisite

The existing Lab ServiceInput owner now uses one no-follow, nonblocking read handle, verifies regular-file type and its 64KiB bound before reading, and verifies unchanged handle/path metadata after the bounded read. Strict depth16 JSON refuses decoded duplicate keys, comments, additions and nonfinite values. This is caller input validation, not root-owned deployment artifact authentication.

Executed inspected controlled selection: `../bin/ace-test test/atoms/service_input_test.rb --timeout 30` from ace-lab, receipt `0c100ebd-b279-4bee-9fe9-bce86075129d`: PASS 4 tests / 14 assertions, raw seed2538, no skips. Tests cover valid bytes, symlink/directory/size refusal, decoded duplicate collision, comments/nonfinite/depth, and path replacement during the held read. No installed/native/kernel/provider probes were executed.

This prerequisite does not deliver registered protected request/status routing, asynchronous listener composition, canonical replay/recovery or required negative gates. Those remain the next source slice. Independent source review remains required before integration.
