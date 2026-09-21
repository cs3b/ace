# frozen_string_literal: true

require "test_helper"

module Forgejo
  class CliExecutorTest < AceGitForgejoTestCase
    def test_execute_returns_structured_result_on_success
      runner = ->(args:, timeout: nil, env: nil) do
        assert_equal ["fj", "pr", "view", "1"], args
        {success: true, stdout: "ok\n", stderr: "", exit_code: 0}
      end

      result = Ace::Git::Forgejo::CliExecutor.execute(["pr", "view", "1"], runner: runner)
      assert result[:success]
      assert_equal "ok\n", result[:stdout]
    end

    def test_execute_without_runner_uses_open3
      Open3.stub :capture3, ["ok\n", "", stub_status(true)] do
        result = Ace::Git::Forgejo::CliExecutor.execute(["pr", "view", "1"])
        assert result[:success]
        assert_equal "ok\n", result[:stdout]
      end
    end

    def test_execute_raises_cli_missing_when_binary_absent
      Open3.stub :capture3, ->(*_args) { raise Errno::ENOENT } do
        error = assert_raises(Ace::Git::ProviderCliMissingError) do
          Ace::Git::Forgejo::CliExecutor.execute(["pr", "view", "1"])
        end
        assert_match(/fj/, error.message)
      end
    end

    def test_execute_raises_unreachable_on_timeout
      Timeout.stub :timeout, ->(_seconds, &_block) { raise Timeout::Error } do
        error = assert_raises(Ace::Git::ProviderUnreachableError) do
          Ace::Git::Forgejo::CliExecutor.execute(["pr", "view", "1"], timeout: 1)
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

    def test_check_installed_raises_classified_error
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "nope", exit_code: 127} }
      assert_raises(Ace::Git::ProviderCliMissingError) do
        Ace::Git::Forgejo::CliExecutor.check_installed!(runner: runner)
      end
    end

    def test_authenticated_checks_configured_host
      runner = ->(args:, timeout: nil, env: nil) {
        assert_equal ["fj", "auth", "list"], args
        {success: true, stdout: "forgejo.example.com\nother.example.com\n", stderr: "", exit_code: 0}
      }
      assert Ace::Git::Forgejo::CliExecutor.authenticated?("forgejo.example.com", runner: runner)
      refute Ace::Git::Forgejo::CliExecutor.authenticated?("missing.example.com", runner: runner)
    end

    def test_check_authenticated_raises_classified_error
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "not logged in", exit_code: 1} }
      error = assert_raises(Ace::Git::ProviderAuthenticationError) do
        Ace::Git::Forgejo::CliExecutor.check_authenticated!(host: "forgejo.example.com", runner: runner)
      end
      assert_match(/fj auth list/, error.message)
    end

    private

    def stub_status(success)
      status = Object.new
      status.define_singleton_method(:success?) { success }
      status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
      status
    end
  end
end
