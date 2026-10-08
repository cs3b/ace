# frozen_string_literal: true
require "ace/review"

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        private

        # Called inside the existing lifecycle exclusions and authority mutex,
        # before entering the journal mutation; the store lock spans CAS retries.
        def with_parent_campaign_registration(params, context, replay:)
          # A stored mutation remains a historical observation after supersession.
          # The journal still verifies its operation and exact parameters below.
          return yield if replay
          return yield unless params.key?("definition_bytes")
          definition = JSON.parse(params.fetch("definition_bytes"))
          return yield unless definition.key?("review_campaign")
          selected = CampaignExecution.validate_parent!(definition.fetch("review_campaign"))
          descriptor = context.fetch(:descriptor)
          map = context.fetch(:map)
          project = descriptor.project(map.fetch("project_id"))
          service = descriptor.authority(map.fetch("authority_id"))
          %w[campaign_repository campaign_store_root].each do |key|
            path = project.fetch(key)
            wire.root_path!(path, directory: true, owner: service.fetch("uid"))
            unless (File.stat(path).mode & 0o077).zero?
              raise AttemptErrors::EvidenceUnavailable, "campaign owner root must remain private"
            end
          end
          store = Ace::Review::Molecules::CampaignStore.new(root: project.fetch("campaign_store_root"))
          manager = Ace::Review::Organisms::CampaignManager.new(repo_root: project.fetch("campaign_repository"), store: store)
          manager.with_campaign_registration!(selected.fetch("campaign_id"), subject: selected.fetch("subject"),
            contract_identity: selected.fetch("contract_identity"), policy: selected.fetch("policy")) { yield }
        rescue KeyError, TypeError, JSON::ParserError, Ace::Review::Atoms::CampaignContract::Invalid
          raise AttemptErrors::EvidenceUnavailable, "registered parent campaign is unavailable"
        end
      end
    end
  end
end
