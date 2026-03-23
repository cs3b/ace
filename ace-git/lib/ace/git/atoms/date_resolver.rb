# frozen_string_literal: true

require "date"

module Ace
  module Git
    module Atoms
      # Pure functions for resolving dates to git commits
      # Migrated from ace-git-diff
      module DateResolver
        class << self
          # Resolve a since parameter to a git commit reference
          # @param since [String, Date] Date string, relative time, or commit SHA
          # @param executor [Module] Command executor module (default: CommandExecutor)
          # @return [String] Git commit reference
          def resolve_since_to_commit(since, executor: CommandExecutor)
            return "HEAD" if since.nil? || since.empty?

            # If it looks like a commit SHA, use as-is
            return since if commit_sha?(since)

            # If it looks like a git ref (branch, tag), use as-is
            return since if git_ref?(since)

            # It's a date or relative time - find the first commit since that date
            first_commit = find_first_commit_since(since, executor)
            return since unless first_commit # Fallback to date string

            # Get parent of first commit to include all changes since date
            parent = get_parent_commit(first_commit, executor)
            parent || first_commit
          end

          # Check if a string looks like a commit SHA
          # @param ref [String] Reference to check
          # @return [Boolean] True if looks like a commit SHA
          def commit_sha?(ref)
            !!(ref =~ /^[0-9a-f]{7,40}$/i)
          end

          # Check if a string looks like a git reference (branch, tag, etc)
          # @param ref [String] Reference to check
          # @return [Boolean] True if looks like a git ref
          def git_ref?(ref)
            # Check for common ref patterns:
            # - refs/heads/*, refs/remotes/*, refs/tags/*
            # - origin/main, upstream/develop, etc
            # - HEAD, HEAD~1, HEAD^, etc
            !!(ref =~ %r{^(refs/|origin/|upstream/|HEAD)}) ||
              !!(ref =~ /^[A-Za-z][A-Za-z0-9_\-\/]*$/) # Branch or tag name
          end

          # Parse relative time strings (e.g., "7d", "1 week ago", "2 months")
          # @param time_str [String] Time string to parse
          # @return [String, nil] ISO date string or nil if can't parse
          def parse_relative_time(time_str)
            case time_str
            when /^(\d+)d$/ # e.g., "7d"
              days = Regexp.last_match(1).to_i
              (Date.today - days).strftime("%Y-%m-%d")
            when /^(\d+)\s*days?\s*ago$/i # e.g., "7 days ago"
              days = Regexp.last_match(1).to_i
              (Date.today - days).strftime("%Y-%m-%d")
            when /^(\d+)\s*weeks?\s*ago$/i # e.g., "1 week ago"
              weeks = Regexp.last_match(1).to_i
              (Date.today - (weeks * 7)).strftime("%Y-%m-%d")
            when /^(\d+)\s*months?\s*ago$/i # e.g., "2 months ago"
              months = Regexp.last_match(1).to_i
              (Date.today << months).strftime("%Y-%m-%d")
            else
              # Try to parse as date string
              begin
                Date.parse(time_str).strftime("%Y-%m-%d")
              rescue ArgumentError
                nil
              end
            end
          end

          # Format since parameter for git commands
          # @param since [String, Date, Time] Since parameter
          # @return [String] Formatted since string
          def format_since(since)
            case since
            when Date
              since.strftime("%Y-%m-%d")
            when Time
              since.strftime("%Y-%m-%d")
            when String
              # Try to parse relative time
              parsed = parse_relative_time(since)
              parsed || since
            else
              (Date.today - 7).strftime("%Y-%m-%d")
            end
          end

          private

          # Find the first commit since a given date
          # @param since [String, nil] Date string or relative time
          # @param executor [Module] Command executor
          # @return [String, nil] First commit SHA or nil
          def find_first_commit_since(since, executor)
            # Handle nil/empty since parameter
            return nil if since.nil? || since.to_s.strip.empty?

            # Parse relative time if needed
            date_str = parse_relative_time(since) || since

            result = executor.execute("git", "log", "--since=#{date_str}", "--format=%H", "--reverse", "--all")
            return nil unless result[:success]

            commits = result[:output].strip.split("\n")
            commits.first
          end

          # Get the parent commit of a given commit
          def get_parent_commit(commit, executor)
            result = executor.execute("git", "rev-parse", "#{commit}~1")
            result[:success] ? result[:output].strip : nil
          rescue
            nil
          end
        end
      end
    end
  end
end
