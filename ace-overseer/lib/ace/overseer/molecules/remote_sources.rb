# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Overseer
    module Molecules
      # Remote issue and PR observation through the existing forge adapters
      # (Ace::Git::Providers.for — Forgejo and GitHub; no separate HTTP
      # client here). Observed repositories and PRs come from the project's
      # own configuration — never a scan of every accessible account.
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
        ISSUE_LIMIT = 500

        def initialize(provider_factory: nil, timeout: nil)
          @provider_factory = provider_factory || ->(server_name) {
            server = Ace::Git::ServerRegistry.resolve(server_name)
            Ace::Git::Providers.for(server, timeout: timeout)
          }
        end

        # @param pull_requests [Array<Hash>] {"server" =>, "number" =>}
        #   entries from the project's observe.remote configuration
        # @param issues [Array<Hash>] {"server" =>} repository entries
        # @return [Hash] {"events" => Array, "sources" => {name => health}}
        def call(pull_requests:, issues: [])
          sources = {}
          events = []

          # Validate entries BEFORE grouping: a malformed entry (non-Hash,
          # missing server/number) must degrade its group to a health
          # marker, never crash the whole observation pass.
          valid, invalid = Array(pull_requests).partition do |entry|
            entry.is_a?(Hash) && !entry["server"].to_s.empty? && !entry["number"].to_s.empty?
          end
          unless invalid.empty?
            index = Array(pull_requests).index(invalid.first)
            collect(sources, events, "pr:configuration") { raise ArgumentError, "invalid observe.remote.pull_requests entry at index #{index}" }
          end

          valid.group_by { |entry| entry["server"] }.each do |server, entries|
            collect(sources, events, "pr:#{server}") do
              entries.flat_map { |entry| project(server, entry["number"]) }
            end
          end

          Array(issues).each_with_index do |entry, index|
            unless entry.is_a?(Hash) && entry["server"].is_a?(String) && !entry["server"].strip.empty?
              unless sources.key?("issues:configuration")
                collect(sources, events, "issues:configuration") { raise ArgumentError, "invalid observe.remote.issues entry at index #{index}" }
              end
              next
            end

            server = entry["server"]
            next if sources.key?("issues:#{server}")

            collect(sources, events, "issues:#{server}") { [issue_snapshot(server)] }
          end

          {"events" => events, "sources" => sources}
        end

        private

        # A single collection revision also detects a closed/deleted issue,
        # which would simply disappear if each open issue had its own row.
        # Refuse a truncated collection instead of silently missing work. The
        # provider must paginate completely and return min(limit, total).
        def issue_snapshot(server)
          provider = @provider_factory.call(server)
          unless provider.respond_to?(:recent_issues)
            raise Ace::Git::ProviderUnsupportedCapabilityError,
              "the selected provider has no issue-listing API; issues are unavailable, not empty"
          end
          issues = provider.recent_issues(limit: ISSUE_LIMIT + 1)
          raise ArgumentError, "too many open issues to observe completely" if issues.length > ISSUE_LIMIT

          items = issues.map do |issue|
            {"number" => issue.number, "title" => issue.title, "state" => issue.state.to_s,
             "author" => issue.author, "url" => issue.url, "labels" => Array(issue.labels).map(&:to_s).sort}
          end.sort_by { |item| item.fetch("number") }
          {"key" => "issues:#{server}", "revision" => digest(items), "type" => "issues",
           "forge" => server, "count" => items.length,
           "issue_numbers" => items.first(20).map { |item| item.fetch("number") }}
        end

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
