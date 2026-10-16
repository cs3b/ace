# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Ace
  module Lab
    module Molecules
      # The Forgejo merge HTTP adapter (spec 8x3.t.xz9.5 integration
      # handoff): the receiver's one authorized effect is a real pull
      # request merge on the real forge, invoked under the scoped service
      # identity from the host-installed forge merge configuration, and
      # every terminal outcome is proven by a real readback — a local git
      # effect is never presented as a forge result. Ruby stdlib Net::HTTP
      # only: no new gem dependency, no queue, no credential bypass.
      #
      # Endpoints (forge API):
      # - `POST /api/v1/repos/{owner}/{repo}/pulls/{index}/merge` with
      #   `{"Do": "fast-forward-only", "head_commit_id": <approved sha>}` —
      #   the merge-method contract's literal `method=merge` is
      #   FAST-FORWARD-ONLY on the wire too, and the body binds the
      #   approved candidate head SERVER-SIDE: the forge refuses to merge
      #   any head other than the bound one, so a race between the state
      #   readback and the merge POST can never merge an unreviewed head.
      #   The adapter never silently substitutes another merge strategy.
      # - `GET  /api/v1/repos/{owner}/{repo}/pulls/{index}` — the PR state
      #   readback (`merged`, `merge_commit_sha`, head/base shas).
      # - `POST /api/v1/repos/{owner}/{repo}/issues/{index}/comments` —
      #   attaches the independent final-head review body to the PR before
      #   the merge (reviewer-produced content handed over in the request).
      #
      # Outcome classification is closed: a 2xx is `:invoked` and a
      # definitive 4xx refusal is `:refused`. Every unverifiable outcome —
      # 5xx responses, open or read timeout, connection reset — is either
      # `:ambiguous` (a returned Result on an HTTP-level 5xx) or an
      # `Unavailable` exception (transport-level failure), because the forge
      # may or may not have processed the request. The receiver reconciles
      # both identically: readback retry, never a blind repeat of the merge.
      # The token is never rendered in any error.
      class ForgejoMergeAdapter
        # The single authorized merge strategy on the wire.
        MERGE_METHOD = "fast-forward-only"

        class Unavailable < ::StandardError; end

        # outcome: :invoked | :refused | :ambiguous; status: Integer|nil;
        # reason: closed refuse/ambiguity detail (token-free).
        Result = Struct.new(:outcome, :status, :reason, keyword_init: true)

        def initialize(base_url:, token:, timeout_seconds: 900, open_timeout_seconds: 10)
          @base_url = base_url.to_s.sub(%r{/+\z}, "")
          @token = token
          @timeout_seconds = timeout_seconds
          @open_timeout_seconds = open_timeout_seconds
          freeze
        end

        # Invoke the eligible merge bound to the approved candidate head.
        # `head_commit_id` is required and validated (full 40-character hex
        # sha): the forge server-side refuses to merge any head other than
        # the bound one. Returns a Result; never raises for HTTP outcomes
        # (ambiguity is a result, not an exception).
        def merge_pull_request!(owner:, repo:, index:, head_commit_id:)
          unless head_commit_id.is_a?(String) && head_commit_id.match?(/\A[0-9a-f]{40}\z/)
            raise ArgumentError,
              "head_commit_id must be a full 40-character lowercase hex sha " \
                "(got: #{head_commit_id.inspect})"
          end
          request(:post, "/api/v1/repos/#{e(owner)}/#{e(repo)}/pulls/#{e(index)}/merge",
            body: JSON.generate("Do" => MERGE_METHOD, "head_commit_id" => head_commit_id)) do |response|
            classify(response)
          end
        end

        # The PR state readback. Returns the closed PR-state hash
        # (`merged`, `merge_commit_sha`, `head.sha`, `base.sha`) or nil when
        # the forge definitively reports the PR absent (404). Raises
        # Unavailable for every unverifiable outcome.
        def pull_request(owner:, repo:, index:)
          request(:get, "/api/v1/repos/#{e(owner)}/#{e(repo)}/pulls/#{e(index)}") do |response|
            case response
            when Net::HTTPSuccess
              begin
                document = JSON.parse(response.body)
              rescue JSON::ParserError
                raise Unavailable, "forge PR readback returned an unparseable body"
              end
              {
                "merged" => document["merged"] == true,
                "merge_commit_sha" => document["merge_commit_sha"].is_a?(String) ?
                  document["merge_commit_sha"] : nil,
                "head" => {"sha" => document.dig("head", "sha").is_a?(String) ?
                  document.dig("head", "sha") : nil},
                "base" => {"sha" => document.dig("base", "sha").is_a?(String) ?
                  document.dig("base", "sha") : nil}
              }
            when Net::HTTPNotFound
              nil
            else
              raise Unavailable, "forge PR readback failed: #{describe(response)}"
            end
          end
        end

        # Attach one comment to the PR (the independent final-head review
        # body handed over by the request — never the executor's own
        # approval).
        def create_comment(owner:, repo:, index:, body:)
          request(:post, "/api/v1/repos/#{e(owner)}/#{e(repo)}/issues/#{e(index)}/comments",
            body: JSON.generate("body" => body.to_s)) do |response|
            classify(response)
          end
        end

        private

        def e(component)
          URI.encode_www_form_component(component.to_s)
        end

        def classify(response)
          case response
          when Net::HTTPSuccess
            Result.new(outcome: :invoked, status: response.code.to_i, reason: nil)
          when Net::HTTPClientError
            Result.new(outcome: :refused, status: response.code.to_i,
              reason: "HTTP #{response.code}: #{snippet(response)}")
          else
            Result.new(outcome: :ambiguous, status: response.code.to_i,
              reason: "HTTP #{response.code}: #{snippet(response)}")
          end
        end

        def describe(response)
          "HTTP #{response.code}: #{snippet(response)}"
        end

        def snippet(response)
          response.body.to_s.scrub.gsub(/\s+/, " ").strip[0, 200]
        end

        # One HTTP exchange with closed failure semantics: every network
        # failure — including all timeouts — is ambiguous at the effect
        # layer, because the forge may or may not have processed it.
        def request(method, path, body: nil)
          uri = URI.parse("#{@base_url}#{path}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.is_a?(URI::HTTPS)
          http.open_timeout = @open_timeout_seconds
          http.read_timeout = @timeout_seconds
          http.write_timeout = @timeout_seconds
          message = Net::HTTP.const_get(method.to_s.capitalize).new(uri.request_uri)
          message["Authorization"] = "token #{@token}"
          message["Content-Type"] = "application/json"
          message.body = body if body
          begin
            response = http.start { |session| session.request(message) }
          rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, Errno::ECONNRESET,
            Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, IOError,
            SocketError, OpenSSL::SSL::SSLError => e
            raise Unavailable, "forge is unreachable: #{e.class}"
          end
          yield response
        rescue URI::Error
          raise Unavailable, "forge endpoint URL is invalid"
        end
      end
    end
  end
end
