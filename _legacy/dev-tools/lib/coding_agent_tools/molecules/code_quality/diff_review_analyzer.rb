# frozen_string_literal: true

require "open3"
require "tempfile"

module CodingAgentTools
  module Molecules
    module CodeQuality
      # Molecule for analyzing diffs and reviewing changes
      class DiffReviewAnalyzer
        def analyze_changes(before_snapshot: nil, after_snapshot: nil)
          if before_snapshot && after_snapshot
            # Compare snapshots
            analyze_snapshots(before_snapshot, after_snapshot)
          else
            # Use git to detect changes
            analyze_git_changes
          end
        end

        def create_snapshot
          # Create a snapshot of current file states
          snapshot = {
            timestamp: Time.now,
            files: {}
          }

          # Find all relevant files
          relevant_files.each do |file|
            next unless File.exist?(file)

            snapshot[:files][file] = {
              content: File.read(file),
              mtime: File.mtime(file),
              size: File.size(file)
            }
          end

          snapshot
        end

        def format_review(analysis)
          review = []
          review << "# Code Quality Changes Review"
          review << ""
          review << "Generated at: #{Time.now}"
          review << ""

          if analysis[:summary]
            review << "## Summary"
            review << "- Files modified: #{analysis[:summary][:files_modified]}"
            review << "- Lines added: #{analysis[:summary][:lines_added]}"
            review << "- Lines removed: #{analysis[:summary][:lines_removed]}"
            review << ""
          end

          if analysis[:changes] && !analysis[:changes].empty?
            review << "## File Changes"
            review << ""

            analysis[:changes].each do |file, changes|
              review << "### #{file}"
              review << ""
              review << format_file_changes(changes)
              review << ""
            end
          end

          review.join("\n")
        end

        private

        def relevant_files
          # Get all Ruby and Markdown files
          ruby_files = Dir.glob("**/*.rb").reject { |f| f.start_with?("spec/", "vendor/") }
          md_files = Dir.glob("**/*.md").reject { |f| f.start_with?("vendor/") }

          ruby_files + md_files
        end

        def analyze_git_changes
          # Check if we're in a git repository
          return {error: "Not in a git repository"} unless system("git rev-parse --git-dir > /dev/null 2>&1")

          # Get the diff
          stdout, stderr, status = Open3.capture3("git diff --numstat")

          if status.success?
            parse_git_diff(stdout)
          else
            {error: "Failed to get git diff: #{stderr}"}
          end
        end

        def parse_git_diff(diff_output)
          analysis = {
            summary: {
              files_modified: 0,
              lines_added: 0,
              lines_removed: 0
            },
            changes: {}
          }

          diff_output.each_line do |line|
            parts = line.strip.split("\t")
            next unless parts.size == 3

            added = parts[0].to_i
            removed = parts[1].to_i
            file = parts[2]

            analysis[:summary][:files_modified] += 1
            analysis[:summary][:lines_added] += added
            analysis[:summary][:lines_removed] += removed

            analysis[:changes][file] = {
              lines_added: added,
              lines_removed: removed
            }
          end

          # Get actual diff content for each file
          analysis[:changes].each_key do |file|
            diff_content, = Open3.capture3("git diff #{file}")
            analysis[:changes][file][:diff] = diff_content
          end

          analysis
        end

        def analyze_snapshots(before, after)
          analysis = {
            summary: {
              files_modified: 0,
              files_added: 0,
              files_removed: 0,
              lines_added: 0,
              lines_removed: 0
            },
            changes: {}
          }

          all_files = (before[:files].keys + after[:files].keys).uniq

          all_files.each do |file|
            before_data = before[:files][file]
            after_data = after[:files][file]

            if before_data && after_data
              # File modified
              if before_data[:content] != after_data[:content]
                analysis[:summary][:files_modified] += 1
                diff = calculate_diff(before_data[:content], after_data[:content], file)
                analysis[:changes][file] = diff
                analysis[:summary][:lines_added] += diff[:lines_added]
                analysis[:summary][:lines_removed] += diff[:lines_removed]
              end
            elsif after_data
              # File added
              analysis[:summary][:files_added] += 1
              lines = after_data[:content].lines.size
              analysis[:summary][:lines_added] += lines
              analysis[:changes][file] = {
                status: "added",
                lines_added: lines,
                lines_removed: 0
              }
            else
              # File removed
              analysis[:summary][:files_removed] += 1
              lines = before_data[:content].lines.size
              analysis[:summary][:lines_removed] += lines
              analysis[:changes][file] = {
                status: "removed",
                lines_added: 0,
                lines_removed: lines
              }
            end
          end

          analysis
        end

        def calculate_diff(before_content, after_content, filename)
          # Use temporary files for diff
          before_file = Tempfile.new(["before", File.extname(filename)])
          after_file = Tempfile.new(["after", File.extname(filename)])

          begin
            before_file.write(before_content)
            before_file.flush

            after_file.write(after_content)
            after_file.flush

            diff_output, = Open3.capture3(
              "diff -u #{before_file.path} #{after_file.path}"
            )

            parse_unified_diff(diff_output)
          ensure
            before_file.close
            before_file.unlink
            after_file.close
            after_file.unlink
          end
        end

        def parse_unified_diff(diff_output)
          lines_added = 0
          lines_removed = 0

          diff_output.each_line do |line|
            if line.start_with?("+") && !line.start_with?("+++")
              lines_added += 1
            elsif line.start_with?("-") && !line.start_with?("---")
              lines_removed += 1
            end
          end

          {
            lines_added: lines_added,
            lines_removed: lines_removed,
            diff: diff_output
          }
        end

        def format_file_changes(changes)
          lines = []

          lines << if changes[:status]
            "**Status:** #{changes[:status]}"
          else
            "**Status:** modified"
          end

          lines << "**Lines added:** #{changes[:lines_added]}"
          lines << "**Lines removed:** #{changes[:lines_removed]}"

          if changes[:diff] && changes[:diff].size < 1000
            lines << ""
            lines << "```diff"
            lines << changes[:diff]
            lines << "```"
          end

          lines.join("\n")
        end
      end
    end
  end
end
