# frozen_string_literal: true

require_relative "../organisms/document_registry"
require_relative "../molecules/frontmatter_manager"

module Ace
  module Docs
    module Commands
      # Command for updating document frontmatter
      class UpdateCommand
        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new
        end

        # Execute the update command
        # @return [Integer] Exit code (0 for success)
        def execute(file = nil)
          documents = select_documents(file)

          if documents.empty?
            puts "No documents to update."
            return 0
          end

          updated_count = update_documents(documents)
          puts "Updated frontmatter for #{updated_count} document(s)"

          0
        rescue StandardError => e
          puts "Error updating documents: #{e.message}"
          puts e.backtrace.join("\n") if ENV["DEBUG"]
          1
        end

        private

        def select_documents(file)
          if @options[:preset]
            # TODO: Implement preset-based selection
            @registry.all.select { |d| d.context_preset == @options[:preset] }
          elsif file
            doc = @registry.find_by_path(file)
            raise "Document not found: #{file}" unless doc
            [doc]
          else
            raise "Please specify a file or --preset"
          end
        end

        def update_documents(documents)
          updated_count = 0
          updates = @options[:set] || {}

          documents.each do |doc|
            if Molecules::FrontmatterManager.update_document(doc, updates)
              updated_count += 1
              puts "Updated: #{doc.display_name}"
            end
          end

          updated_count
        end
      end
    end
  end
end