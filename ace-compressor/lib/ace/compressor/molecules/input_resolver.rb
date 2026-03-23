# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

module Ace
  module Compressor
    module Molecules
      class InputResolver
        CONFIG_EXTENSIONS = %w[.yml .yaml].freeze

        def initialize(inputs, shell_runner: nil, temp_root: nil)
          @inputs = Array(inputs)
          @shell_runner = shell_runner || method(:default_shell_runner)
          @temp_root = temp_root || Dir.mktmpdir("ace_compressor_inputs")
          @owns_temp_root = temp_root.nil?
        end

        def call
          @inputs.map.with_index do |raw_input, index|
            resolve_one(raw_input.to_s, index)
          end
        end

        def cleanup
          FileUtils.rm_rf(@temp_root) if @owns_temp_root && @temp_root && Dir.exist?(@temp_root)
        end

        private

        def resolve_one(raw_input, index)
          expanded = File.expand_path(raw_input)
          if File.file?(expanded)
            return resolve_with_bundle(raw_input, index, source_path: expanded, source_kind: "bundle_config") if config_extension?(raw_input)

            return resolved_input(content_path: expanded, source_path: expanded, source_kind: "file")
          end
          return resolved_input(content_path: expanded, source_path: expanded, source_kind: "directory") if File.directory?(expanded)
          return resolve_with_bundle(raw_input, index, source_path: raw_input, source_kind: protocol_source_kind(raw_input)) if protocol_input?(raw_input)
          raise Ace::Compressor::Error, "Input source not found: #{raw_input}" if looks_like_path?(raw_input)

          resolve_with_bundle(raw_input, index, source_path: raw_input, source_kind: "preset")
        end

        def resolve_with_bundle(raw_input, index, source_path:, source_kind:)
          output_path = File.join(@temp_root, "resolved_#{index + 1}.md")
          stdout, stderr, status = @shell_runner.call(["ace-bundle", raw_input, "--output", output_path])
          if status.success?
            result = resolved_input(content_path: output_path, source_path: source_path, source_kind: source_kind)
            meta_path = "#{output_path}.meta.json"
            if File.exist?(meta_path)
              require "json"
              result[:bundle_compression_stats] = JSON.parse(File.read(meta_path))
            end
            return result
          end

          details = stderr.to_s.strip
          details = stdout.to_s.strip if details.empty?
          raise Ace::Compressor::Error, "Failed to resolve input '#{raw_input}': #{details}"
        end

        def resolved_input(content_path:, source_path:, source_kind:)
          {
            content_path: content_path,
            source_path: source_path,
            source_kind: source_kind
          }
        end

        def looks_like_path?(value)
          return false if protocol_input?(value)

          value.start_with?(".", "/", "~") || value.include?(File::SEPARATOR) || config_extension?(value)
        end

        def config_extension?(value)
          CONFIG_EXTENSIONS.include?(File.extname(value).downcase)
        end

        def protocol_input?(value)
          value.match?(%r{\A[a-z][a-z0-9+\-.]*://}i)
        end

        def protocol_source_kind(value)
          return "workflow" if value.to_s.start_with?("wfi://")

          "protocol"
        end

        def default_shell_runner(command)
          Open3.capture3(*command)
        end
      end
    end
  end
end
