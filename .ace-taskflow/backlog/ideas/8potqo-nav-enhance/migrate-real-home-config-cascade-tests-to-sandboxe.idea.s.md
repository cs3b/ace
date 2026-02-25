# Idea

Migrate real-home config cascade tests to sandboxed E2E and audit remaining unit/molecule tests. Current migration candidates: ace-support-nav/test/molecules/source_registry_test.rb:test_discovers_user_sources, ace-support-nav/test/molecules/config_loader_test.rb:test_protocol_priority_project_overrides_user, ace-support-nav/test/molecules/protocol_scanner_test.rb:test_scan_source_by_alias_user, ace-support-test-helpers/test/molecules/config_helpers_test.rb plus helper ace-support-test-helpers/lib/ace/test_support/config_helpers.rb (with_cascade_configs writes ~/.ace), and ace-support-fs/test/molecules/directory_traverser_test.rb:test_build_cascade_priorities. Goal: keep unit/molecule tests tempdir-only, no writes to real ~/.ace or repo root ./.ace; cover real cascade behavior in E2E with isolated HOME + PROJECT_ROOT.

---
Captured: 2026-02-25 19:49:38
