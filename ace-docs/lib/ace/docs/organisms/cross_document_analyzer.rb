# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'yaml'
require 'colorize'
require 'ace/core/molecules/prompt_cache_manager'
require_relative '../organisms/document_registry'
require_relative '../prompts/consistency_prompt'
require_relative '../models/consistency_report'

# Try to load ace-llm
begin
  require 'ace/llm'
rescue LoadError
  # Will be handled with clear error message during execution
end

module Ace
  module Docs
    module Organisms
      # Orchestrates cross-document consistency analysis using LLM
      class CrossDocumentAnalyzer
        attr_reader :registry, :options

        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new(
            project_root: options[:project_root],
            scope_globs: options[:scope_globs]
          )
        end

        # Analyze documents for consistency issues
        # @param pattern [String, nil] glob pattern to filter documents
        # @return [ConsistencyReport] analysis results
        def analyze(pattern = nil)
          # Load documents
          puts "Loading documents..." if @options[:verbose]
          documents = load_documents(pattern)

          if documents.empty?
            puts "No documents found to analyze.".yellow
            return nil
          end

          # Create standardized session directory using PromptCacheManager
          session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
            "ace-docs",
            "analyze-consistency"
          )

          puts "Analyzing #{documents.count} documents for consistency issues...".cyan
          puts "Session directory: #{session_dir}".yellow

          # Save document list
          puts "Saving document list..." if @options[:verbose]
          save_document_list(documents, session_dir)

          # Prepare document paths (no need to load content, ace-bundle will do it)
          puts "Preparing document paths..." if @options[:verbose]
          document_data = prepare_document_paths(documents)
          puts "  Documents to analyze: #{document_data.size}" if @options[:verbose]

          # Build prompts
          puts "Building analysis prompts..." if @options[:verbose]
          prompt_builder = Prompts::ConsistencyPrompt.new
          prompts = prompt_builder.build(document_data, @options, session_dir: session_dir)

          # Save prompts
          puts "Saving prompts to session directory..." if @options[:verbose]
          save_prompts(prompts, session_dir)

          # Execute LLM query
          puts "\nExecuting LLM analysis..." if @options[:verbose]
          puts "This may take a few minutes for large document sets..." if documents.count > 10
          response = execute_llm_query(prompts, session_dir)

          # Response is already saved to report.md by ace-llm's output option

          # Save metadata for reference
          save_metadata(documents, pattern, session_dir)

          # Display session info
          puts "\nAnalysis saved to: #{session_dir}".green

          # Return the report path
          response
        end

        private

        # Load documents based on pattern
        def load_documents(pattern)
          all_docs = @registry.all

          return all_docs unless pattern

          # Filter documents by pattern
          all_docs.select do |doc|
            rel = doc.relative_path || doc.path
            File.fnmatch?(pattern, rel, File::FNM_PATHNAME | File::FNM_EXTGLOB) ||
              File.fnmatch?(pattern, doc.path, File::FNM_PATHNAME | File::FNM_EXTGLOB) ||
              File.fnmatch?(pattern, File.basename(doc.path), File::FNM_PATHNAME | File::FNM_EXTGLOB)
          end
        end

        # Prepare document paths for analysis
        def prepare_document_paths(documents)
          # Just return a hash of paths to empty string (ace-bundle will load the actual content)
          # This maintains compatibility with the prompt builder interface
          document_paths = {}

          documents.each do |doc|
            # Only include files that actually exist
            if File.exist?(doc.path)
              document_paths[doc.path] = "" # Empty content, ace-bundle will load it
            end
          end

          document_paths
        end

        # Execute LLM query with the prompts
        def execute_llm_query(prompts, session_dir)
          # Check if ace-llm is available
          unless defined?(Ace::LLM)
            raise "ace-llm gem not available. Please install it with: gem install ace-llm"
          end

          # Determine timeout based on document count
          timeout = determine_timeout

          # Determine model (use config or default)
          # Check both llm_model and llm.model in config
          model = @options[:model] ||
                  Ace::Docs.config["llm_model"] ||
                  Ace::Docs.config.dig("llm", "model") ||
                  "glite"  # Default to glite (fast model)

          puts "Executing LLM query (model: #{model}, timeout: #{timeout}s)..." if @options[:verbose]

          begin
            # Determine output path for saving response
            report_path = File.join(session_dir, "report.md")

            # Call LLM via QueryInterface with native output saving
            result = Ace::LLM::QueryInterface.query(
              model,
              prompts[:user],
              system: prompts[:system],
              temperature: 0.3,  # Lower temperature for more consistent analysis
              timeout: timeout,
              output: report_path,  # Save response directly as report
              format: "text",  # Save as text/markdown format
              force: true  # Overwrite if exists
            )

            # Check if we got a valid result
            unless result && result[:text]
              raise "LLM query failed to return text content"
            end

            # Return the report path (not the content)
            report_path
          rescue StandardError => e
            raise "#{e.message}"
          end
        end

        # Determine timeout based on document count
        def determine_timeout
          return @options[:timeout] if @options[:timeout]

          doc_count = @registry.all.count

          case doc_count
          when 0..10
            600   # 10 minutes minimum
          when 11..50
            900   # 15 minutes for medium sets
          else
            1200  # 20 minutes for large sets
          end
        end

        # Save document list to session directory
        def save_document_list(documents, session_dir)
          document_list = documents.map do |doc|
            {
              path: doc.path,
              type: doc.doc_type,
              purpose: doc.purpose,
              last_updated: doc.last_updated
            }
          end

          document_list_path = File.join(session_dir, "documents.json")
          File.write(document_list_path, JSON.pretty_generate(document_list))
        end

        # Save prompts to session directory using standardized names
        def save_prompts(prompts, session_dir)
          # Save system prompt with standardized name
          Ace::Core::Molecules::PromptCacheManager.save_system_prompt(
            format_prompt(prompts[:system], "System Prompt"),
            session_dir
          )

          # Save user prompt with standardized name
          Ace::Core::Molecules::PromptCacheManager.save_user_prompt(
            format_prompt(prompts[:user], "User Prompt"),
            session_dir
          )
        end

        # Format prompt for saving
        def format_prompt(content, title)
          <<~PROMPT
            # #{title}

            Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}

            ---

            #{content}
          PROMPT
        end

        # Save LLM response to session directory
        def save_llm_response(response, session_dir)
          response_path = File.join(session_dir, "llm-response.json")

          # Try to parse as JSON for pretty formatting
          begin
            parsed = JSON.parse(response)
            File.write(response_path, JSON.pretty_generate(parsed))
          rescue JSON::ParserError
            # If not JSON, save as plain text
            File.write(response_path, response)
          end
        end

        # Save report to session directory
        def save_report(report, session_dir)
          # Save markdown report
          report_path = File.join(session_dir, "report.md")
          File.write(report_path, report.to_markdown)

          # Save JSON report
          report_json_path = File.join(session_dir, "report.json")
          File.write(report_json_path, report.to_json)
        end

        # Save metadata to session directory
        def save_metadata(documents, pattern, session_dir)
          metadata = {
            "analysis_type" => "consistency",
            "generated_at" => Time.now.iso8601,
            "document_count" => documents.count,
            "pattern" => pattern,
            "options" => @options,
            "session_dir" => session_dir,
            "ace_docs_version" => Ace::Docs::VERSION
          }

          metadata_path = File.join(session_dir, "metadata.yml")
          require 'yaml'
          File.write(metadata_path, metadata.to_yaml)
        end
      end
    end
  end
end
