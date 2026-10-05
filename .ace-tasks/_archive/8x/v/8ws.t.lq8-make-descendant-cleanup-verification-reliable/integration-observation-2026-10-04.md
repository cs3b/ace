# Integrated-wave timing observation

At integrated ACE c6087f583, default `bin/ace-test-suite` ran all51 packages:49 passed; ace-assign exceeded120s package timeout and ace-llm-providers-cli test_timeout_accepts_numeric_string failed its0.2s process-success assertion. Total10324 tests passed,2 failed,24skipped; duration120.24s. Do not report the aggregate green.

SafeCapture implementation and test are unchanged from b06d0aee9 (empty path-scoped git diff). Immediate focused source run `bin/ace-test ace-llm-providers-cli test/fast/molecules/safe_capture_test.rb` passed24tests/74assertions, zero failures/errors,4.14s, receipt8x3x8y. This is evidence of timing sensitivity, not a repaired issue; retain the existing test-reliability owner. No new code fix or gem release is attributed to this observation. Separate assign bounded follow-up is recorded in release evidence.
