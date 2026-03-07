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

        def initialize(paths, verbose: false)
          @paths = Array(paths)
          @verbose = verbose
          @parser = Ace::Compressor::Atoms::MarkdownParser.new
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
          source_ids = {}

          sources.each_with_index do |source, index|
            source_id = index + 1
            source_ids[source] = source_id
            lines << Ace::Compressor::Models::ContextPack.source_line(source_id, source_label(source))
          end

          sources.each do |source|
            source_id = source_ids.fetch(source)
            text = File.read(source)
            if text.strip.empty?
              raise Ace::Compressor::Error, "Input file is empty. Exact mode requires content: #{source}"
            end
            blocks = @parser.call(text)
            if blocks.empty?
              raise Ace::Compressor::Error,
                    "Input file is empty after frontmatter removal. Exact mode requires content: #{source}"
            end

            blocks.each do |block|
              if block[:type] == :heading
                lines << Ace::Compressor::Models::ContextPack.heading_line(source_id, block[:level], block[:text])
              else
                lines << fact_line_for(source_id, block)
              end
            end
          end

          lines.join("\n")
        end

        private

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
              raise Ace::Compressor::Error, "Binary input is not supported in exact mode: #{original}"
            end

            raise Ace::Compressor::Error,
                  "Unsupported explicit file: #{original}. Supported extensions: #{SUPPORTED_EXTENSIONS.join(', ')}"
          end

          return unless binary_file?(expanded)

          raise Ace::Compressor::Error, "Binary input is not supported in exact mode: #{original}"
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

        def normalize_fact_text(block)
          case block[:type]
          when :unresolved
            [:unresolved, normalize_kind_payload(block[:text])]
          when :fallback
            [:fallback, normalize_kind_payload(block[:text])]
          when :table
            [:table, block[:text]]
          else
            [:text, block[:text]]
          end
        end

        def fact_line_for(source_id, block)
          type, payload = normalize_fact_text(block)

          case type
          when :unresolved
            kind, raw = payload
            Ace::Compressor::Models::ContextPack.unresolved_line(source_id, kind, raw)
          when :fallback
            kind, raw = payload
            Ace::Compressor::Models::ContextPack.fallback_line(source_id, kind, raw)
          when :table
            Ace::Compressor::Models::ContextPack.table_line(source_id, payload)
          else
            Ace::Compressor::Models::ContextPack.fact_line(source_id, payload)
          end
        end

        def normalize_kind_payload(text)
          parts = text.to_s.split("|raw=", 2)
          kind = parts.first.sub(/\Akind=/, "")
          raw = parts[1].to_s
          [kind, raw]
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
      end
    end
  end
end
