# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require_relative 'context_chunker'
require_relative 'section_formatter'

module Ace
  module Context
    module Molecules
      # ContextFileWriter handles writing context to files with caching and chunking
      # Configuration values (cache_dir, max_lines) are loaded from Ace::Context.config
      # following ADR-022 pattern.
      class ContextFileWriter
        def initialize(cache_dir: nil, max_lines: nil)
          @cache_dir = cache_dir || Ace::Context.cache_dir
          @max_lines = max_lines || Ace::Context.max_lines
          @chunker = ContextChunker.new(@max_lines)
        end

        # Write context with optional chunking
        def write_with_chunking(context, output_path, options = {})
          # Check if we should organize by sections
          if options[:organize_by_sections] && context.respond_to?(:has_sections?) && context.has_sections?
            write_sections_organized(context, output_path, options)
          else
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

        # Write context organized by sections
        def write_sections_organized(context, output_path, options = {})
          base_path = resolve_output_path(output_path)
          format = options[:format] || 'markdown-xml'

          # Create section formatter
          section_formatter = SectionFormatter.new(format)

          # Write main index file
          index_content = create_section_index(context, section_formatter)
          index_result = write_single_file(index_content, base_path, options)

          return index_result unless index_result[:success]

          # Write individual section files
          section_files = write_individual_sections(context, base_path, section_formatter, options)

          {
            success: true,
            chunked: true,
            index_file: base_path,
            section_files: section_files,
            total_files: section_files.size + 1,
            sections_written: section_files.size,
            lines: index_result[:lines],
            size_formatted: index_result[:size_formatted]
          }
        end

        # Create section index content
        def create_section_index(context, section_formatter)
          content = []

          content << "# Context Sections Index"
          content << ""
          content << "This context is organized into the following sections:"
          content << ""

          # Add section links
          context.sorted_sections.each do |section_name, section_data|
            title = section_data[:title] || section_data['title'] || section_name.to_s.humanize
            content << "- [#{title}](#{section_name}.md)"
          end

          content << ""
          content << "---"
          content << ""
          content << "## Complete Context"
          content << ""

          # Add complete formatted context
          content << section_formatter.format_with_sections(context)

          content.join("\n")
        end

        # Write individual section files
        def write_individual_sections(context, base_path, section_formatter, options)
          section_files = []
          base_dir = File.dirname(base_path)
          base_name = File.basename(base_path, '.*')

          context.sorted_sections.each do |section_name, section_data|
            # Create section filename
            section_filename = File.join(base_dir, "#{base_name}-#{section_name}.md")

            # Create section content
            section_content = create_section_content(section_name, section_data, context, section_formatter)

            # Write section file
            result = write_single_file(section_content, section_filename, options)

            if result[:success]
              section_files << {
                section: section_name,
                title: section_data[:title] || section_data['title'] || section_name.to_s.humanize,
                file: section_filename,
                lines: result[:lines],
                size: result[:size]
              }
            end
          end

          section_files
        end

        # Create content for an individual section
        def create_section_content(section_name, section_data, context, section_formatter)
          content = []

          title = section_data[:title] || section_data['title'] || section_name.to_s.humanize

          content << "# #{title}"
          content << ""

          # Add section metadata
          content << "**Section:** #{section_name}"
          content << "**Content Type:** #{section_data[:content_type] || section_data['content_type']}"
          content << "**Priority:** #{section_data[:priority] || section_data['priority'] || 'N/A'}"
          content << ""

          # Add section description if available
          if section_data[:description] || section_data['description']
            content << "## Description"
            content << section_data[:description] || section_data['description']
            content << ""
          end

          # Add section content
          content << "## Content"
          content << ""

          # Format just this section
          single_section = { section_name => section_data }
          content << section_formatter.format_sections_only(single_section)

          # Add navigation back to index
          content << ""
          content << "---"
          content << ""
          content << "[← Back to Index](#{File.basename(context.metadata[:output_file] || 'context.md')})"

          content.join("\n")
        end

        # Resolve output path with cache directory
        def resolve_output_path(output_path)
          # If output path is explicitly provided, use it as-is
          output_path
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