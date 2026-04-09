# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "rbconfig"

class TSLLMCLI001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-llm-providers-cli-check")
  end

  def run_cmd(*args, chdir: @root, env: {})
    Open3.capture3(env, @exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-llm-providers-cli-check/, stdout + stderr)
  end

  def test_no_tools_path_reports_failures
    Dir.mktmpdir("ace-llmcli-e2e-") do |dir|
      tools_dir = File.join(dir, "tools")
      FileUtils.mkdir_p(tools_dir)

      stdout, stderr, status = Open3.capture3(
        {"PATH" => tools_dir},
        RbConfig.ruby, @exe,
        chdir: dir
      )
      refute status.success?
      assert_match(/Not installed|Available: 0\/4|No such file/i, stdout + stderr)
    end
  end
end
