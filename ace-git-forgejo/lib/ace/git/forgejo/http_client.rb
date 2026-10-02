# frozen_string_literal: true

require "digest"
require "json"
require "net/http"
require "openssl"
require "uri"
require_relative "repository_binding"

module Ace
  module Git
    module Forgejo
      # Authenticated, repository-bound JSON transport for Forgejo API
      # capabilities whose fj v0.6 output omits stable object IDs.
      class HttpClient
        def initialize(server:, timeout:, runner: nil)
          @target = RepositoryBinding::Target.resolve(server.url)
          @timeout = timeout
          @runner = runner
        end

        def paginate(suffix)
          page = 1
          entries = []
          seen_pages = {}
          loop do
            separator = suffix.include?("?") ? "&" : "?"
            batch = request(:get, "#{suffix}#{separator}page=#{page}&limit=50")
            unless batch.is_a?(Array)
              raise Ace::Git::ProviderMalformedOutputError, "Forgejo #{suffix} did not return a list"
            end
            entries.concat(batch)
            # A server may cap pages below the requested limit, so a short
            # page is not proof of the end; stop only on an empty page and
            # guard against servers repeating the same page forever.
            break if batch.empty?
            digest = Digest::SHA256.hexdigest(batch.to_s)
            raise Ace::Git::ProviderMalformedOutputError,
              "Forgejo #{suffix} pagination repeated page #{page}" if seen_pages[digest]

            seen_pages[digest] = true
            page += 1
          end
          entries
        end

        def request(method, suffix, body: nil)
          RepositoryBinding.reject_selected_host_redirect!(@target.host_url)
          path = "/api/v1/repos/#{@target.repo}/#{suffix}"
          if @runner
            result = @runner.call(args: ["forgejo-http", method.to_s.upcase, "#{@target.host_url}#{path}", body],
              timeout: @timeout, env: {})
            status = result[:status] || (result[:success] ? 200 : 503)
            payload = result[:stdout].to_s
          else
            uri = URI.parse("#{@target.host_url}#{path}")
            klass = {get: Net::HTTP::Get, post: Net::HTTP::Post, patch: Net::HTTP::Patch}.fetch(method)
            req = klass.new(uri)
            req["Authorization"] = "token #{access_token!}"
            req["Accept"] = "application/json"
            req["Content-Type"] = "application/json" if body
            req.body = JSON.generate(body) if body
            response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
              open_timeout: @timeout, read_timeout: @timeout) { |http| http.request(req) }
            status = response.code.to_i
            payload = response.body.to_s
          end
          classify_status!(status, method, path)
          return nil if payload.empty?

          JSON.parse(payload)
        rescue JSON::ParserError => e
          raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo response: #{e.message}"
        rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, IOError, SocketError, OpenSSL::SSL::SSLError, SystemCallError => e
          error = (method == :get) ? Ace::Git::ProviderUnreachableError : Ace::Git::ProviderUnknownOutcomeError
          raise error, "Forgejo #{method} #{path} outcome unknown: #{e.class}"
        end

        private

        def access_token!
          path = RepositoryBinding.default_keys_path
          data = path && JSON.parse(File.read(path))
          # fj stores credentials under the bare host (or host:port)
          # authority, never the scheme-prefixed URL.
          login = data.is_a?(Hash) && data.fetch("hosts", {})[@target.authority]
          token = login.is_a?(Hash) && login["token"]
          return token if token.is_a?(String) && !token.empty?

          raise Ace::Git::ProviderAuthenticationError,
            "No fj token for selected host #{@target.authority}; authenticate with fj first"
        rescue Errno::ENOENT, Errno::EACCES, JSON::ParserError
          raise Ace::Git::ProviderAuthenticationError,
            "Cannot read fj authentication for selected host #{@target.authority}"
        end

        def classify_status!(status, method, path)
          return if (200..299).cover?(status.to_i)

          error = case status.to_i
          when 401, 403 then Ace::Git::ProviderAuthenticationError
          when 404 then Ace::Git::ProviderObjectNotFoundError
          when 409, 422 then Ace::Git::ProviderIdentityMismatchError
          else (method == :get) ? Ace::Git::ProviderUnreachableError : Ace::Git::ProviderUnknownOutcomeError
          end
          raise error, "Forgejo #{method} #{path} returned HTTP #{status}"
        end
      end
    end
  end
end
