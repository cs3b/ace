# frozen_string_literal: true

require "find"
require "pathname"

module Ace
  module Compressor
    module Organisms
      class ExactCompressor
        SUPPORTED_EXTENSIONS = %w[.md .markdown .mdown .mkd .txt .text].freeze
        BINARY_SNIFF_BYTES = 4096

        attr_reader :ignored_paths

        def initialize(paths, verbose: false, mode_label: "exact")
          @paths = Array(paths)
          @verbose = verbose
          @mode_label = mode_label
          @parser = Ace::Compressor::Atoms::MarkdownParser.new
          @transformer = Ace::Compressor::Atoms::CanonicalBlockTransformer
          @ignored_paths = []
        end

        def call
          compress_sources(resolve_sources)
        end

        def resolve_sources
          explicit_set = Set.new
          resolved = []

          @paths.each do |raw_path|
            path = raw_path.to_s
            expanded = File.expand_path(path)

            if File.directory?(expanded)
              directory_files = collect_supported_directory_files(expanded)
              if directory_files.empty?
                raise Ace::Compressor::Error,
                  "Directory has no supported markdown/text sources: #{path}. Supported extensions: #{SUPPORTED_EXTENSIONS.join(", ")}"
              end
              directory_files.each do |file|
                next if explicit_set.include?(file)

                explicit_set << file
                resolved << file
              end
            elsif File.file?(expanded)
              validate_explicit_file!(expanded, path)
              next if explicit_set.include?(expanded)

              explicit_set << expanded
              resolved << expanded
            else
              raise Ace::Compressor::Error, "Input source not found: #{path}"
            end
          end

          sorted = resolved.sort
          if sorted.empty?
            raise Ace::Compressor::Error,
              "No supported markdown/text sources found. Supported extensions: #{SUPPORTED_EXTENSIONS.join(", ")}"
          end

          sorted
        end

        def compress_sources(sources, source_paths: nil)
          lines = [Ace::Compressor::Models::ContextPack.header("exact")]

          sources.each do |source|
            source_label = source_label(display_source(source, source_paths))
            lines << Ace::Compressor::Models::ContextPack.file_line(source_label)
            text = File.read(source)
            if text.strip.empty?
              raise Ace::Compressor::Error, "Input file is empty. #{mode_title} mode requires content: #{source}"
            end
            blocks = @parser.call(text)
            if blocks.empty?
              lines << text
              next
            end
            lines.concat transformed_lines(source_label, blocks)
          end

          lines.join("\n")
        end

        # Compress a content string directly without filesystem access.
        # Returns the compressed ContextPack text (without header line).
        # @param text [String] markdown/text content to compress
        # @param label [String] display label for the source (e.g. original file path)
        # @return [String] compressed ContextPack records (no header)
        def compress_text(text, label:)
          return text if text.to_s.strip.empty?

          blocks = @parser.call(text)
          return text if blocks.empty?

          lines = []
          lines << Ace::Compressor::Models::ContextPack.file_line(label)
          lines.concat @transformer.new(label).call(blocks)
          lines.join("\n")
        end

        private

        def transformed_lines(source, blocks)
          transformer = @transformer.new(source)
          transformer.call(blocks)
        end

        def display_source(source, source_paths)
          return source unless source_paths

          source_paths[File.expand_path(source)] || source_paths[source] || source
        end

        def collect_supported_directory_files(directory)
          supported = []

          Find.find(directory) do |entry|
            next unless File.file?(entry)

            expanded = File.expand_path(entry)
            if supported_extension?(entry)
              if binary_file?(expanded)
                @ignored_paths << expanded if @verbose
              else
                supported << expanded
              end
            elsif @verbose
              @ignored_paths << expanded
            end
          end

          supported.sort
        end

        def validate_explicit_file!(expanded, original)
          unless supported_extension?(expanded)
            if binary_file?(expanded)
              raise Ace::Compressor::Error, "Binary input is not supported in #{mode_label} mode: #{original}"
            end

            raise Ace::Compressor::Error,
              "Unsupported explicit file: #{original}. Supported extensions: #{SUPPORTED_EXTENSIONS.join(", ")}"
          end

          return unless binary_file?(expanded)

          raise Ace::Compressor::Error, "Binary input is not supported in #{mode_label} mode: #{original}"
        end

        def supported_extension?(path)
          SUPPORTED_EXTENSIONS.include?(File.extname(path).downcase)
        end

        def binary_file?(path)
          sample = File.binread(path, BINARY_SNIFF_BYTES) || ""
          sample.include?("\x00")
        rescue
          false
        end

        def source_label(source)
          value = source.to_s
          return value if logical_source?(value)

          source_path = canonical_path(value)
          project_root = canonical_path(Dir.pwd)
          relative = relative_path_under(source_path, project_root)
          return relative if relative

          value
        end

        def mode_label
          @mode_label.to_s.strip.empty? ? "exact" : @mode_label
        end

        def mode_title
          mode_label.capitalize
        end

        def logical_source?(value)
          return true unless Pathname.new(value).absolute?

          value.match?(%r{\A[a-z][a-z0-9+\-.]*://}i)
        rescue ArgumentError
          true
        end

        def canonical_path(path)
          expanded = File.expand_path(path)
          return File.realpath(expanded) if File.exist?(expanded)

          canonical_missing_path(expanded)
        rescue
          File.expand_path(path)
        end

        def canonical_missing_path(path)
          parent = path
          suffix = []
          until File.exist?(parent) || parent == File.dirname(parent)
            suffix.unshift(File.basename(parent))
            parent = File.dirname(parent)
          end
          return path unless File.exist?(parent)

          File.join(File.realpath(parent), *suffix)
        end

        def relative_path_under(path, root)
          return "." if path == root

          prefix = "#{root}#{File::SEPARATOR}"
          return path.delete_prefix(prefix) if path.start_with?(prefix)

          nil
        end
      end
    end
  end
end
