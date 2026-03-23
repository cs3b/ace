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
        EXACT_CACHE_CONTRACT = "exact-list-shell-v3"
        COMPACT_CACHE_CONTRACT = "compact-list-shell-v3"
        AGENT_CACHE_CONTRACT = "agent-payload-rewrite-v7"

        def initialize(cache_root: nil, project_root: Dir.pwd)
          @cache_root = File.expand_path(cache_root || default_cache_root, project_root)
          @project_root = File.expand_path(project_root)
        end

        def manifest(mode:, sources:)
          source_entries = Array(sources).map { |source| normalize_source_entry(source) }
            .sort_by { |entry| entry.fetch("path") }
            .map do |entry|
              content = File.binread(entry.fetch("content_path"))
              {
                "path" => entry.fetch("path"),
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
          payload["mode_contract"] = mode_contract_for(mode)

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
            metadata_path: pack_path.sub(/#{Regexp.escape(PACK_EXTENSION)}\z/o, METADATA_EXTENSION),
            short_key: short_key
          }
        end

        def shared_cache_enabled?
          !shared_cache_root.to_s.strip.empty?
        end

        def shared_cache_eligible?(sources)
          return false unless shared_cache_enabled?
          return false unless shared_cache_scope == "workflow_only"

          values = Array(sources)
          values.size == 1 && workflow_source?(values.first)
        end

        def shared_manifest(mode:, sources:)
          return nil unless shared_cache_eligible?(sources)

          source = normalize_source_entry(Array(sources).first)
          content = File.binread(source.fetch("content_path"))
          payload = {
            "schema" => Ace::Compressor::Models::ContextPack::SCHEMA,
            "mode" => mode,
            "mode_contract" => mode_contract_for(mode),
            "source_kind" => "workflow",
            "sha256" => Digest::SHA256.hexdigest(content),
            "bytes" => content.bytesize,
            "lines" => line_count(content)
          }

          {"key" => Digest::SHA256.hexdigest(JSON.generate(payload))}
        end

        def shared_canonical_paths(mode:, sources:, manifest_key:)
          return nil unless shared_cache_eligible?(sources)

          source = normalize_source_entry(Array(sources).first)
          stem = shared_stem_for(source)
          short_key = manifest_key[0, SHORT_KEY_LENGTH]
          pack_path = File.join(shared_cache_root, mode, "#{stem}.#{short_key}.#{mode}#{PACK_EXTENSION}")

          {
            pack_path: pack_path,
            metadata_path: pack_path.sub(/#{Regexp.escape(PACK_EXTENSION)}\z/o, METADATA_EXTENSION),
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
            "Cache:    #{cache_hit ? "hit" : "miss"}",
            "Output:   #{output_path}",
            "Sources:  #{file_label(metadata.fetch("file_count"))}",
            "Mode:     #{mode}",
            "Original: #{format_bytes(metadata.fetch("original_bytes"))}, #{line_label(metadata.fetch("original_lines"))}",
            "Packed:   #{format_bytes(metadata.fetch("packed_bytes"))}, #{line_label(metadata.fetch("packed_lines"))}",
            "Change:   #{format_change(metadata.fetch("original_bytes"), metadata.fetch("packed_bytes"), "bytes")}, #{format_change(metadata.fetch("original_lines"), metadata.fetch("packed_lines"), "lines")}"
          ].join("\n")
        end

        private

        def default_cache_root
          Ace::Compressor.config["cache_dir"] || ".ace-local/compressor"
        end

        def shared_cache_root
          value = Ace::Compressor.config["shared_cache_dir"]
          return "" if value.to_s.strip.empty?

          File.expand_path(value.to_s)
        end

        def shared_cache_scope
          (Ace::Compressor.config["shared_cache_scope"] || "workflow_only").to_s
        end

        def mode_contract_for(mode)
          case mode.to_s
          when "exact" then EXACT_CACHE_CONTRACT
          when "compact" then COMPACT_CACHE_CONTRACT
          when "agent" then AGENT_CACHE_CONTRACT
          end
        end

        def default_stem_for(sources)
          source = normalize_source_entry(Array(sources).first)
          return "multi" unless Array(sources).size == 1 && source

          source_path = source.fetch("path")
          relative = logical_source?(source_path) ? sanitize_logical_source(source_path) : relative_to_project(source_path).to_s
          sanitized = relative.sub(/\.[^.]+\z/, "")
          sanitized.empty? ? "multi" : sanitized
        end

        def shared_stem_for(source)
          if source.fetch("source_kind") == "workflow" && source.fetch("path").start_with?("wfi://")
            workflow_path = source.fetch("path").sub(/\Awfi:\/\//, "")
            return File.join("workflow", workflow_path)
          end

          expanded = File.expand_path(source.fetch("content_path"))
          if (match = expanded.match(%r{/(ace-[^/]+)/handbook/workflow-instructions/(.+)\.wf\.md\z}))
            package = match[1]
            remainder = match[2]
            return File.join(package, "workflow-instructions", remainder)
          end

          basename = File.basename(source.fetch("path")).sub(/\.[^.]+\z/, "")
          File.join("workflow", basename.empty? ? "source" : basename)
        end

        def relative_to_project(path)
          expanded = File.expand_path(path)
          pathname = Pathname.new(expanded)
          project = Pathname.new(@project_root)
          relative = pathname.relative_path_from(project).to_s
          return File.basename(expanded) if relative.start_with?("..")

          relative
        rescue ArgumentError
          File.basename(path.to_s)
        end

        def directory_target?(raw_output, expanded_output)
          raw_output.end_with?(File::SEPARATOR) || Dir.exist?(expanded_output)
        end

        def directory_output_path(directory, short_key, mode, sources)
          label = File.basename(default_stem_for(sources))
          File.join(directory, "#{label}.#{short_key}.#{mode}#{PACK_EXTENSION}")
        end

        def normalize_source_entry(source)
          if source.is_a?(Hash)
            content_path = File.expand_path(source.fetch(:content_path) { source.fetch("content_path") })
            source_path = source.fetch(:source_path) { source.fetch("source_path") }
            source_kind = source.fetch(:source_kind) { source.fetch("source_kind", "file") }
            return {
              "content_path" => content_path,
              "path" => source_path.to_s,
              "source_kind" => source_kind.to_s
            }
          end

          expanded = File.expand_path(source.to_s)
          {
            "content_path" => expanded,
            "path" => expanded,
            "source_kind" => "file"
          }
        end

        def ensure_parent_dir(path)
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless directory == "."
        end

        def line_count(content)
          content.lines.count
        end

        def logical_source?(value)
          value.to_s.match?(%r{\A[a-z][a-z0-9+\-.]*://}i) || !Pathname.new(value.to_s).absolute?
        rescue ArgumentError
          true
        end

        def sanitize_logical_source(value)
          value.to_s.sub(%r{\A([a-z][a-z0-9+\-.]*)://}i, "\\1/")
            .gsub(/[^A-Za-z0-9._\/-]+/, "_")
            .sub(/\A\/+/, "")
        end

        def format_bytes(bytes)
          "#{format_number(bytes)} B"
        end

        def format_number(number)
          number.to_i.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
        end

        def file_label(count)
          "#{format_number(count)} #{(count == 1) ? "file" : "files"}"
        end

        def line_label(count)
          "#{format_number(count)} #{(count == 1) ? "line" : "lines"}"
        end

        def format_change(original, packed, label)
          return "0.0% #{label}" if original.to_f.zero?

          percent = ((packed.to_f - original.to_f) / original.to_f) * 100.0
          format("%+.1f%% %s", percent, label)
        end

        def workflow_source?(source)
          entry = normalize_source_entry(source)
          return true if entry.fetch("source_kind") == "workflow"

          File.expand_path(entry.fetch("content_path")).match?(%r{/handbook/workflow-instructions/.+\.wf\.md\z})
        end
      end
    end
  end
end
