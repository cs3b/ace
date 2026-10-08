# frozen_string_literal: true
require "ace/herdr/molecules/inbox_context_client"

module Ace
  module Assign
    module Authority
      class Endcap
        private

        def with_inbox_context(params, map, mutation_id:)
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          @deployment.verify_inbox_context!(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          client = @inbox_context_clients&.fetch(params.fetch("inbox_context_id"))
          client ||= Ace::Herdr::Molecules::InboxContextClient.selected(context_id: params.fetch("inbox_context_id"),
            socket_path: context.fetch("control_socket_path"), owner_credentials: context.fetch("owner_credentials"), kernel: @kernel)
          yield client
        rescue Ace::Runtime::RuntimeUnavailableError, Ace::Herdr::Error
          raise AttemptErrors::EvidenceUnavailable, "protected inbox context is unavailable"
        end
      end
    end
  end
end
