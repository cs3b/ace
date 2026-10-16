# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Collection execution is the existing reviewer's ordinary result and
      # terminal receipt. It is not approval and does not count a campaign round
      # until CampaignEvidence validates its pinned session and report bytes.
      module OrdinaryReviewCollection
        def with_review_collection!(events:, commit:, reference:)
          raise ArgumentError, "ordinary collection requires a block" unless block_given?
          strict!(reference, %w[review_id reviewer_assignment_id reviewer_attempt_id result_id receipt_digest])
          reference.except("receipt_digest").each_value { |value| token!(value) }
          unless reference.fetch("receipt_digest").is_a?(String) && reference.fetch("receipt_digest").match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "ordinary collection receipt digest is invalid"
          end
          origin_at!(events: events, commit: commit)
          selection = ordinary_review_selection!(events, reference.fetch("review_id"))
          assigned = selection.fetch("payload").fetch("data")
          unless assigned.slice("reviewer_assignment_id", "reviewer_attempt_id") == reference.slice("reviewer_assignment_id", "reviewer_attempt_id")
            raise AttemptErrors::ReceiptRejected, "ordinary collection belongs to another reviewer attempt"
          end
          producer, reviewer = ordinary_review_origins!(events, commit, assigned)
          params = {"assignment_id" => assigned.fetch("reviewer_assignment_id"), "attempt_id" => assigned.fetch("reviewer_attempt_id")}
          reviewer_events = result_events(params, commit)
          result = retained_ordinary_result(params, reviewer_events, commit)
          terminals = reviewer_events.select { |event| event["type"] == "receipt_accepted" }
          completions = reviewer_events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "finish" }
          unless result && Molecules::CanonicalAttemptState.derive(reviewer_events) == "succeeded" && terminals.one? && completions.one? &&
              result.fetch("result_id") == reference.fetch("result_id") && result.dig("receipt", "digest") == reference.fetch("receipt_digest") &&
              result.dig("receipt", "operation") == "review-collect" && result.dig("receipt", "verdict") == "succeeded" &&
              result.dig("receipt", "head") == assigned.fetch("head") &&
              result.dig("binding", "runtime_binding") == reviewer.fetch("runtime_binding") &&
              terminals.first.dig("payload", "receipt") == result.fetch("receipt") &&
              completions.first.dig("payload", "data").values_at("result_id", "receipt_digest", "state") ==
                [reference.fetch("result_id"), reference.fetch("receipt_digest"), "succeeded"]
            raise AttemptErrors::EvidenceUnavailable, "ordinary collection has no exact successful terminal execution"
          end
          unless result.fetch("receipt").fetch("checks").any? { |check| check["name"] == "review-execution" && check["verdict"] == "passed" }
            raise AttemptErrors::ReceiptRejected, "ordinary collection phase differs"
          end
          proof = result.fetch("receipt").merge("result_id" => result.fetch("result_id"),
            "receipt_digest" => reference.fetch("receipt_digest"), "journal_commit" => commit,
            "execution_binding" => {"authority" => "ordinary", "project_id" => @project,
              "producer_origin" => producer, "reviewer_origin" => reviewer,
              "review_selection_digest" => selection.fetch("digest"),
              "terminal_event_digest" => terminals.first.fetch("digest")})
          canonical = Molecules::CanonicalEvidence.new(journal: @journal)
          active, thread = true, Thread.current
          reader = lambda do |artifact|
            unless active && Thread.current.equal?(thread) && @journal.ref_value == commit && proof.fetch("artifacts").include?(artifact)
              raise AttemptErrors::EvidenceUnavailable, "ordinary collection artifact escaped its canonical scope"
            end
            canonical.read({"ref" => artifact.fetch("path"), "sha256" => artifact.fetch("sha256")},
              **ordinary_result_context(result.fetch("binding")), commit: commit)
          end
          yield proof, reader
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "ordinary collection evidence is incomplete"
        ensure
          active = false
        end
      end
    end
  end
end
