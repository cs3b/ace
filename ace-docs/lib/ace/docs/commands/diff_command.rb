# frozen_string_literal: true

require_relative "../organisms/document_registry"
require_relative "../molecules/change_detector"

module Ace
  module Docs
    module Commands
      # Command for analyzing document changes
      class DiffCommand
        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new
        end

        # Execute the diff command
        # @return [Integer] Exit code (0 for success)
        def execute(file = nil)
          documents = select_documents(file)

          if documents.empty?
            puts "No documents to analyze."
            return 0
          end

          puts "Analyzing changes for #{documents.size} document(s)..."

          result = generate_diff(documents)
          cache_file = Molecules::ChangeDetector.save_diff_to_cache(result)

          puts "Analysis saved to: #{cache_file}"
          display_summary(result)

          0
        rescue StandardError => e
          puts "Error analyzing changes: #{e.message}"
          puts e.backtrace.join("\n") if ENV["DEBUG"]
          1
        end

        private

        def select_documents(file)
          if file
            doc = @registry.find_by_path(file)
            raise "Document not found: #{file}" unless doc
            [doc]
          elsif @options[:all]
            @registry.all
          elsif @options[:needs_update]
            @registry.needing_update
          else
            @registry.needing_update
          end
        end

        def generate_diff(documents)
          diff_options = {
            include_renames: !@options[:exclude_renames],
            include_moves: !@options[:exclude_moves]
          }

          if documents.size == 1
            Molecules::ChangeDetector.get_diff_for_document(
              documents.first,
              since: @options[:since],
              options: diff_options
            )
          else
            Molecules::ChangeDetector.get_diff_for_documents(
              documents,
              since: @options[:since],
              options: diff_options
            )
          end
        end

        def display_summary(result)
          if result[:document_diffs]
            with_changes = result[:documents_with_changes]
            puts "Documents with changes: #{with_changes}/#{result[:total_documents]}"
          elsif result[:has_changes]
            puts "Changes detected for #{File.basename(result[:document_path])}"
          else
            puts "No changes detected."
          end

          return unless result[:document_diffs]

          # Show per-document breakdown for multiple documents
          result[:document_diffs].each do |doc_diff|
            if doc_diff[:has_changes]
              puts "  #{doc_diff[:document]} - #{doc_diff[:stats][:total_lines]} lines changed"
            else
              puts "  #{doc_diff[:document]} - no changes"
            end
          end
        end
      end
    end
  end
end