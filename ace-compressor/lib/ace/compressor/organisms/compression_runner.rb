# frozen_string_literal: true

module Ace
  module Compressor
    module Organisms
      class CompressionRunner
        SUPPORTED_FORMATS = %w[path stdio stats].freeze
        SUPPORTED_MODES = %w[exact compact agent].freeze

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
          raise Ace::Compressor::Error,
                "Unsupported mode '#{@mode}'. Use --mode exact, --mode compact, or --mode agent" unless SUPPORTED_MODES.include?(@mode)

          compressor = compressor_for_mode
          sources = compressor.resolve_sources
          manifest = @cache_store.manifest(mode: @mode, sources: sources)
          canonical = @cache_store.canonical_paths(mode: @mode, sources: sources, manifest_key: manifest["key"])
          shared_manifest = @cache_store.shared_manifest(mode: @mode, sources: sources)
          shared_canonical = if shared_manifest
                               @cache_store.shared_canonical_paths(mode: @mode, sources: sources, manifest_key: shared_manifest["key"])
                             end

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
                              elsif shared_cache_hit?(shared_canonical)
                                hydrate_from_shared_cache(manifest, canonical, shared_canonical)
                              else
                                build_cache_entry(compressor, sources, manifest, canonical, shared_canonical)
                              end
          cache_hit ||= shared_cache_hit?(shared_canonical)

          output_path = @cache_store.output_path_for(
            output: @output,
            mode: @mode,
            sources: sources,
            manifest_key: manifest["key"]
          )

          @cache_store.write_output(output_path, content) unless output_path == canonical[:pack_path]
          refusal_lines = refusal_lines(content)
          fallback_lines = fallback_lines(content)

          {
            console_output: format_console_output(
              content: content,
              cache_hit: cache_hit,
              output_path: output_path,
              metadata: metadata
            ),
            ignored_paths: compressor.ignored_paths,
            output_path: output_path,
            cache_hit: cache_hit,
            metadata: metadata,
            refusal_lines: refusal_lines,
            fallback_lines: fallback_lines,
            exit_code: refusal_lines.empty? ? 0 : 1
          }
        end

        private

        def build_cache_entry(compressor, sources, manifest, canonical, shared_canonical = nil)
          content = compressor.compress_sources(sources)
          metadata = cache_metadata(manifest, canonical[:short_key], content)
          @cache_store.write_cache(
            pack_path: canonical[:pack_path],
            metadata_path: canonical[:metadata_path],
            content: content,
            metadata: metadata
          )
          if shared_canonical
            shared_metadata = cache_metadata(manifest, shared_canonical[:short_key], content, metadata.merge("cache_scope" => "shared"))
            @cache_store.write_cache(
              pack_path: shared_canonical[:pack_path],
              metadata_path: shared_canonical[:metadata_path],
              content: content,
              metadata: shared_metadata
            )
          end
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

        def compressor_for_mode
          return CompactCompressor.new(@paths, verbose: @verbose) if @mode == "compact"
          return AgentCompressor.new(@paths, verbose: @verbose) if @mode == "agent"

          ExactCompressor.new(@paths, verbose: @verbose, mode_label: @mode)
        end

        def refusal_lines(content)
          content.to_s.lines.map(&:strip).select { |line| line.start_with?("REFUSAL|") }
        end

        def fallback_lines(content)
          content.to_s.lines.map(&:strip).select { |line| line.start_with?("FALLBACK|") }
        end

        def shared_cache_hit?(shared_canonical)
          return false unless shared_canonical

          @cache_store.cache_hit?(pack_path: shared_canonical[:pack_path], metadata_path: shared_canonical[:metadata_path])
        end

        def hydrate_from_shared_cache(manifest, canonical, shared_canonical)
          content = @cache_store.read_pack(shared_canonical[:pack_path])
          shared_metadata = @cache_store.read_metadata(shared_canonical[:metadata_path])
          metadata = cache_metadata(manifest, canonical[:short_key], content, shared_metadata.merge("cache_scope" => "shared"))
          @cache_store.write_cache(
            pack_path: canonical[:pack_path],
            metadata_path: canonical[:metadata_path],
            content: content,
            metadata: metadata
          )
          [content, metadata]
        end
      end
    end
  end
end
