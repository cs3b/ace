# frozen_string_literal: true

module Ace
  module Compressor
    module Organisms
      class CompressionRunner
        SUPPORTED_FORMATS = %w[path stdio stats].freeze
        SUPPORTED_MODES = %w[exact compact agent].freeze
        SUPPORTED_SOURCE_SCOPES = %w[merged per-source].freeze

        def initialize(paths, mode:, source_scope: "merged", output: nil, format: nil, verbose: false)
          @paths = Array(paths)
          @mode = mode
          @source_scope = source_scope.to_s
          @output = output
          @format = (format || Ace::Compressor.config["default_format"] || "path").to_s
          @verbose = verbose
          @cache_store = Ace::Compressor::Molecules::CacheStore.new
        end

        def call
          raise Ace::Compressor::Error, "Unsupported format '#{@format}'. Use --format path, stdio, or stats" unless SUPPORTED_FORMATS.include?(@format)
          raise Ace::Compressor::Error,
                "Unsupported mode '#{@mode}'. Use --mode exact, --mode compact, or --mode agent" unless SUPPORTED_MODES.include?(@mode)
          unless SUPPORTED_SOURCE_SCOPES.include?(@source_scope)
            raise Ace::Compressor::Error,
                  "Unsupported source scope '#{@source_scope}'. Use --source-scope merged or --source-scope per-source"
          end

          resolver = Ace::Compressor::Molecules::InputResolver.new(@paths)
          begin
            resolved_inputs = resolver.call
            return run_per_source(resolved_inputs) if @source_scope == "per-source"

            run_for_sources(resolved_inputs)
          ensure
            resolver.cleanup if resolver.respond_to?(:cleanup)
          end
        end

        private

        def run_for_sources(resolved_inputs)
          resolved_paths = Array(resolved_inputs).map { |entry| entry.fetch(:content_path) }
          compressor = compressor_for_mode(resolved_paths)
          sources = compressor.resolve_sources
          source_metadata = build_source_metadata(sources, resolved_inputs)
          manifest = @cache_store.manifest(mode: @mode, sources: source_metadata)
          canonical = @cache_store.canonical_paths(mode: @mode, sources: source_metadata, manifest_key: manifest["key"])
          shared_manifest = @cache_store.shared_manifest(mode: @mode, sources: source_metadata)
          shared_canonical = if shared_manifest
                               @cache_store.shared_canonical_paths(mode: @mode, sources: source_metadata, manifest_key: shared_manifest["key"])
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
                                build_cache_entry(compressor, sources, source_metadata, manifest, canonical, shared_canonical)
                              end
          cache_hit ||= shared_cache_hit?(shared_canonical)

          output_path = @cache_store.output_path_for(
            output: @output,
            mode: @mode,
            sources: source_metadata,
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

        def run_per_source(resolved_inputs)
          if resolved_inputs.size > 1 && output_file_target?
            raise Ace::Compressor::Error,
                  "Per-source mode with multiple inputs requires --output to be a directory path"
          end

          results = resolved_inputs.map { |entry| run_for_sources([entry]) }
          {
            console_output: join_console_outputs(results.map { |result| result[:console_output] }),
            ignored_paths: results.flat_map { |result| result[:ignored_paths] }.uniq,
            output_path: results.first&.dig(:output_path),
            output_paths: results.map { |result| result[:output_path] },
            cache_hit: results.all? { |result| result[:cache_hit] },
            metadata: results.map { |result| result[:metadata] },
            refusal_lines: results.flat_map { |result| result[:refusal_lines] },
            fallback_lines: results.flat_map { |result| result[:fallback_lines] },
            exit_code: results.any? { |result| result[:exit_code].to_i.nonzero? } ? 1 : 0
          }
        end

        def join_console_outputs(outputs)
          values = Array(outputs).map(&:to_s).reject(&:empty?)
          return "" if values.empty?

          separator = @format == "stats" ? "\n\n" : "\n"
          values.join(separator)
        end

        def output_file_target?
          return false if @output.nil? || @output.to_s.strip.empty?
          return false if @output.end_with?(File::SEPARATOR)

          !Dir.exist?(File.expand_path(@output))
        end

        def build_cache_entry(compressor, sources, source_metadata, manifest, canonical, shared_canonical = nil)
          content = compress_content(compressor, sources, source_metadata)
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

        def compress_content(compressor, sources, source_metadata)
          source_paths = source_metadata.each_with_object({}) do |entry, hash|
            hash[entry.fetch(:content_path)] = entry.fetch(:source_path)
          end

          parameters = compressor.method(:compress_sources).parameters
          supports_source_paths = parameters.any? do |type, name|
            [:key, :keyreq].include?(type) && name == :source_paths || type == :keyrest
          end

          return compressor.compress_sources(sources, source_paths: source_paths) if supports_source_paths

          compressor.compress_sources(sources)
        end

        def build_source_metadata(sources, resolved_inputs)
          identities = Array(resolved_inputs).each_with_object({}) do |entry, hash|
            hash[File.expand_path(entry.fetch(:content_path))] = entry
          end

          Array(sources).map do |source|
            expanded = File.expand_path(source)
            resolved = identities[expanded]
            if resolved
              {
                content_path: expanded,
                source_path: resolved.fetch(:source_path),
                source_kind: resolved.fetch(:source_kind)
              }
            else
              {
                content_path: expanded,
                source_path: expanded,
                source_kind: "file"
              }
            end
          end
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

        def compressor_for_mode(paths)
          return CompactCompressor.new(paths, verbose: @verbose) if @mode == "compact"
          return AgentCompressor.new(paths, verbose: @verbose) if @mode == "agent"

          ExactCompressor.new(paths, verbose: @verbose, mode_label: @mode)
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
