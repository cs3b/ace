# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module Ace
  module Git
    module Secrets
      module Atoms
        # HTTP API client for token revocation services
        # Builds requests for GitHub, Anthropic, OpenAI credential revocation APIs
        class ServiceApiClient
          # Default GitHub Credential Revocation API (unauthenticated, rate limited)
          DEFAULT_GITHUB_REVOKE_URL = "https://api.github.com/credentials/revoke"

          # Default user agent for API requests
          DEFAULT_USER_AGENT = "ace-git-secrets/#{Ace::Git::Secrets::VERSION}"

          attr_reader :timeout, :retry_count, :github_revoke_url, :github_api_base_url, :user_agent

          # @param timeout [Integer] Request timeout in seconds
          # @param retry_count [Integer] Number of retries
          # @param github_api_url [String, nil] Custom GitHub API URL (for GitHub Enterprise)
          # @param user_agent [String, nil] Custom User-Agent header
          def initialize(timeout: 30, retry_count: 3, github_api_url: nil, user_agent: nil)
            @timeout = timeout
            @retry_count = retry_count
            @github_api_base_url = github_api_url&.chomp("/") || "https://api.github.com"
            @github_revoke_url = "#{@github_api_base_url}/credentials/revoke"
            @user_agent = user_agent || DEFAULT_USER_AGENT
          end

          # Revoke a GitHub token
          # Uses GitHub's Credential Revocation API (unauthenticated)
          # Connection is reused for bulk revocation efficiency
          # @param token [String] The token to revoke
          # @param check_rate_limit [Boolean] Whether to check rate limit before request
          # @return [Hash] Result with :success, :message, :response keys
          def revoke_github_token(token, check_rate_limit: false)
            # Optionally check rate limit before attempting revocation
            if check_rate_limit
              rate_info = github_rate_limit
              if rate_info[:remaining].is_a?(Integer) && rate_info[:remaining] == 0
                reset_msg = rate_info[:reset_at] ? " Reset at #{rate_info[:reset_at]}" : ""
                return {
                  success: false,
                  message: "GitHub API rate limit exceeded.#{reset_msg}",
                  response: nil,
                  rate_limited: true
                }
              end
            end

            response = github_revoke_connection.post do |req|
              req.headers["Content-Type"] = "application/json"
              req.headers["Accept"] = "application/json"
              req.body = JSON.generate({credential: token})
            end

            parse_github_response(response)
          rescue Faraday::Error => e
            {success: false, message: "GitHub API error: #{e.message}", response: nil}
          end

          # Get cached GitHub revoke connection for bulk operations
          # @return [Faraday::Connection]
          def github_revoke_connection
            @github_revoke_connection ||= build_connection(github_revoke_url)
          end

          # Build revocation request for a service
          # @param service [String] Service name (github, anthropic, openai)
          # @param token [String] Token to revoke
          # @return [Hash] Request details for manual revocation if API not available
          def build_revocation_request(service, token)
            case service
            when "github"
              {
                method: :post,
                url: github_revoke_url,
                headers: {"Content-Type" => "application/json"},
                body: {credential: token},
                notes: "GitHub tokens can be revoked via API without authentication"
              }
            when "anthropic"
              {
                method: :manual,
                url: "https://console.anthropic.com/settings/keys",
                notes: "Anthropic API keys must be revoked manually via the console"
              }
            when "openai"
              {
                method: :manual,
                url: "https://platform.openai.com/api-keys",
                notes: "OpenAI API keys must be revoked manually via the platform"
              }
            when "aws"
              {
                method: :manual,
                url: "https://console.aws.amazon.com/iam/home#/security_credentials",
                notes: "AWS credentials must be rotated/deleted via IAM console"
              }
            else
              {
                method: :unsupported,
                url: nil,
                notes: "Automatic revocation not supported for #{service}"
              }
            end
          end

          # Check API rate limit status for GitHub
          # Uses configured GitHub API base URL (supports GitHub Enterprise)
          # @return [Hash] Rate limit info
          def github_rate_limit
            conn = Faraday.new(url: github_api_base_url) do |f|
              f.options.timeout = timeout
              if retry_count > 0
                f.request :retry, max: retry_count
              end
              f.adapter Faraday.default_adapter
            end

            response = conn.get("/rate_limit")

            if response.success?
              data = JSON.parse(response.body)
              resources = data["resources"]["core"]
              {
                limit: resources["limit"],
                remaining: resources["remaining"],
                reset_at: Time.at(resources["reset"])
              }
            else
              {limit: 60, remaining: "unknown", reset_at: nil}
            end
          rescue
            {limit: 60, remaining: "unknown", reset_at: nil}
          end

          private

          # Build Faraday connection
          # @param url [String] Base URL
          # @return [Faraday::Connection]
          def build_connection(url)
            Faraday.new(url: url) do |f|
              f.options.timeout = timeout
              f.headers["User-Agent"] = user_agent
              # Only add retry middleware if retry_count > 0
              # (Faraday 2.x requires faraday-retry gem for this)
              if retry_count > 0
                f.request :retry, max: retry_count, interval: 0.5,
                  exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
              end
              f.adapter Faraday.default_adapter
            end
          end

          # Parse GitHub API response
          # @param response [Faraday::Response]
          # @return [Hash]
          def parse_github_response(response)
            case response.status
            when 200, 204
              {success: true, message: "Token revoked successfully", response: response}
            when 404
              {success: false, message: "Token not found or already revoked", response: response}
            when 422
              {success: false, message: "Invalid token format", response: response}
            when 429
              {success: false, message: "Rate limit exceeded. Try again later.", response: response}
            else
              body = response.body.to_s
              message = begin
                JSON.parse(body)["message"]
              rescue
                body
              end
              {success: false, message: "GitHub API error: #{message}", response: response}
            end
          end
        end
      end
    end
  end
end
