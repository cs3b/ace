# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/overseer/cli/commands/start"
require "shellwords"

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

      def reconcile(dry_run: false)
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

    def test_default_launcher_waits_for_real_child_then_cleans_credentials_and_returns
      credentials = Dir.mktmpdir("ace-session-")
      File.write(File.join(credentials, "auth.json"), "{}")
      environment_file = File.join(credentials, "environment.json")
      File.write(environment_file, JSON.generate("EXPECTED_VALUE" => "fixture"))
      environment = Object.new
      environment.define_singleton_method(:with_environment) do |**_, &block|
        block.call(environment_file, credentials, [])
      end
      child = 'abort "environment missing" unless ENV["EXPECTED_VALUE"] == "fixture"; puts "CHILD=#{Process.pid}"'
      report = {"status" => "foreground", "scope" => "lab", "root" => Dir.pwd,
        "command" => [RbConfig.ruby, "-e", child]}
      out, err = capture_subprocess_io do
        Ace::Overseer::Molecules::SessionEnvironment.stub(:new, environment) do
          Ace::Overseer::CLI::Commands::Start.new(orchestrator: FakeOrchestrator.new(report)).call
        end
        assert File.directory?(credentials), "keep transcript evidence directory"
        refute File.exist?(File.join(credentials, "auth.json"))
        puts "RETURNED=#{Process.pid}"
      end
      child_pid = out[/CHILD=(\d+)/, 1]
      assert child_pid, err
      refute_equal Process.pid.to_s, child_pid
      assert_equal Process.pid.to_s, out[/RETURNED=(\d+)/, 1]
    ensure
      FileUtils.remove_entry(credentials) if credentials && File.exist?(credentials)
    end

    def test_real_bare_cli_waits_in_current_cwd_without_any_herdr_call_or_environment
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
          puts "RETURNED=#{Process.pid}"
        RUBY
        env = ENV.keys.grep(/\AHERDR/).to_h { |key| [key, nil] }
        env["PATH"] = [bin, ENV.fetch("PATH")].join(File::PATH_SEPARATOR)
        out, err, status = Open3.capture3(env, RbConfig.ruby, "-e", script, root)
        assert status.success?, err
        before = out[/BEFORE=(\d+)/, 1]
        assert before
        refute_equal before, out[/AFTER=(\d+)/, 1]
        assert_equal before, out[/RETURNED=(\d+)/, 1]
        assert_includes out, "CWD=#{File.realpath(root)}"
        assert_includes out, "ARGS=--model|zai/glm-5.3-flash|--thinking|high|--append-system-prompt|"
        assert_includes out, "lab-start.wf.md"
        refute File.exist?(marker), "bare start must never invoke Herdr"
      end
    end

    def test_project_scope_refuses_reconcile_before_orchestration
      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Overseer::CLI::Commands::Start.new(config: {}).call(scope: "project", reconcile: true)
      end
      assert_match(/requires lab scope/, error.message)
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

    def test_unconfirmed_project_start_returns_an_error_and_keeps_the_report
      %w[started reused].each do |status|
        out, = capture_io do
          error = assert_raises(Ace::Support::Cli::Error) do
            Ace::Overseer::CLI::Commands::Start.new(orchestrator: FakeOrchestrator.new(
              {"status" => status, "prompt_failed" => true, "message" => "agent blocked"}
            )).call(scope: "project", format: "json")
          end
          assert_equal "agent blocked", error.message
        end
        assert_equal true, JSON.parse(out).fetch("prompt_failed")
      end
    end

    def test_reconcile_table_includes_each_project_failure_and_its_pane
      report = {"status" => "partial", "message" => "0/1 project overseers ready",
                "projects" => [{"id" => "ace", "path" => "/lab/ace", "status" => "started",
                                "pane" => "w2:p2", "prompt_failed" => true,
                                "message" => "first turn unconfirmed; inspect the existing session"}]}
      out, = capture_io do
        error = assert_raises(Ace::Support::Cli::Error) do
          Ace::Overseer::CLI::Commands::Start.new(orchestrator: FakeOrchestrator.new(report)).call(reconcile: true)
        end
        assert_equal "0/1 project overseers ready", error.message
      end
      assert_includes out, "ace"
      assert_includes out, "/lab/ace"
      assert_includes out, "w2:p2"
      assert_includes out, "first turn unconfirmed; inspect the existing session"
    end

    def test_dry_run_report_exits_clean
      out = run_command({"status" => "dry_run", "message" => "plan only"})
      assert_equal "dry_run", JSON.parse(out)["status"]
    end

    def test_dry_run_table_shows_foreground_command_as_reproducible_argv
      report = {"status" => "dry_run", "command" => ["pi", "--model", "model with spaces", "first turn"]}
      out, = capture_io do
        Ace::Overseer::CLI::Commands::Start.new(orchestrator: FakeOrchestrator.new(report)).call(dry_run: true)
      end
      line = out.lines.find { |item| item.include?("command:") }
      assert line
      assert_equal report["command"], Shellwords.split(line.split("command:", 2).last.strip)
    end

    def test_interrupt_warns_about_uncertain_start_and_exits_130
      orchestrator = Object.new
      orchestrator.define_singleton_method(:bootstrap) { |**| raise Interrupt }
      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Overseer::CLI::Commands::Start.new(orchestrator: orchestrator).call
      end
      assert_equal 130, error.exit_code
      assert_match(/inspect.*session/i, error.message)
    end
  end
end
