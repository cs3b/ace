# frozen_string_literal: true

require "ace/git"

module Ace
  module Git
    module Worktree
      module Molecules
        # Resolves the pull request associated with a worktree through the
        # configured forge provider using exactly one bounded recent-PR query
        # per listing run.
        #
        # Resolution order: branch match, then HEAD-sha match, then a unique
        # task-reference match in a PR title/body. Any provider failure is
        # swallowed: PR resolution never fails the command and never blocks
        # output.
        class PrStatusResolver
          # Bounded recent-PR window fetched once per run.
          PR_QUERY_LIMIT = 50

          # Providers expose PR state as symbols; JSON/table use strings.
          STATE_LABELS = {open: "open", merged: "merged", closed: "closed"}.freeze
          STATE_PRIORITY = {open: 0, merged: 1, closed: 2}.freeze

          # @param provider [Object, nil] injectable provider (tests)
          # @param query [Proc, nil] injectable `->(limit:) { Array }` query (tests)
          # @param limit [Integer] bounded query size
          # @param timeout [Integer, nil] provider timeout
          def initialize(query: nil, provider: nil, limit: PR_QUERY_LIMIT, timeout: nil)
            @query = query
            @provider = provider
            @limit = limit
            @timeout = timeout
          end

          # Resolve the PR for one worktree.
          #
          # @param worktree [Models::WorktreeInfo]
          # @param task_id [String, nil] resolved task id
          # @return [Hash, nil] `{number:, state:, draft:, matched_by:}`
          def resolve(worktree, task_id)
            pull_requests = recent_pull_requests
            return nil if pull_requests.empty?

            match = by_branch(pull_requests, worktree.branch) ||
              by_head_sha(pull_requests, worktree.commit) ||
              by_task_reference(pull_requests, task_id)
            return nil unless match

            {
              number: match[:pull_request][:number],
              state: STATE_LABELS.fetch(match[:pull_request][:state], match[:pull_request][:state].to_s),
              draft: match[:pull_request][:draft] ? true : false,
              matched_by: match[:matched_by]
            }
          end

          # Render the PR cell text.
          #
          # @param pr [Hash, nil]
          # @return [String]
          def self.cell(pr)
            return "-" if pr.nil? || pr[:number].nil?

            label = "##{pr[:number]}"
            case pr[:state].to_s
            when "open" then pr[:draft] ? "#{label} draft" : label
            when "merged" then "#{label} merged"
            when "closed" then "#{label} closed"
            else label
            end
          end

          # The bounded recent-PR query, executed once per resolver.
          #
          # @return [Array<Hash>] normalized PR hashes
          def recent_pull_requests
            return @recent_pull_requests if defined?(@recent_pull_requests)

            @recent_pull_requests = begin
              rows = if @query
                @query.call(limit: @limit)
              else
                provider = resolved_provider
                provider ? provider.recent_pull_requests(limit: @limit) : []
              end
              Array(rows).map { |row| normalize(row) }.compact
            rescue StandardError
              []
            end
          end

          private

          def resolved_provider
            return @provider if defined?(@provider) && @provider

            @provider = begin
              server = Ace::Git::ServerRegistry.resolve_default
              server ? Ace::Git::Providers.for(server, timeout: @timeout) : nil
            rescue StandardError
              nil
            end
          end

          def by_branch(pull_requests, branch)
            return nil if branch.to_s.empty?

            candidates = pull_requests.select { |pr| pr[:head_ref] == branch }
            best_match(candidates, "branch")
          end

          def by_head_sha(pull_requests, commit)
            return nil if commit.to_s.empty?

            candidates = pull_requests.select { |pr| pr[:head_sha] == commit }
            best_match(candidates, "head_sha")
          end

          def by_task_reference(pull_requests, task_id)
            return nil if task_id.to_s.empty?

            pattern = task_reference_pattern(task_id)
            candidates = pull_requests.select do |pr|
              pattern.match?(pr[:title].to_s) || pattern.match?(pr[:body].to_s)
            end
            # Exactly one recent PR may reference the task; ambiguity means no PR.
            return nil unless candidates.length == 1

            {pull_request: candidates.first, matched_by: "task_reference"}
          end

          # Prefer open PRs over merged/closed, then the most recent number.
          def best_match(candidates, matched_by)
            return nil if candidates.empty?

            chosen = candidates.min_by do |pr|
              [STATE_PRIORITY.fetch(pr[:state], STATE_PRIORITY.length), -pr[:number].to_i]
            end
            {pull_request: chosen, matched_by: matched_by}
          end

          # A bounded token: the task id must not be glued to other
          # alphanumerics ("k9y", and inside "8xg.t.k9y").
          def task_reference_pattern(task_id)
            /(?<![0-9a-z])#{Regexp.escape(task_id)}(?![0-9a-z])/i
          end

          def normalize(row)
            {
              number: field(row, :number)&.to_i,
              state: field(row, :state)&.to_sym,
              draft: field(row, :draft) ? true : false,
              head_ref: field(row, :head_ref),
              head_sha: field(row, :head_sha),
              title: field(row, :title),
              body: field(row, :body)
            }
          end

          def field(row, name)
            if row.is_a?(Hash)
              row[name] || row[name.to_s]
            else
              row.respond_to?(name) ? row.public_send(name) : nil
            end
          end
        end
      end
    end
  end
end
