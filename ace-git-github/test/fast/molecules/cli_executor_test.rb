# frozen_string_literal: true

require "test_helper"

module Github
  class CliExecutorTest < AceGitGithubTestCase
    def test_execute_returns_structured_result_on_success
      runner = ->(args:, timeout: nil, env: nil) do
        assert_equal ["gh", "issue", "view", "1"], args
        {success: true, stdout: "ok\n", stderr: "", exit_code: 0}
      end

      result = Ace::Git::Github::CliExecutor.execute("issue", ["view", "1"], runner: runner)
      assert result[:success]
      assert_equal "ok\n", result[:stdout]
    end

    def test_execute_without_runner_uses_open3
      Open3.stub :capture3, ["ok\n", "", stub_status(true)] do
        result = Ace::Git::Github::CliExecutor.execute("issue", ["view", "1"])
        assert result[:success]
        assert_equal "ok\n", result[:stdout]
      end
    end

    def test_execute_raises_cli_missing_when_binary_absent
      Open3.stub :capture3, ->(*_args) { raise Errno::ENOENT } do
        error = assert_raises(Ace::Git::ProviderCliMissingError) do
          Ace::Git::Github::CliExecutor.execute("issue", ["view", "1"])
        end
        assert_match(/gh/, error.message)
      end
    end

    def test_execute_raises_unreachable_on_timeout
      Timeout.stub :timeout, ->(_seconds, &_block) { raise Timeout::Error } do
        error = assert_raises(Ace::Git::ProviderUnreachableError) do
          Ace::Git::Github::CliExecutor.execute("issue", ["view", "1"], timeout: 1)
        end
        assert_match(/timed out/, error.message)
      end
    end

    def test_installed_false_when_probe_fails
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "nope", exit_code: 127} }
      refute Ace::Git::Github::CliExecutor.installed?(runner: runner)
    end

    def test_check_installed_raises_classified_error
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "nope", exit_code: 127} }
      assert_raises(Ace::Git::ProviderCliMissingError) do
        Ace::Git::Github::CliExecutor.check_installed!(runner: runner)
      end
    end

    def test_check_authenticated_raises_classified_error
      runner = ->(_args:, timeout: nil, env: nil) { {success: false, stdout: "", stderr: "not logged in", exit_code: 4} }
      error = assert_raises(Ace::Git::ProviderAuthenticationError) do
        Ace::Git::Github::CliExecutor.check_authenticated!(runner: runner)
      end
      assert_match(/gh auth login/, error.message)
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
