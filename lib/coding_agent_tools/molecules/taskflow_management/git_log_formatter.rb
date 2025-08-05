# frozen_string_literal: true

require_relative '../../atoms/taskflow_management/shell_command_executor'

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # GitLogFormatter composes atoms to provide git log formatting functionality
      class GitLogFormatter
        # Git log entry structure
        LogEntry = Struct.new(:repository, :timestamp, :sha, :author, :message, :raw_timestamp) do
          def formatted_timestamp(format: '%Y-%m-%d %H:%M')
            Time.at(timestamp).strftime(format)
          rescue
            raw_timestamp || 'unknown'
          end

          def short_sha(length: 7)
            return 'unknown' if sha.nil? || sha.empty?

            sha[0, [length, sha.length].min]
          end

          def single_line_message
            return '' if message.nil?

            message.split("\n").first&.strip || ''
          end
        end

        # Log result containing entries and metadata
        LogResult = Struct.new(:entries, :repositories, :time_range, :total_commits, :errors) do
          def success?
            !entries.nil? && errors.empty?
          end

          def empty?
            entries.nil? || entries.empty?
          end
        end

        # Get recent git log from multiple repositories
        def self.get_multi_repo_log(repositories, since_time:, include_merges: false, max_commits: 100)
          entries = []
          errors = []
          valid_repositories = []

          since_str = normalize_time_string(since_time)

          repositories.each do |repo_config|
            repo_entries = get_repository_log(
              repo_config, since_str: since_str, include_merges: include_merges, max_commits: max_commits
            )
            entries.concat(repo_entries)
            valid_repositories << repo_config
          rescue => e
            errors << "Error getting log for #{repo_config[:label] || repo_config[:path]}: #{e.message}"
          end

          entries.sort_by! { |entry| -entry.timestamp }
          LogResult.new(entries, valid_repositories, since_time, entries.length, errors)
        end

        # Format log entries for display
        def self.format_log_output(log_result, format: :compact, show_repository: true)
          return 'No commits found.' if log_result.empty?

          output = []

          case format
          when :compact
            format_compact_output(log_result, output, show_repository)
          when :detailed
            format_detailed_output(log_result, output, show_repository)
          when :oneline
            format_oneline_output(log_result, output, show_repository)
          else
            raise ArgumentError, 'Unknown format: ' + format.to_s
          end

          output.join("\n")
        end

        class << self
          private

          def get_repository_log(repo_config, since_str:, include_merges:, max_commits:)
            path = repo_config[:path]
            label = repo_config[:label] || File.basename(path)

            git_command = build_git_log_command(since_str, include_merges, max_commits)
            result = Atoms::TaskflowManagement::ShellCommandExecutor.execute(git_command, working_directory: path,
              timeout: 30)

            raise "Git command failed: #{result.stderr}" unless result.success?

            parse_git_log_output(result.stdout, label)
          end

          def build_git_log_command(since_str, include_merges, max_commits)
            cmd_parts = ['git', 'log']
            cmd_parts << "--since=#{since_str}"
            cmd_parts << '--no-merges' unless include_merges
            cmd_parts << "--max-count=#{max_commits}"
            cmd_parts << '--pretty=format:%ct|%h|%an|%B<<END>>'
            cmd_parts.join(' ')
          end

          def parse_git_log_output(output, repository_label)
            entries = []
            return entries if output.nil? || output.strip.empty?

            commit_blocks = output.split('<<END>>')

            commit_blocks.each do |block|
              next if block.strip.empty?

              lines = block.strip.lines
              next if lines.empty?

              header_line = lines.first.strip
              header_parts = header_line.split('|', 3)
              next if header_parts.length < 3

              timestamp_str, sha, author = header_parts
              timestamp = timestamp_str.to_i

              message_lines = lines[1..] || []
              message = message_lines.join.strip

              entries << LogEntry.new(repository_label, timestamp, sha, author, message, timestamp_str)
            end

            entries
          end

          def normalize_time_string(time_input)
            case time_input
            when Time
              time_input.strftime('%Y-%m-%dT%H:%M:%S')
            when String
              time_input
            else
              raise ArgumentError, "Invalid time format: #{time_input.class}"
            end
          end

          def format_compact_output(log_result, output, show_repository)
            log_result.entries.each do |entry|
              repo_prefix = show_repository ? "[#{entry.repository}] " : ''
              output << "#{repo_prefix}#{entry.formatted_timestamp} #{entry.short_sha} #{entry.author}:"
              output << entry.single_line_message.to_s
              output << '---'
            end
          end

          def format_detailed_output(log_result, output, show_repository)
            log_result.entries.each do |entry|
              repo_prefix = show_repository ? "[#{entry.repository}] " : ''
              output << "#{repo_prefix}#{entry.formatted_timestamp} #{entry.sha} #{entry.author}:"
              output << ''

              if entry.message && !entry.message.empty?
                entry.message.split("\n").each do |line|
                  output << "    #{line}"
                end
              end

              output << ''
              output << '=' * 70
            end
          end

          def format_oneline_output(log_result, output, show_repository)
            log_result.entries.each do |entry|
              repo_prefix = show_repository ? "[#{entry.repository}] " : ''
              output << "#{repo_prefix}#{entry.short_sha} #{entry.single_line_message}"
            end
          end
        end
      end
    end
  end
end
