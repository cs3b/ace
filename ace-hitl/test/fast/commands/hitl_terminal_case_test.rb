# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # Shared rule for late writes to terminal cases (PR #398 review,
        # F9): once the application is closed or cancelled, no NEW answer
        # or suggestion lands in the file. Idempotent replay of the
        # identical answer to a closed case stays a no-op.
        class HitlTerminalCaseTest < AceHitlTestCase
          def setup
            @dir = Dir.mktmpdir
            @root = File.join(@dir, "hitl")
            @config = {"hitl" => {"root_dir" => @root, "machine" => "lab",
              "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}}}}
            @manager = Organisms::HitlManager.new(root_dir: @root, config: @config)
            @event = @manager.create("Proceed?", type: "question", to: "captain",
              kind: "decision")
          end

          def teardown
            FileUtils.remove_entry(@dir) if @dir
          end

          def test_a_late_reply_to_a_cancelled_case_is_refused_not_recorded
            @manager.cancel_case(@event.id)

            before = File.read(@event.file_path)
            error = assert_raises(Organisms::HitlManager::TerminalCaseError) do
              @manager.receive_answer(@event.id, "Proceed anyway\n")
            end
            assert_match(/cancelled.*never accepts a late answer/, error.message)

            after = File.read(@event.file_path)
            assert_equal before, after,
              "a refused late reply leaves the terminal case byte-identical"
            refute after.include?("Proceed anyway"), "the late answer text is never recorded"
            refute after.include?("answered: true")
          end

          def test_a_late_suggestion_on_a_cancelled_case_is_refused
            @manager.cancel_case(@event.id)

            error = assert_raises(Organisms::HitlManager::TerminalCaseError) do
              @manager.add_suggestion(@event.id, author: "second-captain",
                text: "Proceed", rationale: "late proposal")
            end
            assert_match(/cancelled.*never accepts a late answer or suggestion/, error.message)
            refute File.read(@event.file_path).include?("## Suggestion")
          end

          def test_identical_answer_replay_on_a_closed_case_stays_a_noop
            @manager.receive_answer(@event.id, "Proceed\n")
            @manager.apply_answer_effect(@event.id, "pr:398")
            @manager.close_case(@event.id)

            result = @manager.receive_answer(@event.id, "Proceed\n")
            assert_equal :duplicate, result,
              "transport replay of the identical answer to a closed case is idempotent"

            error = assert_raises(Organisms::HitlManager::AnswerConflictError) do
              @manager.receive_answer(@event.id, "Something else\n")
            end
            assert_match(/never overwrites a decision/, error.message)
          end

          def test_a_terminal_state_landing_between_precheck_and_write_refuses_the_answer
            reply_error = nil

            # Hold the case lock so the reply's locked write blocks AFTER
            # its pre-check passed (unanswered, not terminal); cancel the
            # case, then let the reply through — the locked terminal check
            # must refuse the answer, not write over the cancelled case.
            File.open("#{@event.file_path}.lock", File::RDWR | File::CREAT, 0o600) do |lock|
              lock.flock(File::LOCK_EX)

              writer = Thread.new do
                begin
                  @manager.receive_answer(@event.id, "Proceed anyway\n")
                rescue StandardError => e
                  reply_error = e
                end
              end

              writer.join(0.3)
              assert writer.alive?, "the reply must wait for the case lock"

              content = File.read(@event.file_path)
              frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse!(content)
              frontmatter["application"] = {"state" => "cancelled",
                "cancelled_at" => Time.now.utc}
              File.write(@event.file_path, Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(
                frontmatter, body))
              lock.flock(File::LOCK_UN)
              writer.join
            end

            assert reply_error.is_a?(Organisms::HitlManager::TerminalCaseError),
              "the locked terminal check refuses the answer (got #{reply_error.inspect})"
            assert_match(/cancelled.*never accepts a late answer/, reply_error.message)
            refute File.read(@event.file_path).include?("Proceed anyway")
          end
        end
      end
    end
  end
end
