# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/cli/commands/assignment"
require "ace/lab/organisms/ordinary_campaign_runner"

module Ace
  module Lab
    module CLI
      module Commands
        class AssignmentCampaignTest < Minitest::Test
          def setup
            @dir = Dir.mktmpdir("campaign-cli-")
            @context = File.join(@dir, "context.json")
            File.write(@context, JSON.pretty_generate(valid_context) + "\n")
            @session = File.join(@dir, "session")
            @output = File.join(@dir, "output")
            FileUtils.mkdir_p(@session)
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def valid_context
            {"review_id" => "review-1",
              "producer" => {"assignment_id" => "producer", "attempt_id" => "producer-run", "expected_generation" => 5},
              "reviewer" => {"assignment_id" => "reviewer", "attempt_id" => "reviewer-run",
                "expected_generation" => 2, "pane" => "w1:p2", "actor" => "rev",
                "role" => "worker", "runtime" => "herdr", "scope" => "010.01"},
              "candidate" => {"head" => "a" * 40, "candidate_generation" => 1},
              "campaign" => {"base" => "b" * 40, "contract_identity" => "c" * 64,
                "scope_identity" => {"preset" => "code-valid", "subjects" => ["diff:#{"b" * 40}..#{"a" * 40}"]}},
              "subject" => "diff:#{"b" * 40}..#{"a" * 40}"}
          end

          def capture
            previous = $stdout
            buffer = StringIO.new
            $stdout = buffer
            yield
            buffer.string
          ensure
            $stdout = previous
          end

          def invoke(path:)
            command = Assignment::Campaign.new
            command.call(project: "atlas", context: path, session_dir: @session, output: @output)
          end

          def test_valid_context_runs_the_runner_and_prints_json
            runner = Object.new
            result = {"dispatched" => true, "result" => {"result_id" => "r1"}}
            runner.define_singleton_method(:run) do |**options|
              @seen = options
              result
            end
            Organisms::OrdinaryCampaignRunner.stub(:new, runner) do
              output = capture { invoke(path: @context) }
              parsed = JSON.parse(output)
              assert_equal "r1", parsed.dig("result", "result_id")
              assert_equal "review-1", runner.instance_variable_get(:@seen).fetch(:review_id)
              assert_equal @session, runner.instance_variable_get(:@seen).fetch(:session_dir)
            end
          end

          def test_missing_or_malformed_context_refuses_precisely
            empty = File.join(@dir, "empty.json")
            File.write(empty, "{}\n")
            error = assert_raises(Ace::Support::Cli::Error) { invoke(path: empty) }
            assert_includes error.message, "campaign runner context selection is invalid"
            broken = File.join(@dir, "broken.json")
            File.write(broken, "{not json")
            error = assert_raises(Ace::Support::Cli::Error) { invoke(path: broken) }
            assert_includes error.message, "not valid bounded JSON"
          end
        end
      end
    end
  end
end
