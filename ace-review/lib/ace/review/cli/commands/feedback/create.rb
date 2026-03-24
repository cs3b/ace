# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "session_discovery"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # ace-support-cli Command class for feedback create
          #
          # Creates feedback items from review reports in a session directory.
          # Uses LLM to synthesize multiple review reports into unique,
          # deduplicated feedback items with reviewer attribution.
          class Create < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include SessionDiscovery

            desc <<~DESC.strip
              Create feedback items from review reports

              Parses review markdown files in a session directory and creates
              individual feedback files in the feedback/ subdirectory. Uses LLM
              to synthesize multiple reviews into unique findings with proper
              reviewer attribution.

              Each finding becomes a separate .s.md file that can be verified,
              resolved, or skipped.
            DESC

            example [
              "                              # Use most recent session (default)",
              "--session .ace-local/review/sessions/review-abc123",
              "--model gemini-2.5-flash      # Use specific model for synthesis"
            ]

            option :session, type: :string, desc: "Session directory containing review reports"
            option :model, type: :string, desc: "Model to use for feedback synthesis"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(**options)
              # Resolve session directory
              session_dir = resolve_session_dir(options)

              unless session_dir
                raise Ace::Support::Cli::Error.new(
                  "No session found. Run a review first or use --session to specify path."
                )
              end

              puts "Using session: #{session_dir}" unless quiet?(options)

              unless Dir.exist?(session_dir)
                raise Ace::Support::Cli::Error.new("Session directory not found: #{session_dir}")
              end

              debug_log("Session directory: #{session_dir}", options)

              # Find review report files
              report_paths = find_review_reports(session_dir)

              if report_paths.empty?
                raise Ace::Support::Cli::Error.new(
                  "No review reports found in #{session_dir}. " \
                  "Expected files like review-report-*.md or review-*.md"
                )
              end

              puts "Found #{report_paths.length} review report(s)" unless quiet?(options)
              report_paths.each { |p| debug_log("  - #{File.basename(p)}", options) }

              # Create feedback items
              manager = Organisms::FeedbackManager.new
              result = manager.extract_and_save(
                report_paths: report_paths,
                base_path: session_dir,
                model: options[:model],
                session_dir: session_dir
              )

              if result[:success]
                display_success(result, session_dir, options)
              else
                raise Ace::Support::Cli::Error.new(result[:error])
              end
            end

            private

            # Find review report files in session directory
            #
            # @param session_dir [String] Session directory path
            # @return [Array<String>] List of report file paths
            def find_review_reports(session_dir)
              patterns = [
                File.join(session_dir, "review-report-*.md"),
                File.join(session_dir, "review-*.md")
              ]

              # Collect all matching files, exclude non-report files
              patterns.flat_map { |pattern| Dir.glob(pattern) }
                .uniq
                .reject { |p| exclude_file?(p) }
                .sort
            end

            # Check if a file should be excluded from report collection
            #
            # @param path [String] File path
            # @return [Boolean] True if should be excluded
            def exclude_file?(path)
              basename = File.basename(path)

              # Exclude non-report files
              excluded_patterns = [
                /^review-dev-feedback\.md$/,  # Developer feedback is a source, not a report
                /^synthesis/,                  # Synthesis outputs
                /\.tmp$/,                      # Temporary files
                /^metadata/                    # Metadata files
              ]

              excluded_patterns.any? { |pattern| basename.match?(pattern) }
            end

            # Display success message
            #
            # @param result [Hash] Extraction result
            # @param session_dir [String] Session directory
            # @param options [Hash] Command options
            def display_success(result, session_dir, options)
              if result[:items_count] == 0
                puts "No feedback items extracted from reviews."
                return
              end

              puts "Created #{result[:items_count]} feedback item(s)" unless quiet?(options)

              if options[:verbose] && result[:paths]
                puts
                puts "Files created:"
                result[:paths].each do |path|
                  puts "  #{File.basename(path)}"
                end
              end

              if result[:metadata]
                meta = result[:metadata]
                if meta[:consensus_findings] && meta[:consensus_findings] > 0
                  puts "  Consensus items: #{meta[:consensus_findings]}" unless quiet?(options)
                end
              end

              feedback_dir = File.join(session_dir, "feedback")
              puts
              puts "Feedback directory: #{feedback_dir}"
              puts
              puts "Next steps:"
              puts "  ace-review feedback list --session #{session_dir}"
              puts "  ace-review feedback show <id>"
              puts "  ace-review feedback verify <id> --valid"
            end
          end
        end
      end
    end
  end
end
