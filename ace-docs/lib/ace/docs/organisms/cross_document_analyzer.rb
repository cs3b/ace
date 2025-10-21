# frozen_string_literal: true

require 'shellwords'
require 'fileutils'
require 'json'
require_relative '../organisms/document_registry'
require_relative '../prompts/consistency_prompt'
require_relative '../models/consistency_report'

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
          unless command_exists?('ace-llm-query')
            raise "ace-llm-query not found. Please install ace-llm gem: gem install ace-llm"
          end

          # Determine timeout based on document count
          timeout = determine_timeout

          # Build the full prompt
          full_prompt = build_full_prompt(prompts)

          # Create a temporary file for the prompt (to handle large prompts)
          require 'tempfile'
          prompt_file = Tempfile.new(['consistency_prompt', '.txt'])

          begin
            prompt_file.write(full_prompt)
            prompt_file.close

            # Execute ace-llm-query
            command = build_llm_command(prompt_file.path, timeout)

            puts "Executing LLM query (timeout: #{timeout}s)..." if @options[:verbose]

            output = `#{command} 2>&1`
            exit_status = $?.exitstatus

            if exit_status != 0
              raise "LLM query failed with exit code #{exit_status}: #{output}"
            end

            # Extract JSON from the response
            extract_json_from_response(output)
          ensure
            prompt_file.unlink
          end
        end

        # Build the full prompt combining system and user prompts
        def build_full_prompt(prompts)
          <<~PROMPT
            SYSTEM:
            #{prompts[:system]}

            USER:
            #{prompts[:user]}
          PROMPT
        end

        # Build the ace-llm-query command
        def build_llm_command(prompt_file, timeout)
          model = @options[:model] || 'gpt-4'

          # Build command parts
          cmd_parts = ['ace-llm-query']
          cmd_parts << "--file #{Shellwords.escape(prompt_file)}"
          cmd_parts << "--model #{Shellwords.escape(model)}"
          cmd_parts << "--timeout #{timeout}"
          cmd_parts << "--temperature 0.3"  # Lower temperature for more consistent analysis

          cmd_parts.join(' ')
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

        # Extract JSON from LLM response
        def extract_json_from_response(response)
          # Try to find JSON in the response
          # LLM might wrap it in markdown code blocks
          json_match = response.match(/```json\s*(.*?)\s*```/m) ||
                      response.match(/```\s*(.*?)\s*```/m) ||
                      response.match(/(\{.*\})/m)

          if json_match
            json_match[1]
          else
            response
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

        # Check if a command exists
        def command_exists?(cmd)
          system("which #{cmd} > /dev/null 2>&1")
        end
      end
    end
  end
end