# frozen_string_literal: true

require "ace/git/forgejo"

module Ace
  module Lab
    module Molecules
      # The receiver's forge merge boundary (spec 8x3.t.xz9.5 integration
      # handoff): a THIN delegation to the `ace-git-forgejo` provider, which
      # owns every Forgejo API/PR/review/merge/readback responsibility —
      # HTTP transport, authentication, payload shape, and failure
      # classification live behind `Ace::Git::Forgejo::PullRequestApi` and
      # its `HttpClient`. This molecule holds no HTTP stack of its own: it
      # binds the host-installed scoped service identity from
      # {ForgeMergeConfig} to a repository-scoped provider client and
      # translates the provider's closed outcomes into the receiver's
      # closed outcome set (`:invoked`/`:refused`/`:ambiguous`/`Unavailable`).
      #
      # The receiver's one authorized effect is a real pull request merge on
      # the real forge, invoked under the scoped service identity, and every
      # terminal outcome is proven by a real readback — a local git effect is
      # never presented as a forge result.
      #
      # Outcome translation (provider closed world → receiver closed world):
      #
      # - `2xx` mutation outcome → `:invoked`; a provider refusal outcome
      #   (404/405/409/422 — including the server-side exact-head refusal
      #   for a moved head) → `:refused`; an authentication error (the
      #   provider raises the shared taxonomy for 401/403) → `:refused` —
      #   a definitive refusal can never have merged.
      # - An unknown mutation outcome (5xx responses and transport failures
      #   on the POST — the forge may or may not have processed it) →
      #   `:ambiguous`; the receiver reconciles by readback, never by
      #   repeating the merge.
      # - Every unverifiable read outcome (unreachable forge, malformed
      #   evidence, misrouted payload, unusable endpoint) raises
      #   `Unavailable`, because the true state cannot be proven. The token
      #   is never rendered in any error (provider-sanitized messages only).
      #
      # The exact-head contract is carried by the provider's native merge
      # signature: the POST body binds `head_commit_id` to the approved
      # candidate server-side, so a race between the state readback and the
      # merge POST can never merge an unreviewed head. This molecule never
      # substitutes another merge strategy and validates the binding before
      # the provider is constructed.
      class ForgejoMergeAdapter
        # The single authorized merge strategy on the wire.
        MERGE_METHOD = "fast-forward-only"

        class Unavailable < ::StandardError; end

        # outcome: :invoked | :refused | :ambiguous; status: Integer|nil;
        # reason: closed refuse/ambiguity detail (token-free).
        Result = Struct.new(:outcome, :status, :reason, keyword_init: true)

        def initialize(base_url:, token:, timeout_seconds: 900)
          @base_url = base_url.to_s.sub(%r{/+\z}, "")
          @token = token
          @timeout_seconds = timeout_seconds
          freeze
        end

        # Invoke the eligible merge bound to the approved candidate head.
        # `head_commit_id` is required and validated (full 40-character hex
        # sha) BEFORE any provider construction: the forge server-side
        # refuses to merge any head other than the bound one. Returns a
        # Result; never raises for HTTP outcomes (ambiguity is a result, not
        # an exception).
        def merge_pull_request!(owner:, repo:, index:, head_commit_id:)
          unless head_commit_id.is_a?(String) && head_commit_id.match?(/\A[0-9a-f]{40}\z/)
            raise ArgumentError,
              "head_commit_id must be a full 40-character lowercase hex sha " \
                "(got: #{head_commit_id.inspect})"
          end
          translate_mutation do
            provider(owner, repo).merge_pull_request(index,
              do_method: MERGE_METHOD, head_commit_id: head_commit_id)
          end
        end

        # The PR state readback, normalized to the receiver's closed
        # PR-state shape (`merged`, `merge_commit_sha`, head/base shas) or
        # nil when the forge definitively reports the PR absent (404 — the
        # provider raises the absence taxonomy). Raises Unavailable for
        # every unverifiable outcome.
        def pull_request(owner:, repo:, index:)
          payload = provider(owner, repo).pull_request(index)
          {
            "merged" => payload["merged"] == true,
            "merge_commit_sha" => payload["merge_commit_sha"].is_a?(String) ?
              payload["merge_commit_sha"] : nil,
            "head" => {"sha" => payload.dig("head", "sha").is_a?(String) ?
              payload.dig("head", "sha") : nil},
            "base" => {"sha" => payload.dig("base", "sha").is_a?(String) ?
              payload.dig("base", "sha") : nil}
          }
        rescue Ace::Git::ProviderObjectNotFoundError
          nil
        rescue Ace::Git::Error => e
          raise Unavailable, e.message
        end

        # Attach one comment to the PR (the independent final-head review
        # body handed over by the request — never the executor's own
        # approval).
        def create_comment(owner:, repo:, index:, body:)
          translate_mutation do
            provider(owner, repo).create_comment(index, body)
          end
        end

        private

        # One repository-scoped provider client per exchange: the origin is
        # narrowed with the forge identity this receiver already pinned
        # against the host-installed configuration, and the scoped token
        # rides the provider transport instead of any local credential.
        def provider(owner, repo)
          Ace::Git::Forgejo::PullRequestApi.new(
            server: Ace::Git::ResolvedServer.new(name: "lab-forge-merge",
              provider: :forgejo, url: "#{@base_url}/#{owner}/#{repo}"),
            timeout: @timeout_seconds, token: @token
          )
        end

        # Closed mutation translation: the provider returns an outcome only
        # for statuses whose meaning is endpoint-specific (2xx success and
        # the refusal family); everything else it raises as the shared
        # taxonomy, which maps to :refused (authentication — a definitive
        # refusal), :ambiguous (unknown outcome), or Unavailable (a read
        # classified as unreachable).
        def translate_mutation
          outcome = yield
          if (200..299).cover?(outcome.status)
            Result.new(outcome: :invoked, status: outcome.status, reason: nil)
          else
            Result.new(outcome: :refused, status: outcome.status,
              reason: outcome.message || "HTTP #{outcome.status}")
          end
        rescue Ace::Git::ProviderAuthenticationError => e
          Result.new(outcome: :refused, status: nil, reason: e.message)
        rescue Ace::Git::ProviderUnknownOutcomeError => e
          Result.new(outcome: :ambiguous, status: nil, reason: e.message)
        rescue Ace::Git::Error => e
          raise Unavailable, e.message
        end
      end
    end
  end
end
