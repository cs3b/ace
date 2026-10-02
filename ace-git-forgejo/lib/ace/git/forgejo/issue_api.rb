# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"
require_relative "repository_binding"
require "ace/git/atoms/server_url"

module Ace
  module Git
    module Forgejo
      # Structured issue operations unavailable through fj's output contract.
      # Uses the same exact selected host and the token from fj's keys file.
      class IssueApi
        def initialize(server:, timeout:, runner: nil)
          # Clone URLs may be SSH-style; the HTTP issue client always talks
          # to the verified HTTPS web endpoint derived from that identity.
          @target = RepositoryBinding::Target.resolve(Ace::Git::Atoms::ServerUrl.web_base(server.url))
          @timeout = timeout
          @runner = runner
        end

        def issue(number)
          request(:get, "issues/#{number}")
        end

        def comments(number)
          paginate("issues/#{number}/comments")
        end

        def create_comment(number, body)
          request(:post, "issues/#{number}/comments", body: {body: body})
        end

        def update_comment(comment_id, body)
          request(:patch, "issues/comments/#{comment_id}", body: {body: body})
        end

        def delete_comment(comment_id)
          request(:delete, "issues/comments/#{comment_id}")
        end

        def add_label(number, label_id)
          request(:post, "issues/#{number}/labels", body: {labels: [label_id]})
        end

        def remove_label(number, label_id)
          request(:delete, "issues/#{number}/labels/#{label_id}")
        end

        def repository_labels(wanted: nil)
          labels = paginate("labels")
          # Repository labels satisfy the common case; the organization label
          # listing is an extra request that can fail (403 org scope) and must
          # not block linking when the wanted label is already available.
          return labels if wanted && labels.any? { |entry| entry["name"] == wanted }

          owner = @target.repo.split("/", 2).first
          begin
            labels + paginate("/api/v1/orgs/#{owner}/labels")
          rescue Ace::Git::ProviderObjectNotFoundError
            labels
          end
        end

        def set_state(number, state)
          request(:patch, "issues/#{number}", body: {state: state.to_s})
        end

        private

        def paginate(suffix)
          page = 1
          entries = []
          seen = []
          loop do
            batch = request(:get, "#{suffix}?page=#{page}&limit=50")
            unless batch.is_a?(Array)
              raise Ace::Git::ProviderMalformedOutputError, "Forgejo #{suffix} did not return a list"
            end
            before = entries.length
            # Stop when a page adds no new items (unique ids): instances
            # may cap pages below the requested limit, so a short page alone
            # does not prove the end of the collection.
            fresh = batch.reject { |item| seen.include?(item["id"]) }
            entries.concat(fresh)
            fresh.each { |item| seen << item["id"] }
            break if fresh.empty?

            page += 1
          end
          entries
        end

        def request(method, suffix, body: nil)
          RepositoryBinding.reject_selected_host_redirect!(@target.host_url)
          path = suffix.start_with?("/api/v1/") ? suffix : "/api/v1/repos/#{@target.repo}/#{suffix}"
          if @runner
            result = @runner.call(args: ["forgejo-http", method.to_s.upcase, "#{@target.host_url}#{path}", body],
              timeout: @timeout, env: {})
            status = result[:status] || (result[:success] ? 200 : 503)
            payload = result[:stdout].to_s
          else
            uri = URI.parse("#{@target.host_url}#{path}")
            token = access_token!
            klass = {get: Net::HTTP::Get, post: Net::HTTP::Post, patch: Net::HTTP::Patch,
                     delete: Net::HTTP::Delete}.fetch(method)
            req = klass.new(uri)
            req["Authorization"] = "token #{token}"
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
          raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo issue response: #{e.message}"
        rescue Net::OpenTimeout, Net::ReadTimeout, IOError, SocketError, SystemCallError,
               OpenSSL::SSL::SSLError => e
          error = method == :get ? Ace::Git::ProviderUnreachableError : Ace::Git::ProviderUnknownOutcomeError
          raise error, "Forgejo issue #{method} #{path} outcome unknown: #{e.class}"
        end

        def access_token!
          path = RepositoryBinding.default_keys_path
          data = path && JSON.parse(File.read(path))
          login = data.is_a?(Hash) && data.fetch("hosts", {})[@target.authority]
          token = login.is_a?(Hash) && login["token"]
          return token if token.is_a?(String) && !token.empty?

          raise Ace::Git::ProviderAuthenticationError,
            "No fj token for selected host #{@target.host_url}; authenticate with fj first"
        rescue Errno::ENOENT, Errno::EACCES, JSON::ParserError
          raise Ace::Git::ProviderAuthenticationError,
            "Cannot read fj authentication for selected host #{@target.host_url}"
        end

        def classify_status!(status, method, path)
          return if (200..299).cover?(status.to_i)

          error = case status.to_i
          when 401, 403 then Ace::Git::ProviderAuthenticationError
          when 404 then Ace::Git::ProviderObjectNotFoundError
          when 409, 422 then Ace::Git::ProviderIdentityMismatchError
          else method == :get ? Ace::Git::ProviderUnreachableError : Ace::Git::ProviderUnknownOutcomeError
          end
          raise error, "Forgejo issue #{method} #{path} returned HTTP #{status}"
        end
      end
    end
  end
end
