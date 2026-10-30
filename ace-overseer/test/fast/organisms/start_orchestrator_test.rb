# frozen_string_literal: true

require_relative "../../test_helper"

module Organisms
  # Task 8xs.t.pu0.1: start/reuse/blocked semantics of the project
  # overseer session, herdr-backed, with a fake executor and a real
  # temporary git repository for root resolution.
  class StartOrchestratorTest < Minitest::Test
    GUIDE = "wfi://overseer/start"

    class FakePaneResult
      def initialize(payload)
        @payload = payload
      end

      def parsed_json
        @payload
      end
    end

    # Minimal HerdrExecutor fake answering by command shape.
    class FakeExecutor
      attr_reader :agent_started, :prompts, :tabs

      def initialize(panes: [], pane_current: {}, pane_of_tab: "p1", alive: true)
        @panes = panes
        @pane_current = pane_current
        @pane_of_tab = pane_of_tab
        @alive = alive
        @agent_started = []
        @prompts = []
        @tabs = []
      end

      def pane_list
        FakePaneResult.new(@panes)
      end

      def pane_current
        FakePaneResult.new(@pane_current)
      end

      def agent_get(_pane)
        raise Ace::Herdr::AgentNotFoundError, "no agent" unless @alive

        FakePaneResult.new({"status" => "idle"})
      end

      def tab_create(workspace_id:, label:, cwd: nil, focus: nil)
        @tabs << {workspace_id: workspace_id, label: label, cwd: cwd}
        FakePaneResult.new({"result" => {"root_pane" => {"pane_id" => @pane_of_tab}}})
      end

      def agent_start(name:, kind:, pane:, timeout_ms:, args: [])
        @agent_started << {name: name, kind: kind, pane: pane, timeout_ms: timeout_ms, args: args}
        FakePaneResult.new({"status" => "ready"})
      end

      def agent_prompt(pane:, text:)
        @prompts << {pane: pane, text: text}
        FakePaneResult.new({"status" => "sent"})
      end
    end

    def setup
      @dir = Dir.mktmpdir
      @root = File.join(@dir, "project")
      FileUtils.mkdir_p(@root)
      @root = File.realpath(@root)
      `git -C #{@root.shellescape} init --quiet`
      File.write(File.join(@root, "guide.md"), "# guide\n")
      @config = {"start" => {"scope" => "project", "profile" => "ovs",
        "instructions" => "wfi://overseer/start"},
        "profiles" => {"ovs" => {"harness" => "pi", "model" => "zai/glm-5.3-flash",
          "thinking" => "high"}}}
      @nav_runner = ->(argv, _cwd) {
        {"status" => "ok", "out" => "#{File.join(@root, 'guide.md')}\n", "err" => ""}
      }
    end

    def teardown
      FileUtils.remove_entry(@dir) if @dir
    end

    def orchestrator(executor, cwd: @root, config: @config, workspace: nil)
      Ace::Overseer::Organisms::StartOrchestrator.new(
        config: config, executor: executor, nav_runner: @nav_runner, workspace: workspace, cwd: cwd
      )
    end

    def test_first_start_creates_one_session_with_profile_and_guide
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call

      assert_equal "started", report["status"]
      assert_equal @root, report["root"]
      assert_equal "overseer-project", report["label"]
      assert_equal "ws1", report["workspace"]
      assert_equal "p1", report["pane"]
      assert_equal({"source" => GUIDE, "path" => File.join(@root, "guide.md")},
        report["instructions"])
      assert_equal 1, executor.tabs.size
      assert_equal @root, executor.tabs.first[:cwd]
      start = executor.agent_started.first
      assert_equal "ace-overseer", start[:name]
      assert_equal "pi", start[:kind]
      assert_equal ["--model", "zai/glm-5.3-flash", "--thinking", "high",
        "--append-system-prompt", File.join(@root, "guide.md")], start[:args]
    end

    def test_first_start_sends_the_first_prompt_after_the_agent_is_started
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call

      assert_equal "started", report["status"]
      assert_equal 1, executor.agent_started.size
      prompt = executor.prompts.find { |entry| entry[:pane] == report["pane"] }
      assert prompt, "a prompt must reach the started agent"
      assert_equal Ace::Overseer::Organisms::StartOrchestrator::FIRST_TURN_PROMPT,
        prompt[:text]
      # the prompt FOLLOWS agent_start: the session's first turn only
      # begins once the interactive agent is ready for input
      assert executor.agent_started.all? { |started| started[:pane] == prompt[:pane] }
    end

    def test_reused_session_is_not_prompted_again
      panes = [{"id" => "p7", "title" => "overseer-project", "cwd" => @root}]
      executor = FakeExecutor.new(panes: panes,
        pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call

      assert_equal "reused", report["status"]
      assert_empty executor.prompts, "reuse must not start a new first turn"
    end

    def test_explicit_workspace_seam_replaces_ambient_resolution
      # no ambient herdr context: pane_current reports no workspace
      executor = FakeExecutor.new(pane_current: {"result" => {}})

      report = orchestrator(executor, workspace: "ws-lab").call

      assert_equal "started", report["status"], report.inspect
      assert_equal "ws-lab", report["workspace"]
      assert_equal "ws-lab", executor.tabs.first[:workspace_id]
    end

    def test_second_start_reuses_the_live_owner_without_a_new_session
      panes = [{"id" => "p7", "title" => "overseer-project", "cwd" => @root}]
      executor = FakeExecutor.new(panes: panes,
        pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call

      assert_equal "reused", report["status"]
      assert_equal "p7", report["pane"]
      assert_empty executor.tabs, "reuse must not create a second session"
      assert_empty executor.agent_started
    end

    def test_installed_toolchain_never_uses_the_checkout_binstub
      # the project CONTAINS an ACE checkout with an executable binstub
      # (the reviewer's case a plain no-sources trial cannot detect)
      binstub = File.join(@root, "bin", "ace-nav")
      FileUtils.mkdir_p(File.dirname(binstub))
      File.write(binstub, "#!/bin/sh\n")
      File.chmod(0o755, binstub)

      seen = []
      nav_runner = ->(argv, _cwd) do
        seen << argv.first
        {"status" => "ok", "out" => "#{File.join(@root, 'guide.md')}\n", "err" => ""}
      end
      installed_launcher = "/gems/3.4.5/bin/ace-nav"

      Ace::Support::Cli::Toolchain.stub :executable, installed_launcher do
        executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})
        report = Ace::Overseer::Organisms::StartOrchestrator.new(
          config: @config, executor: executor, nav_runner: nav_runner, cwd: @root
        ).call

        assert_equal "started", report["status"], report.inspect
      end

      assert_equal [installed_launcher], seen
      refute seen.include?(binstub), "installed mode must never reach the checkout binstub"
    end

    def test_unavailable_installed_executable_blocks_the_start
      failing = ->(*_args) { raise Ace::Support::Cli::Toolchain::Error, "installed executable ace-nav unavailable" }
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})

      Ace::Support::Cli::Toolchain.stub :executable, failing do
        report = Ace::Overseer::Organisms::StartOrchestrator.new(
          config: @config, executor: executor, nav_runner: @nav_runner, cwd: @root
        ).call

        assert_equal "blocked", report["status"]
        assert_match(/cannot resolve the ace-nav executable/, report["message"])
      end
      assert_empty executor.tabs
    end

    def test_herdr_pane_list_failure_surfaces_as_blocked_naming_herdr
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})
      def executor.pane_list
        raise Ace::Herdr::CommandError, "herdr exited 1: socket closed"
      end

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_match(/herdr failed while preparing the overseer session/, report["message"])

      # dry-run probes no herdr state, so a failing herdr cannot break it
      dry = orchestrator(executor).call(dry_run: true)
      assert_equal "dry_run", dry["status"]
    end

    def test_herdr_agent_probe_failure_surfaces_as_blocked_naming_herdr
      panes = [{"id" => "p7", "title" => "overseer-project", "cwd" => @root}]
      executor = FakeExecutor.new(panes: panes,
        pane_current: {"result" => {"workspace_id" => "ws1"}})
      def executor.agent_get(_pane)
        raise Ace::Herdr::CommandError, "agent probe failed"
      end

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_match(/herdr failed while preparing the overseer session/, report["message"])
    end

    def test_prompt_failure_after_a_started_agent_is_reported_distinctly
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})
      def executor.agent_prompt(pane:, text:)
        raise Ace::Herdr::CommandError, "prompt pipe closed"
      end

      report = orchestrator(executor).call

      assert_equal "started", report["status"],
        "a live, idle agent must never be reported as not started"
      assert_equal 1, executor.agent_started.size
      assert_equal true, report["prompt_failed"]
      assert_match(/agent is started and idle, but the first prompt failed/, report["message"])
    end

    def test_live_owner_with_a_foreign_cwd_is_a_conflict_never_taken_over
      other = File.join(@dir, "other-project")
      FileUtils.mkdir_p(other)
      `git -C #{other.shellescape} init --quiet`
      panes = [{"id" => "p7", "title" => "overseer-project", "cwd" => other}]
      executor = FakeExecutor.new(panes: panes,
        pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_match(/refusing to take over a foreign session/, report["message"])
      assert_empty executor.tabs
    end

    def test_dead_owner_is_replaced_with_the_new_identity_reported
      panes = [{"id" => "p7", "title" => "overseer-project", "cwd" => @root}]
      executor = FakeExecutor.new(panes: panes, alive: false, pane_of_tab: "p9",
        pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call

      assert_equal "started", report["status"]
      assert_equal "p9", report["pane"]
      assert_equal "p7", report["replaced_pane"]
    end

    def test_unprepared_directory_without_start_configuration_blocks
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor, config: {}).call

      assert_equal "blocked", report["status"]
      assert_match(/requires an explicit 'start' section/, report["message"])
      assert_empty executor.tabs
    end

    def test_directory_outside_any_repository_blocks
      outside = File.join(@dir, "plain")
      FileUtils.mkdir_p(outside)
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor, cwd: outside).call

      assert_equal "blocked", report["status"]
      assert_match(/cannot resolve the project root/, report["message"])
    end

    def test_dry_run_reports_the_plan_and_touches_nothing
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor).call(dry_run: true)

      assert_equal "dry_run", report["status"]
      assert_equal @root, report["root"]
      assert_equal "ovs", report["profile"]
      assert_empty executor.tabs
      assert_empty executor.agent_started
    end

    def test_subdirectory_and_worktree_resolve_to_the_same_owner
      subdir = File.join(@root, "app")
      FileUtils.mkdir_p(subdir)
      panes = [{"id" => "p7", "title" => "overseer-project", "cwd" => @root}]
      executor = FakeExecutor.new(panes: panes,
        pane_current: {"result" => {"workspace_id" => "ws1"}})

      report = orchestrator(executor, cwd: subdir).call

      assert_equal "reused", report["status"], "a subdirectory start must find the same owner"

      # a linked worktree of the same repository is the same project
      worktree = File.join(@dir, "linked-worktree")
      `git -C #{@root.shellescape} worktree add --quiet #{worktree.shellescape} 2>/dev/null`
      skip "git worktree unavailable" unless File.directory?(File.join(worktree, ".git"))

      report = orchestrator(executor, cwd: worktree).call
      assert_equal "reused", report["status"]
      assert_equal @root, report["root"], "a worktree maps to the main project root"
    end

    def test_unresolvable_instructions_block_the_start
      executor = FakeExecutor.new(pane_current: {"result" => {"workspace_id" => "ws1"}})
      failing_nav = ->(_argv, _cwd) { {"status" => "exit 1", "out" => "", "err" => "nope"} }

      report = Ace::Overseer::Organisms::StartOrchestrator.new(
        config: @config, executor: executor, nav_runner: failing_nav, cwd: @root
      ).call

      assert_equal "blocked", report["status"]
      assert_match(/do not resolve through ace-nav/, report["message"])
      assert_empty executor.tabs
    end
  end
end
