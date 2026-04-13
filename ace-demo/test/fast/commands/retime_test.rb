# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/support/cli"
require "tmpdir"
require "fileutils"

class RetimeTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_retime_cmd")
    @orig = Dir.pwd
    Dir.chdir(@tmp)
    @input = File.join(@tmp, "hello.gif")
    File.write(@input, "GIF89a")
  end

  def teardown
    Dir.chdir(@orig)
    FileUtils.rm_rf(@tmp)
    super
  end

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

  def test_retime_calls_processor
    fake = Class.new do
      attr_reader :kwargs

      def retime(**kwargs)
        @kwargs = kwargs
        {
          input_path: kwargs[:input_path],
          output_path: "/tmp/hello-4x.gif",
          speed: "4x",
          dry_run: false
        }
      end
    end.new

    Ace::Demo::Molecules::MediaRetimer.stub(:new, fake) do
      result = invoke(["retime", @input, "--playback-speed", "4x"])
      assert_includes result[:stdout], "Retimed: /tmp/hello-4x.gif (4x)"
      assert_equal "4x", fake.kwargs[:speed]
      refute fake.kwargs[:dry_run]
    end
  end

  def test_retime_dry_run
    fake = Class.new do
      def retime(**_kwargs)
        {
          input_path: "/tmp/in.gif",
          output_path: "/tmp/in-8x.gif",
          speed: "8x",
          dry_run: true
        }
      end
    end.new

    Ace::Demo::Molecules::MediaRetimer.stub(:new, fake) do
      result = invoke(["retime", @input, "--playback-speed", "8x", "--dry-run"])
      assert_includes result[:stdout], "[dry-run] Would retime:"
      assert_includes result[:stdout], "Output: /tmp/in-8x.gif"
    end
  end

  def test_retime_requires_speed
    result = invoke(["retime", @input])
    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Playback speed is required"
  end
end
