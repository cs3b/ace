# frozen_string_literal: true

require "test_helper"

module Forgejo
  class CliExecutorTest < AceGitForgejoTestCase
    TARGET = Ace::Git::Forgejo::RepositoryBinding::Target.resolve("https://forge.example.com/owner/repo")

    def test_execute_control_allowlists_only_version_and_auth_list
      runner = ->(args:, timeout: nil, env: nil) do
        assert_equal ["fj", "version"], args
        {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0}
      end
      result = Ace::Git::Forgejo::CliExecutor.execute_control(:version, runner: runner)
      assert result[:success]

      error = assert_raises(ArgumentError) do
        Ace::Git::Forgejo::CliExecutor.execute_control(:pr_view, runner: runner)
      end
      assert_match(/control command/, error.message)
    end

    def test_execute_repository_stamps_host_and_uses_observed_form
      runner = ->(args:, timeout: nil, env: nil) do
        assert_equal(
          ["fj", "-H", "forge.example.com", "--style", "minimal", "pr", "view", "owner/repo#7"],
          args
        )
        assert_equal({"LC_ALL" => "C"}, env)
        {success: true, stdout: "ok\n", stderr: "", exit_code: 0}
      end

      result = Ace::Git::Forgejo::CliExecutor.execute_repository(
        target: TARGET, operation: :pr_view, arguments: [7], runner: runner
      )
      assert result[:success]
      assert_equal "ok\n", result[:stdout]
    end

    def test_execute_repository_refuses_missing_or_invalid_target_before_launch
      runner = ->(**_kw) { flunk("No subprocess may launch without a validated target") }

      error = assert_raises(Ace::Git::ConfigError) do
        Ace::Git::Forgejo::CliExecutor.execute_repository(
          target: nil, operation: :pr_view, arguments: [7], runner: runner
        )
      end
      assert_match(/validated selected Forgejo target/, error.message)
    end

    def test_forged_target_cannot_bypass_validation
      # Target construction is only reachable through Target.resolve, so a
      # caller cannot fabricate inconsistent authority/repo/url values and
      # launch repository commands against the wrong server.
      error = assert_raises(NoMethodError) do
        Ace::Git::Forgejo::RepositoryBinding::Target.new(
          host: "evil.example.com", authority: "evil.example.com",
          repo: "owner/repo", url: "https://forge.example.com/owner/repo"
        )
      end
      assert_match(/private method/, error.message)
    end

    def test_execute_repository_refuses_unobserved_operation_before_launch
      runner = ->(**_kw) { flunk("Unobserved operations must refuse before any subprocess") }

      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        Ace::Git::Forgejo::CliExecutor.execute_repository(
          target: TARGET, operation: :pr_merge_expected_head, arguments: [7], runner: runner
        )
      end
      assert_match(/no repository-bound argv form/, error.message)
    end

    def test_execute_without_runner_uses_open3
      Open3.stub :capture3, ["ok\n", "", stub_status(true)] do
        result = Ace::Git::Forgejo::CliExecutor.execute_control(:version)
        assert result[:success]
        assert_equal "ok\n", result[:stdout]
      end
    end

    def test_execute_raises_cli_missing_when_binary_absent
      Open3.stub :capture3, ->(*_args) { raise Errno::ENOENT } do
        error = assert_raises(Ace::Git::ProviderCliMissingError) do
          Ace::Git::Forgejo::CliExecutor.execute_control(:version)
        end
        assert_match(/fj/, error.message)
      end
    end

    def test_execute_raises_unreachable_on_timeout
      Timeout.stub :timeout, ->(_seconds, &_block) { raise Timeout::Error } do
        error = assert_raises(Ace::Git::ProviderUnreachableError) do
          Ace::Git::Forgejo::CliExecutor.execute_control(:version, timeout: 1)
        end
        assert_match(/timed out/, error.message)
      end
    end

    def test_installed_probes_fj_version_subcommand
      runner = ->(args:, timeout: nil, env: nil) do
        # Real `fj` v0.6.0 has no --version flag; `fj version` is the probe.
        assert_equal ["fj", "version"], args
        {success: true, stdout: "fj v0.6.0\n", stderr: "", exit_code: 0}
      end

      assert Ace::Git::Forgejo::CliExecutor.installed?(runner: runner)
    end

    def test_installed_version_parses_observed_output
      runner = version_runner("Could not find keys file. Creating a new file.\nfj v0.6.0\n" \
        "Check for a new version with `fj version --check`\n")
      assert_equal "v0.6.0", Ace::Git::Forgejo::CliExecutor.installed_version(runner: runner)
    end

    def test_installed_version_raises_cli_missing_when_probe_fails
      runner = version_runner("", success: false)
      assert_raises(Ace::Git::ProviderCliMissingError) do
        Ace::Git::Forgejo::CliExecutor.installed_version(runner: runner)
      end
    end

    def test_check_version_supported_accepts_observed_version
      runner = version_runner("fj v0.6.0\n")
      assert_equal "v0.6.0", Ace::Git::Forgejo::CliExecutor.check_version_supported!(runner: runner)
    end

    def test_check_version_supported_refuses_unobserved_version
      runner = version_runner("fj v0.7.0\n")
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        Ace::Git::Forgejo::CliExecutor.check_version_supported!(runner: runner)
      end
      assert_match(/v0\.7\.0 was never observed/, error.message)
      assert_match(/v0\.6\.0/, error.message)
    end

    def test_check_version_supported_refuses_unparseable_version
      runner = version_runner("something else\n")
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        Ace::Git::Forgejo::CliExecutor.check_version_supported!(runner: runner)
      end
      assert_match(/unknown version/, error.message)
    end

    def test_check_installed_raises_classified_error
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "nope", exit_code: 127} }
      assert_raises(Ace::Git::ProviderCliMissingError) do
        Ace::Git::Forgejo::CliExecutor.check_installed!(runner: runner)
      end
    end

    def test_authenticated_requires_exact_authority_line_match
      runner = ->(args:, timeout: nil, env: nil) {
        assert_equal ["fj", "auth", "list"], args
        {success: true, stdout: "forge.example.com\nother.example.com\n", stderr: "", exit_code: 0}
      }
      assert Ace::Git::Forgejo::CliExecutor.authenticated?("forge.example.com", runner: runner)
      refute Ace::Git::Forgejo::CliExecutor.authenticated?("missing.example.com", runner: runner)
      # A host that merely contains the selected authority as a substring
      # must never satisfy the selected host's authentication.
      refute Ace::Git::Forgejo::CliExecutor.authenticated?("orge.example.com", runner: runner)
    end

    def test_authenticated_scans_both_streams_and_ignores_noise
      # Observed v0.6.0: no logins -> "No logins." on stderr, exit 0.
      runner = ->(**_kw) {
        {success: true, stdout: "Could not find keys file. Creating a new file.\n",
         stderr: "No logins.\n", exit_code: 0}
      }
      refute Ace::Git::Forgejo::CliExecutor.authenticated?("forge.example.com", runner: runner)

      listed = ->(**_kw) {
        {success: true, stdout: "forge.example.com\n", stderr: "", exit_code: 0}
      }
      assert Ace::Git::Forgejo::CliExecutor.authenticated?("forge.example.com", runner: listed)
    end

    def test_check_authenticated_raises_classified_error
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "not logged in", exit_code: 1} }
      error = assert_raises(Ace::Git::ProviderAuthenticationError) do
        Ace::Git::Forgejo::CliExecutor.check_authenticated!(authority: "forge.example.com", runner: runner)
      end
      assert_match(/fj auth list/, error.message)
    end

    private

    def version_runner(stdout, success: true)
      ->(**_kw) { {success: success, stdout: stdout, stderr: "", exit_code: success ? 0 : 1} }
    end

    def stub_status(success)
      status = Object.new
      status.define_singleton_method(:success?) { success }
      status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
      status
    end
  end
end
