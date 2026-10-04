# frozen_string_literal: true

require "digest"
require "json"
require "faraday"
require "faraday/retry"
require "openssl"
require_relative "repository_binding"

module Ace
  module Git
    module Forgejo
      # Authenticated, repository-bound JSON transport for Forgejo API
      # capabilities whose fj v0.6 output omits stable object IDs.
      #
      # Live traffic uses Faraday (ADR-010): no redirect middleware is
      # installed (a redirect must never carry credentials or a write to
      # another host; the configured endpoint is verified up front by
      # {RepositoryBinding.reject_selected_host_redirect!}), and retries are
      # limited to the safe GET verb — a mutation is sent at most once per
      # call, so a lost response stays an unknown outcome.
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

        # Send one request and classify every non-success status with the
        # shared taxonomy.
        #
        # @return [Object, nil] parsed JSON body (nil when empty)
        def request(method, suffix, body: nil)
          status, payload = exchange(method, suffix, body: body)
          classify_status!(status, method, exchange_path(suffix))
          payload
        end

        # Send one request and return the raw HTTP outcome so endpoint-aware
        # callers can classify statuses the generic map cannot distinguish
        # (e.g. a 409 that may mean "already exists" on create or "head out
        # of date" on merge). Transport failures still classify by method:
        # reads are unreachable, mutations are unknown outcomes.
        #
        # @return [Array(Integer, Object, nil)] status, parsed JSON body
        #   (nil when empty), and the server-supplied error message for
        #   non-success statuses (sanitized, truncated)
        def exchange(method, suffix, body: nil)
          RepositoryBinding.reject_selected_host_redirect!(@target.host_url)
          path = exchange_path(suffix)
          if @runner
            result = @runner.call(args: ["forgejo-http", method.to_s.upcase, "#{@target.host_url}#{path}", body],
              timeout: @timeout, env: {})
            status = result[:status] || (result[:success] ? 200 : 503)
            payload = result[:stdout].to_s
          else
            response = connection(method).send(method, path) do |req|
              req.headers["Content-Type"] = "application/json" if body
              req.body = JSON.generate(body) if body
            end
            status = response.status
            payload = response.body.to_s
          end
          [status, parse_payload(payload), server_error_message(payload)]
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed, IOError, SocketError,
               OpenSSL::SSL::SSLError, SystemCallError => e
          error = (method == :get) ? Ace::Git::ProviderUnreachableError : Ace::Git::ProviderUnknownOutcomeError
          raise error, "Forgejo #{method} #{path} outcome unknown: #{e.class}"
        end

        private

        # Suffixes already carrying the API root are used verbatim (the
        # server-level /api/v1/version probe); everything else is
        # repository-scoped to the selected owner/repo.
        def exchange_path(suffix)
          return suffix if suffix.to_s.start_with?("/api/v1/")

          return "/api/v1/repos/#{@target.repo}" if suffix.to_s.empty?

          "/api/v1/repos/#{@target.repo}/#{suffix}"
        end

        # A non-JSON body is an absent payload, not a parse failure: the
        # status carries the outcome, and every consumer validates the shape
        # of what it reads, so malformed evidence still fails closed.
        def parse_payload(payload)
          return nil if payload.nil? || payload.empty?

          JSON.parse(payload)
        rescue JSON::ParserError
          nil
        end

        # The forge's own explanation for a failed status, sanitized: only
        # the JSON `message` string survives, truncated, so tokens and raw
        # response bodies never reach an error message.
        def server_error_message(payload)
          parsed = parse_payload(payload)
          return nil unless parsed.is_a?(Hash) && parsed["message"].is_a?(String)

          message = parsed["message"].strip
          message.empty? ? nil : message[0, 300]
        end

        # Connection per HTTP method: the retry middleware is installed only
        # for the safe verb so a mutation can never be silently re-sent.
        def connection(method)
          @connections = {} unless @connections.is_a?(Hash)
          @connections[method] ||= Faraday.new(url: @target.host_url) do |faraday|
            faraday.options.timeout = @timeout
            faraday.options.open_timeout = @timeout
            faraday.headers["Accept"] = "application/json"
            faraday.headers["Authorization"] = "token #{access_token!}"
            if method == :get
              faraday.request :retry, max: 2, methods: [:get], retry_if: ->(_env, _result) { false }
            end
            faraday.adapter Faraday.default_adapter
          end
        end

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
