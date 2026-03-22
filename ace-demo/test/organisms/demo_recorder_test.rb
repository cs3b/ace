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
    attr_reader :cmd, :chdir

    def run(cmd, chdir: nil)
      @cmd = cmd
      @chdir = chdir
      Ace::Demo::Models::ExecutionResult.new(stdout: "ok", stderr: "", success: true, exit_code: 0)
    end
  end

  class FailingExecutor < StubExecutor
    def run(cmd, chdir: nil)
      super
      raise "vhs failed"
    end
  end

  class StubYamlParser
    def initialize(spec)
      @spec = spec
    end

    def parse_file(_path)
      @spec
    end
  end

  class StubYamlCompiler
    attr_reader :output_path

    def compile(spec:, output_path:)
      @output_path = output_path
      <<~TAPE
        Output #{output_path}
        Type "echo demo"
        Sleep 1s
      TAPE
    end
  end

  class StubSandboxBuilder
    attr_reader :source_tape_path, :setup_steps

    def initialize(sandbox_path)
      @sandbox_path = sandbox_path
    end

    def build(source_tape_path:, setup_steps:)
      @source_tape_path = source_tape_path
      @setup_steps = setup_steps
      { id: "abc123", path: @sandbox_path, warnings: [] }
    end
  end

  class StubTeardownExecutor
    attr_reader :steps, :sandbox_path

    def execute(steps:, sandbox_path:)
      @steps = steps
      @sandbox_path = sandbox_path
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

  def test_records_yaml_tape_using_production_sandbox_pipeline
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    output_path = File.join(@tmp, "demo.gif")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)

    resolver = StubResolver.new(yaml_path)
    executor = StubExecutor.new
    parser = StubYamlParser.new(
      "settings" => { "format" => "gif" },
      "setup" => ["sandbox", "copy-fixtures"],
      "teardown" => ["cleanup"],
      "scenes" => [{ "name" => "Main flow", "commands" => [{ "type" => "echo ok", "sleep" => "1s" }] }]
    )
    compiler = StubYamlCompiler.new
    sandbox_builder = StubSandboxBuilder.new(sandbox_path)
    teardown_executor = StubTeardownExecutor.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: resolver,
      executor: executor,
      yaml_parser: parser,
      yaml_compiler: compiler,
      sandbox_builder: sandbox_builder,
      teardown_executor: teardown_executor
    )

    output = recorder.record(tape_ref: "demo", output: output_path)

    assert_equal output_path, output
    assert_equal yaml_path, sandbox_builder.source_tape_path
    assert_equal ["sandbox", "copy-fixtures"], sandbox_builder.setup_steps
    assert_equal "./demo.gif", compiler.output_path
    assert executor.cmd[1].end_with?("demo.tape.compiled.tape")
    assert_equal sandbox_path, executor.chdir
    assert_equal ["cleanup"], teardown_executor.steps
    assert_equal sandbox_path, teardown_executor.sandbox_path
  end

  def test_yaml_teardown_runs_when_vhs_execution_fails
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    teardown_executor = StubTeardownExecutor.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: FailingExecutor.new,
      yaml_parser: StubYamlParser.new(
        "settings" => { "format" => "gif" },
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{ "name" => "Main flow", "commands" => [{ "type" => "echo ok", "sleep" => "1s" }] }]
      ),
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: teardown_executor
    )

    error = assert_raises(RuntimeError) do
      recorder.record(tape_ref: "demo")
    end

    assert_includes error.message, "vhs failed"
    assert_equal ["cleanup"], teardown_executor.steps
    assert_equal sandbox_path, teardown_executor.sandbox_path
  end
end
