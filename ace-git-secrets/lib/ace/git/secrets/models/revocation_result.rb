# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Models
        # Represents the result of a token revocation attempt
        # Immutable value object containing revocation outcome
        class RevocationResult
          attr_reader :token, :service, :status, :message, :revoked_at

          # Valid revocation statuses
          STATUSES = %w[revoked failed unsupported skipped].freeze

          # @param token [DetectedToken] The token that was revoked
          # @param service [String] Service name (github, anthropic, openai, aws)
          # @param status [String] Revocation status (revoked, failed, unsupported, skipped)
          # @param message [String, nil] Additional message or error details
          # @param revoked_at [Time, nil] Timestamp of revocation
          def initialize(token:, service:, status:, message: nil, revoked_at: nil)
            @token = token
            @service = service
            @status = validate_status(status)
            @message = message
            @revoked_at = revoked_at || ((status == "revoked") ? Time.now : nil)

            freeze
          end

          # Check if revocation was successful
          # @return [Boolean]
          def success?
            status == "revoked"
          end

          # Check if revocation failed
          # @return [Boolean]
          def failed?
            status == "failed"
          end

          # Check if token type is unsupported for revocation
          # @return [Boolean]
          def unsupported?
            status == "unsupported"
          end

          # Check if revocation was skipped
          # @return [Boolean]
          def skipped?
            status == "skipped"
          end

          # Convert to hash for serialization
          # @return [Hash]
          def to_h
            {
              token_type: token.token_type,
              masked_value: token.masked_value,
              service: service,
              status: status,
              message: message,
              revoked_at: revoked_at&.iso8601
            }
          end

          # Create a successful revocation result
          # @param token [DetectedToken] The token that was revoked
          # @param service [String] Service name
          # @param message [String, nil] Success message
          # @return [RevocationResult]
          def self.success(token:, service:, message: nil)
            new(
              token: token,
              service: service,
              status: "revoked",
              message: message || "Token successfully revoked"
            )
          end

          # Create a failed revocation result
          # @param token [DetectedToken] The token that failed to revoke
          # @param service [String] Service name
          # @param message [String] Error message
          # @return [RevocationResult]
          def self.failure(token:, service:, message:)
            new(
              token: token,
              service: service,
              status: "failed",
              message: message
            )
          end

          # Create an unsupported revocation result
          # @param token [DetectedToken] The token that cannot be revoked
          # @param service [String, nil] Service name
          # @return [RevocationResult]
          def self.unsupported(token:, service: nil)
            new(
              token: token,
              service: service || "unknown",
              status: "unsupported",
              message: "Token type #{token.token_type} does not support automatic revocation"
            )
          end

          private

          def validate_status(status)
            return status if STATUSES.include?(status)

            raise ArgumentError, "Invalid status: #{status}. Must be one of: #{STATUSES.join(", ")}"
          end
        end
      end
    end
  end
end
