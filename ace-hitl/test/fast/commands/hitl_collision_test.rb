# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Cross-worktree collision (task 8xs.t.pu0.f): the same case id
        # appearing in two HITL roots is an explicit ambiguity — a reply
        # or suggestion never lands in a foreign copy, and no shortcut
        # resolves the collision by latest-match. The fixtures use the
        # canonical 6-char id shape and BOTH roots are visible to the
        # scope resolver, so the ambiguity actually fires (regression:
        # the first version passed vacuously through UnknownCaseError).
        class HitlCollisionTest < AceHitlTestCase
          CASE_ID = "8x0col"

          def setup
            @tmp = Dir.mktmpdir("hitl-collision")
          end

          def teardown
            FileUtils.remove_entry(@tmp) if @tmp
          end

          # The SAME case id present in two OTHER linked worktree roots:
          # resolution from the caller's worktree falls back to "all",
          # finds both copies and must report the ambiguity.
          def build_collision_roots
            main_worktree = File.join(@tmp, "main")
            second_worktree = File.join(@tmp, "feature-77")
            caller_worktree = File.join(@tmp, "task-123")
            collision_roots = [main_worktree, second_worktree].map { |wt| File.join(wt, ".ace-local", "hitl") }
            collision_roots.each do |root|
              create_hitl_fixture(root, id: CASE_ID, slug: "collision",
                type: "question", questions: ["Proceed?"])
            end
            caller_hitl = File.join(caller_worktree, ".ace-local", "hitl")
            FileUtils.mkdir_p(caller_hitl)
            resolver = StaticScopeResolver.new(
              default_scope: "current",
              current_worktree_root: caller_worktree,
              roots_by_scope: {"current" => [caller_worktree],
                "all" => [caller_worktree, main_worktree, second_worktree]}
            )
            config = {"hitl" => {"root_dir" => ".ace-local/hitl", "machine" => "lab",
              "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}}}}
            [collision_roots, caller_hitl, resolver, config]
          end

          def test_reply_on_a_colliding_case_id_is_an_explicit_ambiguity
            roots, _caller_hitl, resolver, config = build_collision_roots
            before = roots.map { |root| File.read(Dir.glob(File.join(root, "**", "*.md")).first) }

            with_cli_root(_caller_hitl, config: config, scope_resolver: resolver) do
              $stdin = StringIO.new("Proceed\n")
              begin
                result = run_cli(["reply", CASE_ID, "--stdin"])
                assert_equal 1, result[:exit_code], "a colliding case id must fail the reply"
                assert_match(/ambiguous/i, result[:stderr],
                  "the failure names the collision, not an unknown case: #{result[:stderr]}")
              ensure
                $stdin = STDIN
              end
            end

            after = roots.map { |root| File.read(Dir.glob(File.join(root, "**", "*.md")).first) }
            assert_equal before, after, "neither copy was modified by the refused reply"
          end

          def test_suggestion_on_a_colliding_case_id_is_an_explicit_ambiguity
            roots, _caller_hitl, resolver, config = build_collision_roots
            before = roots.map { |root| File.read(Dir.glob(File.join(root, "**", "*.md")).first) }

            with_cli_root(_caller_hitl, config: config, scope_resolver: resolver) do
              result = run_cli(["suggest", CASE_ID, "--by", "second-captain",
                "--text", "Proceed", "--rationale", "n/a"])
              assert_equal 1, result[:exit_code], "a colliding case id must fail the suggestion"
              assert_match(/ambiguous/i, result[:stderr],
                "the failure names the collision: #{result[:stderr]}")
            end

            after = roots.map { |root| File.read(Dir.glob(File.join(root, "**", "*.md")).first) }
            assert_equal before, after, "neither copy was modified by the refused suggestion"
          end
        end
      end
    end
  end
end
