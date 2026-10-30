# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/hitl/cli/commands/reply"

module Ace
  module Hitl
    module CLI
      module Commands
        # The reply contract (task 8xs.t.pu0.5): Hermes runs `reply` on
        # the owner's machine with the answer on stdin; only the case and
        # its state are reported, every failure is an explicit
        # non-delivery, and a redelivered identical answer is
        # idempotent.
        class HitlCliReplyTest < AceHitlTestCase
          def setup
            @dir = Dir.mktmpdir
            @root = File.join(@dir, "hitl")
            @config = {"hitl" => {"root_dir" => @root, "machine" => "lab",
              "recipients" => {"captain" => {"machine" => "lab", "panel" => "cap"}}}}
            @manager = Organisms::HitlManager.new(root_dir: @root, config: @config)
            @event = @manager.create("Proceed?", type: "question", to: "captain",
              kind: "decision", questions: ["Proceed with batch 2?"])
          end

          def teardown
            FileUtils.remove_entry(@dir) if @dir
          end

          def reply_with(text, case_id: @event.id)
            out, = capture_io do
              $stdin = StringIO.new(text)
              begin
                with_cli_root(@root, config: @config) do
                  Reply.new.call(case_id: case_id, stdin: true, quiet: true)
                end
              ensure
                $stdin = STDIN
              end
            end
            out
          end

          def test_a_delivered_answer_reports_case_and_received_only
            out = reply_with("Proceed with batch 2\n")

            assert_equal({"case" => @event.id, "state" => "received"}, JSON.parse(out))
            content = File.read(@event.file_path)
            assert_match(/^answered: true/, content)
            assert_match(/Proceed with batch 2/, content)
          end

          def test_redelivery_of_the_identical_answer_is_duplicate_without_rewrite
            reply_with("Proceed\n")
            path = @event.file_path
            content = File.read(path)

            out = reply_with("Proceed\n")

            assert_equal({"case" => @event.id, "state" => "duplicate"}, JSON.parse(out))
            assert_equal content, File.read(path), "a duplicate never rewrites the case"
          end

          def test_a_conflicting_answer_never_overwrites_the_decision
            reply_with("Proceed\n")

            error = assert_raises(Ace::Support::Cli::Error) { reply_with("Stop everything\n") }
            assert_match(/not delivered:.*different answer/, error.message)
            assert_match(/Proceed/, File.read(@event.file_path))
          end

          def test_empty_answer_is_an_explicit_non_delivery
            error = assert_raises(Ace::Support::Cli::Error) { reply_with("   \n") }
            assert_match(/empty answer/, error.message)
            refute_match(/^answered: true/, File.read(@event.file_path))
          end

          def test_a_report_is_not_answerable
            report = @manager.create("Worker result", type: "report", result: "success",
              to: "captain")

            error = assert_raises(Ace::Support::Cli::Error) { reply_with("ok", case_id: report.id) }
            assert_match(/not delivered:.*report/, error.message)
          end

          def test_shortcuts_and_unknown_ids_never_resolve_to_a_case
            error = assert_raises(Ace::Support::Cli::Error) do
              reply_with("Proceed\n", case_id: @event.id[-3..])
            end
            assert_match(/not delivered:.*exact case id/, error.message)

            error = assert_raises(Ace::Support::Cli::Error) do
              reply_with("Proceed\n", case_id: "8xs.t.ghost")
            end
            assert_match(/not delivered:.*exact id/, error.message)
          end

          def test_answered_case_survives_the_asking_session_being_absent
            # The durable record IS the delivery: no wake consumer is
            # needed for the answer to be stored and later noticed.
            reply_with("Proceed\n")
            reloaded = Organisms::HitlManager.new(root_dir: @root, config: @config)

            body = File.read(@event.file_path)
            assert_match(/^answered: true/, body)
            assert_match(/^## Answer/, body)
            assert_match(/Proceed/, body)
          end
        end
      end
    end
  end
end
