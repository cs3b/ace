# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'yaml'
require 'colorize'
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
          @registry = Organisms::DocumentRegistry.new
        end

        # Analyze documents for consistency issues
        # @param pattern [String, nil] glob pattern to filter documents
        # @return [ConsistencyReport] analysis results
        def analyze(pattern = nil)
          # Load documents
          documents = load_documents(pattern)

          if documents.empty?
            return Models::ConsistencyReport.new(
              document_count: 0,
              generated_at: Time.now
            )
          end

          # Create session directory for analysis
          cache_dir = Ace::Docs.config["cache_dir"] || ".cache/ace-docs"
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(cache_dir, "analyze-consistency-#{timestamp}")
          FileUtils.mkdir_p(session_dir)

          puts "Analyzing #{documents.count} documents for consistency issues..." if @options[:verbose]
          puts "Session directory: #{session_dir}" if @options[:verbose]

          # Save document list
          save_document_list(documents, session_dir)

          # Prepare document content
          document_data = prepare_document_data(documents)

          # Build prompts
          prompt_builder = Prompts::ConsistencyPrompt.new
          prompts = prompt_builder.build(document_data, @options)

          # Save prompts
          save_prompts(prompts, session_dir)

          # Execute LLM query
          response = execute_llm_query(prompts)

          # Save LLM response
          save_llm_response(response, session_dir)

          # Parse response into report
          report = Models::ConsistencyReport.parse(response, documents.count)

          # Save report and metadata
          save_report(report, session_dir)
          save_metadata(documents, pattern, session_dir)

          # Display session info
          puts "\nAnalysis saved to: #{session_dir}".green

          report
        end

        private

        # Load documents based on pattern
        def load_documents(pattern)
          all_docs = @registry.all

          return all_docs unless pattern

          # Filter documents by pattern
          all_docs.select do |doc|
            File.fnmatch?(pattern, doc.path) ||
            File.fnmatch?(pattern, File.basename(doc.path))
          end
        end

        # Prepare document data for analysis
        def prepare_document_data(documents)
          document_data = {}

          documents.each do |doc|
            content = if File.exist?(doc.path)
                       File.read(doc.path)
                     else
                       ""
                     end

            document_data[doc.path] = content
          end

          document_data
        end

        # Execute LLM query with the prompts
        def execute_llm_query(prompts)
          # Check if ace-llm is available
          unless defined?(Ace::LLM)
            raise "ace-llm gem not available. Please install it with: gem install ace-llm"
          end

          # Determine timeout based on document count
          timeout = determine_timeout

          # Determine model (use config or default)
          model = @options[:model] || Ace::Docs.config["llm_model"] || "gflash"

          puts "Executing LLM query (model: #{model}, timeout: #{timeout}s)..." if @options[:verbose]

          begin
            # Call LLM via QueryInterface with system prompt
            result = Ace::LLM::QueryInterface.query(
              model,
              prompts[:user],
              system: prompts[:system],
              temperature: 0.3,  # Lower temperature for more consistent analysis
              timeout: timeout
            )

            # Check if the query was successful
            unless result[:success]
              raise "LLM query failed: #{result[:error] || 'Unknown error'}"
            end

            # Return the response content
            result[:response]
          rescue StandardError => e
            raise "LLM query error: #{e.message}"
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

        # Save prompts to session directory
        def save_prompts(prompts, session_dir)
          # Save system prompt
          system_prompt_path = File.join(session_dir, "prompt-system.md")
          File.write(system_prompt_path, format_prompt(prompts[:system], "System Prompt"))

          # Save user prompt
          user_prompt_path = File.join(session_dir, "prompt-user.md")
          File.write(user_prompt_path, format_prompt(prompts[:user], "User Prompt"))
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