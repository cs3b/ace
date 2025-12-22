# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Molecules
        # Orchestrates token revocation across multiple services
        # Routes tokens to appropriate service handlers
        class TokenRevoker
          attr_reader :api_client

          # @param api_client [Atoms::ServiceApiClient, nil] API client for revocation
          def initialize(api_client: nil)
            @api_client = api_client || Atoms::ServiceApiClient.new
          end

          # Revoke multiple tokens
          # @param tokens [Array<DetectedToken>] Tokens to revoke
          # @param services [Array<String>, nil] Filter to specific services
          # @return [Array<Models::RevocationResult>]
          def revoke_all(tokens, services: nil)
            tokens.map do |token|
              next unless token.revocable?
              next if services && !services.include?(token.revocation_service)

              revoke_token(token)
            end.compact
          end

          # Revoke a single token
          # @param token [DetectedToken] Token to revoke
          # @return [Models::RevocationResult]
          def revoke_token(token)
            service = token.revocation_service

            unless service
              return Models::RevocationResult.unsupported(token: token)
            end

            case service
            when "github"
              revoke_github(token)
            when "anthropic", "openai", "aws"
              # These services don't have public revocation APIs
              manual_revocation_result(token, service)
            else
              Models::RevocationResult.unsupported(token: token, service: service)
            end
          end

          # Get revocation instructions for a token
          # @param token [DetectedToken] Token to get instructions for
          # @return [Hash] Instructions hash
          def revocation_instructions(token)
            service = token.revocation_service
            api_client.build_revocation_request(service, token.raw_value)
          end

          private

          # Revoke GitHub token via API
          # @param token [DetectedToken]
          # @return [Models::RevocationResult]
          def revoke_github(token)
            result = api_client.revoke_github_token(token.raw_value)

            if result[:success]
              Models::RevocationResult.success(
                token: token,
                service: "github",
                message: result[:message]
              )
            else
              Models::RevocationResult.failure(
                token: token,
                service: "github",
                message: result[:message]
              )
            end
          end

          # Create result for services requiring manual revocation
          # @param token [DetectedToken]
          # @param service [String]
          # @return [Models::RevocationResult]
          def manual_revocation_result(token, service)
            instructions = api_client.build_revocation_request(service, token.raw_value)

            Models::RevocationResult.new(
              token: token,
              service: service,
              status: "skipped",
              message: "Manual revocation required. #{instructions[:notes]} Visit: #{instructions[:url]}"
            )
          end
        end
      end
    end
  end
end
