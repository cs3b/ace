# frozen_string_literal: true

require "pathname"

module CodingAgentTools
  module Molecules
    module Context
      # ContextChunker - Molecule for splitting large context files into manageable chunks
      #
      # Responsibilities:
      # - Split large content based on line count limits
      # - Generate index files referencing all chunks
      # - Maintain chunk naming conventions
      # - Preserve content integrity across chunks
      class ContextChunker
        DEFAULT_CHUNK_LIMIT = 150_000
        DEFAULT_CHUNK_SUFFIX = "_chunk"

        def initialize(chunk_limit = DEFAULT_CHUNK_LIMIT)
          @chunk_limit = chunk_limit
        end

        # Check if content needs chunking
        #
        # @param content [String] Content to check
        # @return [Boolean] true if content exceeds chunk limit
        def needs_chunking?(content)
          return false if content.nil? || content.empty?
          
          line_count = content.split("\n").length
          line_count > @chunk_limit
        end

        # Split content into chunks with index file
        #
        # @param content [String] Content to chunk
        # @param base_path [String] Base output path (without extension)
        # @param options [Hash] Chunking options
        # @option options [String] :chunk_suffix Suffix for chunk files (default: "_chunk")
        # @option options [Boolean] :include_metadata Include metadata in chunks (default: true)
        # @return [Hash] Chunking result with file paths and statistics
        def chunk_content(content, base_path, options = {})
          opts = {
            chunk_suffix: DEFAULT_CHUNK_SUFFIX,
            include_metadata: true
          }.merge(options)

          return single_file_result(content, base_path) unless needs_chunking?(content)

          lines = content.split("\n")
          chunks = split_into_chunks(lines)
          
          chunk_files = generate_chunk_files(chunks, base_path, opts)
          index_content = generate_index_content(chunk_files, base_path, opts)

          {
            chunked: true,
            total_chunks: chunks.length,
            chunk_limit: @chunk_limit,
            total_lines: lines.length,
            index_file: "#{base_path}.md",
            index_content: index_content,
            chunk_files: chunk_files,
            total_size: calculate_total_size(chunk_files)
          }
        end

        # Split content and write all files (index + chunks)
        #
        # @param content [String] Content to chunk and write
        # @param base_path [String] Base output path
        # @param file_writer [Object] File writer instance
        # @param options [Hash] Options for chunking and writing
        # @return [Hash] Write results for all files
        def chunk_and_write(content, base_path, file_writer, options = {})
          chunk_result = chunk_content(content, base_path, options)
          
          unless chunk_result[:chunked]
            # Write single file
            return {
              chunked: false,
              files_written: 1,
              results: [
                file_writer.write_file(content, "#{base_path}.md", options)
              ]
            }
          end

          # Write index file and all chunks
          write_results = []
          
          # Write index file
          index_result = file_writer.write_file(
            chunk_result[:index_content],
            chunk_result[:index_file],
            options
          )
          write_results << index_result.merge(file_type: "index")

          # Write chunk files
          chunk_result[:chunk_files].each do |chunk_file|
            chunk_write_result = file_writer.write_file(
              chunk_file[:content],
              chunk_file[:path],
              options
            )
            write_results << chunk_write_result.merge(file_type: "chunk", chunk_number: chunk_file[:number])
          end

          {
            chunked: true,
            files_written: write_results.length,
            total_chunks: chunk_result[:total_chunks],
            chunk_limit: @chunk_limit,
            results: write_results
          }
        end

        # Generate chunk file paths for a given base path
        #
        # @param base_path [String] Base path without extension
        # @param chunk_count [Integer] Number of chunks
        # @param suffix [String] Chunk suffix
        # @return [Array<String>] Array of chunk file paths
        def generate_chunk_paths(base_path, chunk_count, suffix = DEFAULT_CHUNK_SUFFIX)
          (1..chunk_count).map do |i|
            "#{base_path}#{suffix}#{i}.md"
          end
        end

        # Calculate optimal chunk size for given content
        #
        # @param content [String] Content to analyze
        # @return [Hash] Analysis with recommended chunk strategy
        def analyze_chunking_strategy(content)
          return { chunking_needed: false } unless needs_chunking?(content)

          lines = content.split("\n")
          total_lines = lines.length
          chunks_needed = (total_lines.to_f / @chunk_limit).ceil
          avg_chunk_size = total_lines / chunks_needed

          {
            chunking_needed: true,
            total_lines: total_lines,
            chunk_limit: @chunk_limit,
            chunks_needed: chunks_needed,
            avg_chunk_size: avg_chunk_size,
            last_chunk_size: total_lines - ((chunks_needed - 1) * @chunk_limit),
            estimated_files: chunks_needed + 1 # +1 for index
          }
        end

        private

        # Split lines into chunks
        #
        # @param lines [Array<String>] Lines to split
        # @return [Array<Array<String>>] Array of line chunks
        def split_into_chunks(lines)
          chunks = []
          current_chunk = []
          
          lines.each do |line|
            current_chunk << line
            
            if current_chunk.length >= @chunk_limit
              chunks << current_chunk
              current_chunk = []
            end
          end
          
          # Add remaining lines as final chunk
          chunks << current_chunk unless current_chunk.empty?
          
          chunks
        end

        # Generate chunk file data
        #
        # @param chunks [Array<Array<String>>] Line chunks
        # @param base_path [String] Base output path
        # @param options [Hash] Chunking options
        # @return [Array<Hash>] Chunk file specifications
        def generate_chunk_files(chunks, base_path, options)
          chunks.map.with_index(1) do |chunk_lines, index|
            chunk_path = "#{base_path}#{options[:chunk_suffix]}#{index}.md"
            chunk_content = generate_chunk_content(chunk_lines, index, chunks.length, options)
            
            {
              number: index,
              path: chunk_path,
              content: chunk_content,
              lines: chunk_lines.length,
              size: chunk_content.bytesize,
              basename: File.basename(chunk_path)
            }
          end
        end

        # Generate content for a single chunk
        #
        # @param chunk_lines [Array<String>] Lines for this chunk
        # @param chunk_number [Integer] Chunk number (1-based)
        # @param total_chunks [Integer] Total number of chunks
        # @param options [Hash] Options
        # @return [String] Formatted chunk content
        def generate_chunk_content(chunk_lines, chunk_number, total_chunks, options)
          content_parts = []
          
          if options[:include_metadata]
            content_parts << "<!-- Chunk #{chunk_number} of #{total_chunks} -->"
            content_parts << "<!-- Lines: #{chunk_lines.length} -->"
            content_parts << ""
          end
          
          content_parts.concat(chunk_lines)
          content_parts.join("\n")
        end

        # Generate index file content
        #
        # @param chunk_files [Array<Hash>] Chunk file specifications
        # @param base_path [String] Base path
        # @param options [Hash] Options
        # @return [String] Index file content
        def generate_index_content(chunk_files, base_path, options)
          lines = []
          
          lines << "# Context Index"
          lines << ""
          lines << "This context has been split into multiple chunks for easier processing."
          lines << ""
          
          # Summary statistics
          total_lines = chunk_files.sum { |chunk| chunk[:lines] }
          total_size = chunk_files.sum { |chunk| chunk[:size] }
          
          lines << "## Summary"
          lines << ""
          lines << "- **Total chunks**: #{chunk_files.length}"
          lines << "- **Total lines**: #{total_lines}"
          lines << "- **Total size**: #{format_size(total_size)}"
          lines << "- **Chunk limit**: #{@chunk_limit} lines"
          lines << ""
          
          # Chunk listing
          lines << "## Chunks"
          lines << ""
          chunk_files.each do |chunk|
            lines << "### #{chunk[:basename]}"
            lines << ""
            lines << "- **Lines**: #{chunk[:lines]}"
            lines << "- **Size**: #{format_size(chunk[:size])}"
            lines << "- **Path**: `#{chunk[:path]}`"
            lines << ""
          end
          
          lines << "---"
          lines << ""
          lines << "*Generated by ContextChunker*"
          
          lines.join("\n")
        end

        # Handle single file (no chunking needed)
        #
        # @param content [String] Content
        # @param base_path [String] Base path
        # @return [Hash] Single file result
        def single_file_result(content, base_path)
          lines = content.split("\n")
          
          {
            chunked: false,
            total_chunks: 1,
            chunk_limit: @chunk_limit,
            total_lines: lines.length,
            single_file: "#{base_path}.md",
            single_content: content,
            total_size: content.bytesize
          }
        end

        # Calculate total size of all chunk files
        #
        # @param chunk_files [Array<Hash>] Chunk file specifications
        # @return [Integer] Total size in bytes
        def calculate_total_size(chunk_files)
          chunk_files.sum { |chunk| chunk[:size] }
        end

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