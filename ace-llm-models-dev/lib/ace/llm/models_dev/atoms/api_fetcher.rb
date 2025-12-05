# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"

module Ace
  module LLM
    module ModelsDev
      module Atoms
        # Fetches data from the models.dev API
        class ApiFetcher
          API_URL = "https://models.dev/api.json"
          TIMEOUT = 30

          class << self
            # Fetch the API JSON
            # @param url [String] API URL (default: models.dev)
            # @return [String] Raw JSON response
            # @raise [NetworkError] on network failures
            # @raise [ApiError] on non-200 responses
            def fetch(url = API_URL)
              uri = URI.parse(url)
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = uri.scheme == "https"
              http.open_timeout = TIMEOUT
              http.read_timeout = TIMEOUT

              if http.use_ssl?
                http.verify_mode = OpenSSL::SSL::VERIFY_PEER
                http.cert_store = build_cert_store
              end

              request = Net::HTTP::Get.new(uri.request_uri)
              request["User-Agent"] = "ace-llm-models-dev/#{VERSION}"
              request["Accept"] = "application/json"

              response = http.request(request)

              unless response.is_a?(Net::HTTPSuccess)
                raise ApiError.new(
                  "API request failed: #{response.code} #{response.message}",
                  status_code: response.code.to_i
                )
              end

              response.body
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT,
                   Net::OpenTimeout, Net::ReadTimeout, SocketError,
                   OpenSSL::SSL::SSLError => e
              raise NetworkError, "Network error fetching API: #{e.message}"
            end

            private

            # Build a cert store with system CA certificates
            # Uses default paths without CRL checking (OpenSSL 3.x compatibility)
            # @return [OpenSSL::X509::Store]
            def build_cert_store
              store = OpenSSL::X509::Store.new
              store.set_default_paths
              store
            end
          end
        end
      end
    end
  end
end
