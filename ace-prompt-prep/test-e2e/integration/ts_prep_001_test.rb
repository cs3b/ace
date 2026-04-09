# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"

class TSPREP001IntegrationTest < Minitest::Test
  def setup
    @root = File.expand_path("../..", __dir__)
    @exe = File.join(@root, "exe", "ace-prompt-prep")
  end

  def run_cmd(*args, chdir: @root)
    Open3.capture3(@exe, *args, chdir: chdir)
  end

  def test_help_surface
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-prompt-prep/, stdout + stderr)
    assert_match(/process|setup/, stdout + stderr)
  end

  def test_process_archives_prompt
    Dir.mktmpdir("ace-prompt-prep-e2e-") do |dir|
      prompt_dir = File.join(dir, ".ace-local", "prompt-prep", "prompts")
      FileUtils.mkdir_p(prompt_dir)
      File.write(File.join(prompt_dir, "the-prompt.md"), "Review this integration change\n")

      stdout, stderr, status = run_cmd("process", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "Review this integration change"
      assert(File.symlink?(File.join(prompt_dir, "_previous.md")))
      refute_empty Dir.glob(File.join(prompt_dir, "archive", "*.md"))
    end
  end
end
