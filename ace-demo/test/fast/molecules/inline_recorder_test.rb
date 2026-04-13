# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class InlineRecorderTest < AceDemoTestCase
  class StubExecutor
    attr_reader :cmd

    def run(cmd)
      @cmd = cmd
      Ace::Demo::Models::ExecutionResult.new(stdout: "ok", stderr: "", success: true, exit_code: 0)
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_inline_recorder")
    @orig_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@orig_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_generates_session_dir_and_writes_tape
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "my-demo", commands: ["echo hello"])

    assert File.directory?(result[:session_dir])
    assert File.exist?(result[:tape_path])

    content = File.read(result[:tape_path])
    assert_includes content, 'Type "echo hello"'
    assert_includes content, "Output ./my-demo.gif"
  end

  def test_delegates_to_executor
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "my-demo", commands: ["echo hello"])

    assert_equal "vhs", executor.cmd[0]
    assert_equal result[:tape_path], executor.cmd[1]
    assert_includes executor.cmd, "--output"
    assert_includes executor.cmd, result[:output_path]
  end

  def test_returns_paths
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "my-demo", commands: ["echo hello"])

    assert result[:output_path].end_with?("my-demo.gif")
    assert result[:tape_path].end_with?("my-demo.tape")
    assert_includes result[:session_dir], ".ace-local/demo/"
  end

  def test_session_dir_is_b36ts_based
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "my-demo", commands: ["echo hello"])

    session_name = File.basename(result[:session_dir])
    assert_match(/\A[0-9a-z]{6}\z/, session_name)
  end

  def test_sanitizes_name
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "My Demo/evil", commands: ["echo hi"])

    assert result[:tape_path].end_with?("my-demo-evil.tape")
    assert result[:output_path].end_with?("my-demo-evil.gif")
  end

  def test_respects_format_option
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "my-demo", commands: ["echo hello"], format: "mp4")

    assert result[:output_path].end_with?("my-demo.mp4")
  end

  def test_respects_custom_vhs_bin
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo", vhs_bin: "vhs-custom")

    recorder.record(name: "my-demo", commands: ["echo hello"])

    assert_equal "vhs-custom", executor.cmd[0]
  end

  def test_passes_tape_options_to_content_generator
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(
      name: "my-demo",
      commands: ["echo hello"],
      description: "A test demo",
      tags: "ci,test",
      font_size: 20,
      width: 1200,
      height: 600,
      timeout: "3s"
    )

    content = File.read(result[:tape_path])
    assert_includes content, "# Description: A test demo"
    assert_includes content, "# Tags: ci,test"
    assert_includes content, "Set FontSize 20"
    assert_includes content, "Set Width 1200"
    assert_includes content, "Set Height 600"
    assert_includes content, "Sleep 3s"
  end

  def test_multiple_commands
    executor = StubExecutor.new
    recorder = Ace::Demo::Molecules::InlineRecorder.new(executor: executor, output_dir: ".ace-local/demo")

    result = recorder.record(name: "multi", commands: ["git status", "make deploy"])

    content = File.read(result[:tape_path])
    assert_includes content, 'Type "git status"'
    assert_includes content, 'Type "make deploy"'
  end
end
