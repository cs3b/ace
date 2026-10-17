# frozen_string_literal: true

require "securerandom"
require_relative "../molecules/ordinary_owner_config"
require_relative "ordinary_assignment_client"
require "ace/review/organisms/prepared_candidate_review"
require "ace/assign/atoms/candidate_limits"

module Ace
  module Lab
    module Organisms
      # Drives one canonical campaign review round at the provider boundary.
      # The native begin is requested exactly once per execution through a
      # retained mutation; dispatch runs only on a FRESH begin response (a
      # replayed begin is an observation, never a second dispatch), and the
      # collected context returns through submit_review_context so the round
      # ingests the exact canonical prompt bytes without re-upload.
      class OrdinaryCampaignRunner
        ReceiptTransfer = ->(receipt_sha256:, artifacts:) do
          artifacts.map { |entry| {"path" => entry.fetch(:path), "sha256" => entry.fetch(:sha256)} }
        end

        def initialize(project:, client: nil, review: nil)
          @project = project
          @client = client || Organisms::OrdinaryAssignmentClient.new(project: project)
          @review = review || Ace::Review::Organisms::PreparedCandidateReview
        end

        # reviewer: identity mapping with actor/role/runtime/pane; candidate:
        # the canonical candidate reference view (head/tree + reader); identity
        # of the reviewer supplies the receipt producer.
        def run(review_id:, producer:, reviewer:, candidate:, subject:,
                session_dir:, output:, campaign:, deadline: nil)
          require_dir!(session_dir)
          require_dir!(output)
          begin_request = retain_request(output, "campaign-begin", {
            "version" => 1, "project_id" => @project, "operation" => "campaign_begin",
            "mutation_id" => mutation_id("begin", review_id),
            "params" => {"assignment_id" => producer.fetch("assignment_id"), "attempt_id" => producer.fetch("attempt_id"),
              "expected_generation" => producer.fetch("expected_generation"), "pane" => reviewer.fetch("pane"),
              "head" => candidate.fetch("head"), "candidate_generation" => candidate.fetch("candidate_generation"),
              "review_id" => review_id}, "parts" => []
          }, [])
          begun = @client.request(input: begin_request)
          session_binding = begun.fetch("data").fetch("session_binding")
          if begun.fetch("transport").fetch("replayed")
            return {"begun" => false, "replayed" => true, "session_binding" => session_binding, "dispatched" => false}
          end
          expected = {"campaign_id" => begun.fetch("data").fetch("campaign_id"),
            "round_id" => begun.fetch("data").fetch("round_id"), "scope" => begun.fetch("data").fetch("scope")}
          dispatched = false
          boundary = ->(binding:, model:, &dispatch) do
            unless binding.is_a?(Hash) && binding.values_at("campaign_id", "round_id", "scope") ==
                expected.values_at("campaign_id", "round_id", "scope") &&
                binding.fetch("head") == candidate.fetch("head") && binding.fetch("base") == campaign.fetch("base")
              raise ArgumentError, "campaign execution boundary binding differs from its canonical begin"
            end
            dispatched = true
            dispatch.call
          end
          executed = @review.execute_prepared_campaign(candidate: candidate, subject: subject,
            session_dir: session_dir, campaign_binding: binding_for(begun.fetch("data"), candidate, campaign, subject),
            execution_boundary: boundary)
          unless dispatched && executed.is_a?(Hash) && executed[:success]
            return {"begun" => true, "replayed" => false, "dispatched" => false,
              "session_binding" => session_binding,
              "error" => executed.is_a?(Hash) ? executed[:error] : "execution boundary withheld dispatch"}
          end
          if executed.fetch(:artifacts).length > Ace::Assign::Atoms::CandidateLimits::REVIEW_CONTEXT_ARTIFACTS
            return {"begun" => true, "replayed" => false, "dispatched" => true, "session_binding" => session_binding,
              "error" => "campaign context exceeds the review-context artifact count "                 "(#{executed.fetch(:artifacts).length} > #{Ace::Assign::Atoms::CandidateLimits::REVIEW_CONTEXT_ARTIFACTS}); "                 "reduce the feedback inventory for this round"}
          end
          verdict = executed[:verdict]
          unless verdict == "approved"
            return {"begun" => true, "replayed" => false, "dispatched" => true, "session_binding" => session_binding,
              "error" => "campaign review verdict was not approved: #{verdict.inspect}"}
          end
          artifacts = executed.fetch(:artifacts)
          receipt = reviewer_receipt(review_id, reviewer, candidate, begun.fetch("data"), artifacts)
          submit_request = retain_request(output, "review-context", {
            "version" => 1, "project_id" => @project, "operation" => "submit_review_context",
            "mutation_id" => mutation_id("context", review_id),
            "params" => {"assignment_id" => reviewer.fetch("assignment_id"), "attempt_id" => reviewer.fetch("attempt_id"),
              "expected_generation" => reviewer.fetch("expected_generation"), "pane" => reviewer.fetch("pane"),
              "head" => candidate.fetch("head"), "receipt_sha256" => receipt.fetch(:sha256),
              "review_id" => review_id, "producer_assignment_id" => producer.fetch("assignment_id")},
            "parts" => ([{"file" => "receipt.json", "bytes" => receipt.fetch(:bytes),
              "sha256" => receipt.fetch(:sha256)}] + artifacts.map { |entry|
              {"file" => entry.fetch(:path), "bytes" => entry.fetch(:bytes), "sha256" => entry.fetch(:sha256)} })
          }, [receipt.fetch(:bytes)] + artifacts.map { |entry| entry.fetch(:bytes) })
          submitted = @client.request(input: submit_request)
          {"begun" => true, "replayed" => false, "dispatched" => true,
            "session_binding" => session_binding, "result" => submitted.fetch("data")}
        end

        private

        def binding_for(begin_data, candidate, campaign, subject)
          {"campaign_id" => begin_data.fetch("campaign_id"), "round_id" => begin_data.fetch("round_id"),
            "scope" => begin_data.fetch("scope"), "head" => candidate.fetch("head"),
            "base" => campaign.fetch("base"), "contract_identity" => campaign.fetch("contract_identity"),
            "scope_identity" => campaign.fetch("scope_identity"), "subject" => subject}.freeze
        end

        def reviewer_receipt(review_id, reviewer, candidate, begin_data, artifacts)
          campaign = begin_data.slice("campaign_id", "round_id", "scope", "execution_id")
          payload = {"assignment_id" => reviewer.fetch("assignment_id"), "attempt_id" => reviewer.fetch("attempt_id"),
            "project_id" => @project, "scope" => reviewer.fetch("scope"),
            "operation" => "review-collect", "producer" => reviewer.slice("actor", "role", "runtime"),
            "head" => candidate.fetch("head"), "verdict" => "succeeded",
            "checks" => [{"name" => "review-execution", "verdict" => "passed"}],
            "review" => {"head" => candidate.fetch("head"), "verdict" => "approved",
              "reviewer" => {"actor" => reviewer.fetch("actor")}, "review_id" => review_id, "campaign" => campaign},
            "artifacts" => artifacts.map { |entry| {"path" => entry.fetch(:path), "sha256" => entry.fetch(:sha256)} }}
          bytes = JSON.pretty_generate(payload) + "\n"
          {bytes: bytes.b, sha256: Digest::SHA256.hexdigest(bytes)}
        end

        def retain_request(output, name, request, part_bytes)
          path = File.join(output, "#{name}-request.json")
          File.write(path, JSON.pretty_generate(request) + "\n")
          request.fetch("parts").each_with_index do |part, index|
            File.binwrite(File.join(output, part.fetch("file")), part_bytes.fetch(index))
          end
          path
        end

        def mutation_id(kind, review_id)
          "campaign-#{kind}-#{SecureRandom.hex(8)}-#{review_id}"[0, 64]
        end

        def require_dir!(path)
          raise ArgumentError, "campaign runner requires a new private directory: #{path}" unless File.directory?(path)
        end
      end
    end
  end
end
