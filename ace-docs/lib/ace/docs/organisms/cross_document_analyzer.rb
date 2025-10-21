# frozen_string_literal: true

require 'fileutils'
require 'json'
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

          puts "Analyzing #{documents.count} documents for consistency issues..." if @options[:verbose]

          # Prepare document content
          document_data = prepare_document_data(documents)

          # Build prompts
          prompt_builder = Prompts::ConsistencyPrompt.new
          prompts = prompt_builder.build(document_data, @options)

          # Execute LLM query
          response = execute_llm_query(prompts)

          # Parse response into report
          report = Models::ConsistencyReport.parse(response, documents.count)

          # Cache results if requested
          cache_report(report) if @options[:save]

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
            60
          when 11..50
            120
          else
            180
          end
        end

        # Cache the report to filesystem
        def cache_report(report)
          cache_dir = '.cache/ace-docs'
          FileUtils.mkdir_p(cache_dir)

          timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
          cache_file = File.join(cache_dir, "consistency-#{timestamp}.md")

          File.write(cache_file, report.to_markdown)

          puts "Report saved to: #{cache_file}" if @options[:verbose]
        end
      end
    end
  end
end