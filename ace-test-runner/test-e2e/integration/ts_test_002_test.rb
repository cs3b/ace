# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "fileutils"

class TSTEST002IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @source_root = ENV.fetch("ACE_E2E_SOURCE_ROOT", @root)
    @exe = File.join(@root, "exe", "ace-test-suite")
  end

  def test_tc_001_run_full_suite
    stdout, stderr, status = Open3.capture3(command_env, @exe, "--group", "foundation", chdir: @source_root)

    assert_match(/Running tests for \d+ packages|Packages:\s+\d+ passed/i, stdout + stderr)
    assert_match(/ace-test-runner|ace-b36ts|ace-support-core/i, stdout + stderr)
    unless status.success?
      assert_match(/SOME TESTS FAILED|Failed packages:/i, stdout + stderr)
    end
  end

  def test_tc_002_verify_failure_propagation
    failing_test = File.join(@root, "test", "atoms", "intentional_failure_test.rb")
    FileUtils.mkdir_p(File.dirname(failing_test))
    File.write(failing_test, <<~RUBY)
      # frozen_string_literal: true

      require "minitest/autorun"

      class IntentionalFailureTest < Minitest::Test
        def test_intentional_failure
          assert_equal 1, 2
        end
      end
    RUBY

    stdout, stderr, status = Open3.capture3(
      command_env,
      File.join(@root, "exe", "ace-test"),
      @root,
      "test/atoms/intentional_failure_test.rb",
      chdir: @root
    )

    refute status.success?
    assert_match(/intentional_failure_test|Failure|assert_equal/i, stdout + stderr)
  ensure
    FileUtils.rm_f(failing_test)
  end

  private

  def command_env
    {
      "RUBYOPT" => "-W0",
      "PROJECT_ROOT_PATH" => @source_root,
      "ACE_E2E_SOURCE_ROOT" => @source_root
    }
  end
end
