# frozen_string_literal: true

require_relative "../../test_helper"

module Organisms
  class ForegroundStartTest < AceOverseerTestCase
    class ForbiddenHerdr
      def method_missing(name, *)
        raise "bare start must not call Herdr: #{name}"
      end
    end

    def setup
      @root = Dir.mktmpdir("lab-bootstrap")
    end

    def teardown
      FileUtils.remove_entry(@root)
    end

    def test_bare_bootstrap_needs_no_herdr_environment_or_queries_or_start_yaml
      report = Ace::Overseer::Organisms::StartOrchestrator.new(config: {},
        executor: ForbiddenHerdr.new, cwd: @root, env: {}).bootstrap
      assert_equal "foreground", report["status"]
      assert_equal File.realpath(@root), report["root"]
      assert_equal ["pi", "--model", "zai/glm-5.3-flash", "--thinking", "high"], report["command"].first(5)
      assert_equal "wfi://overseer/lab-start", report["instructions"]["source"]
      assert File.file?(report["instructions"]["path"])
      refute File.exist?(File.join(@root, ".ace"))
      assert_equal [".", ".."], Dir.children(@root).sort + [".", ".."]
    end

    def test_dry_run_does_not_launch_or_query_herdr
      report = Ace::Overseer::Organisms::StartOrchestrator.new(config: {},
        executor: ForbiddenHerdr.new, cwd: @root, env: {}).bootstrap(dry_run: true)
      assert_equal "dry_run", report["status"]
      assert_empty Dir.children(@root)
    end
  end
end
