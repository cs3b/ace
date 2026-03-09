# frozen_string_literal: true

require 'ace/compressor'
require 'fileutils'
require 'tmpdir'

module Ace
  module Bundle
    module Molecules
      # Compresses file content within bundle sections using ace-compressor.
      # Each section is compressed independently. Files that are not
      # compressible (non-markdown/text) pass through unchanged.
      #
      # Uses the compressor's file-based API (compress_sources) so that both
      # "exact" and "agent" engines work through the same code path.
      class SectionCompressor
        COMPRESSIBLE_EXTENSIONS = %w[.md .markdown .mdown .mkd .txt .text].freeze

        # @param default_mode [String] default source scope: "off", "per-source", "merged"
        # @param compressor_mode [String] compressor engine: "exact", "agent"
        # @param cache_store [Ace::Compressor::Molecules::CacheStore, nil] injectable cache store
        def initialize(default_mode: "off", compressor_mode: "exact", cache_store: nil)
          @default_mode = default_mode.to_s
          @compressor_mode = compressor_mode.to_s
          @cache_store = cache_store || Ace::Compressor::Molecules::CacheStore.new
          validate_compressor_mode!
        end

        # Compress files in all sections of a bundle.
        # @param bundle_data [Models::BundleData] bundle with sections
        # @return [Models::BundleData] same bundle with compressed file content
        def call(bundle_data)
          unless bundle_data.has_sections?
            compress_content(bundle_data) if @default_mode != "off"
            return bundle_data
          end

          bundle_data.sections.each do |name, section_data|
            section_mode = resolve_mode(section_data)
            next if section_mode == "off"

            compress_section_files(section_data, section_mode)
          end

          bundle_data
        end

        private

        def validate_compressor_mode!
          return if %w[exact agent].include?(@compressor_mode)

          raise ArgumentError, "Unknown compressor_mode: #{@compressor_mode.inspect}. Supported: exact, agent"
        end

        def resolve_mode(section_data)
          # Section-level params override: check compressor_source_scope first, fall back to compress
          section_scope = section_data.dig(:params, :compressor_source_scope) ||
                          section_data.dig(:params, "compressor_source_scope") ||
                          section_data.dig("params", "compressor_source_scope") ||
                          section_data.dig(:params, :compress) ||
                          section_data.dig(:params, "compress") ||
                          section_data.dig("params", "compress")
          mode = (section_scope || @default_mode).to_s
          return "off" unless %w[off per-source merged].include?(mode)

          mode
        end

        def build_compressor(paths)
          case @compressor_mode
          when "exact"
            Ace::Compressor::Organisms::ExactCompressor.new(paths, mode_label: "exact")
          when "agent"
            Ace::Compressor::Organisms::AgentCompressor.new(paths)
          else
            raise ArgumentError, "Unknown compressor_mode: #{@compressor_mode.inspect}. Supported: exact, agent"
          end
        end

        def compress_section_files(section_data, mode)
          files = section_data[:_processed_files]
          return if files.nil? || files.empty?

          compressible = files.select { |f| compressible?(f[:path]) }
          return if compressible.empty?

          case mode
          when "per-source"
            compress_per_source(compressible)
          when "merged"
            merged = compress_merged(compressible)
            merged_inserted = false
            section_data[:_processed_files] = files.each_with_object([]) do |file_info, ordered_files|
              if compressible?(file_info[:path])
                next if merged_inserted

                ordered_files << merged
                merged_inserted = true
              else
                ordered_files << file_info
              end
            end
          end
        end

        def compress_per_source(files)
          Dir.mktmpdir("ace-bundle-compress") do |tmpdir|
            uncached = []
            files.each do |file_info|
              fragment = write_fragment(tmpdir, file_info[:path], file_info[:content])
              source_entry = cache_source_entry(fragment, file_info[:path], source_kind: "file")
              manifest = @cache_store.manifest(mode: @compressor_mode, sources: [source_entry])
              canonical = @cache_store.canonical_paths(mode: @compressor_mode, sources: [source_entry], manifest_key: manifest["key"])

              if @cache_store.cache_hit?(pack_path: canonical[:pack_path], metadata_path: canonical[:metadata_path])
                file_info[:content] = @cache_store.read_pack(canonical[:pack_path])
                file_info[:compressed] = true
              else
                uncached << { file_info: file_info, fragment: fragment, manifest: manifest, canonical: canonical }
              end
            end

            uncached.each do |entry|
              fi = entry[:file_info]
              compressor = build_compressor([entry[:fragment]])
              output = compress_with_source_identity(compressor, entry[:fragment] => fi[:path])
              compressed = strip_context_pack_header(output)
              write_cache_entry(entry[:manifest], entry[:canonical], compressed)
              fi[:content] = compressed
              fi[:compressed] = true
            end
          end
        end

        def compress_merged(files)
          Dir.mktmpdir("ace-bundle-compress") do |tmpdir|
            path_map = {}
            source_entries = files.map do |f|
              fragment = write_fragment(tmpdir, f[:path], f[:content])
              path_map[fragment] = f[:path]
              cache_source_entry(fragment, f[:path], source_kind: "file")
            end

            manifest = @cache_store.manifest(mode: @compressor_mode, sources: source_entries)
            canonical = @cache_store.canonical_paths(mode: @compressor_mode, sources: source_entries, manifest_key: manifest["key"])

            content = if @cache_store.cache_hit?(pack_path: canonical[:pack_path], metadata_path: canonical[:metadata_path])
                        @cache_store.read_pack(canonical[:pack_path])
                      else
                        fragments = source_entries.map { |entry| entry[:content_path] }
                        compressor = build_compressor(fragments)
                        output = compress_with_source_identity(compressor, path_map)
                        compressed = strip_context_pack_header(output)
                        write_cache_entry(manifest, canonical, compressed)
                        compressed
                      end

            {
              path: files.first[:path],
              content: content,
              compressed: true,
              merged_sources: files.map { |f| f[:path] }
            }
          end
        end

        def write_fragment(tmpdir, path, content)
          fragment = File.join(tmpdir, path)
          FileUtils.mkdir_p(File.dirname(fragment))
          File.write(fragment, content)
          fragment
        end

        def strip_context_pack_header(output)
          lines = output.lines
          lines.shift if lines.first&.start_with?("H|ContextPack/")
          lines.join.strip
        end

        def write_cache_entry(manifest, canonical, compressed)
          metadata = {
            "schema" => Ace::Compressor::Models::ContextPack::SCHEMA,
            "mode" => @compressor_mode,
            "key" => manifest["key"],
            "short_key" => canonical[:short_key],
            "sources" => manifest["sources"],
            "file_count" => manifest["sources"].size,
            "original_bytes" => manifest["original_bytes"],
            "original_lines" => manifest["original_lines"],
            "packed_bytes" => compressed.bytesize,
            "packed_lines" => compressed.lines.count
          }
          @cache_store.write_cache(
            pack_path: canonical[:pack_path],
            metadata_path: canonical[:metadata_path],
            content: compressed,
            metadata: metadata
          )
        end

        def compressible?(path)
          ext = File.extname(path.to_s).downcase
          COMPRESSIBLE_EXTENSIONS.include?(ext)
        end

        # Compress content-only bundles (no sections) using the real file path.
        # Uses the source metadata path directly — no temp files needed.
        def compress_content(bundle_data)
          source = bundle_data.metadata[:source]&.to_s
          return if source.nil? || source.empty? || !File.exist?(source) || !compressible?(source)

          manifest = @cache_store.manifest(mode: @compressor_mode, sources: [source])
          canonical = @cache_store.canonical_paths(mode: @compressor_mode, sources: [source], manifest_key: manifest["key"])

          if @cache_store.cache_hit?(pack_path: canonical[:pack_path], metadata_path: canonical[:metadata_path])
            bundle_data.content = @cache_store.read_pack(canonical[:pack_path])
          else
            compressor = build_compressor([source])
            output = compressor.compress_sources([source])
            compressed = strip_context_pack_header(output)
            write_cache_entry(manifest, canonical, compressed)
            bundle_data.content = compressed
          end
          bundle_data.metadata[:compressed] = true
        end

        def compress_with_source_identity(compressor, path_map)
          parameters = compressor.method(:compress_sources).parameters
          supports_source_paths = parameters.any? do |type, name|
            ([:key, :keyreq].include?(type) && name == :source_paths) || type == :keyrest
          end
          fragments = path_map.keys
          return compressor.compress_sources(fragments, source_paths: path_map) if supports_source_paths

          compressor.compress_sources(fragments)
        end

        def cache_source_entry(content_path, source_path, source_kind:)
          {
            content_path: content_path,
            source_path: source_path,
            source_kind: source_kind
          }
        end
      end
    end
  end
end
