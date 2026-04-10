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

  def test_tc_001_help_command_surface
    stdout, stderr, status = run_cmd(@exe, "--help")
    assert status.success?, stderr
    assert_match(/ace-test-e2e/, stdout + stderr)
    assert_match(/--dry-run/, stdout + stderr)
    assert_match(/--provider/, stdout + stderr)
  end

  def test_tc_002_invalid_package_dry_run
    stdout, stderr, status = run_cmd(@exe, "not-a-real-package", "--dry-run")

    refute status.success?
    assert_match(/No tests found for package 'not-a-real-package'/, stderr)
    refute_match(/Phase 1\/2|Phase 2\/2/, stdout)
  end

  def test_tc_003_dry_run_discovers_repo_tests
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
      assert_match(/Dry run: preview of package phases to execute/, stdout)
      assert_match(/Phase 1\/2: sandboxed integration/, stdout)
      assert_match(/ts_demo_001_test\.rb/, stdout)
      assert_match(/\[run\] 1 integration file\(s\)/, stdout)
    end
  end

  def test_tc_004_suite_help_command_surface
    stdout, stderr, status = run_cmd(@suite_exe, "--help")
    assert status.success?, stderr
    assert_match(/ace-test-e2e-suite/, stdout + stderr)
    assert_match(/--only-failures/, stdout + stderr)
    assert_match(/--affected/, stdout + stderr)
  end
end
