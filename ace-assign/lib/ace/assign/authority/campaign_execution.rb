# frozen_string_literal: true

require "ace/git/atoms/pr_identifier"
require "ace/review/atoms/campaign_contract"
require_relative "../molecules/receipt_verifier"

module Ace
  module Assign
    module Authority
      # Closed child linkage. Validation is structural; the registration owner
      # must independently compare it with canonical parent/campaign state.
      module CampaignExecution
        Contract = Ace::Review::Atoms::CampaignContract
        FIELDS = %w[version parent_assignment_id parent_attempt_id parent_scope parent_candidate_generation
          subject campaign_id contract_identity policy_digest round_id phase review_scope scope_identity_digest
          head base operation check_name].sort.freeze

        def self.validate_parent!(value)
          unless value.is_a?(Hash) && value.keys.sort == %w[campaign_id contract_identity policy subject version] &&
              value["version"].is_a?(Integer) && value["version"] == 1
            raise ArgumentError, "parent campaign fields differ"
          end
          Contract.id!(value["campaign_id"], "campaign ID")
          unless value["contract_identity"].is_a?(String) && /\A[0-9a-f]{64}\z/.match?(value["contract_identity"]) &&
              Contract.subject!(value["subject"]) == value["subject"]
            raise ArgumentError, "parent campaign identity differs"
          end
          Contract.policy!(value["policy"])
          value
        end

        def self.validate_round!(value, parent:, round:)
          validate!(value, parent: parent, policy: round.fetch("policy"))
          binding = round.fetch("binding")
          expected = round.slice("campaign_id", "subject", "contract_identity", "round_id").merge(
            "head" => binding.fetch("head"), "base" => binding.fetch("base"),
            "scope_identity_digest" => Contract.digest(binding.fetch("scope_identity").fetch(value.fetch("review_scope"))))
          unless expected.all? { |key, item| value.fetch(key) == item }
            raise ArgumentError, "campaign execution differs from pinned round"
          end
          value
        rescue KeyError, TypeError
          raise ArgumentError, "campaign execution round is incomplete"
        end

        # This does not accept a receipt; the canonical result owner still
        # validates its producer, artifacts and introduction before use.
        def self.validate_result!(value, receipt:, base:)
          unless receipt.is_a?(Hash) && receipt["campaign"].nil? &&
              receipt["operation"] == value.fetch("operation") &&
              receipt["head"] == value.fetch("head") && base == value.fetch("base")
            raise ArgumentError, "campaign child result differs from registered phase or candidate"
          end
          if receipt["verdict"] == "succeeded" && !Array(receipt["checks"]).any? { |check|
              check.is_a?(Hash) && check["name"] == value.fetch("check_name") && check["verdict"] == "passed" }
            raise ArgumentError, "campaign child result lacks its executed phase check"
          end
          value
        rescue KeyError, TypeError
          raise ArgumentError, "campaign child result binding is incomplete"
        end

        def self.validate_finished_review!(value, receipt:, accepted_review:)
          executed = Array(receipt.fetch("artifacts")).map { |ref| ref.fetch("sha256") }
          reviewed = Array(accepted_review.fetch("artifacts")).map { |ref| ref.fetch("sha256") }
          unless (executed - reviewed).empty?
            raise ArgumentError, "independent campaign review does not cover executed artifacts"
          end
          if value.fetch("phase") == "approval" && receipt["review"] != accepted_review.fetch("review")
            raise ArgumentError, "campaign approval differs from canonical independent review"
          end
          true
        rescue KeyError, TypeError
          raise ArgumentError, "campaign independent review binding is incomplete"
        end

        def self.validate!(value, parent:, policy:)
          unless value.is_a?(Hash) && value.keys.sort == FIELDS && value["version"].is_a?(Integer) && value["version"] == 1
            raise ArgumentError, "campaign execution fields differ"
          end
          %w[parent_assignment_id parent_attempt_id parent_scope campaign_id round_id review_scope].each do |key|
            Contract.id!(value[key], key)
          end
          unless value["parent_assignment_id"] == parent && value["parent_candidate_generation"].is_a?(Integer) &&
              value["parent_candidate_generation"] >= 0
            raise ArgumentError, "campaign execution parent differs"
          end
          %w[contract_identity policy_digest scope_identity_digest].each do |key|
            unless value[key].is_a?(String) && /\A[0-9a-f]{64}\z/.match?(value[key])
              raise ArgumentError, "campaign execution digest differs"
            end
          end
          %w[head base].each { |key| Contract.sha!(value[key], key) }
          unless Contract.subject!(value["subject"]) == value["subject"]
            raise ArgumentError, "campaign execution subject is not canonical"
          end
          policy = Contract.policy!(policy)
          unless Contract.digest(policy) == value["policy_digest"] && policy["required_scopes"].include?(value["review_scope"])
            raise ArgumentError, "campaign execution policy differs"
          end
          expected = case value["phase"]
          when "collection" then ["review-collect", "review-execution"]
          when "approval" then ["review", "review-approval"]
          when "check"
            check = value["check_name"]
            if Molecules::ReceiptVerifier::EXTERNAL_EFFECT_OPERATIONS.include?(check)
              raise ArgumentError, "external effects cannot be campaign checks"
            end
            raise ArgumentError, "campaign execution check is not required" unless policy["required_checks"].include?(check)
            [check == "tests" ? "test" : check, check]
          else raise ArgumentError, "campaign execution phase differs"
          end
          raise ArgumentError, "campaign execution operation differs" unless value.values_at("operation", "check_name") == expected
          value
        end
      end
    end
  end
end
