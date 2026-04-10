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

  def test_tc_001_help_survey
    stdout, stderr, status = run_cmd("--help")

    assert status.success?, stderr
    assert_match(/ace-prompt-prep/, stdout + stderr)
    assert_match(/process/, stdout + stderr)
    assert_match(/setup/, stdout + stderr)

    stdout, stderr, status = run_cmd("process", "--help")
    assert status.success?, stderr
    assert_match(/process/i, stdout + stderr)
  end

  def test_tc_002_setup_workspace
    Dir.mktmpdir("ace-prompt-prep-e2e-") do |dir|
      stdout, stderr, status = run_cmd("setup", chdir: dir)
      assert status.success?, stderr

      prompt_dir = File.join(dir, ".ace-local", "prompt-prep", "prompts")
      template = File.join(prompt_dir, "the-prompt.md")

      assert_match(/Prompt initialized/i, stdout)
      assert File.directory?(prompt_dir)
      assert File.file?(template)
      assert_match(/Path:/, stdout)
    end
  end

  def test_tc_003_process_and_archive
    Dir.mktmpdir("ace-prompt-prep-e2e-") do |dir|
      run_cmd("setup", chdir: dir)
      prompt_dir = File.join(dir, ".ace-local", "prompt-prep", "prompts")
      prompt_path = File.join(prompt_dir, "the-prompt.md")
      File.write(prompt_path, "Review this integration change\n")

      stdout, stderr, status = run_cmd("process", chdir: dir)
      assert status.success?, stderr
      assert_includes stdout, "Review this integration change"
      assert(File.symlink?(File.join(prompt_dir, "_previous.md")))
      refute_empty Dir.glob(File.join(prompt_dir, "archive", "*.md"))
    end
  end

  def test_tc_004_bundle_context
    Dir.mktmpdir("ace-prompt-prep-e2e-") do |dir|
      run_cmd("setup", chdir: dir)
      prompt_dir = File.join(dir, ".ace-local", "prompt-prep", "prompts")
      prompt_path = File.join(prompt_dir, "the-prompt.md")
      File.write(prompt_path, <<~PROMPT)
        # Task
        Use this.

        ```yaml
        context:
          - file: README.md
        ```
      PROMPT
      File.write(File.join(dir, "README.md"), "sample readme\n")

      stdout, stderr, status = run_cmd("process", "--bundle", chdir: dir)
      assert status.success?, stderr
      assert_match(/FILE\|\.ace-local\/prompt-prep\/prompts\/the-prompt\.md/, stdout)
      assert_match(/README\.md/, stdout)
      assert(File.symlink?(File.join(prompt_dir, "_previous.md")))
      refute_empty Dir.glob(File.join(prompt_dir, "archive", "*.md"))
    end
  end
end
