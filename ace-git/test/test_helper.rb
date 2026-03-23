# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "ace/test_support"
require "ace/git"

# Base test case for ace-git tests
class AceGitTestCase < AceTestCase
  def setup
    super
    # Reset ace-git config cache to ensure clean state
    Ace::Git.reset_config!
  end

  def teardown
    Ace::Git.reset_config!
    super
  end

  # Helper to build mock PR data for PrMetadataFetcher stubs
  # Used across multiple organism tests to avoid duplication
  def build_mock_prs(current_pr: nil, merged_prs: [], open_prs: [])
    prs = []
    prs << current_pr.merge("state" => "OPEN") if current_pr
    merged_prs.each { |pr| prs << pr.merge("state" => "MERGED") }
    open_prs.each { |pr| prs << pr.merge("state" => "OPEN") }
    {success: true, prs: prs}
  end

  # Helper to safely modify lock_retry config within a block
  # Ensures config is restored even if test fails
  def with_lock_retry_config(enabled:)
    original_config = Ace::Git.config.dup
    Ace::Git.instance_variable_set(:@config, {"lock_retry" => {"enabled" => enabled}})
    yield
  ensure
    Ace::Git.instance_variable_set(:@config, original_config)
  end
end
