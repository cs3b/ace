# Test Report

**Generated:** 2026-10-16 21:29:50
**Status:** ❌ Failed
**Execution failure:** /Users/mc/Ps/ace/.ace-wt/ei9-ordinary-publication/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | 9 |
| Passed | 6 |
| Failed | 3 |
| Errors | 0 |
| Skipped | 0 |
| Pass Rate | 66.67% |
| Duration | 179.20021s |

## Failures

### 1. test_release_artifact_retention_refuses_changed_bytes_metadata_candidate_or_native_origin_before_write

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/ei9-ordinary-publication/ace-assign/lib/ace/assign/authority/ordinary_client.rb:50`
- **Message:** [Ace::Assign::AttemptErrors::ReceiptRejected] exception expected, not
Class: <Ace::Assign::AttemptErrors::EvidenceUnavailable>
Message: <"ordinary authority refused (evidence_unavailable); retain original mutation">
---Backtrace---

### 2. test_release_artifact_replay_rechecks_revoked_release_grant

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/ei9-ordinary-publication/ace-assign/lib/ace/assign/authority/ordinary_client.rb:50`
- **Message:** [Ace::Assign::AttemptErrors::UnauthorizedIdentity] exception expected, not
Class: <Ace::Assign::AttemptErrors::EvidenceUnavailable>
Message: <"ordinary authority refused (unauthorized); retain original mutation">
---Backtrace---

### 3. test_release_artifact_requires_installed_authorizer_and_current_independent_review

- **Type:** failure
- **Location:** `/Users/mc/Ps/ace/.ace-wt/ei9-ordinary-publication/ace-assign/lib/ace/assign/authority/ordinary_client.rb:50`
- **Message:** [Ace::Assign::AttemptErrors::UnauthorizedIdentity] exception expected, not
Class: <Ace::Assign::AttemptErrors::EvidenceUnavailable>
Message: <"ordinary authority refused (unauthorized); retain original mutation">
---Backtrace---

## Files Tested

- test/feat/authority/ordinary_release_artifacts_test.rb
