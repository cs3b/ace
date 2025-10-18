# frozen_string_literal: true

require_relative "../organisms/document_registry"
require_relative "../molecules/change_detector"
require_relative "../prompts/document_analysis_prompt"
require "colorize"

# Try to load ace-llm
begin
  require "ace/llm"
rescue LoadError
  # Will be handled with clear error message during execution
end

module Ace
  module Docs
    module Commands
      # Command for analyzing changes relevant to a specific document
      class AnalyzeCommand
        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new
        end

        # Execute the analyze command
        # @param file [String] Document path to analyze
        # @return [Integer] Exit code (0 success, 1 no doc, 2 no changes, 3 LLM error)
        def execute(file)
          # Validate file argument
          unless file
            puts "Error: Please specify a document to analyze".red
            puts "Usage: ace-docs analyze FILE"
            puts "Example: ace-docs analyze README.md"
            return 1
          end

          # Load document
          document = @registry.find_by_path(file)

          unless document
            puts "Error: Document not found or not managed by ace-docs: #{file}".red
            puts "Ensure the file has ace-docs frontmatter (doc-type, purpose)"
            return 1
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
          since = determine_since(document)
          puts "\nAnalyzing changes since: #{since}".cyan

          # Generate filtered diff(s)
          puts "Generating git diff...".cyan
          diff_result = Molecules::ChangeDetector.get_diff_for_document(
            document,
            since: since,
            options: build_diff_options
          )

          # Check if there are changes
          unless diff_result[:has_changes]
            puts "No changes detected in the specified period.".green
            puts "The document may already be up to date."
            return 2
          end

          # Display diff statistics
          if diff_result[:multi_subject]
            # Multi-subject: show stats for each subject
            diffs_hash = diff_result[:diffs]
            diffs_hash.each do |subject_name, diff_content|
              next if diff_content.strip.empty?
              lines = count_diff_lines(diff_content)
              puts "  ✓ #{subject_name}: #{lines} lines changed".green
            end
          else
            # Single subject
            diff = diff_result[:diff]
            puts "Changes detected (#{count_diff_lines(diff)} lines)".green
          end

          # Check if ace-llm is available
          unless defined?(Ace::LLM)
            puts "\nError: ace-llm gem not available".red
            puts "Install it with: gem install ace-llm"
            puts "\nOr add to your Gemfile:"
            puts "  gem 'ace-llm'"
            return 3
          end

          # Create session directory for analysis
          cache_dir = Ace::Docs.config["cache_dir"] || ".cache/ace-docs"
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(cache_dir, "analyze-#{timestamp}")
          FileUtils.mkdir_p(session_dir)

          # Analyze with LLM
          puts "\nAnalyzing changes with LLM...".cyan
          # Pass the appropriate diff format (single string or hash of diffs)
          diff_for_analysis = diff_result[:multi_subject] ? diff_result[:diffs] : diff_result[:diff]
          analysis = analyze_with_llm(document, diff_for_analysis, since, session_dir: session_dir)

          unless analysis[:success]
            puts "Error: #{analysis[:error]}".red
            return 3
          end

          # Save results to cache
          puts "\nSaving analysis results...".cyan
          cache_path = save_to_cache(document, diff_result, analysis, since, session_dir: session_dir)
          puts "Analysis saved to: #{cache_path}".green

          # Display summary
          display_summary(analysis)

          0
        rescue StandardError => e
          puts "Error during analysis: #{e.message}".red
          puts e.backtrace.join("\n") if ENV["DEBUG"]
          3
        end

        private

        def determine_since(document)
          # Use explicit --since option if provided
          return @options[:since] if @options[:since]

          # Use document's last-updated date if available
          if document.last_updated
            return document.last_updated.strftime("%Y-%m-%d")
          end

          # Default to 7 days ago
          (Date.today - 7).strftime("%Y-%m-%d")
        end

        def build_diff_options
          {
            include_renames: !@options[:exclude_renames],
            include_moves: !@options[:exclude_moves]
          }
        end

        def count_diff_lines(diff)
          diff.lines.count
        end

        def analyze_with_llm(document, diff, since, session_dir: nil)
          # Build prompts (returns hash with :system, :user, :context_md, :diff_stats)
          prompts = Prompts::DocumentAnalysisPrompt.build(
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

          # Call LLM via QueryInterface with system prompt
          result = Ace::LLM::QueryInterface.query(
            model,
            prompts[:user],
            system: prompts[:system],
            temperature: 0.3,
            timeout: 60
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
        rescue StandardError => e
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
            **Source**: #{prompt_type == "System Prompt" ? "ace-nav prompt://document-analysis.system" : "Generated from document context"}

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

        def display_summary(analysis)
          puts "\n" + "="*60
          puts "Analysis Complete".bold.green
          puts "="*60
          puts "\nModel: #{analysis[:model]} (#{analysis[:provider]})"
          puts "\nThe analysis has been saved to the cache directory."
          puts "Review the analysis.md file for detailed recommendations."
        end
      end
    end
  end
end
