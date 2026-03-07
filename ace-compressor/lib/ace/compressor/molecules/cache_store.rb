# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"

module Ace
  module Compressor
    module Molecules
      class CacheStore
        PACK_EXTENSION = ".pack"
        METADATA_EXTENSION = ".json"
        SHORT_KEY_LENGTH = 12

        def initialize(cache_root: nil, project_root: Dir.pwd)
          @cache_root = File.expand_path(cache_root || default_cache_root, project_root)
          @project_root = File.expand_path(project_root)
        end

        def manifest(mode:, sources:)
          source_entries = Array(sources).sort.map do |source|
            content = File.binread(source)
            {
              "path" => File.expand_path(source),
              "sha256" => Digest::SHA256.hexdigest(content),
              "bytes" => content.bytesize,
              "lines" => line_count(content)
            }
          end

          payload = {
            "schema" => Ace::Compressor::Models::ContextPack::SCHEMA,
            "mode" => mode,
            "sources" => source_entries
          }

          {
            "key" => Digest::SHA256.hexdigest(JSON.generate(payload)),
            "sources" => source_entries,
            "original_bytes" => source_entries.sum { |entry| entry["bytes"] },
            "original_lines" => source_entries.sum { |entry| entry["lines"] }
          }
        end

        def canonical_paths(mode:, sources:, manifest_key:)
          relative_stem = default_stem_for(sources)
          short_key = manifest_key[0, SHORT_KEY_LENGTH]
          pack_path = File.join(@cache_root, mode, "#{relative_stem}.#{short_key}.#{mode}#{PACK_EXTENSION}")

          {
            pack_path: pack_path,
            metadata_path: pack_path.sub(/#{Regexp.escape(PACK_EXTENSION)}\z/, METADATA_EXTENSION),
            short_key: short_key
          }
        end

        def output_path_for(output:, mode:, sources:, manifest_key:)
          paths = canonical_paths(mode: mode, sources: sources, manifest_key: manifest_key)
          return paths[:pack_path] if output.nil? || output.to_s.strip.empty?

          expanded = File.expand_path(output)
          return directory_output_path(expanded, paths[:short_key], mode, sources) if directory_target?(output, expanded)

          expanded
        end

        def cache_hit?(pack_path:, metadata_path:)
          File.file?(pack_path) && File.file?(metadata_path)
        end

        def read_pack(pack_path)
          File.read(pack_path)
        end

        def read_metadata(metadata_path)
          JSON.parse(File.read(metadata_path))
        end

        def write_cache(pack_path:, metadata_path:, content:, metadata:)
          ensure_parent_dir(pack_path)
          ensure_parent_dir(metadata_path)
          File.write(pack_path, content)
          File.write(metadata_path, JSON.pretty_generate(metadata))
        end

        def write_output(output_path, content)
          ensure_parent_dir(output_path)
          File.write(output_path, content)
        end

        def stats_block(mode:, cache_hit:, output_path:, metadata:)
          [
            "Cache:    #{cache_hit ? 'hit' : 'miss'}",
            "Output:   #{output_path}",
            "Sources:  #{file_label(metadata.fetch('file_count'))}",
            "Mode:     #{mode}",
            "Original: #{format_bytes(metadata.fetch('original_bytes'))}, #{line_label(metadata.fetch('original_lines'))}",
            "Packed:   #{format_bytes(metadata.fetch('packed_bytes'))}, #{line_label(metadata.fetch('packed_lines'))}",
            "Change:   #{format_change(metadata.fetch('original_bytes'), metadata.fetch('packed_bytes'), 'bytes')}, #{format_change(metadata.fetch('original_lines'), metadata.fetch('packed_lines'), 'lines')}"
          ].join("\n")
        end

        private

        def default_cache_root
          Ace::Compressor.config["cache_dir"] || ".ace-local/compressor"
        end

        def default_stem_for(sources)
          source = Array(sources).first
          return "multi" unless Array(sources).size == 1 && source

          relative = relative_to_project(source)
          sanitized = relative.sub(/\.[^.]+\z/, "")
          sanitized.empty? ? "multi" : sanitized
        end

        def relative_to_project(path)
          pathname = Pathname.new(File.expand_path(path))
          project = Pathname.new(@project_root)
          relative = pathname.relative_path_from(project).to_s
          return relative unless relative.start_with?("..")
        rescue ArgumentError
          nil
        end || File.basename(path)

        def directory_target?(raw_output, expanded_output)
          raw_output.end_with?(File::SEPARATOR) || Dir.exist?(expanded_output)
        end

        def directory_output_path(directory, short_key, mode, sources)
          label = File.basename(default_stem_for(sources))
          File.join(directory, "#{label}.#{short_key}.#{mode}#{PACK_EXTENSION}")
        end

        def ensure_parent_dir(path)
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless directory == "."
        end

        def line_count(content)
          content.lines.count
        end

        def format_bytes(bytes)
          "#{format_number(bytes)} B"
        end

        def format_number(number)
          number.to_i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
        end

        def file_label(count)
          "#{format_number(count)} #{count == 1 ? 'file' : 'files'}"
        end

        def line_label(count)
          "#{format_number(count)} #{count == 1 ? 'line' : 'lines'}"
        end

        def format_change(original, packed, label)
          return "0.0% #{label}" if original.to_f.zero?

          percent = ((packed.to_f - original.to_f) / original.to_f) * 100.0
          format("%+.1f%% %s", percent, label)
        end
      end
    end
  end
end
