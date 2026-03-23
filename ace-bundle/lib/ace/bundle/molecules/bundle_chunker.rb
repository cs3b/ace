# frozen_string_literal: true

require_relative "../atoms/boundary_finder"

module Ace
  module Bundle
    module Molecules
      # BundleChunker splits large content into manageable chunks
      # Configuration is loaded from Ace::Bundle.max_lines (ADR-022)
      #
      # Performance Note: Current implementation loads full content into memory.
      # For very large files (>100MB), consider implementing streaming chunking
      # to reduce memory footprint. This optimization can be added in future versions.
      class BundleChunker
        # Fallback value if config is not available
        DEFAULT_MAX_LINES = 2_000
        DEFAULT_CHUNK_SUFFIX = "_chunk"

        attr_reader :max_lines

        # @param max_lines [Integer, nil] Override max lines per chunk (nil uses config)
        def initialize(max_lines = nil)
          @max_lines = max_lines || config_max_lines || DEFAULT_MAX_LINES
        end

        private

        # Load max_lines from configuration
        # Falls back to DEFAULT_MAX_LINES if config is unavailable
        # @return [Integer] Configured max lines per chunk
        def config_max_lines
          Ace::Bundle.max_lines
        rescue
          DEFAULT_MAX_LINES
        end

        public

        # Check if content needs chunking
        def needs_chunking?(content)
          return false if content.nil? || content.empty?

          line_count = content.lines.size
          line_count > @max_lines
        end

        # Split content into chunks
        def chunk_content(content, base_path, options = {})
          opts = {
            chunk_suffix: DEFAULT_CHUNK_SUFFIX,
            include_metadata: true
          }.merge(options)

          return single_file_result(content, base_path) unless needs_chunking?(content)

          lines = content.lines
          chunks = split_into_chunks(lines)

          chunk_files = generate_chunk_files(chunks, base_path, opts)
          index_content = generate_index_content(chunk_files, base_path, opts)

          {
            chunked: true,
            total_chunks: chunks.size,
            max_lines: @max_lines,
            total_lines: lines.size,
            index_file: "#{base_path}.md",
            index_content: index_content,
            chunk_files: chunk_files,
            total_size: calculate_total_size(chunk_files)
          }
        end

        # Split content and write all files (index + chunks)
        def chunk_and_write(content, base_path, file_writer, options = {})
          chunk_result = chunk_content(content, base_path, options)

          unless chunk_result[:chunked]
            # Write single file
            return {
              chunked: false,
              files_written: 1,
              results: [
                file_writer.write(content, "#{base_path}.md", options)
              ]
            }
          end

          # Write index file and all chunks
          write_results = []

          # Write index file
          index_result = file_writer.write(
            chunk_result[:index_content],
            chunk_result[:index_file],
            options
          )
          write_results << index_result.merge(file_type: "index")

          # Write chunk files
          chunk_result[:chunk_files].each do |chunk_info|
            chunk_result_write = file_writer.write(
              chunk_info[:content],
              chunk_info[:path],
              options
            )
            write_results << chunk_result_write.merge(file_type: "chunk", chunk_number: chunk_info[:chunk_number])

            # Progress callback if provided
            if options[:progress_callback]
              options[:progress_callback].call("Wrote chunk #{chunk_info[:chunk_number]} of #{chunk_result[:total_chunks]}")
            end
          end

          {
            chunked: true,
            total_chunks: chunk_result[:total_chunks],
            files_written: write_results.size,
            results: write_results
          }
        end

        private

        # Generate result for single file (no chunking needed)
        def single_file_result(content, base_path)
          {
            chunked: false,
            total_chunks: 1,
            total_lines: content.lines.size,
            file_path: "#{base_path}.md",
            content: content,
            total_size: content.bytesize
          }
        end

        # Split lines into chunks using semantic boundaries when possible
        # Semantic boundaries ensure XML elements like <file> and <output> are never split
        def split_into_chunks(lines)
          content = lines.join

          # Check if content has semantic elements (XML tags we shouldn't split)
          if Atoms::BoundaryFinder.has_semantic_elements?(content)
            split_by_semantic_boundaries(content)
          else
            split_by_line_count(lines)
          end
        end

        # Split content using semantic boundaries (never splits <file> or <output> elements)
        # Falls back to keeping large single elements whole rather than splitting them
        def split_by_semantic_boundaries(content)
          blocks = Atoms::BoundaryFinder.parse_blocks(content)

          chunks = []
          current_chunk_blocks = []
          current_line_count = 0

          blocks.each do |block|
            block_lines = block[:lines]

            # If adding this block would exceed limit and we have content, flush current chunk
            if current_line_count + block_lines > @max_lines && current_chunk_blocks.any?
              chunks << current_chunk_blocks.map { |b| b[:content] }.join
              current_chunk_blocks = []
              current_line_count = 0
            end

            # Add block to current chunk (even if it exceeds limit - we don't split elements)
            current_chunk_blocks << block
            current_line_count += block_lines
          end

          # Add remaining blocks
          chunks << current_chunk_blocks.map { |b| b[:content] }.join if current_chunk_blocks.any?

          chunks
        end

        # Original line-based splitting for content without semantic elements
        def split_by_line_count(lines)
          chunks = []
          current_chunk = []

          lines.each do |line|
            current_chunk << line

            if current_chunk.size >= @max_lines
              chunks << current_chunk.join
              current_chunk = []
            end
          end

          # Add remaining lines
          chunks << current_chunk.join unless current_chunk.empty?

          chunks
        end

        # Generate chunk file information
        def generate_chunk_files(chunks, base_path, options)
          chunk_files = []

          chunks.each_with_index do |chunk_content, index|
            chunk_number = index + 1
            chunk_path = "#{base_path}#{options[:chunk_suffix]}_#{chunk_number.to_s.rjust(3, "0")}.md"

            chunk_files << {
              chunk_number: chunk_number,
              path: chunk_path,
              content: chunk_content,
              lines: chunk_content.lines.size,
              size: chunk_content.bytesize
            }
          end

          chunk_files
        end

        # Generate index file content
        def generate_index_content(chunk_files, base_path, options)
          index_lines = []

          index_lines << "# Bundle Index"
          index_lines << ""
          index_lines << "This content has been split into #{chunk_files.size} chunks due to size constraints."
          index_lines << ""
          index_lines << "## Summary"
          index_lines << ""
          index_lines << "- Total chunks: #{chunk_files.size}"
          index_lines << "- Max lines per chunk: #{@max_lines}"
          index_lines << "- Total size: #{format_bytes(calculate_total_size(chunk_files))}"
          index_lines << ""
          index_lines << "## Chunks"
          index_lines << ""

          chunk_files.each do |chunk_info|
            relative_path = chunk_info[:path].sub(%r{^.*/}, "")
            index_lines << "### Chunk #{chunk_info[:chunk_number]}"
            index_lines << ""
            index_lines << "- File: [#{relative_path}](#{relative_path})"
            index_lines << "- Lines: #{chunk_info[:lines]}"
            index_lines << "- Size: #{format_bytes(chunk_info[:size])}"
            index_lines << ""
          end

          if options[:include_metadata]
            index_lines << "## Metadata"
            index_lines << ""
            index_lines << "- Generated at: #{Time.now.iso8601}"
            index_lines << "- Base path: #{base_path}"
            index_lines << "- Chunk suffix: #{options[:chunk_suffix]}"
            index_lines << ""
          end

          index_lines.join("\n")
        end

        # Calculate total size of all chunks
        def calculate_total_size(chunk_files)
          chunk_files.sum { |chunk| chunk[:size] }
        end

        # Format bytes for human readability
        def format_bytes(bytes)
          units = ["B", "KB", "MB", "GB"]
          size = bytes.to_f
          unit_index = 0

          while size >= 1024 && unit_index < units.size - 1
            size /= 1024
            unit_index += 1
          end

          "#{size.round(2)} #{units[unit_index]}"
        end
      end
    end
  end
end
