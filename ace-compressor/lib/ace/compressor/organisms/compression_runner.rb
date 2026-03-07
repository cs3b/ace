# frozen_string_literal: true

module Ace
  module Compressor
    module Organisms
      class CompressionRunner
        SUPPORTED_FORMATS = %w[path stdio stats].freeze

        def initialize(paths, mode:, output: nil, format: nil, verbose: false)
          @paths = Array(paths)
          @mode = mode
          @output = output
          @format = (format || Ace::Compressor.config["default_format"] || "path").to_s
          @verbose = verbose
          @cache_store = Ace::Compressor::Molecules::CacheStore.new
        end

        def call
          raise Ace::Compressor::Error, "Unsupported format '#{@format}'. Use --format path, stdio, or stats" unless SUPPORTED_FORMATS.include?(@format)

          compressor = ExactCompressor.new(@paths, verbose: @verbose)
          sources = compressor.resolve_sources
          manifest = @cache_store.manifest(mode: @mode, sources: sources)
          canonical = @cache_store.canonical_paths(mode: @mode, sources: sources, manifest_key: manifest["key"])

          cache_hit = @cache_store.cache_hit?(pack_path: canonical[:pack_path], metadata_path: canonical[:metadata_path])
          content, metadata = if cache_hit
                                content = @cache_store.read_pack(canonical[:pack_path])
                                metadata = hydrate_metadata(
                                  @cache_store.read_metadata(canonical[:metadata_path]),
                                  manifest,
                                  canonical,
                                  content
                                )
                                [content, metadata]
                              else
                                build_cache_entry(compressor, sources, manifest, canonical)
                              end

          output_path = @cache_store.output_path_for(
            output: @output,
            mode: @mode,
            sources: sources,
            manifest_key: manifest["key"]
          )

          @cache_store.write_output(output_path, content) unless output_path == canonical[:pack_path]

          {
            console_output: format_console_output(
              content: content,
              cache_hit: cache_hit,
              output_path: output_path,
              metadata: metadata
            ),
            ignored_paths: compressor.ignored_paths,
            output_path: output_path
          }
        end

        private

        def build_cache_entry(compressor, sources, manifest, canonical)
          content = compressor.compress_sources(sources)
          metadata = cache_metadata(manifest, canonical[:short_key], content)
          @cache_store.write_cache(
            pack_path: canonical[:pack_path],
            metadata_path: canonical[:metadata_path],
            content: content,
            metadata: metadata
          )
          [content, metadata]
        end

        def format_console_output(content:, cache_hit:, output_path:, metadata:)
          case @format
          when "stdio"
            content
          when "stats"
            @cache_store.stats_block(mode: @mode, cache_hit: cache_hit, output_path: output_path, metadata: metadata)
          else
            output_path
          end
        end

        def cache_metadata(manifest, short_key, content, existing_metadata = nil)
          base = existing_metadata || {}
          base.merge(
            "schema" => Ace::Compressor::Models::ContextPack::SCHEMA,
            "mode" => @mode,
            "key" => manifest["key"],
            "short_key" => short_key,
            "sources" => manifest["sources"],
            "file_count" => manifest["sources"].size,
            "original_bytes" => manifest["original_bytes"],
            "original_lines" => manifest["original_lines"],
            "packed_bytes" => content.bytesize,
            "packed_lines" => content.lines.count
          )
        end

        def hydrate_metadata(existing_metadata, manifest, canonical, content)
          metadata = cache_metadata(manifest, canonical[:short_key], content, existing_metadata)
          return metadata if metadata == existing_metadata

          @cache_store.write_cache(
            pack_path: canonical[:pack_path],
            metadata_path: canonical[:metadata_path],
            content: content,
            metadata: metadata
          )
          metadata
        end
      end
    end
  end
end
