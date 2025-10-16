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
            @registry.all.select { |d| d.context_preset == @options[:preset] }
          elsif file
            # Try to find in registry first (existing doc with frontmatter)
            doc = @registry.find_by_path(file)

            # If not in registry, check if file exists without frontmatter
            if !doc && File.exist?(file)
              # Create minimal Document object for file without frontmatter
              require_relative "../models/document"
              doc = Models::Document.new(
                path: File.expand_path(file),
                frontmatter: {},  # Empty frontmatter - will be initialized
                content: File.read(file)
              )
            end

            raise "File not found: #{file}" unless doc
            [doc]
          else
            raise "Please specify a file or --preset"
          end
        end

        def update_documents(documents)
          updated_count = 0
          updates = @options[:set] || {}

          documents.each do |doc|
            # Initialize required fields if frontmatter is empty
            working_updates = doc.frontmatter.empty? ? initialize_required_fields(doc, updates) : updates

            if Molecules::FrontmatterManager.update_document(doc, working_updates)
              updated_count += 1
              puts "Updated: #{doc.display_name}"
            end
          end

          updated_count
        end

        def initialize_required_fields(doc, updates)
          required_updates = updates.dup

          # Infer doc-type from file path/extension if not provided
          required_updates['doc-type'] ||= infer_doc_type(doc.path)

          # Require purpose to be provided
          unless required_updates['purpose']
            raise "Purpose required for new frontmatter. Use: --set purpose:'Document description'"
          end

          required_updates
        end

        def infer_doc_type(path)
          case path
          when /README\.md$/i then 'reference'
          when /\.wf\.md$/ then 'workflow'
          when /\.g\.md$/ then 'guide'
          when /\.template\.md$/ then 'template'
          when /docs\/.*\.md$/ then 'context'
          else 'reference'
          end
        end
      end
    end
  end
end