# frozen_string_literal: true

require 'find'
require_relative 'project_sandbox'

module CodingAgentTools
  module Molecules
    # ContextLoader handles loading project context from documentation files
    # This is a molecule - it provides behavior-oriented context loading functionality
    class ContextLoader
      def initialize(sandbox = nil)
        @sandbox = sandbox || ProjectSandbox.new
      end

      # Load all docs/*.md files as project context
      # @return [Hash] Result with success status and context content
      def load_docs_context
        docs_dir = File.join(@sandbox.project_root, 'docs')

        return { success: false, error: "Docs directory not found: #{docs_dir}" } unless Dir.exist?(docs_dir)

        context_documents = []
        failed_files = []

        # Find all .md files in docs directory
        md_files = Dir.glob(File.join(docs_dir, '**/*.md')).sort

        md_files.each do |file_path|
          relative_path = file_path.sub(@sandbox.project_root + '/', '')

          begin
            content = File.read(file_path)
            context_documents << {
              path: relative_path,
              content: content
            }
          rescue => e
            failed_files << { path: relative_path, error: e.message }
          end
        end

        # Format context as embedded documents
        context_content = format_embedded_context(context_documents)

        result = {
          success: true,
          context: context_content,
          files_loaded: context_documents.length,
          files_failed: failed_files.length
        }

        # Add failure details if any files failed
        result[:failed_files] = failed_files unless failed_files.empty?

        result
      rescue => e
        { success: false, error: "Context loading failed: #{e.message}" }
      end

      private

      def format_embedded_context(documents)
        return '' if documents.empty?

        context = "<context>\n"
        documents.each do |doc|
          context += "    <document path=\"#{doc[:path]}\">\n"
          # Indent content for proper XML structure
          indented_content = doc[:content].lines.map { |line| "        #{line}" }.join
          context += indented_content
          context += "\n    </document>\n"
        end
        context += '</context>'

        context
      end
    end
  end
end
