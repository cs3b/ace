# frozen_string_literal: true

require "ace/support/cli"
require "fileutils"
require "ace/core"
require "colorize"
require "ace/b36ts"
require_relative "../../organisms/document_registry"
require_relative "../../molecules/change_detector"
require_relative "../../prompts/document_analysis_prompt"

# Try to load ace-llm
begin
  require "ace/llm"
rescue LoadError
  # Will be handled with clear error message during execution
end

module Ace
  module Docs
    module CLI
      module Commands
        # ace-support-cli Command class for the analyze command
        #
        # This command handles document analysis with LLM integration.
        class Analyze < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          # Exit codes
          EXIT_SUCCESS = 0
          EXIT_ERROR = 1
          EXIT_NO_CHANGES = 2
          EXIT_ANALYSIS_ERROR = 3

          desc <<~DESC.strip
            Analyze changes for a document with LLM

            Analyze git changes for a document using an LLM to understand what content
            has changed and whether documentation updates are needed.

            Configuration:
              LLM model configured via ace-llm
              Global config:  ~/.ace/docs/config.yml
              Project config: .ace/docs/config.yml

            Output:
              Analysis results printed to stdout
              Exit codes: 0 (success), 1 (error)
          DESC

          example [
            "README.md",
            "docs/architecture.md --since '2025-01-01'",
            "file.md --exclude-renames --exclude-moves"
          ]

          argument :file, required: true, desc: "File to analyze"

          option :since, type: :string, desc: "Date or commit to analyze from"
          option :exclude_renames, type: :boolean, desc: "Exclude renamed files from diff"
          option :exclude_moves, type: :boolean, desc: "Exclude moved files from diff"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(file:, **options)
            # Handle --help/-h passed as file argument
            if file == "--help" || file == "-h"
              # ace-support-cli will handle help automatically, so we just ignore
              return EXIT_SUCCESS
            end

            execute_analyze(file, options)
          end

          private

          def execute_analyze(file, options)
            # Load document (file argument is enforced as required by ace-support-cli)
            registry = Ace::Docs::Organisms::DocumentRegistry.new
            document = registry.find_by_path(file)

            unless document
              warn "Error: Document not found or not managed by ace-docs: #{file}"
              warn "Ensure the file has ace-docs frontmatter (doc-type, purpose)"
              return EXIT_ERROR
            end

            puts "Analyzing changes for: #{document.display_name}".cyan
            puts "Document type: #{document.doc_type}" if document.doc_type
            puts "Purpose: #{document.purpose}" if document.purpose

            # Show subject configuration
            if document.multi_subject?
              subjects = document.subject_configurations
              puts "\nSubjects configured:".yellow
              subjects.each do |subject|
                filter_desc = subject[:filters].join(", ")
                puts "  - #{subject[:name]}: #{filter_desc}"
              end
            else
              # Single subject - show filters if present
              filters = document.subject_diff_filters
              if filters && !filters.empty?
                puts "\nSubject filters (tracking changes in):".yellow
                filters.each { |f| puts "  - #{f}" }
              else
                puts "\nNo subject filters defined (tracking all changes)".yellow
              end
            end

            # Determine time range
            since = determine_since(document, options)
            puts "\nAnalyzing changes since: #{since}".cyan

            # Generate filtered diff(s)
            puts "Generating git diff...".cyan
            diff_result = Ace::Docs::Molecules::ChangeDetector.get_diff_for_document(
              document,
              since: since,
              options: build_diff_options(options)
            )

            # Check if there are changes
            unless diff_result[:has_changes]
              puts "\n✅ No changes detected in the specified period.".green
              puts "The document appears to be up to date."
              puts "\nNext steps:"
              puts "  • Run with different --since date to check other time periods"
              puts "  • Use 'ace-docs status' to see document freshness"
              return EXIT_NO_CHANGES
            end

            # Display diff statistics
            if diff_result[:multi_subject]
              # Multi-subject: show stats for each subject
              diffs_hash = diff_result[:diffs]
              diffs_hash.each do |subject_name, diff_content|
                next if diff_content.strip.empty?
                lines = count_diff_lines(diff_content)
                puts "  ✓ #{subject_name}: #{lines} lines changed"
              end
            else
              # Single subject
              diff = diff_result[:diff]
              puts "Changes detected (#{count_diff_lines(diff)} lines)"
            end

            # Check if ace-llm is available
            unless defined?(Ace::LLM)
              warn "\nError: ace-llm gem not available"
              warn "Install it with: gem install ace-llm"
              warn "\nOr add to your Gemfile:"
              warn "  gem 'ace-llm'"
              return EXIT_ANALYSIS_ERROR
            end

            # Create session directory for analysis
            cache_dir = Ace::Docs.config["cache_dir"] || ".ace-local/docs"
            compact_id = Ace::B36ts.encode(Time.now)
            session_dir = File.join(cache_dir, "analyze-#{compact_id}")
            FileUtils.mkdir_p(session_dir)

            # Analyze with LLM
            puts "\nAnalyzing changes with LLM...".cyan
            # Pass the appropriate diff format (single string or hash of diffs)
            diff_for_analysis = diff_result[:multi_subject] ? diff_result[:diffs] : diff_result[:diff]
            analysis = analyze_with_llm(document, diff_for_analysis, since, session_dir: session_dir)

            unless analysis[:success]
              warn "Error: #{analysis[:error]}"
              return EXIT_ANALYSIS_ERROR
            end

            # Save results to cache
            puts "\nSaving analysis results...".cyan
            save_to_cache(document, diff_result, analysis, since, session_dir: session_dir)

            # Display summary with session directory
            display_summary(analysis, session_dir: session_dir)

            EXIT_SUCCESS
          rescue => e
            warn "Error during analysis: #{e.message}"
            warn e.backtrace.join("\n") if debug?(options)
            EXIT_ANALYSIS_ERROR
          end

          def determine_since(document, options)
            # Use explicit --since option if provided
            return options[:since] if options[:since]

            # Use document's last-updated date if available
            if document.last_updated
              return document.last_updated.strftime("%Y-%m-%d")
            end

            # Default to 7 days ago
            (Date.today - 7).strftime("%Y-%m-%d")
          end

          def build_diff_options(options)
            {
              exclude_renames: options[:exclude_renames] || false,
              exclude_moves: options[:exclude_moves] || false
            }
          end

          def count_diff_lines(diff)
            diff.lines.count
          end

          def analyze_with_llm(document, diff, since, session_dir: nil)
            # Build prompts (returns hash with :system, :user, :context_md, :diff_stats)
            prompts = Ace::Docs::Prompts::DocumentAnalysisPrompt.build(
              document,
              diff,
              since: since,
              cache_dir: session_dir
            )

            # Save prompts BEFORE calling LLM (for debugging even if LLM fails)
            if session_dir
              # Save system prompt
              system_prompt_path = File.join(session_dir, "prompt-system.md")
              File.write(system_prompt_path, format_prompt(prompts[:system], "System Prompt"))

              # Save user prompt
              user_prompt_path = File.join(session_dir, "prompt-user.md")
              File.write(user_prompt_path, format_prompt(prompts[:user], "User Prompt"))
            end

            # Determine model (use config or default to gflash)
            model = Ace::Docs.config["llm_model"] || "gflash"

            # Get timeout from config (default is 300 seconds from default_config)
            timeout = Ace::Docs.config["llm_timeout"]

            # Call LLM via QueryInterface with system prompt
            result = Ace::LLM::QueryInterface.query(
              model,
              prompts[:user],
              system: prompts[:system],
              temperature: 0.3,
              timeout: timeout
            )

            {
              success: true,
              analysis: result[:text],
              model: result[:model],
              provider: result[:provider],
              system_prompt: prompts[:system],
              user_prompt: prompts[:user],
              context_md: prompts[:context_md],
              diff_stats: prompts[:diff_stats],
              timestamp: Time.now.utc.iso8601
            }
          rescue => e
            {
              success: false,
              error: e.message,
              timestamp: Time.now.utc.iso8601
            }
          end

          def save_to_cache(document, diff_result, analysis, since, session_dir:)
            # session_dir is already created in execute method
            # Note: repo-diff.diff, context.md, and prompts are already saved by analyze_with_llm

            # Save LLM analysis
            analysis_path = File.join(session_dir, "analysis.md")
            File.write(analysis_path, format_analysis(document, analysis, since))

            # Save diff statistics
            if analysis[:diff_stats]
              diff_stats_path = File.join(session_dir, "diff-stats.yml")
              File.write(diff_stats_path, analysis[:diff_stats].to_yaml)
            end

            # Save metadata
            metadata_path = File.join(session_dir, "metadata.yml")
            metadata = {
              "document_path" => document.path,
              "document_type" => document.doc_type,
              "generated" => analysis[:timestamp],
              "since" => since,
              "has_changes" => diff_result[:has_changes],
              "filters_applied" => diff_result[:options][:paths] || [],
              "llm_model" => analysis[:model],
              "llm_provider" => analysis[:provider],
              "prompts_saved" => {
                "system" => "prompt-system.md",
                "user" => "prompt-user.md"
              },
              "context_saved" => "context.md",
              "diff_stats_saved" => analysis[:diff_stats] ? "diff-stats.yml" : nil
            }
            File.write(metadata_path, metadata.to_yaml)

            analysis_path
          end

          def format_prompt(prompt_content, prompt_type)
            <<~MARKDOWN
              # #{prompt_type}

              **Generated**: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
              **Source**: #{(prompt_type == "System Prompt") ? "ace-nav prompt://document-analysis.system" : "Generated from document context"}

              ---

              #{prompt_content}
            MARKDOWN
          end

          def format_analysis(document, analysis, since)
            <<~MARKDOWN
              # Documentation Analysis Report

              **Document**: #{document.relative_path || document.path}
              **Type**: #{document.doc_type}
              **Purpose**: #{document.purpose}
              **Generated**: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
              **Period**: Changes since #{since}
              **Model**: #{analysis[:model]} (#{analysis[:provider]})

              ---

              #{analysis[:analysis]}
            MARKDOWN
          end

          def display_summary(analysis, session_dir:)
            puts "\n" + "=" * 60
            puts "✅ Analysis Complete".bold.green
            puts "=" * 60
            puts "\nModel: #{analysis[:model]} (#{analysis[:provider]})"
            puts "\nResults saved to: #{session_dir}"
            puts "\nNext steps:"
            puts "  • Review analysis.md for detailed recommendations"
            puts "  • Check prompt-system.md and prompt-user.md to see prompts used"
            puts "  • Run 'ace-docs update FILE --set last-updated=today' to mark as reviewed"
          end
        end
      end
    end
  end
end
