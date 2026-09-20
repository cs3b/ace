# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/organisms/navigation_engine"
require "ace/support/nav/cli"

module Ace
  module Support
    module Nav
      module Organisms
        # Precedence observability for duplicate candidates.
        # Mirrors the planted-competitor probes from task 8wg.t.tjv:
        # project-local wins workflows/cookbooks/guides when registered with a
        # lower priority; skills always resolve to the gem even with planted
        # competitors in .ace-handbook/skills/ and .agents/skills/.
        class NavigationEnginePrecedenceTest < Minitest::Test
          def setup
            @test_dir = create_temp_ace_directory
            @engine = nil
          end

          def teardown
            cleanup_temp_directory(@test_dir)
            Ace::Support::Nav.reset_config!
          end

          def test_duplicate_workflow_candidates_project_local_wins
            register_project_source("wfi", "local", {
              "path" => ".ace-handbook/workflow-instructions",
              "priority" => 5
            })
            plant_project_file(".ace-handbook/workflow-instructions/release/publish.wf.md", "# LOCAL OVERRIDE")

            in_project do
              assert_equal \
                File.join(@test_dir, ".ace-handbook/workflow-instructions/release/publish.wf.md"),
                engine.resolve("wfi://release/publish")

              explanation = engine.explain("wfi://release/publish")
              assert_exactly_one_winner(explanation)
              assert_equal 2, explanation[:candidates].size
              assert_equal "@local", explanation[:candidates].first[:source]
              assert_equal 5, explanation[:candidates].first[:priority]
              assert_equal "@ace-handbook", explanation[:candidates].last[:source]
            end
          end

          def test_duplicate_cookbook_candidates_lower_priority_source_wins
            register_project_source("cookbook", "local-cookbooks", {
              "path" => ".ace-handbook/cookbooks",
              "priority" => 5
            })
            plant_project_file(
              ".ace-handbook/cookbooks/setup-starting-a-multi-ruby-gem-monorepo-with-ace.cookbook.md",
              "# LOCAL OVERRIDE"
            )

            in_project do
              uri = "cookbook://setup-starting-a-multi-ruby-gem-monorepo-with-ace"

              assert_equal \
                File.join(@test_dir, ".ace-handbook/cookbooks/setup-starting-a-multi-ruby-gem-monorepo-with-ace.cookbook.md"),
                engine.resolve(uri)

              explanation = engine.explain(uri)
              assert_exactly_one_winner(explanation)
              assert_equal "@local-cookbooks", explanation[:candidates].first[:source]
              assert_equal "@ace-handbook", explanation[:candidates].last[:source]
            end
          end

          def test_duplicate_guide_candidates_registered_project_source_wins
            register_project_source("guide", "local-guides", {
              "path" => "handbook/guides",
              "priority" => 5
            })
            plant_project_file("handbook/guides/changelog.g.md", "# LOCAL OVERRIDE")

            in_project do
              assert_equal \
                File.join(@test_dir, "handbook/guides/changelog.g.md"),
                engine.resolve("guide://changelog")

              explanation = engine.explain("guide://changelog")
              assert_exactly_one_winner(explanation)
              assert_equal "@local-guides", explanation[:candidates].first[:source]
              assert_equal "@ace-handbook", explanation[:candidates].last[:source]
            end
          end

          def test_planted_skill_competitors_are_ignored
            # Skills are NOT overridable: neither the .ace-handbook overlay nor
            # the .agents/ sync projection is a registered skill source.
            plant_project_file(".ace-handbook/skills/as-review-pr/SKILL.md", "# PLANTED")
            plant_project_file(".agents/skills/as-review-pr/SKILL.md", "# PLANTED")

            in_project do
              gem_dir = Gem::Specification.find_by_name("ace-review").gem_dir

              assert_equal \
                File.join(gem_dir, "handbook/skills/as-review-pr/SKILL.md"),
                engine.resolve("skill://as-review-pr")

              explanation = engine.explain("skill://as-review-pr")
              assert_equal 1, explanation[:candidates].size
              assert explanation[:candidates].first[:winner]
              assert_equal "@ace-review", explanation[:candidates].first[:source]
              assert_start_with_gem_dir(explanation, gem_dir)
            end
          end

          def test_resolve_command_why_explains_precedence
            register_project_source("wfi", "local", {
              "path" => ".ace-handbook/workflow-instructions",
              "priority" => 5
            })
            plant_project_file(".ace-handbook/workflow-instructions/release/publish.wf.md", "# LOCAL OVERRIDE")

            in_project do
              require "ace/support/nav/cli/commands/resolve"
              resolve_cmd = CLI::Commands::Resolve.new
              out, = capture_io do
                resolve_cmd.call(uri: "wfi://release/publish", why: true, quiet: true)
              end

              assert_includes out, "uri: wfi://release/publish"
              assert_includes out, "rule:"
              assert_includes out, "@local"
              assert_includes out, "← winner"
              assert_includes out, ".ace-handbook/workflow-instructions/release/publish.wf.md"
            end
          end

          private

          def engine
            @engine ||= NavigationEngine.new
          end

          def in_project
            Ace::Support::Nav.reset_config!
            Dir.chdir(@test_dir) { yield }
          end

          def register_project_source(protocol, name, config)
            create_test_source(@test_dir, protocol, name, config)
          end

          def plant_project_file(relative_path, content)
            absolute = File.join(@test_dir, relative_path)
            FileUtils.mkdir_p(File.dirname(absolute))
            File.write(absolute, content)
            absolute
          end

          def assert_exactly_one_winner(explanation)
            winners = explanation[:candidates].select { |candidate| candidate[:winner] }
            assert_equal 1, winners.size, "expected exactly one winner in: #{explanation[:candidates].inspect}"
            assert_equal explanation[:candidates].first, winners.first
          end

          def assert_start_with_gem_dir(explanation, gem_dir)
            explanation[:candidates].each do |candidate|
              assert candidate[:path].start_with?(gem_dir),
                "expected #{candidate[:path].inspect} to be inside gem dir #{gem_dir.inspect}"
            end
          end
        end
      end
    end
  end
end
