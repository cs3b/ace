# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for validating markdown links
      # Extracted from dev-taskflow/.../lint-md-links.rb
      class MarkdownLinkValidator
        LINK_REGEX = /\[[^\]]+\]\(([^)]+)\)/
        SCHEME_SKIP = %r{^(?:[a-z][a-z0-9+\-.]*://|mailto:)}i

        attr_reader :root_path, :context_lines

        def initialize(options = {})
          @root_path = Pathname.new(File.expand_path(options[:root] || '.'))
          @context_lines = options[:context] || 3
        end

        def validate(paths = ['.'])
          md_files = collect_markdown_files(paths)
          broken_links = []

          md_files.each do |file|
            validate_file_links(file, broken_links)
          end

          {
            success: broken_links.empty?,
            findings: broken_links,
            errors: broken_links.map { |link| format_error(link) }
          }
        end

        private

        def collect_markdown_files(paths)
          paths.flat_map do |p|
            File.directory?(p) ? Dir.glob(File.join(p, '**', '*.md')) : [p]
          end
        end

        def validate_file_links(file, broken_links)
          lines = File.readlines(file, chomp: true)
          in_code_block = false

          lines.each_with_index do |line, idx|
            # Toggle code block mode
            fence_start = line.lstrip[0, 3]
            if ['```', '~~~'].include?(fence_start)
              in_code_block = !in_code_block
              next
            end

            next if in_code_block

            line.scan(LINK_REGEX) do |match|
              raw_target = match.first.strip
              next if should_skip_link?(raw_target)

              unless link_exists?(raw_target, file)
                broken_links << {
                  file: file,
                  line_no: idx + 1,
                  link: raw_target,
                  context: extract_context(lines, idx)
                }
              end
            end
          end
        end

        def should_skip_link?(target)
          target.match?(SCHEME_SKIP) || target.start_with?('#')
        end

        def link_exists?(target, source_file)
          # Clean up fragment identifiers
          clean_target = target.split('#').first || target

          # Try relative to source file first
          source_dir = Pathname.new(File.dirname(source_file))
          relative_path = source_dir.join(clean_target)

          return true if File.exist?(relative_path)

          # Try from project root
          root_relative_path = root_path.join(clean_target)
          File.exist?(root_relative_path)
        end

        def extract_context(lines, index)
          start_idx = [index - context_lines, 0].max
          end_idx = [index + context_lines, lines.size - 1].min

          lines[start_idx..end_idx]
        end

        def format_error(link)
          "#{link[:file]}:#{link[:line_no]}: Broken link '#{link[:link]}'"
        end
      end
    end
  end
end
