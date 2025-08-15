# frozen_string_literal: true

require "yaml"

module CodingAgentTools
  module Molecules
    module Context
      # DocumentEmbedder - Molecule for embedding processed context back into source documents
      #
      # Responsibilities:
      # - Embed processed context content back into original documents
      # - Handle different embedding strategies based on configuration
      # - Preserve original document structure while adding processed content
      # - Support embedding markers and metadata
      class DocumentEmbedder
        # Default marker for embedded content
        DEFAULT_EMBEDDING_MARKER = "<!-- PROCESSED CONTEXT -->"

        # Embed processed content into source document
        #
        # @param source_document [String] Original document content
        # @param processed_content [String] Processed context content to embed
        # @param options [Hash] Embedding options
        # @option options [Boolean] :embed_document_source Whether to embed into source doc
        # @option options [String] :embedding_marker Custom marker for embedded content
        # @option options [String] :embedding_position Position to embed (:end, :after_config, :replace_config)
        # @return [Hash] {success: Boolean, content: String, embedded: Boolean, error: String}
        def embed_content(source_document, processed_content, options = {})
          return {success: false, error: "Source document cannot be nil"} if source_document.nil?
          return {success: false, error: "Processed content cannot be nil"} if processed_content.nil?

          # Check if embedding is requested
          unless should_embed?(options)
            return {
              success: true,
              content: processed_content,
              embedded: false,
              source: :processed_only
            }
          end

          # Perform embedding based on strategy
          embedding_strategy = options[:embedding_position] || :end
          marker = options[:embedding_marker] || DEFAULT_EMBEDDING_MARKER

          case embedding_strategy
          when :end
            embed_at_end(source_document, processed_content, marker)
          when :after_config
            embed_after_config_block(source_document, processed_content, marker)
          when :replace_config
            replace_config_with_processed(source_document, processed_content, marker)
          else
            embed_at_end(source_document, processed_content, marker)
          end
        rescue => e
          {success: false, error: "Document embedding failed: #{e.message}"}
        end

        # Check if content should be embedded into source document
        #
        # @param options [Hash] Configuration options
        # @return [Boolean] True if embedding should occur
        def should_embed?(options)
          # Check explicit embedding option
          return options[:embed_document_source] if options.key?(:embed_document_source)

          # Check if YAML configuration has embedding directive
          if options[:yaml_config].is_a?(Hash)
            return options[:yaml_config][:embed_document_source] ||
                   options[:yaml_config]["embed_document_source"]
          end

          # Default to no embedding
          false
        end

        # Embed content at the end of the document
        #
        # @param source_document [String] Original document
        # @param processed_content [String] Content to embed
        # @param marker [String] Embedding marker
        # @return [Hash] Embedding result
        def embed_at_end(source_document, processed_content, marker)
          # Remove any existing embedded content first
          cleaned_document = remove_existing_embedded_content(source_document, marker)

          # Add new embedded content at the end
          embedded_document = cleaned_document.rstrip + "\n\n" + 
                              "#{marker}\n\n" +
                              processed_content.strip

          {
            success: true,
            content: embedded_document,
            embedded: true,
            source: :full_document_with_embedded,
            strategy: :end,
            marker: marker
          }
        end

        # Embed content after the configuration block
        #
        # @param source_document [String] Original document
        # @param processed_content [String] Content to embed
        # @param marker [String] Embedding marker
        # @return [Hash] Embedding result
        def embed_after_config_block(source_document, processed_content, marker)
          # Find the end of the last <context-tool-config> block
          config_end_pattern = /<\/context-tool-config>/
          match = source_document.match(config_end_pattern)

          unless match
            # Fallback to end embedding if no config block found
            return embed_at_end(source_document, processed_content, marker)
          end

          # Insert content after the config block
          insert_position = match.end(0)
          before_content = source_document[0...insert_position]
          after_content = source_document[insert_position..-1]

          # Remove any existing embedded content from the after section
          after_content = remove_existing_embedded_content(after_content, marker)

          embedded_document = before_content +
                              "\n\n#{marker}\n\n" +
                              processed_content.strip +
                              after_content

          {
            success: true,
            content: embedded_document,
            embedded: true,
            source: :full_document_with_embedded,
            strategy: :after_config,
            marker: marker
          }
        end

        # Replace configuration block with processed content
        #
        # @param source_document [String] Original document
        # @param processed_content [String] Content to embed
        # @param marker [String] Embedding marker
        # @return [Hash] Embedding result
        def replace_config_with_processed(source_document, processed_content, marker)
          # Find and replace <context-tool-config> blocks
          config_pattern = /<context-tool-config>.*?<\/context-tool-config>/m
          
          if source_document.match(config_pattern)
            replaced_document = source_document.gsub(config_pattern) do
              "#{marker}\n\n#{processed_content.strip}\n\n<!-- END #{marker.gsub(/[<>!-]/, '')} -->"
            end

            {
              success: true,
              content: replaced_document,
              embedded: true,
              source: :replaced_config_blocks,
              strategy: :replace_config,
              marker: marker
            }
          else
            # Fallback to end embedding if no config blocks found
            embed_at_end(source_document, processed_content, marker)
          end
        end

        # Remove existing embedded content from document
        #
        # @param document [String] Document content
        # @param marker [String] Embedding marker
        # @return [String] Document with embedded content removed
        def remove_existing_embedded_content(document, marker)
          # Pattern to match embedded content sections
          # Handles both single marker and marker pairs
          escaped_marker = Regexp.escape(marker)
          
          # Remove content between marker and end of document
          end_pattern = /\n\n#{escaped_marker}\n.*\z/m
          document = document.gsub(end_pattern, "")

          # Remove content between paired markers
          paired_pattern = /\n\n#{escaped_marker}\n.*?\n<!-- END [^>]+ -->/m
          document = document.gsub(paired_pattern, "")

          document.rstrip
        end

        # Extract YAML configuration from embedded content
        #
        # @param yaml_content [String] YAML content string
        # @return [Hash] Parsed YAML configuration
        def extract_yaml_config(yaml_content)
          return {} if yaml_content.nil? || yaml_content.strip.empty?

          YAML.safe_load(yaml_content)
        rescue => e
          {}
        end

        # Validate embedding options
        #
        # @param options [Hash] Embedding options
        # @return [Hash] {valid: Boolean, errors: Array<String>}
        def validate_embedding_options(options)
          errors = []

          # Validate embedding position
          if options[:embedding_position]
            valid_positions = [:end, :after_config, :replace_config]
            unless valid_positions.include?(options[:embedding_position])
              errors << "Invalid embedding position: #{options[:embedding_position]}. " \
                       "Valid options: #{valid_positions.join(', ')}"
            end
          end

          # Validate marker format
          if options[:embedding_marker]
            marker = options[:embedding_marker]
            if marker.strip.empty?
              errors << "Embedding marker cannot be empty"
            elsif marker.include?("\n")
              errors << "Embedding marker cannot contain newlines"
            end
          end

          {
            valid: errors.empty?,
            errors: errors
          }
        end

        # Get embedding summary for display
        #
        # @param embedding_result [Hash] Result from embed_content
        # @return [String] Human-readable summary
        def embedding_summary(embedding_result)
          return "Embedding failed: #{embedding_result[:error]}" unless embedding_result[:success]

          lines = []
          
          if embedding_result[:embedded]
            lines << "Content embedded successfully:"
            lines << "  Strategy: #{embedding_result[:strategy]}"
            lines << "  Source: #{embedding_result[:source]}"
            lines << "  Marker: #{embedding_result[:marker]}"
            
            content_size = embedding_result[:content]&.bytesize || 0
            lines << "  Result size: #{format_size(content_size)}"
          else
            lines << "Content returned without embedding:"
            lines << "  Source: #{embedding_result[:source]}"
            
            content_size = embedding_result[:content]&.bytesize || 0
            lines << "  Content size: #{format_size(content_size)}"
          end

          lines.join("\n")
        end

        private

        # Format size for display
        #
        # @param bytes [Integer] Size in bytes
        # @return [String] Formatted size
        def format_size(bytes)
          if bytes < 1024
            "#{bytes} bytes"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          else
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          end
        end
      end
    end
  end
end