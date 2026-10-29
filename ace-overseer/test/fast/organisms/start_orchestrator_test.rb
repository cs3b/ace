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
      attr_reader :agent_started, :tabs

      def initialize(panes: [], pane_current: {}, pane_of_tab: "p1", alive: true)
        @panes = panes
        @pane_current = pane_current
        @pane_of_tab = pane_of_tab
        @alive = alive
        @agent_started = []
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

    def orchestrator(executor, cwd: @root, config: @config)
      Ace::Overseer::Organisms::StartOrchestrator.new(
        config: config, executor: executor, nav_runner: @nav_runner, cwd: cwd
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
