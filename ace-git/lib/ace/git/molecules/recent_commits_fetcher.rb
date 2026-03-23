# frozen_string_literal: true

module Ace
  module Git
    module Molecules
      # Fetches recent commits from the repository
      # Returns commit hashes and subjects in oneline format
      module RecentCommitsFetcher
        class << self
          # Fetch recent commits
          # @param limit [Integer] Number of commits to fetch (default: 3)
          # @param executor [CommandExecutor] Command executor
          # @return [Hash] Result with :success, :commits array, :error
          def fetch(limit: 3, executor: Atoms::CommandExecutor)
            return {success: true, commits: []} if limit <= 0

            result = executor.execute(
              "git", "log",
              "-#{limit}",
              "--format=%h %s"
            )

            if result[:success]
              commits = parse_commits(result[:output])
              {success: true, commits: commits}
            else
              {success: false, commits: [], error: result[:error]}
            end
          rescue => e
            {success: false, commits: [], error: e.message}
          end

          private

          # Parse git log output into structured array
          # @param output [String] Git log output
          # @return [Array<Hash>] Array of commit hashes with :hash and :subject
          def parse_commits(output)
            return [] if output.nil? || output.empty?

            output.strip.split("\n").map do |line|
              hash, *subject_parts = line.split(" ")
              {
                hash: hash,
                subject: subject_parts.join(" ")
              }
            end
          end
        end
      end
    end
  end
end
