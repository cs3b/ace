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
        orchestrator.define_singleton_method(:call) { |**| report }
        Ace::Overseer::CLI::Commands::Start.new(orchestrator: orchestrator).call
        abort "exec returned"
      RUBY
      out, err, status = Open3.capture3(RbConfig.ruby, "-e", script)
      assert status.success?, err
      assert_equal 2, out.lines.size
      assert_equal out.lines[0], out.lines[1], "harness must keep the calling CLI pid"
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
