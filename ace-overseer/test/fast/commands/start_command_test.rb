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
