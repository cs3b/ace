# frozen_string_literal: true

require "find"
require "pathname"
require "set"

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
                      "Directory has no supported markdown/text sources: #{path}. Supported extensions: #{SUPPORTED_EXTENSIONS.join(', ')}"
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
                  "No supported markdown/text sources found. Supported extensions: #{SUPPORTED_EXTENSIONS.join(', ')}"
          end

          sorted
        end

        def compress_sources(sources)
          lines = [Ace::Compressor::Models::ContextPack.header("exact")]

          sources.each do |source|
            source_label = source_label(source)
            lines << Ace::Compressor::Models::ContextPack.file_line(source_label)
            text = File.read(source)
            if text.strip.empty?
              raise Ace::Compressor::Error, "Input file is empty. #{mode_title} mode requires content: #{source}"
            end
            blocks = @parser.call(text)
            if blocks.empty?
              raise Ace::Compressor::Error,
                    "Input file is empty after frontmatter removal. #{mode_title} mode requires content: #{source}"
            end
            lines.concat transformed_lines(source, blocks)
          end

          lines.join("\n")
        end

        private

        def transformed_lines(source, blocks)
          transformer = @transformer.new(source)
          transformer.call(blocks)
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
                  "Unsupported explicit file: #{original}. Supported extensions: #{SUPPORTED_EXTENSIONS.join(', ')}"
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
        rescue StandardError
          false
        end

        def source_label(source)
          pathname = Pathname.new(source)
          project_root = Pathname.new(Dir.pwd)
          relative = pathname.relative_path_from(project_root).to_s
          return relative unless relative.start_with?("..")

          source
        rescue ArgumentError
          source
        end

        def mode_label
          @mode_label.to_s.strip.empty? ? "exact" : @mode_label
        end

        def mode_title
          mode_label.capitalize
        end
      end
    end
  end
end
