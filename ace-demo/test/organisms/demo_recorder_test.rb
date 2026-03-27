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

  class RaisingYamlParser
    def parse_file(_path)
      raise "parse_file should not be called"
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
      {id: "abc123", path: @sandbox_path, warnings: []}
    end
  end

  class StubTeardownExecutor
    attr_reader :steps, :sandbox_path

    def execute(steps:, sandbox_path:)
      @steps = steps
      @sandbox_path = sandbox_path
    end
  end

  class StubMediaRetimer
    attr_reader :calls

    def initialize
      @calls = []
    end

    def retime(**kwargs)
      @calls << kwargs
      output_path = kwargs[:output_path] || kwargs[:input_path].sub(/(\.[a-z0-9]+)\z/i, "-#{kwargs[:speed]}\\1")
      {
        input_path: kwargs[:input_path],
        output_path: output_path,
        speed: kwargs[:speed],
        dry_run: false
      }
    end
  end

  class StubCastVerifier
    attr_reader :args

    def initialize(result:)
      @result = result
    end

    def verify(cast_path:, tape_spec:)
      @args = {cast_path: cast_path, tape_spec: tape_spec}
      @result
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

    recorder = Ace::Demo::Organisms::DemoRecorder.new(resolver: resolver, executor: executor, default_backend: "vhs")
    output = recorder.record(tape_ref: "hello", format: "gif")

    assert_equal File.expand_path(".ace-local/demo/hello.gif", @tmp), output.visual_path
    assert_equal "vhs", output.backend
    assert_nil output.cast_path
    assert_includes executor.cmd, "--output"
    assert_includes executor.cmd, output.visual_path
  end

  def test_uses_configured_defaults_for_output_dir_and_vhs_bin
    resolver = StubResolver.new(File.join(@tmp, "hello.tape"))
    File.write(resolver.resolve("hello"), "output /tmp/hello.gif\n")
    executor = StubExecutor.new

    Ace::Demo.stub(:config, {"output_dir" => "tmp/demo-out", "vhs_bin" => "vhs-custom"}) do
      recorder = Ace::Demo::Organisms::DemoRecorder.new(
        resolver: resolver,
        executor: executor,
        default_backend: "vhs"
      )
      output = recorder.record(tape_ref: "hello", format: "gif")

      assert_equal File.expand_path("tmp/demo-out/hello.gif", @tmp), output.visual_path
      assert_equal "vhs-custom", executor.cmd.first
    end
  end

  def test_respects_custom_output
    resolver = StubResolver.new(File.join(@tmp, "hello.tape"))
    File.write(resolver.resolve("hello"), "output /tmp/hello.gif\n")
    executor = StubExecutor.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(resolver: resolver, executor: executor, default_backend: "vhs")
    output = recorder.record(tape_ref: "hello", output: "/tmp/custom.webm", format: "webm")

    assert_equal "/tmp/custom.webm", output.visual_path
    assert_includes executor.cmd, "/tmp/custom.webm"
  end

  def test_rejects_unsupported_format
    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new("/tmp/x.tape"),
      executor: StubExecutor.new,
      default_backend: "vhs"
    )

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
      "settings" => {"format" => "gif"},
      "setup" => ["sandbox", "copy-fixtures"],
      "teardown" => ["cleanup"],
      "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
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
      teardown_executor: teardown_executor,
      default_backend: "vhs"
    )

    output = recorder.record(tape_ref: "demo", output: output_path)

    assert_equal output_path, output.visual_path
    assert_equal "vhs", output.backend
    assert_equal yaml_path, sandbox_builder.source_tape_path
    assert_equal ["sandbox", "copy-fixtures"], sandbox_builder.setup_steps
    assert_equal "./demo.gif", compiler.output_path
    assert executor.cmd[1].end_with?("demo.tape.compiled.tape")
    assert_equal sandbox_path, executor.chdir
    assert_equal ["cleanup"], teardown_executor.steps
    assert_equal sandbox_path, teardown_executor.sandbox_path
  end

  def test_records_yaml_tape_with_preparsed_spec_without_reparsing
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    output_path = File.join(@tmp, "demo.gif")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    executor = StubExecutor.new

    spec = {
      "settings" => {"format" => "gif"},
      "setup" => ["sandbox"],
      "teardown" => ["cleanup"],
      "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
    }

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: executor,
      yaml_parser: RaisingYamlParser.new,
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: StubTeardownExecutor.new,
      default_backend: "vhs"
    )

    output = recorder.record(tape_ref: "demo", output: output_path, yaml_spec: spec)

    assert_equal output_path, output.visual_path
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
        "settings" => {"format" => "gif"},
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
      ),
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: teardown_executor,
      default_backend: "vhs"
    )

    error = assert_raises(RuntimeError) do
      recorder.record(tape_ref: "demo")
    end

    assert_includes error.message, "vhs failed"
    assert_equal ["cleanup"], teardown_executor.steps
    assert_equal sandbox_path, teardown_executor.sandbox_path
  end

  def test_records_yaml_tape_with_playback_speed_only_and_returns_retimed_path
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    executor = StubExecutor.new
    retimer = StubMediaRetimer.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: executor,
      yaml_parser: StubYamlParser.new(
        "settings" => {"format" => "gif", "playback_speed" => "4x"},
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
      ),
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: StubTeardownExecutor.new,
      media_retimer: retimer,
      default_backend: "vhs"
    )

    output = recorder.record(tape_ref: "demo")

    raw_path = File.expand_path(".ace-local/demo/demo.gif", @tmp)
    assert_equal File.expand_path(".ace-local/demo/demo-4x.gif", @tmp), output.visual_path
    assert_includes executor.cmd, raw_path
    assert_equal raw_path, retimer.calls[0][:input_path]
    assert_equal "4x", retimer.calls[0][:speed]
    assert_nil retimer.calls[0][:output_path]
  end

  def test_records_yaml_tape_with_speed_only_and_retime_output_override
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    final_output = File.join(@tmp, "docs", "demo", "override.gif")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    executor = StubExecutor.new
    retimer = StubMediaRetimer.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: executor,
      yaml_parser: StubYamlParser.new(
        "settings" => {"format" => "gif", "playback_speed" => "4x"},
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
      ),
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: StubTeardownExecutor.new,
      media_retimer: retimer,
      default_backend: "vhs"
    )

    output = recorder.record(tape_ref: "demo", retime_output: final_output)

    raw_path = File.expand_path(".ace-local/demo/demo.gif", @tmp)
    assert_equal final_output, output.visual_path
    assert_includes executor.cmd, raw_path
    assert_equal raw_path, retimer.calls[0][:input_path]
    assert_equal final_output, retimer.calls[0][:output_path]
    assert_equal "4x", retimer.calls[0][:speed]
  end

  def test_records_yaml_tape_with_output_only_without_retime
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    output_path = File.join(@tmp, "docs", "demo", "demo.gif")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    retimer = StubMediaRetimer.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: StubExecutor.new,
      yaml_parser: StubYamlParser.new(
        "settings" => {"format" => "gif", "output" => output_path},
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
      ),
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: StubTeardownExecutor.new,
      media_retimer: retimer,
      default_backend: "vhs"
    )

    output = recorder.record(tape_ref: "demo")

    assert_equal output_path, output.visual_path
    assert_empty retimer.calls
  end

  def test_records_yaml_tape_with_output_and_speed_as_retime_only_mode
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    final_output = File.join(@tmp, "docs", "demo", "demo.gif")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    executor = StubExecutor.new
    retimer = StubMediaRetimer.new

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: executor,
      yaml_parser: StubYamlParser.new(
        "settings" => {"format" => "gif", "playback_speed" => "4x", "output" => final_output},
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
      ),
      yaml_compiler: StubYamlCompiler.new,
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: StubTeardownExecutor.new,
      media_retimer: retimer,
      default_backend: "vhs"
    )

    output = recorder.record(tape_ref: "demo")

    raw_path = File.expand_path(".ace-local/demo/demo.gif", @tmp)
    assert_equal final_output, output.visual_path
    assert_includes executor.cmd, raw_path
    assert_equal raw_path, retimer.calls[0][:input_path]
    assert_equal final_output, retimer.calls[0][:output_path]
    assert_equal "4x", retimer.calls[0][:speed]
  end

  def test_records_yaml_tape_with_asciinema_default_backend
    yaml_path = File.join(@tmp, "demo.tape.yml")
    File.write(yaml_path, "description: demo\n")
    sandbox_path = File.join(@tmp, "sandbox")
    FileUtils.mkdir_p(sandbox_path)
    asciinema_executor = StubExecutor.new
    agg_executor = StubExecutor.new
    verification_result = Ace::Demo::Models::VerificationResult.new(
      success: true,
      status: "pass",
      commands_found: ["echo ok"],
      commands_missing: [],
      details: {commands_expected: 1}
    )
    cast_verifier = StubCastVerifier.new(result: verification_result)

    recorder = Ace::Demo::Organisms::DemoRecorder.new(
      resolver: StubResolver.new(yaml_path),
      executor: StubExecutor.new,
      asciinema_executor: asciinema_executor,
      agg_executor: agg_executor,
      cast_verifier: cast_verifier,
      yaml_parser: StubYamlParser.new(
        "settings" => {"format" => "gif", "agg_font_family" => "Hack Nerd Font Mono"},
        "setup" => ["sandbox"],
        "teardown" => ["cleanup"],
        "scenes" => [{"name" => "Main flow", "commands" => [{"type" => "echo ok", "sleep" => "1s"}]}]
      ),
      sandbox_builder: StubSandboxBuilder.new(sandbox_path),
      teardown_executor: StubTeardownExecutor.new,
      default_backend: "asciinema"
    )

    output = recorder.record(tape_ref: "demo")

    assert_equal "asciinema", output.backend
    assert_equal File.expand_path(".ace-local/demo/demo.gif", @tmp), output.visual_path
    assert_equal File.expand_path(".ace-local/demo/demo.cast", @tmp), output.cast_path
    assert_equal verification_result, output.verification
    assert_equal output.cast_path, cast_verifier.args[:cast_path]
    assert_equal "asciinema", asciinema_executor.cmd.first
    assert_equal "agg", agg_executor.cmd.first
    assert_includes agg_executor.cmd, "--font-family"
    assert_includes agg_executor.cmd, "Hack Nerd Font Mono"
  end
end
