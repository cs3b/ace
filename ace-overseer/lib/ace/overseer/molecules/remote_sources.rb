# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Overseer
    module Molecules
      # Remote PR/repo observation (task 8xs.t.pu0.4): projects configured
      # pull requests through the EXISTING forge provider adapters
      # (Ace::Git::Providers.for — Forgejo and GitHub; no separate HTTP
      # client here). Observed PRs come from the project's own
      # configuration (`observe.remote.pull_requests` in the overseer
      # cascade) — never a scan of every accessible account.
      #
      # Rows follow the standing-observation contract of LocalSources:
      # stable key + SEMANTIC revision (state, head SHA, review/comment
      # identity sets — never poll timestamps or list order), so repeated
      # reads of identical state project identical revisions (zero model
      # turns) while a new HEAD, review, approval, comment, merge, close
      # or reopen revises exactly its row. The row carries the wake
      # payload: forge, PR number/title, event kind, author, link.
      #
      # A failing forge (401/403, rate limit, timeout, malformed payload)
      # degrades ONLY its source — a marker revision keyed by error
      # class wakes once per failure mode, never as an empty healthy
      # list — and recovery re-observes the real state.
      class RemoteSources
        def initialize(provider_factory: nil, timeout: nil)
          @provider_factory = provider_factory || ->(server_name) {
            server = Ace::Git::ServerRegistry.resolve(server_name)
            Ace::Git::Providers.for(server, timeout: timeout)
          }
        end

        # @param pull_requests [Array<Hash>] {"server" =>, "number" =>}
        #   entries from the project's observe.remote configuration
        # @return [Hash] {"events" => Array, "sources" => {name => health}}
        def call(pull_requests:)
          sources = {}
          events = []

          pull_requests.group_by { |entry| entry["server"] }.each do |server, entries|
            collect(sources, events, "pr:#{server}") do
              entries.flat_map { |entry| project(server, entry["number"]) }
            end
          end

          {"events" => events, "sources" => sources}
        end

        private

        def collect(sources, events, name)
          rows = yield
          sources[name] = {"status" => "ok"}
          events.concat(rows)
        rescue StandardError => e
          sources[name] = {"status" => "degraded", "error" => "#{e.class}: #{e.message}"}
          events << {"key" => "source:#{name}",
                     "revision" => Digest::SHA256.hexdigest("degraded:#{e.class}"),
                     "type" => "source-health", "status" => "degraded",
                     "error" => "#{e.class}: #{e.message}"}
        end

        def project(server, number)
          provider = @provider_factory.call(server)
          pr = provider.pull_request(number: number)
          return [] if pr.nil?

          rows = [pr_row(server, pr)]
          evidence = provider.pull_request_review_evidence(number: number, expected_head: pr.head_sha)
          rows << activity_row(server, pr, evidence) if evidence
          rows
        end

        # The PR's own lifecycle: new HEAD (head_sha), merge, close,
        # reopen, title/draft changes. Read fresh before any merge
        # decision — remote data stays data.
        def pr_row(server, pr)
          payload = {"number" => pr.number, "state" => pr.state.to_s,
                     "head_sha" => pr.head_sha, "draft" => pr.draft,
                     "title" => pr.title, "merged_at" => pr.merged_at,
                     "merge_commit_sha" => pr.merge_commit_sha}
          {"key" => "pr:#{server}:#{pr.number}", "revision" => digest(payload),
           "type" => "pr", "forge" => server, "number" => pr.number,
           "title" => pr.title, "state" => pr.state.to_s, "head_sha" => pr.head_sha,
           "author" => pr.author, "url" => pr.url}
        end

        # Review/comment/approval activity: the revision covers the
        # SORTED identity set (id, author, state, head binding) of every
        # review and comment — re-ordered payloads and volatile counters
        # never revise; a new verdict, approval or comment revises once.
        # The row's summary names the latest item for the wake payload.
        def activity_row(server, pr, evidence)
          reviews = Array(evidence.reviews).map { |review|
            {"id" => review.id.to_s, "author" => review.author, "state" => review.state.to_s,
             "head_sha" => review.head_sha, "kind" => "review"}
          }
          comments = Array(evidence.comments).map { |comment|
            {"id" => comment.id.to_s, "author" => comment.author, "state" => nil,
             "head_sha" => comment.head_sha, "kind" => "comment"}
          }
          items = (reviews + comments).sort_by { |item| item["id"] }
          latest = items.last

          {"key" => "pr-activity:#{server}:#{pr.number}", "revision" => digest(items),
           "type" => "pr-activity", "forge" => server, "number" => pr.number,
           "title" => pr.title, "event_kind" => latest && latest["kind"],
           "event_id" => latest && latest["id"], "author" => latest && latest["author"],
           "url" => pr.url, "items" => items.size}
        end

        def digest(payload)
          Digest::SHA256.hexdigest(JSON.generate(payload))
        end
      end
    end
  end
end
