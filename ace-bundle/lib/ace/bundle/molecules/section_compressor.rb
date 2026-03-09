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

          compressible, passthrough = files.partition { |f| compressible?(f[:path]) }
          return if compressible.empty?

          case mode
          when "per-source"
            compress_per_source(compressible)
            section_data[:_processed_files] = compressible + passthrough
          when "merged"
            merged = compress_merged(compressible)
            section_data[:_processed_files] = [merged] + passthrough
          end
        end

        def compress_per_source(files)
          Dir.mktmpdir("ace-bundle-compress") do |tmpdir|
            uncached = []
            files.each do |file_info|
              fragment = write_fragment(tmpdir, file_info[:path], file_info[:content])
              labels = { fragment => file_info[:path] }
              manifest = @cache_store.manifest(mode: @compressor_mode, sources: [fragment], labels: labels)
              canonical = @cache_store.canonical_paths(mode: @compressor_mode, sources: [fragment], manifest_key: manifest["key"])

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
              output = compressor.compress_sources([entry[:fragment]])
              compressed = strip_context_pack_header(fix_source_labels(output, { entry[:fragment] => fi[:path] }))
              write_cache_entry(entry[:manifest], entry[:canonical], compressed)
              fi[:content] = compressed
              fi[:compressed] = true
            end
          end
        end

        def compress_merged(files)
          Dir.mktmpdir("ace-bundle-compress") do |tmpdir|
            path_map = {}
            labels = {}
            fragments = files.map do |f|
              fragment = write_fragment(tmpdir, f[:path], f[:content])
              path_map[fragment] = f[:path]
              labels[fragment] = f[:path]
              fragment
            end

            manifest = @cache_store.manifest(mode: @compressor_mode, sources: fragments, labels: labels)
            canonical = @cache_store.canonical_paths(mode: @compressor_mode, sources: fragments, manifest_key: manifest["key"])

            content = if @cache_store.cache_hit?(pack_path: canonical[:pack_path], metadata_path: canonical[:metadata_path])
                        @cache_store.read_pack(canonical[:pack_path])
                      else
                        compressor = build_compressor(fragments)
                        output = compressor.compress_sources(fragments)
                        compressed = strip_context_pack_header(fix_source_labels(output, path_map))
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

        def fix_source_labels(output, path_map)
          result = output
          path_map.each do |absolute_path, original_label|
            result = result.gsub("FILE|#{absolute_path}", "FILE|#{original_label}")
          end
          result
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
      end
    end
  end
end
