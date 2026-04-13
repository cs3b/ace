# frozen_string_literal: true

require "test_helper"
require "ace/git/molecules/gh_cli_executor"

class GhCliExecutorTest < AceGitTestCase
  def test_execute_returns_structured_result_on_success
    Open3.stub :capture3, ["ok\n", "", stub_status(true)] do
      result = Ace::Git::Molecules::GhCliExecutor.execute("issue", ["view", "1"])
      assert result[:success]
      assert_equal "ok\n", result[:stdout]
      assert_equal "", result[:stderr]
      assert_equal 0, result[:exit_code]
    end
  end

  def test_execute_raises_not_installed_error_on_missing_gh
    Open3.stub :capture3, ->(*_args) { raise Errno::ENOENT } do
      assert_raises(Ace::Git::GhNotInstalledError) do
        Ace::Git::Molecules::GhCliExecutor.execute("issue", ["view", "1"])
      end
    end
  end

  def test_execute_raises_timeout_error
    Ace::Git::Molecules::GhCliExecutor.stub :check_installed, true do
      Timeout.stub :timeout, ->(_seconds, &_block) { raise Timeout::Error } do
        assert_raises(Ace::Git::TimeoutError) do
          Ace::Git::Molecules::GhCliExecutor.execute("issue", ["view", "1"])
        end
      end
    end
  end

  def test_check_authenticated_returns_username
    Open3.stub :capture3, ["", "✓ Logged in to github.com as octocat", stub_status(true)] do
      result = Ace::Git::Molecules::GhCliExecutor.check_authenticated
      assert_equal true, result[:authenticated]
      assert_equal "octocat", result[:username]
    end
  end

  private

  def stub_status(success)
    status = Object.new
    status.define_singleton_method(:success?) { success }
    status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
    status
  end
end
