# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'ace/core/molecules/context_chunker'

module Ace
  module Context
    module Molecules
      # ContextFileWriter handles writing context to files with caching and chunking
      class ContextFileWriter
        DEFAULT_CACHE_DIR = 'docs/context/cached'
        DEFAULT_CHUNK_LIMIT = 150_000

        def initialize(cache_dir: nil, chunk_limit: nil)
          @cache_dir = cache_dir || DEFAULT_CACHE_DIR
          @chunk_limit = chunk_limit || DEFAULT_CHUNK_LIMIT
          @chunker = Ace::Core::Molecules::ContextChunker.new(@chunk_limit)
        end

        # Write context with optional chunking
        def write_with_chunking(context, output_path, options = {})
          content = format_content(context, options[:format])

          # Determine actual output path
          path = resolve_output_path(output_path)

          # Check if chunking is needed
          if @chunker.needs_chunking?(content)
            write_chunked_content(content, path, options)
          else
            write_single_file(content, path, options)
          end
        end

        # Write single file
        def write(content, path, options = {})
          begin
            # Ensure directory exists
            dir = File.dirname(path)
            FileUtils.mkdir_p(dir) unless File.directory?(dir)

            # Write file
            File.write(path, content)

            # Calculate statistics
            lines = content.lines.size
            size = content.bytesize

            {
              success: true,
              path: path,
              lines: lines,
              size: size,
              size_formatted: format_bytes(size)
            }
          rescue => e
            {
              success: false,
              error: e.message,
              path: path
            }
          end
        end

        private

        # Format content based on context data
        def format_content(context, format = nil)
          if context.respond_to?(:content)
            context.content
          elsif context.is_a?(Hash)
            formatter = Ace::Core::Molecules::OutputFormatter.new(format || 'markdown-xml')
            formatter.format(context)
          else
            context.to_s
          end
        end

        # Resolve output path with cache directory
        def resolve_output_path(output_path)
          path = Pathname.new(output_path)

          # If path is relative and doesn't start with a known directory
          if path.relative? && !output_path.start_with?('docs/', 'tmp/', './')
            # Assume it should go in the cache directory
            File.join(@cache_dir, output_path)
          else
            output_path
          end
        end

        # Write content in chunks
        def write_chunked_content(content, base_path, options)
          # Remove extension from base path for chunking
          base_path_no_ext = base_path.sub(/\.[^.]+$/, '')

          # Chunk and write content
          result = @chunker.chunk_and_write(content, base_path_no_ext, self, options)

          # Add formatted output path
          result[:index_file] = "#{base_path_no_ext}.md"
          result[:success] = true

          result
        end

        # Write single file (no chunking)
        def write_single_file(content, path, options)
          result = write(content, path, options)

          {
            success: result[:success],
            chunked: false,
            files_written: result[:success] ? 1 : 0,
            lines: result[:lines],
            size_formatted: result[:size_formatted],
            error: result[:error]
          }
        end

        # Format bytes for human readability
        def format_bytes(bytes)
          units = ['B', 'KB', 'MB', 'GB']
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