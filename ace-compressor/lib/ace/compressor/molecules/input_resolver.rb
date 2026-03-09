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
            return resolve_with_bundle(raw_input, index) if config_extension?(raw_input)

            return raw_input
          end
          return raw_input if File.directory?(expanded)
          return resolve_with_bundle(raw_input, index) if protocol_input?(raw_input)
          raise Ace::Compressor::Error, "Input source not found: #{raw_input}" if looks_like_path?(raw_input)

          resolve_with_bundle(raw_input, index)
        end

        def resolve_with_bundle(raw_input, index)
          output_path = File.join(@temp_root, "resolved_#{index + 1}.md")
          stdout, stderr, status = @shell_runner.call(["ace-bundle", raw_input, "--output", output_path])
          return output_path if status.success?

          details = stderr.to_s.strip
          details = stdout.to_s.strip if details.empty?
          raise Ace::Compressor::Error, "Failed to resolve input '#{raw_input}': #{details}"
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

        def default_shell_runner(command)
          Open3.capture3(*command)
        end
      end
    end
  end
end
