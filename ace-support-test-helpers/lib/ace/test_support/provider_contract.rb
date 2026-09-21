# frozen_string_literal: true

module Ace
  module TestSupport
    # Shared provider-contract parity suite.
    #
    # Provider packages (ace-git-github, ace-git-forgejo) include this module
    # in a test class backed by a scripted fake command runner and assert that
    # their implementation produces identical normalized evidence and the
    # exact classified failure taxonomy. Identical assertions run against every
    # provider, which proves contract parity without any network or CLI.
    #
    # Host test class contract:
    # - #build_provider(runner) -> Ace::Git::Providers::Base wired to the runner
    # - #ok_runner               -> successful scripted runner
    # - #version_fail_runner     -> provider CLI presence probe fails
    # - #auth_fail_runner        -> provider CLI auth probe fails
    # - #not_found_runner        -> object lookup command fails as "not found"
    # - #malformed_runner        -> object lookup returns unparseable output
    # - #unreachable_runner      -> object lookup fails as unreachable/timeout
    #
    # Runners are callables receiving kwargs (args:, timeout:, env:) and
    # returning {stdout:, stderr:, exit_code:}.
    module ProviderContract
      # Essential normalized evidence: fields every provider must supply.
      # Provider-optional fields (url, draft, merged_at) are asserted as
      # present or left unchecked where a provider cannot supply them.
      EXPECTED_PR = {
        server_name: "forge-server",
        number: 25,
        title: "Ship the provider contract",
        state: :merged,
        head_ref: "lab/W675-ace",
        base_ref: "main",
        head_sha: "fc14c43d3660ac6c133959a6dec29603413f0e8a",
        author: "lab-builder"
      }.freeze

      EXPECTED_BRANCH_PR = {
        server_name: "forge-server",
        number: 31,
        title: "Wire status to providers",
        state: :open,
        head_ref: "lab/W676-ace",
        base_ref: "main",
        head_sha: "a1b2c3d4e5f60718293a4b5c6d7e8f9012345678",
        author: "lab-builder"
      }.freeze

      EXPECTED_ISSUE = {
        server_name: "forge-server",
        number: 9,
        title: "Broken diff on detached HEAD",
        state: :open,
        author: "lab-admin"
      }.freeze

      EXPECTED_CHECK = {server_name: "forge-server", name: "test-suite", state: :success, conclusion: :success}.freeze

      EXPECTED_REPO = {
        server_name: "forge-server",
        full_name: "owner/repo",
        url: "https://forge.example.com/owner/repo"
      }.freeze

      def test_contract_reports_available_and_authenticated
        provider = build_provider(ok_runner)
        assert_equal true, provider.available?
        assert_equal true, provider.authenticated?
        provider.check_available!
        provider.check_authenticated!
      end

      def test_contract_pull_request_evidence_matches_normalized_shape
        pr = build_provider(ok_runner).pull_request(number: 25)
        assert_instance_of Ace::Git::ProviderPullRequest, pr
        assert_normalized_fields(EXPECTED_PR, pr)
        refute_nil pr.url
      end

      def test_contract_pull_request_for_branch_evidence_matches_normalized_shape
        pr = build_provider(ok_runner).pull_request_for_branch(branch: "lab/W676-ace")
        assert_instance_of Ace::Git::ProviderPullRequest, pr
        assert_normalized_fields(EXPECTED_BRANCH_PR, pr)
      end

      def test_contract_pull_request_for_branch_returns_nil_without_match
        assert_nil build_provider(ok_runner).pull_request_for_branch(branch: "no-such-branch")
      end

      def test_contract_pull_request_diff_returns_raw_text
        diff = build_provider(ok_runner).pull_request_diff(number: 25)
        assert_instance_of String, diff
        assert_includes diff, "diff --git"
      end

      def test_contract_recent_pull_requests_returns_normalized_list
        prs = build_provider(ok_runner).recent_pull_requests(limit: 30)
        assert_instance_of Array, prs
        assert_equal 2, prs.length
        assert prs.all? { |pr| pr.instance_of?(Ace::Git::ProviderPullRequest) }
        # Newest first (descending PR number), identical across providers
        assert_equal [31, 25], prs.map(&:number)
      end

      def test_contract_issue_evidence_matches_normalized_shape
        issue = build_provider(ok_runner).issue(number: 9)
        assert_instance_of Ace::Git::ProviderIssue, issue
        assert_normalized_fields(EXPECTED_ISSUE, issue)
        refute_nil issue.url
      end

      def test_contract_checks_return_normalized_list
        checks = build_provider(ok_runner).checks(ref: "fc14c43d3660ac6c133959a6dec29603413f0e8a")
        assert_instance_of Array, checks
        assert_equal 1, checks.length
        check = checks.first
        assert_instance_of Ace::Git::ProviderCheck, check
        assert_equal EXPECTED_CHECK[:server_name], check.server_name
        assert_equal EXPECTED_CHECK[:name], check.name
        assert_equal EXPECTED_CHECK[:state], check.state
        assert_equal EXPECTED_CHECK[:conclusion], check.conclusion
      end

      def test_contract_repository_evidence_matches_normalized_shape
        repo = build_provider(ok_runner).repository
        assert_instance_of Ace::Git::ProviderRepository, repo
        assert_equal EXPECTED_REPO[:server_name], repo.server_name
        assert_equal EXPECTED_REPO[:full_name], repo.full_name
        assert_equal EXPECTED_REPO[:url], repo.url
      end

      def test_contract_cli_missing_failure_is_classified
        provider = build_provider(version_fail_runner)
        error = assert_raises(Ace::Git::ProviderCliMissingError) { provider.check_available! }
        assert_match(/cli/i, error.message)
      end

      def test_contract_authentication_failure_is_classified
        provider = build_provider(auth_fail_runner)
        error = assert_raises(Ace::Git::ProviderAuthenticationError) { provider.check_authenticated! }
        assert_match(/auth/i, error.message)
      end

      def test_contract_object_not_found_failure_is_classified
        provider = build_provider(not_found_runner)
        error = assert_raises(Ace::Git::ProviderObjectNotFoundError) { provider.pull_request(number: 999) }
        assert_match(/999/, error.message)
      end

      def test_contract_malformed_output_failure_is_classified
        provider = build_provider(malformed_runner)
        error = assert_raises(Ace::Git::ProviderMalformedOutputError) { provider.pull_request(number: 25) }
        assert_match(/malformed|parse|unrecognized/i, error.message)
      end

      def test_contract_unreachable_failure_is_classified
        provider = build_provider(unreachable_runner)
        error = assert_raises(Ace::Git::ProviderUnreachableError) { provider.pull_request(number: 25) }
        assert_match(/unreachable|timed out|failed/i, error.message)
      end

      private

      def assert_normalized_fields(expected, evidence)
        expected.each do |field, value|
          assert_equal value, evidence.public_send(field),
            "#{field} must be normalized identically across providers"
        end
      end
    end
  end
end
