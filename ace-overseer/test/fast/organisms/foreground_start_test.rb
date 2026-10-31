# frozen_string_literal: true

require_relative "../../test_helper"

module Organisms
  class ForegroundStartTest < AceOverseerTestCase
    class Executor
      Result = Struct.new(:parsed_json)
      attr_reader :renames
      attr_accessor :alive, :cwd, :other_owner

      def initialize(cwd)
        @cwd = cwd
        @renames = []
      end

      def agent_get(_pane)
        raise Ace::Herdr::AgentNotFoundError, "no agent" unless alive
        Result.new({"result" => {"agent" => {"agent_status" => "working"}}})
      end

      def pane_list(workspace_id: nil)
        panes = [{"pane_id" => "w1:p1", "workspace_id" => "w1", "cwd" => cwd,
                  "terminal_title" => "shell"}]
        panes << other_owner if other_owner
        Result.new({"id" => "cli:pane:list", "result" => {"panes" => panes}})
      end

      def pane_rename(pane, label)
        @renames << [pane, label]
      end

      def workspace_create(**)
        raise "foreground bootstrap must not create a workspace"
      end

      def tab_create(**)
        raise "foreground bootstrap must not create a tab or pane"
      end
    end

    def setup
      @root = Dir.mktmpdir("lab-bootstrap")
      @executor = Executor.new(@root)
      @guide = File.join(@root, "guide.md")
      File.write(@guide, "# lab guide")
    end

    def teardown
      FileUtils.remove_entry(@root)
    end

    def start(dry_run: false, config: {})
      Ace::Overseer::Organisms::StartOrchestrator.new(config: config,
        executor: @executor, cwd: @root, env: {"HERDR_PANE" => "", "HERDR_PANE_ID" => "w1:p1",
          "HERDR_TAB" => "", "HERDR_WORKSPACE_ID" => "w1"},
        nav_runner: ->(*) { {"status" => "ok", "out" => @guide} }).call(dry_run: dry_run)
    end

    def test_unconfigured_directory_boots_in_calling_pane_without_writing_files
      before = Dir.glob(File.join(@root, "**", "*"), File::FNM_DOTMATCH)
      report = start
      assert_equal "foreground", report["status"], report.inspect
      assert_equal "w1:p1", report["pane"]
      assert_equal "w1", report["workspace"]
      assert_equal ["pi", "--model", "zai/glm-5.3-flash", "--thinking", "high",
        "--append-system-prompt", @guide,
        Ace::Overseer::Organisms::StartOrchestrator::FIRST_TURN_PROMPT], report["command"]
      assert_equal [["w1:p1", "overseer-#{File.basename(@root)}"]], @executor.renames
      assert_equal before, Dir.glob(File.join(@root, "**", "*"), File::FNM_DOTMATCH)
    end

    def test_dry_run_does_not_rename_or_launch_anything
      report = start(dry_run: true)
      assert_equal "dry_run", report["status"]
      assert_empty @executor.renames
      refute File.exist?(File.join(@root, ".ace"))
    end

    def test_live_agent_is_never_replaced_by_foreground_bootstrap
      @executor.alive = true
      report = start
      assert_equal "blocked", report["status"] # topology still missing: agent owns setup
      refute report.key?("command")
      assert_empty @executor.renames
    end

    def test_foreign_calling_pane_is_refused_before_rename
      @executor.cwd = File.dirname(@root)
      report = start
      assert_equal "blocked", report["status"]
      assert_match(/calling Herdr pane/, report["message"])
      assert_empty @executor.renames
    end

    def test_existing_owner_in_another_pane_is_not_duplicated
      @executor.other_owner = {"pane_id" => "w2:p1", "workspace_id" => "w2",
        "cwd" => @root, "terminal_title" => "overseer-#{File.basename(@root)}"}
      report = start
      refute report.key?("command")
      assert_empty @executor.renames
    end
  end
end
