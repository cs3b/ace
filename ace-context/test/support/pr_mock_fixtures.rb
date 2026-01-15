# frozen_string_literal: true

# Shared fixtures for PR-related tests
# Provides consistent mock diff data for context_loader tests
module PrMockFixtures
  # Standard git diff format with proper headers for single PR tests
  MOCK_DIFF_STANDARD = <<~DIFF
    diff --git a/lib/foo.rb b/lib/foo.rb
    index abc123..def456 100644
    --- a/lib/foo.rb
    +++ b/lib/foo.rb
    @@ -1,3 +1,4 @@
     class Foo
    +  def bar; end
     end
  DIFF

  # Simple diff for PR 123 (multi-PR tests)
  MOCK_DIFF_PR_123 = "diff --git a/foo.rb b/foo.rb\n+line from PR 123"

  # Simple diff for PR 456 (multi-PR tests)
  MOCK_DIFF_PR_456 = "diff --git a/bar.rb b/bar.rb\n+line from PR 456"
end
