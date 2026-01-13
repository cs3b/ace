# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module Ace
  module Support
    module Models
      module Atoms
        # Fetches data from the models.dev API using Faraday (ADR-010 compliant)
        class ApiFetcher
          API_URL = "https://models.dev/api.json"
          TIMEOUT = 30
          OPEN_TIMEOUT = 10
          MAX_RETRIES = 2
          RETRY_INTERVAL = 0.5

          class << self
            # Fetch the API JSON
            # @param url [String] API URL (default: models.dev)
            # @return [String] Raw JSON response
            # @raise [NetworkError] on network failures
            # @raise [ApiError] on non-200 responses
            def fetch(url = API_URL)
              response = connection.get(url)

              unless response.success?
                raise ApiError.new(
                  "API request failed: #{response.status} #{response.reason_phrase}",
                  status_code: response.status
                )
              end

              response.body
            rescue Faraday::TimeoutError => e
              raise NetworkError, "Request timed out: #{e.message}"
            rescue Faraday::ConnectionFailed => e
              raise NetworkError, "Connection failed: #{e.message}"
            rescue Faraday::SSLError => e
              raise NetworkError, "SSL error: #{e.message}"
            rescue Faraday::Error => e
              raise NetworkError, "Network error fetching API: #{e.message}"
            end

            private

            # Build Faraday connection with retry middleware
            # @return [Faraday::Connection]
            def connection
              @connection ||= Faraday.new do |faraday|
                faraday.options.timeout = TIMEOUT
                faraday.options.open_timeout = OPEN_TIMEOUT

                # Retry middleware for transient failures (ADR-010)
                faraday.request :retry, {
                  max: MAX_RETRIES,
                  interval: RETRY_INTERVAL,
                  interval_randomness: 0.5,
                  backoff_factor: 2,
                  retry_statuses: [429, 500, 502, 503, 504],
                  methods: [:get]
                }

                # Set headers
                faraday.headers["User-Agent"] = "ace-models/#{VERSION}"
                faraday.headers["Accept"] = "application/json"

                faraday.adapter Faraday.default_adapter
              end
            end
          end
        end
      end
    end
  end
end
