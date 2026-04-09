# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSRUNNER001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-test-e2e")
    @suite_exe = File.join(@root, "exe", "ace-test-e2e-suite")
  end

  def run_cmd(exe, *args, chdir: @root)
    Open3.capture3(exe, *args, chdir: chdir)
  end

  def test_help_surfaces
    stdout, stderr, status = run_cmd(@exe, "--help")
    assert status.success?, stderr
    assert_match(/ace-test-e2e/, stdout + stderr)

    stdout, stderr, status = run_cmd(@suite_exe, "--help")
    assert status.success?, stderr
    assert_match(/ace-test-e2e-suite/, stdout + stderr)
  end

  def test_dry_run_discovers_integration_tests
    Dir.mktmpdir("ace-test-e2e-e2e-") do |dir|
      integration_dir = File.join(dir, "ace-demo", "test-e2e", "integration")
      FileUtils.mkdir_p(integration_dir)
      File.write(File.join(integration_dir, "ts_demo_001_test.rb"), <<~RUBY)
        require "minitest/autorun"
        class GeneratedIntegrationTest < Minitest::Test
          def test_smoke
            assert true
          end
        end
      RUBY

      stdout, stderr, status = run_cmd(@exe, "ace-demo", "--dry-run", chdir: dir)
      assert status.success?, stderr
      assert_match(/ace-demo/, stdout)
      assert_match(/ts_demo_001_test\.rb|TS-DEMO-001/i, stdout)
    end
  end
end
