# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class DemoRecorderTest < AceDemoTestCase
  class StubResolver
    attr_reader :requested

    def initialize(path)
      @path = path
    end

    def resolve(tape_ref)
      @requested = tape_ref
      @path
    end
  end

  class StubExecutor
    attr_reader :cmd

    def run(cmd)
      @cmd = cmd
      Ace::Demo::Models::ExecutionResult.new(stdout: "ok", stderr: "", success: true, exit_code: 0)
    end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_recorder")
    @cwd = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@cwd)
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_records_with_default_output
    resolver = StubResolver.new(File.join(@tmp, "hello.tape"))
    File.write(resolver.resolve("hello"), "output /tmp/hello.gif\n")
    executor = StubExecutor.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(resolver: resolver, executor: executor)
    output = recorder.record(tape_ref: "hello", format: "gif")

    assert_equal File.expand_path(".ace-local/demo/hello.gif", @tmp), output
    assert_includes executor.cmd, "--output"
    assert_includes executor.cmd, output
  end

  def test_uses_configured_defaults_for_output_dir_and_vhs_bin
    resolver = StubResolver.new(File.join(@tmp, "hello.tape"))
    File.write(resolver.resolve("hello"), "output /tmp/hello.gif\n")
    executor = StubExecutor.new

    Ace::Demo.stub(:config, { "output_dir" => "tmp/demo-out", "vhs_bin" => "vhs-custom" }) do
      recorder = Ace::Demo::Organisms::DemoRecorder.new(resolver: resolver, executor: executor)
      output = recorder.record(tape_ref: "hello", format: "gif")

      assert_equal File.expand_path("tmp/demo-out/hello.gif", @tmp), output
      assert_equal "vhs-custom", executor.cmd.first
    end
  end

  def test_respects_custom_output
    resolver = StubResolver.new(File.join(@tmp, "hello.tape"))
    File.write(resolver.resolve("hello"), "output /tmp/hello.gif\n")
    executor = StubExecutor.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(resolver: resolver, executor: executor)
    output = recorder.record(tape_ref: "hello", output: "/tmp/custom.mp4", format: "mp4")

    assert_equal "/tmp/custom.mp4", output
    assert_includes executor.cmd, "/tmp/custom.mp4"
  end

  def test_rejects_unsupported_format
    recorder = Ace::Demo::Organisms::DemoRecorder.new(resolver: StubResolver.new("/tmp/x.tape"), executor: StubExecutor.new)

    assert_raises(ArgumentError) do
      recorder.record(tape_ref: "hello", format: "avi")
    end
  end
end
