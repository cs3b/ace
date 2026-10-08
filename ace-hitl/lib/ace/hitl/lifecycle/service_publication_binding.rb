# frozen_string_literal: true
require_relative "binding"
require "json"

module Ace
  module Hitl
    module Lifecycle
      # Constructed beside the same-process authority, never from wire data.
      # The selector is routing data; only the authority's held callback can
      # admit a store transition for the original receiver process.
      class ServicePublicationBinding < Binding
        FIELDS = %w[schema mapping_id assignment_id attempt_id request_id claim_binding input_digest
          candidate_generation head challenge_digest].freeze

        def initialize(ordinary:, authority:, kernel:)
          @ordinary, @authority, @kernel = ordinary, authority, kernel
        end

        def validate_request(**params)
          deny_executor_ordinary!(params.fetch(:project), params[:caller_pid])
          @ordinary.validate_request(**params)
        end

        def reverse_address(**params)
          @ordinary.reverse_address(**params)
        end

        def with_active(**params, &block)
          @ordinary.with_active(**params, &block)
        end

        def proposal_journal(project:)
          @ordinary.proposal_journal(project: project)
        end

        def proposal_projects
          @ordinary.proposal_projects
        end

        def with_publication!(binding:, identity:, assignment:, attempt:, project:, otp:, original_peer: nil, requester_required: true)
          unless binding.is_a?(Hash) && binding.keys.sort == FIELDS.sort &&
              binding["schema"] == "ace.hitl-publication-binding/v1" &&
              binding["assignment_id"] == assignment && binding["attempt_id"] == attempt &&
              %w[mapping_id assignment_id attempt_id request_id].all? { |key| binding[key].is_a?(String) && binding[key].match?(/\A[a-zA-Z0-9][a-zA-Z0-9._:-]{0,127}\z/) } &&
              %w[claim_binding input_digest challenge_digest].all? { |key| binding[key].is_a?(String) && binding[key].match?(/\A[0-9a-f]{64}\z/) } &&
              binding["head"].is_a?(String) && binding["head"].match?(/\A[0-9a-f]{40}\z/) &&
              binding["candidate_generation"].is_a?(Integer) && binding["candidate_generation"].positive? &&
              otp.is_a?(Hash) && otp["operation"] == "publish" && otp["input_digest"] == binding["input_digest"]
            raise BindingError, "publication HITL selector differs"
          end
          caller = requester_required ? actual_peer!(identity) : original_peer
          raise BindingError, "publication original receiver differs" if original_peer && caller != original_peer
          @authority.with_publication_hitl!(binding: binding, project: project, peer: caller) do |selection|
            unless selection.fetch("challenge_ref") == otp["result_ref"] && selection.fetch("executor_process_binding") == caller
              raise BindingError, "publication challenge or receiver differs"
            end
            yield selection
          end
        rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError => e
          raise BindingError, "publication authority unavailable (#{e.class.name})"
        end

        def verify_publication_requester!(identity:, original_peer:)
          raise BindingError, "publication original receiver differs" unless actual_peer!(identity) == original_peer
          true
        end

        private

        def actual_peer!(identity)
          unless identity.respond_to?(:pid) && identity.pid.is_a?(Integer) && identity.pid.positive?
            raise BindingError, "publication kernel peer is unavailable"
          end
          peer = @kernel.capture(identity.pid)
          unless peer["uid"] == identity.uid && peer["gid"] == identity.gid
            raise BindingError, "publication kernel credentials differ"
          end
          @kernel.live!(peer)
          peer
        end

        def deny_executor_ordinary!(project, pid)
          unless pid.is_a?(Integer) && pid.positive?
            raise BindingError, "HITL kernel requester is unavailable"
          end
          peer = @kernel.capture(pid)
          @kernel.live!(peer)
          if @authority.publication_executor_identity?(project: project, uid: peer.fetch("uid"))
            raise BindingError, "executor cannot select an ordinary worker HITL request"
          end
        rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError => error
          raise BindingError, "HITL kernel requester unavailable (#{error.class.name})"
        end
      end
    end
  end
end
