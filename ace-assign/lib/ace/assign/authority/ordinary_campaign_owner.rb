# frozen_string_literal: true

require "ace/review/organisms/campaign_manager"
require_relative "campaign_consumer_policy"
require_relative "candidate_transfer"

module Ace
  module Assign
    module Authority
      # Installed capability for the existing CampaignStore. The lifecycle
      # supplies canonical candidate bytes and execution callbacks at its held
      # journal prefix. No requester repository or Review config is consulted.
      class OrdinaryCampaignOwner
        attr_reader :repository

        def initialize(repository:, store_root:, policy:, verify_selection:, consumer: CampaignConsumerPolicy.new)
          @repository, @store_root = PrivateDirectory.verify!(repository), PrivateDirectory.verify!(store_root)
          if @repository == @store_root || @repository.start_with?(@store_root + "/") || @store_root.start_with?(@repository + "/")
            raise ArgumentError, "ordinary campaign owner directories overlap"
          end
          CampaignConsumerPolicy.reference!(policy)
          @policy = JSON.parse(JSON.generate(policy), freeze: true)
          @verify_selection, @consumer = verify_selection, consumer
          verify!
        end

        def with(candidate:, bundle:, base:, guard:, evidence: {})
          raise ArgumentError, "ordinary campaign owner requires a block" unless block_given?
          verify!
          guard.call
          @consumer.with(@policy) do |profiles, held|
            quarantine = File.join(@repository, ".ace-local", "review", "candidate-views")
            FileUtils.mkdir_p(quarantine, mode: 0o700)
            PrivateDirectory.verify!(quarantine)
            CandidateTransfer.new(root: quarantine).with_campaign_repository(bytes: bundle,
              sha256: candidate.fetch("sha256"), size: candidate.fetch("bytes"), head: candidate.fetch("head"),
              tree: candidate.fetch("tree"), base: base) do |reader|
              unavailable = ->(*, **) { raise AttemptErrors::EvidenceUnavailable, "ordinary campaign execution owner is unavailable" }
              dependencies = {check_evidence: unavailable, review_evidence: unavailable,
                approval_evidence: unavailable, head_assessment_evidence: unavailable}.merge(evidence)
              manager = Ace::Review::Organisms::CampaignManager.new(repo_root: @repository,
                store: Ace::Review::Molecules::CampaignStore.new(root: @store_root), candidate_reader: reader, **dependencies)
              recheck = -> { verify!; held.verify_unchanged!; guard.call }
              recheck.call
              result = yield manager, profiles, recheck
              recheck.call
              result
            end
          end
        end

        private

        def verify!
          @verify_selection.call
          PrivateDirectory.verify!(@repository)
          PrivateDirectory.verify!(@store_root)
        end
      end
    end
  end
end
