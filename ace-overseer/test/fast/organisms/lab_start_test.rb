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
      attr_reader :workspaces_created, :tabs

      def initialize
        @workspaces = []
        @workspaces_created = []
        @tabs = []
      end

      def workspace_list
        FakePaneResult.new({"result" => @workspaces})
      end

      def workspace_create(label:)
        @workspaces_created << label
        @workspaces << {"id" => "ws-#{label}", "title" => label}
        FakePaneResult.new({"result" => {"id" => "ws-#{label}"}})
      end

      def pane_current
        FakePaneResult.new({"result" => {"workspace_id" => "ws-lab"}})
      end

      def pane_list
        FakePaneResult.new(@tabs.map do |tab|
          {"id" => "p-#{tab[:label]}", "title" => tab[:label], "cwd" => tab[:cwd]}
        end)
      end

      def tab_create(workspace_id:, label:, cwd: nil, focus: nil)
        @tabs << {workspace_id: workspace_id, label: label, cwd: cwd}
        FakePaneResult.new({"result" => {"root_pane" => {"pane_id" => "p-#{label}"}}})
      end

      def agent_get(_pane)
        raise Ace::Herdr::AgentNotFoundError, "no agent"
      end

      def agent_start(name:, kind:, pane:, timeout_ms:, args: [])
        FakePaneResult.new({"status" => "ready"})
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
      Ace::Overseer::Organisms::StartOrchestrator.new(config: config, executor: executor,
        cwd: cwd)
    end

    def test_lab_start_prepares_both_projects_and_the_lab_workspace
      executor = FakeExecutor.new

      report = orchestrator(executor).call

      assert_equal "ready", report["status"], report.inspect
      assert_equal 2, report["project_count"]
      assert_equal %w[alpha beta], report["projects"].map { |project| project["id"] }
      assert(report["projects"].all? { |project| project["status"] == "started" })
      assert_equal 1, executor.workspaces_created.size, "the lab space is created once"
      assert(executor.tabs.all? { |tab| tab[:cwd].match?(/(alpha|beta)\z/) },
        "each project session boots in its own project directory")
    end

    def test_repeated_lab_start_reuses_without_duplicates
      executor = FakeExecutor.new
      first = orchestrator(executor).call

      # Simulate the started panes now being live agents.
      def executor.agent_get(_pane)
        FakePaneResult.new({"status" => "idle"})
      end
      second = orchestrator(executor).call

      assert_equal "ready", second["status"]
      assert(second["projects"].all? { |project| project["status"] == "reused" })
      assert_equal 1, executor.workspaces_created.size, "no duplicate lab space"
      assert_equal first["project_count"], second["project_count"]
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
    end

    def test_empty_lab_is_ready_idle
      File.write(File.join(@lab_root, ".ace", "lab", "config.yml"), "topology:\n  projects: []\n")
      executor = FakeExecutor.new

      report = orchestrator(executor).call

      assert_equal "ready", report["status"]
      assert_equal 0, report["project_count"]
      assert_match(/no projects configured/, report["message"])
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
