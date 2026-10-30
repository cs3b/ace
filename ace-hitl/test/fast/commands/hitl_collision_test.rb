# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Cross-worktree collision (task 8xs.t.pu0.f): the same case id
        # appearing in two HITL roots is an explicit ambiguity — a reply
        # or suggestion never lands in the foreign copy, and no shortcut
        # resolves the collision by latest-match.
        class HitlCollisionTest < AceHitlTestCase
          def setup
            @dir = Dir.mktmpdir
            @roots = Array.new(2) { |i| File.join(@dir, "wt#{i}", ".ace-local", "hitl") }
            @config = {"hitl" => {"root_dir" => @roots.first, "machine" => "lab",
              "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}}}}
            # the SAME case id present in two linked worktree roots
            @roots.each_with_index do |root, index|
              FileUtils.mkdir_p(File.join(root, "8xt0col-collision"))
              File.write(File.join(root, "8xt0col-collision", "8xt0col-collision.hitl.s.md"), <<~MD)
                ---
                id: 8xt0col
                title: "Same case in two worktrees"
                type: question
                kind: decision
                status: pending
                answered: false
                created_at: "2026-10-30 00:00:00 UTC"
                ---

                # Same case in two worktrees

                ## Answer

                wait #{index}
              MD
            end
          end

          def teardown
            FileUtils.remove_entry(@dir) if @dir
          end

          def test_reply_on_a_colliding_case_id_is_an_explicit_ambiguity
            error = nil
            capture_io do
              with_cli_root(@roots.first, config: @config) do
                $stdin = StringIO.new("Proceed\n")
                begin
                  Reply.new.call(case_id: "8xt0col", stdin: true, quiet: true)
                rescue Ace::Support::Cli::Error => e
                  error = e
                ensure
                  $stdin = STDIN
                end
              end
            end

            # Assert on the raised error only: the reply MUST fail closed —
            # if the ambiguity error ever disappears this fails loudly
            # instead of reading a restored $stderr.
            assert error, "a colliding case id must fail the reply, not deliver it"
            assert_match(/8xt0col/, error.message)
            # neither copy was modified
            @roots.each do |root|
              body = File.read(File.join(root, "8xt0col-collision", "8xt0col-collision.hitl.s.md"))
              refute_match(/^answered: true/, body)
              refute_match(/^Proceed$/, body)
            end
          end

          def test_suggestion_on_a_colliding_case_id_is_refused_without_side_effects
            error = assert_raises(Ace::Support::Cli::Error) do
              capture_io do
                with_cli_root(@roots.first, config: @config) do
                  Suggest.new.call(case_id: "8xt0col", by: "second-captain",
                    text: "Proceed", rationale: "why")
                end
              end
            end

            assert_match(/8xt0col/, error.message)
            @roots.each do |root|
              body = File.read(File.join(root, "8xt0col-collision", "8xt0col-collision.hitl.s.md"))
              refute body.include?("## Suggestion")
            end
          end
        end
      end
    end
  end
end
