# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"

module Organisms
  # Lab-scope start (task 8xs.t.pu0.a): one external entry point that
  # reads the project list from the ace-lab topology, starts or finds
  # each project overseer through the SAME operation as a standalone
  # start, reports per-project readiness, and never duplicates sessions.
  class LabStartTest < AceOverseerTestCase
    class FakePaneResult
      def initialize(payload)
        @payload = payload
      end

      def parsed_json
        @payload
      end
    end

    class FakeExecutor
      attr_reader :workspaces_created, :tabs, :prompts

      def initialize
        @workspaces = []
        @workspaces_created = []
        @tabs = []
        @prompts = []
        @extra_panes = []
      end

      def workspace_list
        FakePaneResult.new({"result" => {"workspaces" => @workspaces}})
      end

      def workspace_create(label:)
        @workspaces_created << label
        @workspaces << {"workspace_id" => "ws-#{label}", "label" => label}
        FakePaneResult.new({"result" => {"workspace_id" => "ws-#{label}"}})
      end

      def pane_current
        # NO ambient workspace: the lab start must not depend on the
        # caller's herdr context (review 8xte508b failure mode a).
        FakePaneResult.new({"result" => {}})
      end

      def pane_list(workspace_id: nil)
        panes = @tabs.map do |tab|
          {"id" => "p-#{tab[:label]}", "title" => tab[:label], "cwd" => tab[:cwd],
           "workspace_id" => tab[:workspace_id]}
        end + @extra_panes
        FakePaneResult.new({"result" => {"panes" => panes.map do |pane|
          pane.transform_keys { |key| {"id" => "pane_id", "title" => "terminal_title"}.fetch(key, key) }
        end}})
      end

      # A pane that exists OUTSIDE this fake's created tabs (e.g. a
      # project session started standalone in another workspace).
      def add_pane(pane)
        @extra_panes << pane
      end

      def tab_create(workspace_id:, label:, cwd: nil, focus: nil)
        @tabs << {workspace_id: workspace_id, label: label, cwd: cwd}
        FakePaneResult.new({"result" => {"root_pane" => {"pane_id" => "p-#{label}"}}})
      end

      def agent_get(_pane)
        raise Ace::Herdr::AgentNotFoundError, "no agent"
      end

      def pane_run(_pane, _command)
        FakePaneResult.new({"result" => {}})
      end

      def agent_start(name:, kind:, pane:, timeout_ms:, args: [])
        FakePaneResult.new({"status" => "ready"})
      end

      def agent_prompt(pane:, text:, wait: false, timeout_ms: nil)
        @prompts << {pane: pane, text: text, wait: wait, timeout_ms: timeout_ms}
        FakePaneResult.new({"status" => "sent"})
      end
    end

    def setup
      @dir = Dir.mktmpdir
      @lab_root = File.join(@dir, "lab")
      # The lab coordination directory with its own _overseer and topology.
      FileUtils.mkdir_p(File.join(@lab_root, ".ace-tasks", "_overseer"))
      FileUtils.mkdir_p(File.join(@lab_root, ".ace", "lab"))
      File.write(File.join(@lab_root, ".ace", "lab", "config.yml"), <<~YAML)
        topology:
          projects:
            - id: alpha
              path: #{@dir}/alpha
              remote: #{File.join(@dir, "origin.git")}
            - id: beta
              path: #{@dir}/beta
      YAML
      # Lab start configuration.
      FileUtils.mkdir_p(File.join(@lab_root, ".ace", "overseer"))
      File.write(File.join(@lab_root, ".ace", "overseer", "config.yml"), <<~YAML)
        start:
          scope: lab
          profile: ovs
          instructions: #{@lab_root}/lab-guide.md
        profiles:
          ovs:
            harness: pi
            model: zai/glm-5.3-flash
            thinking: high
      YAML
      File.write(File.join(@lab_root, "lab-guide.md"), "# lab guide\n")
      @projects = prepare_project("alpha") + prepare_project("beta")
      ENV.delete("HERDR_WORKSPACE_ID")
      Ace::Lab.reset_config! if Ace::Lab.respond_to?(:reset_config!)
    end

    def teardown
      FileUtils.remove_entry(@dir) if @dir
    end

    # A project directory: git repo + its own project-scope start config.
    def prepare_project(name)
      path = File.join(@dir, name)
      FileUtils.mkdir_p(path)
      path = File.realpath(path)
      `git -C #{path.shellescape} init --quiet`
      File.write(File.join(path, "guide.md"), "# guide\n")
      FileUtils.mkdir_p(File.join(path, ".ace", "overseer"))
      File.write(File.join(path, ".ace", "overseer", "config.yml"), <<~YAML)
        start:
          scope: project
          profile: ovs
          instructions: #{path}/guide.md
        profiles:
          ovs:
            harness: pi
            model: zai/glm-5.3-flash
            thinking: high
      YAML
      [path]
    end

    def orchestrator(executor, cwd: @lab_root)
      config = Ace::Overseer.config_at(cwd)
      runner = ->(root:, workspace:, env:) {
        Ace::Overseer::Organisms::StartOrchestrator.new(config: Ace::Overseer.config_at(root),
          executor: executor, cwd: root, workspace: workspace, scope: "project", env: {}).call
      }
      Ace::Overseer::Organisms::StartOrchestrator.new(config: config, executor: executor,
        cwd: cwd, project_runner: runner)
    end

    def test_projects_without_start_yaml_use_the_project_bootstrap
      %w[alpha beta].each do |id|
        FileUtils.rm(File.join(@dir, id, ".ace/overseer/config.yml"))
      end
      executor = FakeExecutor.new
      report = orchestrator(executor).call
      assert_equal "ready", report["status"], report.inspect
      assert_equal %w[overseer alpha beta], executor.workspaces_created
      assert(report["projects"].all? { |project| project["scope"] == "project" })
    end

    def test_lab_start_boots_the_lab_overseer_and_each_project_in_its_own_space
      executor = FakeExecutor.new

      report = orchestrator(executor).call

      assert_equal "ready", report["status"], report.inspect
      assert_equal 2, report["project_count"]
      assert_equal %w[alpha beta], report["projects"].map { |project| project["id"] }
      assert(report["projects"].all? { |project| project["status"] == "started" })
      # the lab space plus ONE OWN space per project — never one shared
      # space for all tabs (review F2 / readiness line 28)
      assert_equal %w[overseer alpha beta], executor.workspaces_created
      assert_equal "ws-overseer", report["workspace"]
      # the lab's OWN overseer session boots in the lab space (review
      # 8xte508e): the lab-start instructions reach a real agent
      lab_tab = executor.tabs.find { |tab| tab[:cwd] == File.realpath(@lab_root) }
      assert lab_tab, "a lab session tab with the lab root as cwd must exist"
      assert_equal "overseer-lab", lab_tab[:label]
      assert_equal "ws-overseer", lab_tab[:workspace_id]
      assert_equal "p-overseer-lab", report["pane"]
      # each project session lives in its OWN space with its own cwd
      by_label = executor.tabs.to_h { |tab| [tab[:label], tab] }
      assert_equal "ws-alpha", by_label["overseer-alpha"][:workspace_id]
      assert_equal "ws-beta", by_label["overseer-beta"][:workspace_id]
      assert(by_label["overseer-alpha"][:cwd].match?(/alpha\z/))
      assert(by_label["overseer-beta"][:cwd].match?(/beta\z/))
      # the report carries each project's space id
      by_id = report["projects"].to_h { |project| [project["id"], project] }
      assert_equal "ws-alpha", by_id["alpha"]["workspace"]
      assert_equal "ws-beta", by_id["beta"]["workspace"]
    end

    def test_lab_start_prompts_every_started_agent_including_the_lab_overseer
      executor = FakeExecutor.new

      report = orchestrator(executor).call

      assert_equal "ready", report["status"]
      prompt_panes = executor.prompts.map { |entry| entry[:pane] }
      assert_equal %w[p-overseer-lab p-overseer-alpha p-overseer-beta].sort, prompt_panes.sort
      assert(executor.prompts.all? do |entry|
        entry[:text] == Ace::Overseer::Organisms::StartOrchestrator::FIRST_TURN_PROMPT
      end)
    end

    def test_lab_start_works_without_ambient_herdr_context
      executor = FakeExecutor.new
      # no herdr pane, no HERDR_WORKSPACE_ID (FakeExecutor.pane_current
      # reports none): projects must not fall back to the caller's space

      report = orchestrator(executor).call

      assert_equal "ready", report["status"], report.inspect
      by_label = executor.tabs.to_h { |tab| [tab[:label], tab] }
      assert_equal "ws-overseer", by_label["overseer-lab"][:workspace_id]
      assert_equal "ws-alpha", by_label["overseer-alpha"][:workspace_id]
      assert_equal "ws-beta", by_label["overseer-beta"][:workspace_id]
    end

    def test_repeated_lab_start_reuses_the_lab_and_project_sessions_without_duplicates
      executor = FakeExecutor.new
      first = orchestrator(executor).call

      # Simulate the started panes now being live agents.
      def executor.agent_get(_pane)
        FakePaneResult.new({"result" => {"agent" => {"agent_status" => "idle"}}})
      end
      second = orchestrator(executor).call

      assert_equal "ready", second["status"]
      assert(second["projects"].all? { |project| project["status"] == "reused" })
      assert_equal %w[overseer alpha beta], executor.workspaces_created,
        "every space is found by title, none recreated"
      assert_equal first["project_count"], second["project_count"]
      assert_equal 3, executor.tabs.size, "no duplicate sessions"
      assert_equal "p-overseer-lab", second["pane"], "the lab session is reused too"
      by_id = second["projects"].to_h { |project| [project["id"], project] }
      assert_equal "ws-alpha", by_id["alpha"]["workspace"],
        "a reused project reports its own space"
    end

    def test_a_standalone_started_project_is_reused_without_creating_a_new_space
      executor = FakeExecutor.new
      alpha = File.realpath(File.join(@dir, "alpha"))
      # alpha's overseer already lives in a foreign (manual) workspace
      executor.add_pane({"id" => "p-alpha-live", "title" => "overseer-alpha",
        "cwd" => alpha, "workspace_id" => "ws-manual"})
      def executor.agent_get(_pane)
        FakePaneResult.new({"result" => {"agent" => {"agent_status" => "idle"}}})
      end

      report = orchestrator(executor).call

      assert_equal "ready", report["status"]
      by_id = report["projects"].to_h { |project| [project["id"], project] }
      assert_equal "reused", by_id["alpha"]["status"]
      assert_equal "p-alpha-live", by_id["alpha"]["pane"]
      assert_equal "ws-manual", by_id["alpha"]["workspace"],
        "the live session's actual space is reported"
      assert_equal %w[overseer beta], executor.workspaces_created,
        "no empty alpha space is left behind by a pure reuse; beta still gets its own"
    end

    def test_native_workspace_list_envelope_starts_and_reuses_existing_lab_space
      executor = FakeExecutor.new
      def executor.workspace_list
        FakePaneResult.new({"id" => "cli:workspace:list", "result" => {
          "type" => "workspace_list", "workspaces" => [
            {"active_tab_id" => "w1:t1", "agent_status" => "unknown", "focused" => true,
             "label" => "~", "number" => 1, "pane_count" => 1, "tab_count" => 1,
             "workspace_id" => "w1"},
            {"label" => "overseer", "workspace_id" => "existing-lab"}
          ]
        }})
      end

      report = orchestrator(executor).call

      assert_equal "ready", report["status"], report.inspect
      assert_equal "existing-lab", report["workspace"]
      refute_includes executor.workspaces_created, "overseer"
      assert_equal %w[alpha beta], executor.workspaces_created
    end

    def test_a_titled_space_without_an_id_is_reused_never_duplicated
      executor = FakeExecutor.new
      # a live overseer entry carries a title but no id
      def executor.workspace_list
        @titled ||= [{"label" => "overseer"}]
        FakePaneResult.new({"result" => {"workspaces" => @titled}})
      end

      def executor.workspace_create(label:)
        raise "must not create a duplicate '#{label}' space" if label == "overseer"

        super
      end

      report = orchestrator(executor).call

      assert_equal "ready", report["status"], report.inspect
      assert_equal "overseer", report["workspace"],
        "the titled-but-idless space is reused by its title"
    end

    def test_a_lab_level_failure_keeps_the_lab_context
      executor = FakeExecutor.new
      def executor.workspace_list
        raise Ace::Herdr::ExecutorUnavailableError, "herdr CLI not found"
      end

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_equal "lab", report["scope"], "a lab-level block keeps its scope"
      assert_equal File.realpath(@lab_root), report["root"]
      assert_equal "overseer-lab", report["label"]
      assert_match(/lab start failed: herdr is unavailable/, report["message"])
    end

    def test_a_lab_level_herdr_command_error_surfaces_as_blocked_with_lab_context
      executor = FakeExecutor.new
      def executor.workspace_list
        raise Ace::Herdr::CommandError, "herdr exited 1: socket closed"
      end

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_equal "lab", report["scope"]
      assert_match(/lab start failed: herdr exited 1/, report["message"])
    end

    def test_a_project_declaring_lab_scope_is_refused_not_recursed
      executor = FakeExecutor.new
      # beta's own cascade declares scope lab — a nested lab start
      beta = File.join(@dir, "beta")
      File.write(File.join(beta, ".ace", "overseer", "config.yml"), <<~YAML)
        start:
          scope: lab
          profile: ovs
          instructions: #{beta}/guide.md
        profiles:
          ovs:
            harness: pi
            model: zai/glm-5.3-flash
            thinking: high
      YAML

      report = orchestrator(executor).call

      assert_equal "partial", report["status"]
      by_id = report["projects"].to_h { |project| [project["id"], project] }
      assert_equal "started", by_id["alpha"]["status"], "the healthy project runs"
      assert_equal "blocked", by_id["beta"]["status"]
      assert_match(/nested lab scopes are refused/, by_id["beta"]["message"])
    end

    # Review R7, probe 1: an unconfirmed first turn is never a ready
    # lab — no state read, no /eyes arming — while the live agent
    # stays visible (partial, not blocked).
    def test_lab_with_no_confirmed_first_turn_is_not_ready
      executor = FakeExecutor.new
      # every prompt delivery fails: live agents, no first turn
      def executor.agent_prompt(pane:, text:, wait: false, timeout_ms: nil)
        @prompts << {pane: pane, text: text, wait: wait, timeout_ms: timeout_ms}
        raise Ace::Herdr::CommandError, "synthetic initial delivery failure"
      end

      report = orchestrator(executor).call

      assert_equal true, report["prompt_failed"], report.inspect
      assert_equal "partial", report["status"]
      assert_equal false, report["ready"],
        "no model turn ran and no watchers are armed, yet the lab reports ready"
      assert(report["projects"].all? { |project| project["prompt_failed"] })
    end

    # Review R7, probe 2: a repeated start after a failed delivery
    # repairs the missing initialization through the existing session
    # — only then is the lab ready.
    def test_restart_after_failed_delivery_repairs_initialization_then_is_ready
      executor = FakeExecutor.new
      def executor.agent_prompt(pane:, text:, wait: false, timeout_ms: nil)
        raise Ace::Herdr::CommandError, "synthetic initial delivery failure" if @failed_delivery

        @prompts << {pane: pane, text: text, wait: wait, timeout_ms: timeout_ms}
        FakePaneResult.new({"status" => "sent"})
      end
      executor.instance_variable_set(:@failed_delivery, true)
      first = orchestrator(executor).call
      assert_equal false, first["ready"]

      # the agents are live now; delivery works again
      executor.instance_variable_set(:@failed_delivery, false)
      def executor.agent_get(_pane)
        FakePaneResult.new({"result" => {"agent" => {"agent_status" => "idle"}}})
      end
      second = orchestrator(executor).call

      assert_equal true, second["ready"], second.inspect
      assert_equal false, second["prompt_failed"]
      assert(second["projects"].all? { |project| !project["prompt_failed"] })
      lab_prompts = executor.prompts.count { |entry| entry[:pane] == "p-overseer-lab" }
      assert_operator lab_prompts, :>=, 1, "the lab session's first turn is re-delivered"
      assert_equal 3, executor.tabs.size, "repair reuses the sessions, no restart"
    end

    def test_empty_lab_with_unconfirmed_first_turn_is_not_ready
      File.write(File.join(@lab_root, ".ace", "lab", "config.yml"), "topology:\n  projects: []\n")
      executor = FakeExecutor.new
      def executor.agent_prompt(pane:, text:, wait: false, timeout_ms: nil)
        raise Ace::Herdr::CommandError, "synthetic initial delivery failure"
      end

      report = orchestrator(executor).call

      assert_equal true, report["prompt_failed"]
      assert_equal false, report["ready"]
      assert_equal "partial", report["status"]
    end

    def test_lab_owner_pane_in_a_foreign_cwd_is_a_conflict
      executor = FakeExecutor.new
      # a pane already owns the lab label but works in another directory
      def executor.pane_list(workspace_id: nil)
        @foreign_cwd ||= Dir.mktmpdir
        FakePaneResult.new({"result" => {"panes" => [{"pane_id" => "p9", "terminal_title" => "overseer-lab", "cwd" => @foreign_cwd}]}})
      end

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_match(/refusing to take over a foreign session/, report["message"])
    end

    def test_an_unhealthy_project_is_reported_while_the_healthy_one_runs
      executor = FakeExecutor.new
      # beta has no directory on disk
      FileUtils.rm_rf(File.join(@dir, "beta"))

      report = orchestrator(executor).call

      assert_equal "partial", report["status"]
      assert_equal false, report["ready"]
      by_id = report["projects"].to_h { |project| [project["id"], project] }
      assert_equal "started", by_id["alpha"]["status"], "the healthy project runs"
      assert_equal "blocked", by_id["beta"]["status"]
      assert_match(/does not exist/, by_id["beta"]["message"])
      assert_equal %w[overseer alpha], executor.workspaces_created,
        "the unhealthy project creates no space"
    end

    def test_empty_lab_is_ready_idle_with_the_lab_overseer_running
      File.write(File.join(@lab_root, ".ace", "lab", "config.yml"), "topology:\n  projects: []\n")
      executor = FakeExecutor.new

      report = orchestrator(executor).call

      assert_equal "ready", report["status"]
      assert_equal 0, report["project_count"]
      assert_match(/no projects configured/, report["message"])
      assert_equal "p-overseer-lab", report["pane"], "the lab session still boots"
      assert_equal 1, executor.tabs.size
    end

    def test_conflicting_lab_project_roles_are_refused
      File.write(File.join(@lab_root, ".ace", "lab", "config.yml"), <<~YAML)
        topology:
          projects:
            - id: lab-itself
              path: #{@lab_root}
      YAML
      executor = FakeExecutor.new

      report = orchestrator(executor).call

      assert_equal "blocked", report["status"]
      assert_match(/conflicting lab\/project roles/, report["message"])
    end

    def test_lab_dry_run_creates_nothing
      executor = FakeExecutor.new

      report = orchestrator(executor).call(dry_run: true)

      assert_equal "dry_run", report["status"]
      assert_equal 2, report["project_count"]
      assert_empty executor.workspaces_created
      assert_empty executor.tabs
    end
  end
end
