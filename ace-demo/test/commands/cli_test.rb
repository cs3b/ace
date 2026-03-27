# frozen_string_literal: true

require_relative "../test_helper"
require "ace/support/cli"
require "tmpdir"

class CliTest < AceDemoTestCase
  def invoke(args)
    stdout, stderr = capture_io do
      @result = Ace::Support::Cli::Runner.new(Ace::Demo::CLI).call(args: args)
    rescue SystemExit => e
      @result = e.status
    rescue Ace::Support::Cli::Error => e
      warn e.message
      @result = e.exit_code
    end

    {stdout: stdout, stderr: stderr, result: @result}
  end

  def test_help_lists_record_command
    result = invoke(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "list"
    assert_includes output, "show"
    assert_includes output, "record"
    assert_includes output, "retime"
    assert_includes output, "attach"
  end

  def test_version_output
    result = invoke(["--version"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "ace-demo"
    assert_includes output, Ace::Demo::VERSION
  end

  def test_record_calls_recorder
    fake_recorder = Class.new do
      def record(tape_ref:, output:, format:, playback_speed: nil, retime_output: nil)
        raise "bad tape" unless tape_ref == "hello"
        raise "bad output" unless output == "/tmp/x.gif"
        raise "bad format" unless format.nil?
        raise "bad playback_speed" unless playback_speed.nil?
        raise "bad retime_output" unless retime_output.nil?

        "/tmp/x.gif"
      end
    end.new

    Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
      result = invoke(["record", "hello", "--output", "/tmp/x.gif"])
      assert_includes result[:stdout], "Recorded: /tmp/x.gif"
    end
  end

  def test_record_yaml_path_calls_demo_recorder
    Dir.mktmpdir("ace_demo_cli_yaml") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      File.write(tape_path, "description: demo\n")

      fake_recorder = Class.new do
        def record(tape_ref:, output:, format:, playback_speed: nil, retime_output: nil, **_kwargs)
          raise "bad tape" unless tape_ref.end_with?(".tape.yml")
          raise "bad output" unless output.nil?
          raise "bad format" unless format == "gif"
          raise "bad playback_speed" unless playback_speed.nil?
          raise "bad retime_output" unless retime_output.nil?

          ".ace-local/demo/yaml.gif"
        end
      end.new

      Ace::Demo::Atoms::DemoYamlParser.stub(:parse_file, {"settings" => {}, "scenes" => [{"commands" => [{"type" => "echo hi"}]}]}) do
        Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
          result = invoke(["record", tape_path])
          assert_includes result[:stdout], "Recorded: .ace-local/demo/yaml.gif"
        end
      end
    end
  end

  def test_record_yaml_passes_backend_override_to_demo_recorder
    Dir.mktmpdir("ace_demo_cli_yaml_backend") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      File.write(tape_path, "description: demo\n")

      fake_recorder = Class.new do
        attr_reader :kwargs

        def record(**kwargs)
          @kwargs = kwargs
          Ace::Demo::Models::RecordingResult.new(
            backend: "vhs",
            visual_path: ".ace-local/demo/yaml.webm"
          )
        end
      end.new

      Ace::Demo::Atoms::DemoYamlParser.stub(:parse_file, {"settings" => {}, "scenes" => [{"commands" => [{"type" => "echo hi"}]}]}) do
        Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
          result = invoke(["record", tape_path, "--backend", "vhs", "--format", "webm"])
          assert_includes result[:stdout], "Recorded backend: vhs"
          assert_equal "vhs", fake_recorder.kwargs[:backend]
        end
      end
    end
  end

  def test_record_yaml_dry_run_defaults_preview_format_to_gif_when_yaml_not_found
    result = invoke(["record", "./demo.tape.yml", "--dry-run"])
    assert_includes result[:stdout], "[dry-run] Would record tape: ./demo.tape.yml (format: gif)"
  end

  def test_record_yaml_dry_run_reads_format_from_resolved_yaml_spec
    Dir.mktmpdir("ace_demo_cli") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      File.write(
        tape_path,
        <<~YAML
          description: demo
          tags: []
          settings:
            backend: vhs
            format: webm
          scenes:
            - name: one
              commands:
                - type: echo hi
                  sleep: 1s
        YAML
      )

      result = invoke(["record", tape_path, "--dry-run"])
      assert_includes result[:stdout], "[dry-run] Would record tape: #{tape_path} (format: webm)"
    end
  end

  def test_record_yaml_dry_run_rejects_unsupported_yaml_format
    Dir.mktmpdir("ace_demo_cli") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      File.write(
        tape_path,
        <<~YAML
          description: demo
          settings:
            format: avi
          scenes:
            - name: one
              commands:
                - type: echo hi
                  sleep: 1s
        YAML
      )

      result = invoke(["record", tape_path, "--dry-run"])
      assert_equal 1, result[:result]
      assert_includes result[:stderr], "Unsupported format: avi"
    end
  end

  def test_record_yaml_uses_tape_playback_speed_and_output_defaults
    Dir.mktmpdir("ace_demo_cli_yaml_defaults") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      final_output = File.join(dir, "docs", "demo.gif")
      File.write(tape_path, "description: demo\n")

      fake_recorder = Class.new do
        attr_reader :kwargs

        def initialize(return_path)
          @return_path = return_path
        end

        def record(**kwargs)
          @kwargs = kwargs
          @return_path
        end
      end.new(final_output)

      Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
        Ace::Demo::Atoms::DemoYamlParser.stub(:parse_file, {
          "settings" => {"format" => "gif", "playback_speed" => "4x", "output" => final_output},
          "scenes" => [{"name" => "one", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}]
        }) do
          result = invoke(["record", tape_path])
          assert_includes result[:stdout], "Recorded: #{final_output}"
          assert_equal "4x", fake_recorder.kwargs[:playback_speed]
          assert_nil fake_recorder.kwargs[:output]
          assert_equal final_output, fake_recorder.kwargs[:retime_output]
          assert_equal "4x", fake_recorder.kwargs.dig(:yaml_spec, "settings", "playback_speed")
        end
      end
    end
  end

  def test_record_yaml_cli_flags_override_tape_settings
    Dir.mktmpdir("ace_demo_cli_yaml_override") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      tape_output = File.join(dir, "docs", "from-tape.gif")
      cli_output = File.join(dir, "docs", "from-cli.gif")
      File.write(tape_path, "description: demo\n")

      fake_recorder = Class.new do
        attr_reader :kwargs

        def initialize(return_path)
          @return_path = return_path
        end

        def record(**kwargs)
          @kwargs = kwargs
          @return_path
        end
      end.new(cli_output)

      Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
        Ace::Demo::Atoms::DemoYamlParser.stub(:parse_file, {
          "settings" => {"format" => "gif", "playback_speed" => "4x", "output" => tape_output},
          "scenes" => [{"name" => "one", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}]
        }) do
          result = invoke(["record", tape_path, "--playback-speed", "2x", "--output", cli_output])
          assert_includes result[:stdout], "Recorded: #{cli_output}"
          assert_equal "2x", fake_recorder.kwargs[:playback_speed]
          assert_nil fake_recorder.kwargs[:output]
          assert_equal cli_output, fake_recorder.kwargs[:retime_output]
          assert_equal "4x", fake_recorder.kwargs.dig(:yaml_spec, "settings", "playback_speed")
        end
      end
    end
  end

  def test_record_yaml_uses_tape_speed_with_cli_output_override
    Dir.mktmpdir("ace_demo_cli_yaml_output_override") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      cli_output = File.join(dir, "docs", "from-cli.gif")
      File.write(tape_path, "description: demo\n")

      fake_recorder = Class.new do
        attr_reader :kwargs

        def initialize(return_path)
          @return_path = return_path
        end

        def record(**kwargs)
          @kwargs = kwargs
          @return_path
        end
      end.new(cli_output)

      Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
        Ace::Demo::Atoms::DemoYamlParser.stub(:parse_file, {
          "settings" => {"format" => "gif", "playback_speed" => "4x"},
          "scenes" => [{"name" => "one", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}]
        }) do
          result = invoke(["record", tape_path, "--output", cli_output])
          assert_includes result[:stdout], "Recorded: #{cli_output}"
          assert_equal "4x", fake_recorder.kwargs[:playback_speed]
          assert_nil fake_recorder.kwargs[:output]
          assert_equal cli_output, fake_recorder.kwargs[:retime_output]
          assert_equal "4x", fake_recorder.kwargs.dig(:yaml_spec, "settings", "playback_speed")
        end
      end
    end
  end

  def test_record_yaml_dry_run_shows_exact_retime_target_when_output_is_defined
    Dir.mktmpdir("ace_demo_cli_yaml_dry_run") do |dir|
      tape_path = File.join(dir, "demo.tape.yml")
      final_output = File.join(dir, "docs", "demo.gif")
      File.write(tape_path, "description: demo\n")

      Ace::Demo::Atoms::DemoYamlParser.stub(:parse_file, {
        "settings" => {"format" => "gif", "playback_speed" => "4x", "output" => final_output},
        "scenes" => [{"name" => "one", "commands" => [{"type" => "echo hi", "sleep" => "1s"}]}]
      }) do
        result = invoke(["record", tape_path, "--dry-run"])
        assert_includes result[:stdout], "[dry-run] Would retime recording to 4x: #{final_output}"
      end
    end
  end

  def test_record_invalid_format_returns_error
    result = invoke(["record", "hello", "--format", "avi"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Unsupported format"
  end

  def test_attach_calls_attacher
    fake_attacher = Class.new do
      def attach(file:, pr:, dry_run:)
        raise "bad file" unless file == ".ace-local/demo/hello.gif"
        raise "bad pr" unless pr == "123"
        raise "bad dry_run" unless dry_run == false

        {
          dry_run: false,
          pr: pr,
          asset_name: "hello-1700.gif",
          asset_url: "https://github.com/org/repo/releases/download/demo-assets/hello-1700.gif",
          comment_body: "## Demo: hello"
        }
      end
    end.new

    Ace::Demo::Organisms::DemoAttacher.stub(:new, fake_attacher) do
      result = invoke(["attach", ".ace-local/demo/hello.gif", "--pr", "123"])
      assert_includes result[:stdout], "Uploaded: hello-1700.gif"
      assert_includes result[:stdout], "Posted demo comment to PR #123"
    end
  end

  def test_record_with_pr_attaches_after_recording
    fake_recorder = Class.new do
      def record(tape_ref:, output:, format:, playback_speed: nil, retime_output: nil)
        raise "bad tape" unless tape_ref == "hello"
        raise "bad output" unless output.nil?
        raise "bad format" unless format.nil?
        raise "bad playback_speed" unless playback_speed.nil?
        raise "bad retime_output" unless retime_output.nil?
        ".ace-local/demo/hello.gif"
      end
    end.new

    fake_attacher = Class.new do
      def attach(file:, pr:, dry_run:)
        raise "bad file" unless file == ".ace-local/demo/hello.gif"
        raise "bad pr" unless pr == "123"
        raise "bad dry_run" unless dry_run == false

        {
          dry_run: false,
          pr: pr,
          asset_name: "hello-1700.gif",
          asset_url: "https://github.com/org/repo/releases/download/demo-assets/hello-1700.gif",
          comment_body: "## Demo: hello"
        }
      end
    end.new

    Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
      Ace::Demo::Organisms::DemoAttacher.stub(:new, fake_attacher) do
        result = invoke(["record", "hello", "--pr", "123"])
        assert_includes result[:stdout], "Recorded: .ace-local/demo/hello.gif"
        assert_includes result[:stdout], "Uploaded: hello-1700.gif"
      end
    end
  end

  def test_record_with_pr_dry_run_prints_preview
    result = invoke(["record", "hello", "--pr", "123", "--dry-run"])
    assert_includes result[:stdout], "[dry-run] Would record tape: hello (format: gif)"
  end

  def test_record_with_playback_speed_retimes_and_attaches_retimed_output
    fake_recorder = Class.new do
      def record(tape_ref:, output:, format:, playback_speed: nil, retime_output: nil)
        raise "bad tape" unless tape_ref == "hello"
        raise "bad output" unless output.nil?
        raise "bad format" unless format.nil?
        raise "bad playback_speed" unless playback_speed.nil?
        raise "bad retime_output" unless retime_output.nil?
        ".ace-local/demo/hello.gif"
      end
    end.new

    fake_retimer = Class.new do
      attr_reader :kwargs

      def retime(**kwargs)
        @kwargs = kwargs
        {
          input_path: kwargs[:input_path],
          output_path: ".ace-local/demo/hello-4x.gif",
          speed: kwargs[:speed],
          dry_run: false
        }
      end
    end.new

    fake_attacher = Class.new do
      def attach(file:, pr:, dry_run:)
        raise "bad file" unless file == ".ace-local/demo/hello-4x.gif"
        raise "bad pr" unless pr == "123"
        raise "bad dry_run" unless dry_run == false
        {
          dry_run: false,
          pr: pr,
          asset_name: "hello-4x.gif",
          asset_url: "https://github.com/org/repo/releases/download/demo-assets/hello-4x.gif",
          comment_body: "## Demo: hello"
        }
      end
    end.new

    Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
      Ace::Demo::Molecules::MediaRetimer.stub(:new, fake_retimer) do
        Ace::Demo::Organisms::DemoAttacher.stub(:new, fake_attacher) do
          result = invoke(["record", "hello", "--playback-speed", "4x", "--pr", "123"])
          assert_includes result[:stdout], "Recorded: .ace-local/demo/hello.gif"
          assert_includes result[:stdout], "Retimed: .ace-local/demo/hello-4x.gif (4x)"
          assert_includes result[:stdout], "Uploaded: hello-4x.gif"
          assert_equal ".ace-local/demo/hello.gif", fake_retimer.kwargs[:input_path]
          assert_equal "4x", fake_retimer.kwargs[:speed]
        end
      end
    end
  end

  def test_record_uses_configured_playback_speed
    fake_recorder = Class.new do
      def record(tape_ref:, output:, format:, playback_speed: nil, retime_output: nil)
        raise "bad tape" unless tape_ref == "hello"
        raise "bad format" unless format.nil?
        raise "bad playback_speed" unless playback_speed.nil?
        raise "bad retime_output" unless retime_output.nil?
        ".ace-local/demo/hello.gif"
      end
    end.new

    fake_retimer = Class.new do
      attr_reader :speed

      def retime(**kwargs)
        @speed = kwargs[:speed]
        {
          input_path: kwargs[:input_path],
          output_path: ".ace-local/demo/hello-8x.gif",
          speed: kwargs[:speed],
          dry_run: false
        }
      end
    end.new

    Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
      Ace::Demo::Molecules::MediaRetimer.stub(:new, fake_retimer) do
        Ace::Demo.stub(:config, {"record" => {"postprocess" => {"playback_speed" => "8x"}}}) do
          result = invoke(["record", "hello"])
          assert_includes result[:stdout], "Retimed: .ace-local/demo/hello-8x.gif (8x)"
          assert_equal "8x", fake_retimer.speed
        end
      end
    end
  end

  def test_record_inline_with_commands
    fake_inline = Class.new do
      attr_reader :recorded_args

      def record(**kwargs)
        @recorded_args = kwargs
        {
          output_path: ".ace-local/demo/20260305-120000/my-demo.gif",
          tape_path: ".ace-local/demo/20260305-120000/my-demo.tape",
          session_dir: ".ace-local/demo/20260305-120000"
        }
      end
    end.new

    Ace::Demo::Molecules::InlineRecorder.stub(:new, fake_inline) do
      result = invoke(["record", "my-demo", "--", "echo hello"])
      assert_includes result[:stdout], "Recorded: .ace-local/demo/20260305-120000/my-demo.gif"
      assert_includes result[:stdout], "Tape: .ace-local/demo/20260305-120000/my-demo.tape"
      assert_equal "my-demo", fake_inline.recorded_args[:name]
      assert_equal ["echo hello"], fake_inline.recorded_args[:commands]
      assert_equal "gif", fake_inline.recorded_args[:format]
    end
  end

  def test_record_inline_with_multiple_commands
    fake_inline = Class.new do
      attr_reader :recorded_args

      def record(**kwargs)
        @recorded_args = kwargs
        {
          output_path: ".ace-local/demo/20260305-120000/my-demo.gif",
          tape_path: ".ace-local/demo/20260305-120000/my-demo.tape",
          session_dir: ".ace-local/demo/20260305-120000"
        }
      end
    end.new

    Ace::Demo::Molecules::InlineRecorder.stub(:new, fake_inline) do
      result = invoke(["record", "my-demo", "--", "git status", "make deploy"])
      assert_includes result[:stdout], "Recorded:"
      assert_equal ["git status", "make deploy"], fake_inline.recorded_args[:commands]
    end
  end

  def test_record_inline_with_options
    fake_inline = Class.new do
      attr_reader :recorded_args

      def record(**kwargs)
        @recorded_args = kwargs
        {
          output_path: ".ace-local/demo/20260305-120000/my-demo.webm",
          tape_path: ".ace-local/demo/20260305-120000/my-demo.tape",
          session_dir: ".ace-local/demo/20260305-120000"
        }
      end
    end.new

    Ace::Demo::Molecules::InlineRecorder.stub(:new, fake_inline) do
      result = invoke(["record", "my-demo", "--format", "webm", "--timeout", "3s",
        "--width", "1200", "--height", "600", "--font-size", "20",
        "--desc", "A test", "--tags", "ci,test",
        "--", "echo hello"])
      assert_includes result[:stdout], "Recorded:"
      assert_equal "webm", fake_inline.recorded_args[:format]
      assert_equal "3s", fake_inline.recorded_args[:timeout]
      assert_equal 1200, fake_inline.recorded_args[:width].to_i
      assert_equal 600, fake_inline.recorded_args[:height].to_i
      assert_equal 20, fake_inline.recorded_args[:font_size].to_i
      assert_equal "A test", fake_inline.recorded_args[:description]
      assert_equal "ci,test", fake_inline.recorded_args[:tags]
    end
  end

  def test_record_rejects_mp4_with_actionable_guidance
    result = invoke(["record", "hello", "--format", "mp4"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Unsupported format: mp4"
    assert_includes result[:stderr], "--backend vhs --format webm"
  end

  def test_record_inline_dry_run_prints_tape_content
    result = invoke(["record", "my-demo", "--dry-run", "--", "echo hello"])

    assert_includes result[:stdout], 'Type "echo hello"'
    assert_includes result[:stdout], "Output"
  end

  def test_record_inline_with_pr
    fake_inline = Class.new do
      def record(**_kwargs)
        {
          output_path: ".ace-local/demo/20260305-120000/my-demo.gif",
          tape_path: ".ace-local/demo/20260305-120000/my-demo.tape",
          session_dir: ".ace-local/demo/20260305-120000"
        }
      end
    end.new

    fake_attacher = Class.new do
      def attach(file:, pr:, dry_run:)
        raise "bad file" unless file == ".ace-local/demo/20260305-120000/my-demo.gif"
        raise "bad pr" unless pr == "123"
        raise "bad dry_run" unless dry_run == false

        {
          dry_run: false,
          pr: pr,
          asset_name: "my-demo-1700.gif",
          asset_url: "https://github.com/org/repo/releases/download/demo-assets/my-demo-1700.gif",
          comment_body: "## Demo: my-demo"
        }
      end
    end.new

    Ace::Demo::Molecules::InlineRecorder.stub(:new, fake_inline) do
      Ace::Demo::Organisms::DemoAttacher.stub(:new, fake_attacher) do
        result = invoke(["record", "my-demo", "--pr", "123", "--", "echo hello"])
        assert_includes result[:stdout], "Recorded:"
        assert_includes result[:stdout], "Uploaded: my-demo-1700.gif"
      end
    end
  end

  def test_record_without_args_uses_tape_path
    fake_recorder = Class.new do
      def record(tape_ref:, output:, format:, playback_speed: nil, retime_output: nil)
        raise "bad tape" unless tape_ref == "hello"
        raise "bad format" unless format.nil?
        raise "bad playback_speed" unless playback_speed.nil?
        raise "bad retime_output" unless retime_output.nil?
        ".ace-local/demo/hello.gif"
      end
    end.new

    Ace::Demo::Organisms::DemoRecorder.stub(:new, fake_recorder) do
      result = invoke(["record", "hello"])
      assert_includes result[:stdout], "Recorded: .ace-local/demo/hello.gif"
    end
  end

  def test_record_inline_from_stdin
    fake_inline = Class.new do
      attr_reader :recorded_args

      def record(**kwargs)
        @recorded_args = kwargs
        {
          output_path: ".ace-local/demo/20260305-120000/stdin-demo.gif",
          tape_path: ".ace-local/demo/20260305-120000/stdin-demo.tape",
          session_dir: ".ace-local/demo/20260305-120000"
        }
      end
    end.new

    reader, writer = IO.pipe
    writer.puts "git status"
    writer.puts "make deploy"
    writer.close

    original_stdin = $stdin
    $stdin = reader

    Ace::Demo::Molecules::InlineRecorder.stub(:new, fake_inline) do
      result = invoke(["record", "stdin-demo"])
      assert_includes result[:stdout], "Recorded:"
      assert_equal ["git status", "make deploy"], fake_inline.recorded_args[:commands]
    end

    $stdin = original_stdin
    reader.close
  end

  def test_attach_requires_pr
    result = invoke(["attach", ".ace-local/demo/hello.gif"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "PR number is required"
  end

  def test_list_prints_discovered_tapes
    fake_scanner = Class.new do
      def list
        [
          {name: "hello", description: "Built-in echo demo", source: ".ace-defaults/demo/tapes/"},
          {name: "quick-check", description: "Project quick check demo", source: ".ace/demo/tapes/"}
        ]
      end
    end.new

    Ace::Demo::Molecules::TapeScanner.stub(:new, fake_scanner) do
      result = invoke(["list"])

      assert_equal "", result[:stderr]
      assert_includes result[:stdout], "Available demo tapes:"
      assert_includes result[:stdout], "hello"
      assert_includes result[:stdout], "Built-in echo demo"
      assert_includes result[:stdout], "(.ace-defaults/demo/tapes/)"
    end
  end

  def test_show_prints_metadata_and_contents
    fake_scanner = Class.new do
      def find(name)
        raise "bad name" unless name == "hello"

        {
          name: "hello",
          display_path: ".ace-defaults/demo/tapes/hello.tape",
          description: "Built-in echo demo",
          metadata: {
            "description" => "Built-in echo demo",
            "tags" => "example, getting-started",
            "author" => "ace"
          },
          content: "Output .ace-local/demo/hello.gif\n"
        }
      end
    end.new

    Ace::Demo::Molecules::TapeScanner.stub(:new, fake_scanner) do
      result = invoke(["show", "hello"])

      assert_equal "", result[:stderr]
      assert_includes result[:stdout], "Tape: hello"
      assert_includes result[:stdout], "Source: .ace-defaults/demo/tapes/hello.tape"
      assert_includes result[:stdout], "Description: Built-in echo demo"
      assert_includes result[:stdout], "Tags: example, getting-started"
      assert_includes result[:stdout], "--- Contents ---"
      assert_includes result[:stdout], "Output .ace-local/demo/hello.gif"
    end
  end

  def test_show_not_found_returns_error
    fake_scanner = Class.new do
      def find(_name)
        raise Ace::Demo::TapeNotFoundError, "Tape not found: missing\nAvailable tapes: hello"
      end
    end.new

    Ace::Demo::Molecules::TapeScanner.stub(:new, fake_scanner) do
      result = invoke(["show", "missing"])

      assert_equal 1, result[:result]
      assert_includes result[:stderr], "Tape not found: missing"
      assert_includes result[:stderr], "Available tapes: hello"
    end
  end
end
