# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/lab/organisms/ordinary_campaign_runner"

module Ace
  module Lab
    class OrdinaryCampaignRunnerTest < Minitest::Test
      class FakeClient
        attr_accessor :responses, :requests

        def initialize(responses)
          @responses = responses.dup
          @requests = []
        end

        def request(input:)
          request = JSON.parse(File.read(input))
          @requests << request
          reply = @responses.shift
          raise "no scripted reply for #{request.fetch('operation')}" unless reply
          reply
        end
      end

      class FakeReview
        attr_accessor :executions, :boundary_binding

        def initialize(result = nil)
          @result = result || {success: true, artifacts: [
            {path: "system-prompt.md", bytes: "x" * 300, sha256: Digest::SHA256.hexdigest("x" * 300)}]}
          @executions = []
        end

        attr_accessor :boundary_drift
        def execute_prepared_campaign(candidate:, subject:, session_dir:, campaign_binding:, execution_boundary:)
          @executions << {candidate: candidate, subject: subject, campaign_binding: campaign_binding}
          @boundary_binding = campaign_binding
          engine_binding = @boundary_drift ? campaign_binding.merge("session_binding" => "drifted") : campaign_binding
          execution_boundary.call(binding: engine_binding, model: "role:review-default") { :dispatched }
          @result
        rescue ArgumentError, KeyError, TypeError => error
          {success: false, error: "Prepared campaign review unavailable: #{error.message}"}
        end
      end

      def setup
        @dir = Dir.mktmpdir("campaign-runner-")
        @reviewer = {"assignment_id" => "reviewer", "attempt_id" => "reviewer-run",
          "expected_generation" => 6, "pane" => "w1:p2", "actor" => "rev", "role" => "worker",
          "runtime" => "herdr", "scope" => "010.01"}
        @candidate = {"head" => "a" * 40, "candidate_generation" => 1}
        @begin_reply = {"data" => {"campaign_id" => "camp-1", "round_id" => "round-1", "scope" => "full",
          "execution_id" => "execution-1", "session_binding" => "binding-1"}, "transport" => {"replayed" => false}}
      end

      def teardown
        FileUtils.remove_entry(@dir)
      end

      def runner(client, review)
        Organisms::OrdinaryCampaignRunner.new(project: "atlas", client: client, review: review)
      end

      def run_with(client, review)
        runner(client, review).run(review_id: "review-1", producer_assignment_id: "producer",
          reviewer: @reviewer, candidate: @candidate, subject: "diff:#{'b' * 40}..#{'a' * 40}",
          session_dir: tap_dir("session"), output: tap_dir("out"))
      end

      def tap_dir(name)
        path = File.join(@dir, name)
        FileUtils.mkdir_p(path)
        path
      end

      def test_fresh_begin_dispatches_and_submits_review_context
        submit_reply = {"data" => {"result_id" => "r1", "state" => "running"}, "transport" => {"replayed" => false}}
        client = FakeClient.new([@begin_reply, submit_reply])
        review = FakeReview.new
        result = run_with(client, review)
        assert result.fetch("dispatched")
        assert_equal "binding-1", result.fetch("session_binding")
        assert_equal 1, review.executions.length, "model execution must run exactly once"
        submit = client.requests.fetch(1)
        assert_equal "submit_review_context", submit.fetch("operation")
        assert_equal "producer", submit.dig("params", "producer_assignment_id")
        assert_equal "review-1", submit.dig("params", "review_id")
        receipt = JSON.parse(File.read(File.join(@dir, "out", "receipt.json")))
        assert_equal "review-collect", receipt.fetch("operation")
        assert_equal "camp-1", receipt.dig("review", "campaign", "campaign_id")
        assert_equal "binding-1", review.executions.first.fetch(:campaign_binding).fetch("session_binding")
      end

      def test_replayed_begin_never_dispatches
        replay = {"data" => @begin_reply.fetch("data"), "transport" => {"replayed" => true}}
        client = FakeClient.new([replay])
        review = FakeReview.new
        result = run_with(client, review)
        refute result.fetch("dispatched")
        assert result.fetch("replayed")
        assert_empty review.executions, "a replayed begin is an observation, never a dispatch"
        assert_equal 1, client.requests.length, "no context submission without dispatch"
      end

      def test_failed_execution_submits_nothing
        client = FakeClient.new([@begin_reply])
        review = FakeReview.new({success: false, error: "provider refused"})
        result = run_with(client, review)
        refute result.fetch("dispatched")
        assert_equal "provider refused", result.fetch("error")
        assert_equal 1, client.requests.length
      end

      def test_boundary_binding_must_match_the_canonical_begin
        mismatch = @begin_reply.merge("data" => @begin_reply.fetch("data").merge("session_binding" => "other"))
        client = FakeClient.new([mismatch])
        review = FakeReview.new
        review.boundary_drift = true
        result = run_with(client, review)
        refute result.fetch("dispatched")
        assert_includes result.fetch("error"), "boundary binding differs"
      end
    end
  end
end
