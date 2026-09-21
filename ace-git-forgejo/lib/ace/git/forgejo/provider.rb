# frozen_string_literal: true

require "json"
require "uri"
require_relative "cli_executor"
require_relative "parsers"

module Ace
  module Git
    module Forgejo
      # Forgejo provider implementation of the shared provider contract.
      #
      # Owns Forgejo terminology and translates `fj` responses into the
      # normalized evidence types defined by the ace-git core. Every failure is
      # classified with the shared taxonomy; `fj` failures are never hidden
      # behind ad-hoc curl calls or silent fallbacks.
      class Provider < Ace::Git::Providers::Base
        class << self
          def display_name
            "Forgejo"
          end
        end

        # @return [Boolean] true when the `fj` binary is installed
        def available?
          CliExecutor.installed?(runner: runner)
        end

        # @raise [Ace::Git::ProviderCliMissingError] when `fj` is missing
        def check_available!
          CliExecutor.check_installed!(runner: runner)
        end

        # @return [Boolean] true when the server host has a configured `fj` login
        def authenticated?
          CliExecutor.authenticated?(server_host, runner: runner)
        end

        # @raise [Ace::Git::ProviderAuthenticationError] when unauthenticated
        def check_authenticated!
          CliExecutor.check_authenticated!(host: server_host, runner: runner)
        end

        # @return [ProviderPullRequest] normalized pull request evidence
        # @raise [ProviderObjectNotFoundError] when the PR does not exist
        # @raise [ProviderMalformedOutputError] when `fj` output is unexpected
        # @raise [ProviderUnreachableError] when the endpoint is unreachable
        def pull_request(number:)
          view = fj(["--style", "minimal", "pr", "view", number.to_s])
          parsed = Parsers.parse_pr_view(view) ||
            raise(Ace::Git::ProviderMalformedOutputError,
              "Unrecognized `fj pr view #{number}` output; update the Forgejo provider parser")

          parsed[:head_sha] = head_sha_of(number)
          normalize_pr(parsed)
        end

        # @return [ProviderPullRequest, nil] evidence for the branch's PR
        def pull_request_for_branch(branch:)
          listing = fj(["--style", "minimal", "pr", "search", "--state", "all", "--limit", "30"])
          entries = Parsers.parse_search(listing).sort_by { |entry| -entry[:number] }

          entries.each do |entry|
            view = fj(["--style", "minimal", "pr", "view", entry[:number].to_s])
            parsed = Parsers.parse_pr_view(view)
            next unless parsed && parsed[:head_ref] == branch

            parsed[:head_sha] = head_sha_of(entry[:number])
            return normalize_pr(parsed)
          end

          nil
        end

        # @return [String] unified diff text for the pull request
        def pull_request_diff(number:)
          fj(["pr", "view", number.to_s, "diff"])
        end

        # @return [Array<ProviderPullRequest>] recent PRs, newest first
        def recent_pull_requests(limit:)
          listing = fj(["--style", "minimal", "pr", "search", "--state", "all", "--limit", limit.to_s])
          Parsers.parse_search(listing)
            .map { |entry| normalize_search_entry(entry) }
            .sort_by { |pr| -pr.number }
        end

        # @return [ProviderIssue] normalized issue evidence
        def issue(number:)
          view = fj(["--style", "minimal", "issue", "view", number.to_s])
          parsed = Parsers.parse_issue_view(view) ||
            raise(Ace::Git::ProviderMalformedOutputError,
              "Unrecognized `fj issue view #{number}` output; update the Forgejo provider parser")

          Ace::Git::ProviderIssue.new(
            server_name: server.name,
            number: parsed[:number],
            title: parsed[:title],
            state: parsed[:state],
            author: parsed[:author],
            url: issue_url(parsed[:number]),
            labels: nil
          )
        end

        # @return [Array<ProviderCheck>] normalized check evidence for a ref
        def checks(ref:)
          tasks = fj(["--style", "minimal", "actions", "tasks"])
          Parsers.parse_actions_tasks(tasks)
            .select { |task| task[:sha].start_with?(ref.to_s) || ref.to_s.start_with?(task[:sha]) }
            .map do |task|
              Ace::Git::ProviderCheck.new(
                server_name: server.name,
                name: task[:name],
                state: task[:state],
                conclusion: task[:state],
                url: nil
              )
            end
        end

        # @return [ProviderRepository] normalized repository evidence
        def repository
          view = fj(["--style", "minimal", "repo", "view"])
          parsed = Parsers.parse_repo_view(view)

          Ace::Git::ProviderRepository.new(
            server_name: server.name,
            full_name: parsed[:full_name],
            default_branch: nil,
            url: parsed[:url]
          )
        end

        private

        # Run one `fj` command, classifying every failure with the taxonomy.
        def fj(args)
          result = CliExecutor.execute(args, timeout: timeout, runner: runner)
          return result[:stdout] if result[:success]

          message = result[:stderr].to_s
          case message
          when /not found|does not exist|no pull request|no issue/i
            raise Ace::Git::ProviderObjectNotFoundError, "Object not found (#{args.join(" ")}): #{message}"
          when /access denied|unauthorized|token/i
            raise Ace::Git::ProviderAuthenticationError, "Not authenticated with Forgejo: #{message}"
          else
            raise Ace::Git::ProviderUnreachableError, "Forgejo request failed (#{args.join(" ")}): #{message}"
          end
        end

        def head_sha_of(number)
          commits = fj(["--style", "minimal", "pr", "view", number.to_s, "commits"])
          Parsers.parse_head_sha(commits)
        end

        def normalize_pr(parsed)
          Ace::Git::ProviderPullRequest.new(
            server_name: server.name,
            number: parsed[:number],
            title: parsed[:title],
            state: parsed[:state],
            head_ref: parsed[:head_ref],
            base_ref: parsed[:base_ref],
            head_sha: parsed[:head_sha],
            author: parsed[:author],
            url: pr_url(parsed[:number]),
            draft: nil,
            merged_at: nil
          )
        end

        def normalize_search_entry(entry)
          Ace::Git::ProviderPullRequest.new(
            server_name: server.name,
            number: entry[:number],
            title: entry[:title],
            state: nil,
            head_ref: nil,
            base_ref: nil,
            head_sha: nil,
            author: entry[:author],
            url: pr_url(entry[:number]),
            draft: nil,
            merged_at: nil
          )
        end

        def server_host
          @server_host ||= begin
            uri = URI.parse(server.url.to_s)
            uri.host
          rescue URI::Error
            nil
          end
        end

        def pr_url(number)
          base = server.url.to_s.chomp("/")
          "#{base}/pulls/#{number}"
        end

        def issue_url(number)
          base = server.url.to_s.chomp("/")
          "#{base}/issues/#{number}"
        end
      end
    end
  end
end
