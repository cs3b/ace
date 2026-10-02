# frozen_string_literal: true

require "ace/git"
require "ace/git/github"
require "ace/git/forgejo"
require "ace/git/organisms/pull_request_lifecycle"
require "digest"

module Ace
  module Review
    module Molecules
      # Review-facing projection of the shared, exact-head provider contract.
      # Provider commands and response parsing remain in ace-git packages.
      class PrProvider
        def self.format_comment(review_text, preset: nil, model: nil, timestamp: nil)
          header = "## Code Review - ace-review\n\n"
          header += "**Preset**: #{preset}\n" if preset
          header += "**Model**: #{model}\n" if model
          header += "**Generated**: #{timestamp}\n" if timestamp
          header += "\n" if preset || model || timestamp
          content = review_text.to_s
          content += "\n```\n" if content.scan(/^```/).count.odd?
          header + <<~MARKDOWN
            <details>
            <summary><b>Full Review</b> (click to expand)</summary>

            #{content}

            </details>
          MARKDOWN
        end

        # The forge server URL resolved by the lifecycle at construction;
        # posting compares it with the reviewed repository before mutating.
        def resolved_server_url
          @lifecycle.resolved_server_url
        end

        def initialize(server_name: nil, use_default: false, timeout: nil, runner: nil, lifecycle: nil)
          @lifecycle = lifecycle || Ace::Git::Organisms::PullRequestLifecycle.new(
            server_name: server_name, use_default: use_default,
            timeout: timeout, runner: runner
          )
        end

        def fetch(pr_identifier, include_comments: true)
          snapshot = @lifecycle.review_snapshot(pr_identifier, include_comments: include_comments)
          metadata = metadata_for(snapshot)
          {
            success: true,
            diff: snapshot.diff,
            metadata: metadata,
            comments: comments_for(snapshot),
            checks: snapshot.checks,
            snapshot: snapshot
          }
        rescue Ace::Git::Error, ArgumentError => e
          {success: false, error: "#{e.class.name.split('::').last}: #{e.message}"}
        end

        # Exact-head PR metadata only (no diff, comments, or checks); the
        # delta resolver needs identity and base provenance, never the
        # whole diff.
        def fetch_metadata(pr_identifier)
          snapshot = @lifecycle.review_metadata_snapshot(pr_identifier)
          {success: true, metadata: metadata_for(snapshot)}
        rescue Ace::Git::Error, ArgumentError => e
          {success: false, error: "#{e.class.name.split('::').last}: #{e.message}"}
        end

        def post_comment(pr_identifier, expected_head:, content:, session_key:)
          correlation = Digest::SHA256.hexdigest(session_key.to_s)
          @lifecycle.post_review_comment(
            pr_identifier, expected_head: expected_head,
            body: content, correlation: correlation
          )
        end

        def resolve_thread(pr_identifier, expected_head:, thread_id:)
          @lifecycle.resolve_review_thread(
            pr_identifier, expected_head: expected_head, thread_id: thread_id
          )
        end

        def update_comment(pr_identifier, expected_head:, comment_id:, body:)
          @lifecycle.update_review_comment(
            pr_identifier, expected_head: expected_head,
            comment_id: comment_id, body: body
          )
        end

        def file_at_ref(pr_identifier, path:, ref:)
          @lifecycle.file_at_ref(pr_identifier, path: path, ref: ref)
        end

        private

        def metadata_for(snapshot)
          pr = snapshot.pull_request
          {
            "server_name" => pr.server_name,
            "provider" => snapshot.provider.to_s,
            "repository_url" => pr.base_repository_url,
            "number" => pr.number,
            "title" => pr.title,
            "body" => pr.body,
            "author" => {"login" => pr.author},
            "state" => pr.state.to_s.upcase,
            "isDraft" => pr.draft,
            "baseRefName" => pr.base_ref,
            "baseRefOid" => snapshot.base_sha,
            "headRefName" => pr.head_ref,
            "headRefOid" => pr.head_sha,
            "head_repository_url" => pr.head_repository_url,
            "url" => pr.url,
            "changedFiles" => snapshot.files.length,
            "files" => snapshot.files.map { |path| {"path" => path} },
            "checks" => snapshot.checks.map { |check| check.to_h.transform_keys(&:to_s) }
          }
        end

        def comments_for(snapshot)
          pr = snapshot.pull_request
          comments = snapshot.review_evidence.comments
          issue_comments = comments.reject(&:path).map do |comment|
            {type: "issue_comment", id: comment.id, author: comment.author,
             body: comment.body, url: comment.url}
          end
          inline = comments.select(&:path)
          # Comments sharing a provider thread id belong to one thread; a
          # nil thread id stays an honest per-comment entry.
          threads = inline.select(&:thread_id).group_by(&:thread_id).map do |id, members|
            first = members.first
            {id: id, path: first.path, line: first.line, is_resolved: first.resolved,
             comments: members.map { |comment|
               {id: comment.id, author: comment.author, body: comment.body, url: comment.url}
             }}
          end
          threads += inline.reject(&:thread_id).map do |comment|
            {id: nil, path: comment.path, line: comment.line, is_resolved: comment.resolved,
             comments: [{id: comment.id, author: comment.author, body: comment.body, url: comment.url}]}
          end
          reviews = snapshot.review_evidence.reviews.map do |review|
            {id: review.id, author: review.author, body: review.body,
             state: review.state.to_s.upcase, url: review.url}
          end
          {
            success: true, comments: issue_comments, review_threads: threads,
            reviews: reviews, pr_number: pr.number, pr_title: pr.title,
            pr_author: pr.author, server_name: pr.server_name,
            repository_url: pr.base_repository_url, head_sha: pr.head_sha
          }
        end
      end
    end
  end
end
