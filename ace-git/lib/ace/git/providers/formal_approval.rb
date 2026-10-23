# frozen_string_literal: true

require "digest"
require "tmpdir"
require "etc"
require_relative "evidence"
require_relative "../atoms/server_url"

module Ace
  module Git
    module Providers
      # Shared policy for formal review evidence. Provider packages supply the
      # authenticated I/O ports; no credentials or delivery state live here.
      class FormalApproval
        SHA = /\A[0-9a-f]{40}\z/
        CORRELATION = /\A[a-zA-Z0-9][a-zA-Z0-9._:-]{0,127}\z/
        MARKER = /\n\n<!-- ace-approval:([a-zA-Z0-9][a-zA-Z0-9._:-]{0,127}) sha256:([0-9a-f]{64}) -->\z/

        def initialize(provider:, request:, list:, official: false, pending_reuse: false)
          @provider, @request, @list, @official = provider, request, list, official
          @pending_reuse = pending_reuse
        end

        def approve(number:, expected_head:, body:, correlation:)
          validate_input!(number, expected_head)
          unless body.is_a?(String) && body.dup.force_encoding(Encoding::UTF_8).valid_encoding? && !body.strip.empty? &&
              body.bytesize <= 64 * 1024 && !body.include?("\0") && !body.include?("<!-- ace-approval:") &&
              correlation.is_a?(String) && correlation.match?(CORRELATION)
            raise ArgumentError, "Approval requires a nonempty UTF-8 report (maximum 64KiB) and valid correlation"
          end
          body = body.dup.force_encoding(Encoding::UTF_8)
          digest = Digest::SHA256.hexdigest(body)
          sent_body = "#{body}\n\n<!-- ace-approval:#{correlation} sha256:#{digest} -->"
          # Same existing per-session flock family as comment publication,
          # with a digest filename so caller text never forms a filesystem path.
          # All correlations for this PR share the lock: a provider may reuse
          # an actor's pending review instead of creating a distinct object.
          scope = [@provider.server.provider, Atoms::ServerUrl.normalize(@provider.server.url), number]
          key = Digest::SHA256.hexdigest(scope.join("\0"))
          File.open(File.join(Etc.systmpdir, "ace-review-session-approval-#{Process.uid}-#{key}.lock"),
            File::CREAT | File::RDWR | File::NOFOLLOW, 0600) do |lock|
            unless lock.stat.file? && lock.stat.uid == Process.uid && (lock.stat.mode & 0777) == 0600
              raise ConfigError, "Unsafe approval session lock"
            end
            lock.flock(File::LOCK_EX)
            pr = current!(number, expected_head)
            actor = identity!(@request.call(:get, :actor, nil))
            deny_author!(pr, actor)
            rows = reviews!(number)
            matches = rows.select { |row| row.fetch("body").include?("<!-- ace-approval:#{correlation} ") }
            raise ProviderConflictingMatchesError, "Ambiguous approval correlation" if matches.length > 1
            existing = matches.first
            row!(existing) if existing
            if existing && (existing["body"] != sent_body || existing["commit_id"] != expected_head ||
                identity!(existing["user"]) != actor)
              raise ProviderConflictingMatchesError, "Approval correlation is already bound to different evidence"
            end
            # A provider may reuse its current pending object on direct create.
            # Only an exact known, comment-free pending review is resumable, and
            # only when the adapter proves explicit commit preservation on reuse.
            owned_pending = rows.select do |row|
              row["state"] == "PENDING" && row["user"].is_a?(Hash) && row["user"]["id"] == actor.first
            end
            unrelated = owned_pending.any? { |row| !existing || row["id"] != existing["id"] }
            if unrelated
              raise ProviderConflictingMatchesError,
                "Authenticated reviewer has an unrelated pending review; no publication performed"
            end
            recovering = existing && existing["state"] == "PENDING"
            if recovering && (!@pending_reuse || existing["comments_count"] != 0 ||
                existing["dismissed"] || existing["stale"])
              raise ProviderUnsupportedCapabilityError,
                "This pending review cannot be safely completed with its accepted commit/content; pending is preserved"
            end
            mutated = false
            disposition = existing ? :existing : :created
            begin
              current!(number, expected_head)
              if !existing || recovering
                pending_id = existing && existing["id"]
                mutated = true
                # Direct approval keeps the explicit reviewed commit. Never
                # use a later pending-submit endpoint with implicit current HEAD.
                existing = @request.call(:post, "pulls/#{number}/reviews",
                  {"body" => sent_body, "commit_id" => expected_head, "event" => "APPROVE"})
                row!(existing)
                if pending_id && existing["id"] != pending_id
                  raise ProviderUnknownOutcomeError, "Pending review identity changed during direct approval"
                end
              end
              verifying = true
              receipt(number: number, expected_head: expected_head, review_id: existing.fetch("id"),
                disposition: disposition, expected_body: sent_body, actor: actor)
            rescue Error => error
              definitive_refusal = error.is_a?(ProviderAuthenticationError) ||
                error.is_a?(ProviderUnsupportedCapabilityError)
              raise unless mutated && (verifying || !definitive_refusal)

              raise ProviderUnknownOutcomeError,
                "Approval outcome unknown for #{@provider.server.name}/#{number}, head #{expected_head}, " \
                "correlation #{correlation}: #{error.class.name.split('::').last}; reconcile before repeating"
            end
          end
        rescue SystemCallError
          raise ConfigError, "Cannot acquire the private approval session lock"
        end

        def read(number:, expected_head:, review_id:)
          validate_input!(number, expected_head)
          unless review_id.is_a?(Integer) && review_id.positive?
            raise ArgumentError, "Approval review ID must be a positive integer"
          end
          receipt(number: number, expected_head: expected_head, review_id: review_id, disposition: :existing)
        end

        private

        def validate_input!(number, head)
          unless number.is_a?(Integer) && number.positive? && head.is_a?(String) && head.match?(SHA)
            raise ArgumentError, "Approval requires a positive PR number and full lowercase head SHA"
          end
        end

        def current!(number, head)
          pr = @provider.pull_request(number: number)
          unless pr.number == number && pr.server_name == @provider.server.name &&
              pr.head_sha == head && pr.state == :open && pr.draft == false &&
              Atoms::ServerUrl.match?(pr.base_repository_url, @provider.server.url)
            raise ProviderExpectedHeadConflictError,
              "Approval requires the selected open, ready PR at the expected head"
          end
          pr
        end

        def identity!(user)
          unless user.is_a?(Hash) && user["id"].is_a?(Integer) && user["id"].positive? &&
              user["login"].is_a?(String) && !user["login"].empty?
            raise ProviderMalformedOutputError, "Malformed authenticated review identity"
          end
          [user["id"], user["login"]]
        end

        def deny_author!(pr, actor)
          unless pr.author.is_a?(String) && !pr.author.empty?
            raise ProviderMalformedOutputError, "PR author is unverified"
          end
          if pr.author.casecmp?(actor.last)
            raise ProviderAuthenticationError, "PR author cannot approve own pull request"
          end
        end

        def row!(row)
          unless row.is_a?(Hash) && row["id"].is_a?(Integer) && row["id"].positive? &&
              row["body"].is_a?(String) && row["state"].is_a?(String) &&
              row["commit_id"].is_a?(String) && row["commit_id"].match?(SHA)
            raise ProviderMalformedOutputError, "Malformed formal review evidence"
          end
          identity!(row["user"])
          row
        end

        def reviews!(number)
          rows = @list.call("pulls/#{number}/reviews")
          raise ProviderMalformedOutputError, "Formal reviews are not a list" unless rows.is_a?(Array)
          rows.each do |row|
            unless row.is_a?(Hash) && row["id"].is_a?(Integer) && row["id"].positive? &&
                row["body"].is_a?(String) && row["state"].is_a?(String)
              raise ProviderMalformedOutputError, "Malformed formal review list entry"
            end
          end
          if rows.map { |row| row["id"] }.uniq.length != rows.length
            raise ProviderMalformedOutputError, "Duplicate formal review IDs"
          end
          rows
        end

        def receipt(number:, expected_head:, review_id:, disposition:, expected_body: nil, actor: nil)
          pr = current!(number, expected_head)
          rows = reviews!(number)
          row = rows.find { |entry| entry["id"] == review_id }
          raise ProviderIdentityMismatchError, "Formal approval was not found" unless row
          row!(row)
          actual_actor = identity!(row["user"])
          deny_author!(pr, actual_actor)
          marker = row["body"].match(MARKER)
          content = marker && row["body"][0...marker.begin(0)]
          latest = rows.select do |entry|
            next false unless entry["user"].is_a?(Hash) && entry["user"]["id"] == actual_actor.first
            next false unless %w[APPROVED CHANGES_REQUESTED REQUEST_CHANGES DISMISSED].include?(entry["state"])

            row!(entry)
            unless identity!(entry["user"]) == actual_actor
              raise ProviderIdentityMismatchError, "Inconsistent identity in relevant formal review history"
            end
            true
          end.max_by { |entry| entry["id"] }
          unless marker && !content.strip.empty? && content.bytesize <= 64 * 1024 &&
              Digest::SHA256.hexdigest(content) == marker[2] &&
              row["state"] == "APPROVED" && row["commit_id"] == expected_head &&
              !row["dismissed"] && !row["stale"] && (!@official || row["official"] == true) &&
              (!latest || latest["id"] == row["id"]) && (!expected_body || row["body"] == expected_body) &&
              (!actor || actor == actual_actor) && row["html_url"].is_a?(String) &&
              row["html_url"].start_with?("#{pr.url}#")
            raise ProviderIdentityMismatchError, "Review is not the effective exact-head formal approval"
          end
          current!(number, expected_head)
          ProviderApprovalReceipt.new(provider: @provider.server.provider, server_name: @provider.server.name,
            repository_url: @provider.server.url, pr_number: number, pr_url: pr.url,
            head_sha: expected_head, reviewer_id: actual_actor.first, reviewer: actual_actor.last,
            review_id: row["id"], review_url: row["html_url"], state: :approved, effective: true,
            official: @official ? row["official"] : nil,
            correlation: marker[1], evidence_sha256: marker[2], idempotency: disposition)
        end
      end
    end
  end
end
