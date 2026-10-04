# frozen_string_literal: true

require "json"

module Ace
  module Git
    module Forgejo
      # Repository-bound Forgejo API v1 operations for the PR delivery
      # lifecycle (create, edit, ready, merge) plus the authoritative single
      # pull request read.
      #
      # The fj v0.6 CLI cannot encode a fork head, an explicit draft state,
      # a ready transition, or an atomic expected-head merge precondition;
      # this molecule owns those endpoints on the same selected host and
      # token transport as {HttpClient}. Every returned payload is validated
      # against the documented Forgejo `PullRequest` schema before it may
      # become provider evidence; contradictory or missing identity fields
      # fail closed as malformed evidence.
      #
      # Mutations return a {MutationOutcome} for the statuses that carry
      # endpoint-specific meaning (201/200 success, 405/409/422 refusal) so
      # the provider can classify the forge's own semantics; authentication,
      # absence, and transport failures raise the shared taxonomy directly.
      class PullRequestApi
        # Official capability evidence (see the task capability-evidence
        # report): `head_commit_id` merge enforcement is documented in the
        # Forgejo API swagger on release branch v7.0 and every later branch
        # inspected; WIP-title drafts and `owner:branch` fork heads predate
        # it. Older servers must not inherit these capabilities.
        MINIMUM_SERVER_VERSION = Gem::Version.new("7.0.0")

        # Outcome of one mutation send whose status the provider must
        # interpret: the HTTP status, the sanitized server message (nil on
        # success), and the parsed payload when the server returned one.
        MutationOutcome = Data.define(:status, :message, :payload)

        def initialize(server:, timeout:, runner: nil)
          @http = HttpClient.new(server: server, timeout: timeout, runner: runner)
        end

        # Probe and validate the selected server's API version once per
        # instance. Every lifecycle mutation gate goes through here and
        # fails closed when the server cannot prove the documented
        # capability floor. Transport and authentication failures classify
        # as they would for any read; an unusable or too-old version
        # reports is a capability refusal.
        #
        # @raise [Ace::Git::ProviderUnsupportedCapabilityError] when the
        #   server version cannot be verified or is below the floor
        def ensure_version_supported!
          return if @version_supported

          status, payload = @http.exchange(:get, "/api/v1/version")
          version_text = payload.is_a?(Hash) ? payload["version"] : nil
          unless status == 200 && version_text.is_a?(String) && !version_text.empty?
            if [401, 403].include?(status.to_i)
              raise Ace::Git::ProviderAuthenticationError,
                "Forgejo server version probe returned HTTP #{status}; authenticate with fj first"
            end
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Forgejo server did not report a usable API version (HTTP #{status}); " \
              "cannot prove the PR delivery capability floor " \
              "#{MINIMUM_SERVER_VERSION} before mutating"
          end

          version = parse_version(version_text)
          unless version >= MINIMUM_SERVER_VERSION
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Forgejo server reports #{version}; PR delivery requires #{MINIMUM_SERVER_VERSION} " \
              "(server-enforced expected-head merge is not documented below it)"
          end
          @version_supported = true
        end

        # @return [Hash] the raw validated pull request payload
        # @raise [Ace::Git::ProviderObjectNotFoundError] when absent
        # @raise [Ace::Git::ProviderMalformedOutputError] on schema violation
        # @raise [Ace::Git::ProviderIdentityMismatchError] when the payload
        #   reports another object number (misrouted evidence)
        def pull_request(number)
          status, payload = @http.exchange(:get, "pulls/#{number}")
          case status
          when 200 then validate_pr_payload!(payload, number)
          when 404 then raise Ace::Git::ProviderObjectNotFoundError, "Forgejo pull request ##{number} not found"
          when 401, 403
            raise Ace::Git::ProviderAuthenticationError,
              "Forgejo pull request ##{number} read failed with HTTP #{status}"
          else
            raise Ace::Git::ProviderUnreachableError,
              "Forgejo pull request ##{number} read failed with HTTP #{status}"
          end
        end

        # @return [Array<Hash>] validated payloads of all open pull requests
        def open_pull_requests
          @http.paginate("pulls?state=open").map { |payload| validate_pr_payload!(payload, payload["number"]) }
        end

        # Send the create mutation. The head argument must already be in the
        # documented API form (plain branch, or "owner:branch" for a
        # same-server fork).
        #
        # @return [MutationOutcome] 201 with the created payload, or a
        #   refusal outcome (409 duplicate, 404/422 unprovable source)
        def create_pull_request(head:, base:, title:, body: nil)
          form = {"title" => title, "base" => base, "head" => head}
          form["body"] = body if body
          status, payload, message = @http.exchange(:post, "pulls", body: form)
          classify_send!(status, "create pull request")
          MutationOutcome.new(status: status, message: message, payload: payload)
        end

        # Edit title/body of one pull request (also the ready transition:
        # Forgejo marks a draft ready by removing its WIP title prefix).
        #
        # @return [MutationOutcome] 200, or a refusal outcome
        def edit_pull_request(number, title: nil, body: nil)
          form = {}
          form["title"] = title if title
          form["body"] = body if body
          status, payload, message = @http.exchange(:patch, "pulls/#{number}", body: form)
          classify_send!(status, "edit pull request #{number}")
          MutationOutcome.new(status: status, message: message, payload: payload)
        end

        # Send the server-enforced merge: Forgejo re-resolves the head ref
        # at merge time and refuses with 409 when it does not equal
        # `head_commit_id` (documented `MergePullRequestOption`).
        #
        # @param do_method [String] "squash", "merge", or "rebase"
        # @return [MutationOutcome] 200, or a refusal outcome (405 disabled
        #   style, 409 stale head / conflicts / already merged)
        def merge_pull_request(number, do_method:, head_commit_id:)
          form = {"Do" => do_method, "head_commit_id" => head_commit_id}
          status, payload, message = @http.exchange(:post, "pulls/#{number}/merge", body: form)
          classify_send!(status, "merge pull request #{number}")
          MutationOutcome.new(status: status, message: message, payload: payload)
        end

        private

        # Authentication, absence, and transport failures classify directly
        # inside the transport; only statuses whose meaning is
        # endpoint-specific reach the provider as an outcome.
        def classify_send!(status, operation)
          return if (200..299).cover?(status)
          return if [404, 405, 409, 422].include?(status.to_i)

          error = case status.to_i
          when 401, 403 then Ace::Git::ProviderAuthenticationError
          else Ace::Git::ProviderUnknownOutcomeError
          end
          raise error, "Forgejo #{operation} returned HTTP #{status}; reconcile before repeating"
        end

        def validate_pr_payload!(payload, requested_number)
          unless payload.is_a?(Hash)
            raise Ace::Git::ProviderMalformedOutputError, "Malformed Forgejo pull request evidence"
          end
          head = payload["head"]
          base = payload["base"]
          unless payload["number"].is_a?(Integer) && payload["number"].positive? &&
              %w[open closed].include?(payload["state"]) &&
              [true, false].include?(payload["draft"]) &&
              [true, false].include?(payload["merged"]) &&
              head.is_a?(Hash) && head["ref"].is_a?(String) && !head["ref"].empty? &&
              head["sha"].to_s.match?(/\A[0-9a-f]{40}\z/) &&
              base.is_a?(Hash) && base["ref"].is_a?(String) && !base["ref"].empty?
            raise Ace::Git::ProviderMalformedOutputError,
              "Malformed Forgejo pull request payload (missing number/state/draft/head/base identity)"
          end
          unless payload["number"] == requested_number
            raise Ace::Git::ProviderIdentityMismatchError,
              "Forgejo returned pull request ##{payload["number"]} for selected ##{requested_number}; " \
              "refusing misrouted evidence"
          end
          payload
        end

        # Server version strings look like "7.0.5+gitea-..." or "v12.0.1";
        # only the leading numeric release is comparable.
        def parse_version(text)
          match = text.strip.sub(/\Av/i, "").match(/\A(\d+\.\d+\.\d+)/)
          unless match
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "Forgejo server version #{text.inspect} is not a comparable release; " \
              "cannot prove the PR delivery capability floor #{MINIMUM_SERVER_VERSION}"
          end
          Gem::Version.new(match[1])
        end
      end
    end
  end
end
