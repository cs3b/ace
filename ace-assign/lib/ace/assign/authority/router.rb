# frozen_string_literal: true
module Ace
  module Assign
    module Authority
      # Source-owned handlers share one listener. Requests never name a method.
      class Router
        def initialize(launch: nil, handlers: [])
          @launch = launch
          @routes = {}
          ([launch].compact + handlers).each do |handler|
            handler.class::OPERATIONS.each do |operation|
              raise ArgumentError, "duplicate authority operation" if @routes.key?(operation)
              @routes[operation] = handler
            end
          end
          @routes.freeze
        end

        def dispatch(request:, peer:, role:, transfer: nil, deadline: nil)
          validate_review_namespace!(request)
          handler = @routes.fetch(request.fetch("operation")) { raise ArgumentError, "unknown authority operation" }
          options = {request: request, peer: peer, role: role}
          options[:transfer] = transfer if transfer
          options[:deadline] = deadline if deadline
          handler.dispatch(**options)
        end

        def transfer_binding(request)
          validate_review_namespace!(request)
          operation = request.fetch("operation")
          handler = @routes.fetch(operation) { raise ArgumentError, "unknown authority operation" }
          return nil unless handler.class.const_defined?(:TRANSFER_OPERATIONS, false)
          binding = handler.class::TRANSFER_OPERATIONS[operation]
          if operation == "evidence_fetch" && %w[prepared_work campaign_candidate].include?(request.dig("params", "kind"))
            binding = {direction: :download, purpose: :candidate, roles: [:worker]}
          end
          return nil unless binding
          unless binding.is_a?(Hash) && binding.keys.sort == %i[direction purpose roles] &&
              %i[upload download].include?(binding[:direction]) && TransferCodec::LIMITS.key?(binding[:purpose]) &&
              binding[:roles].is_a?(Array) && binding[:roles].all? { |role| %i[worker launcher reviewer executor supervisor observer signer].include?(role) }
            raise ArgumentError, "invalid source transfer binding"
          end
          binding
        end

        def authorize_transfer!(request:, peer:, role:, deadline: nil)
          validate_review_namespace!(request)
          handler = @routes.fetch(request.fetch("operation"))
          options = {request: request, peer: peer, role: role}
          options[:deadline] = deadline if deadline
          handler.authorize_transfer!(**options)
        end

        def validate_review_namespace!(request)
          if request["mutation_id"].is_a?(String) && request["mutation_id"].start_with?("review-reply.")
            raise ArgumentError, "reserved review reply namespace"
          end
          if request["mutation_id"].is_a?(String) && request["mutation_id"].start_with?("review-delegate.") &&
              request["operation"] != "assign_review"
            raise ArgumentError, "reserved review delegation namespace"
          end
        end
        private :validate_review_namespace!

        def close
          @routes.values.uniq.each { |handler| handler.close if handler.respond_to?(:close) }
        end

        def serve_launch_control!(**options)
          raise AttemptErrors::EvidenceUnavailable, "launch control is unavailable in this composition" unless @launch
          @launch.serve_launch_control!(**options)
        end

        def gate_ready(**options)
          raise AttemptErrors::EvidenceUnavailable, "launch gate is unavailable in this composition" unless @launch
          @launch.gate_ready(**options)
        end
      end
    end
  end
end
