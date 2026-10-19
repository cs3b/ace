# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module CLI
      module Commands
        class RoundsTest < AceCoworkerTestCase
          def setup
            super
            @dir = Dir.mktmpdir("coworker-rounds-cmd")
            @store = Molecules::ReviewRoundStore.new(project_root: @dir)
          end

          def teardown
            FileUtils.remove_entry(@dir)
            super
          end

          def test_record_prints_verdict_and_persists
            out, = capture_io do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "full", status: "completed",
                                             confirmed: [], resolved: [])
            end
            assert_includes out, "Coworker rounds record"
            assert_includes out, "verdict:                continue"
            assert_includes out, "assignment:             asg01"
            assert_equal 1, @store.read("asg01").length
          end

          def test_record_parses_confirmed_and_resolved_options
            out, = capture_io do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "full", status: "completed",
                                             confirmed: ["f-1:high", "f-2:low"],
                                             resolved: ["f-3"])
            end
            assert_includes out, "unresolved High/Critical: f-1"

            stored = @store.read("asg01").last
            assert_equal [{"id" => "f-1", "severity" => "high"},
                          {"id" => "f-2", "severity" => "low"}], stored["confirmed"]
            assert_equal ["f-3"], stored["resolved"]
          end

          def test_record_json_output
            out, = capture_io do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "delta", status: "aborted",
                                             format: "json")
            end
            payload = JSON.parse(out)
            assert_equal "asg01", payload["assignment"]
            assert_equal "continue", payload["verdict"]
            assert_equal 0, payload["full_rounds"]
          end

          def test_record_accept_verdict_after_three_clean_rounds
            2.times do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "full", status: "completed")
            end
            out, = capture_io do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "full", status: "completed")
            end
            assert_includes out, "verdict:                accept"
          end

          def test_unknown_subcommand_fails
            error = assert_raises(Ace::Support::Cli::Error) do
              Rounds.new(store: @store).call(action: "list", assignment: "asg01",
                                             type: "full", status: "completed")
            end
            assert_match(/unknown subcommand 'list'/, error.message)
          end

          def test_invalid_record_surfaces_store_error
            error = assert_raises(Ace::Support::Cli::Error) do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "partial", status: "completed")
            end
            assert_match(/'type' must be one of/, error.message)
          end

          def test_corrupt_history_fails_instead_of_resetting
            path = @store.state_path("asg01")
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, "{not json")

            error = assert_raises(Ace::Support::Cli::Error) do
              Rounds.new(store: @store).call(action: "record", assignment: "asg01",
                                             type: "full", status: "completed")
            end
            assert_match(/corrupt round history/, error.message)
            assert_equal "{not json", File.read(path)
          end
        end
      end
    end
  end
end
