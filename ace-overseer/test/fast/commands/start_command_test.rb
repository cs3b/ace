# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/overseer/cli/commands/start"

module Commands
  # Task 8xs.t.pu0.1: `ace-overseer start` CLI semantics — exit-0 only
  # for a ready start/reuse, a blocked start raises, dry-run plans.
  class StartCommandTest < Minitest::Test
    class FakeOrchestrator
      def initialize(report)
        @report = report
      end

      def bootstrap(dry_run: false)
        @report
      end

      def call(dry_run: false)
        @report
      end
    end

    def run_command(report)
      out, = capture_io do
        Ace::Overseer::CLI::Commands::Start.new(
          orchestrator: FakeOrchestrator.new(report)
        ).call(dry_run: false, format: "json", quiet: false)
      end
      out
    end

    def test_foreground_report_execs_the_harness_without_rendering_a_success_report
      command = ["pi", "--model", "zai/glm-5.3-flash"]
      launched = nil
      out, = capture_io do
        Ace::Overseer::CLI::Commands::Start.new(
          orchestrator: FakeOrchestrator.new({"status" => "foreground", "command" => command}),
          launcher: ->(argv) { launched = argv }
        ).call
      end
      assert_equal command, launched
      assert_empty out
    end

    def test_default_launcher_replaces_the_cli_process
      script = <<~RUBY
        require "ace/overseer"
        $stdout.sync = true
        puts Process.pid
        report = {"status" => "foreground", "command" => [RbConfig.ruby, "-e", "puts Process.pid"]}
        orchestrator = Object.new
        orchestrator.define_singleton_method(:bootstrap) { |**| report }
        Ace::Overseer::CLI::Commands::Start.new(orchestrator: orchestrator).call
        abort "exec returned"
      RUBY
      out, err, status = Open3.capture3(RbConfig.ruby, "-e", script)
      assert status.success?, err
      assert_equal 2, out.lines.size
      assert_equal out.lines[0], out.lines[1], "harness must keep the calling CLI pid"
    end

    def test_real_bare_cli_execs_in_current_cwd_without_any_herdr_call_or_environment
      Dir.mktmpdir("bare-start") do |root|
        bin = File.join(root, "bin")
        FileUtils.mkdir_p(bin)
        marker = File.join(root, "herdr-called")
        File.write(File.join(bin, "herdr"), "#!/bin/sh\ntouch #{Shellwords.escape(marker)}\nexit 99\n")
        File.write(File.join(bin, "pi"), <<~'RUBY')
          #!/usr/bin/env ruby
          puts "AFTER=#{Process.pid}"
          puts "CWD=#{Dir.pwd}"
          puts "ARGS=#{ARGV.join('|')}"
        RUBY
        FileUtils.chmod(0o755, [File.join(bin, "herdr"), File.join(bin, "pi")])
        script = <<~'RUBY'
          require "ace/overseer"
          Dir.chdir(ARGV.fetch(0))
          $stdout.sync = true
          puts "BEFORE=#{Process.pid}"
          Ace::Overseer::CLI::Commands::Start.new(config: {}).call
          abort "foreground exec returned"
        RUBY
        env = ENV.keys.grep(/\AHERDR/).to_h { |key| [key, nil] }
        env["PATH"] = [bin, ENV.fetch("PATH")].join(File::PATH_SEPARATOR)
        out, err, status = Open3.capture3(env, RbConfig.ruby, "-e", script, root)
        assert status.success?, err
        before = out[/BEFORE=(\d+)/, 1]
        assert before
        assert_equal before, out[/AFTER=(\d+)/, 1]
        assert_includes out, "CWD=#{root}"
        assert_includes out, "ARGS=--model|zai/glm-5.3-flash|--thinking|high|--append-system-prompt|"
        assert_includes out, "lab-start.wf.md"
        refute File.exist?(marker), "bare start must never invoke Herdr"
      end
    end

    def test_started_report_renders_json_and_exits_clean
      out = run_command({"status" => "started", "root" => "/lab/projects/ace",
        "message" => "session started"})

      parsed = JSON.parse(out)
      assert_equal "started", parsed["status"]
      assert_equal "/lab/projects/ace", parsed["root"]
    end

    def test_blocked_report_raises_a_cli_error
      error = assert_raises(Ace::Support::Cli::Error) do
        run_command({"status" => "blocked", "message" => "no start section"})
      end
      assert_equal "no start section", error.message
    end

    def test_dry_run_report_exits_clean
      out = run_command({"status" => "dry_run", "message" => "plan only"})
      assert_equal "dry_run", JSON.parse(out)["status"]
    end
  end
end
