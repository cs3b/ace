# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for validating VCR cassettes size
      # Extracted from dev-tools/bin/lint-cassettes
      class CassettesValidator
        DEFAULT_THRESHOLD = 50 * 1024 # 50KB in bytes
        CASSETTES_DIR = 'spec/cassettes'

        attr_reader :threshold, :cassettes_dir

        def initialize(options = {})
          @threshold = options[:threshold] || DEFAULT_THRESHOLD
          @cassettes_dir = Pathname.new(options[:cassettes_dir] || CASSETTES_DIR)
        end

        def validate
          unless cassettes_dir_exists?
            return {
              success: true,
              findings: [],
              message: "No cassettes directory found at #{cassettes_dir}"
            }
          end

          large_cassettes = find_large_cassettes

          {
            success: true, # Always succeeds, only warns
            findings: large_cassettes,
            warnings: large_cassettes.map { |c| format_warning(c) }
          }
        end

        private

        def cassettes_dir_exists?
          cassettes_dir.exist? && cassettes_dir.directory?
        end

        def find_large_cassettes
          cassette_files = Dir.glob(cassettes_dir.join('**', '*.{json,yml}'))

          large_files = []

          cassette_files.each do |file_path|
            file_size = File.size(file_path)

            next unless file_size > threshold

            relative_path = begin
              Pathname.new(file_path).relative_path_from(Pathname.pwd)
            rescue ArgumentError
              file_path
            end

            large_files << {
              path: relative_path.to_s,
              size: file_size,
              size_formatted: format_size(file_size)
            }
          end

          # Sort by size, largest first
          large_files.sort_by { |file| -file[:size] }
        end

        def format_size(bytes)
          case bytes
          when 0..1023
            "#{bytes}B"
          when 1024..1_048_575
            "#{(bytes / 1024.0).round(1)}KB"
          else
            "#{(bytes / 1_048_576.0).round(1)}MB"
          end
        end

        def format_warning(cassette)
          "#{cassette[:path]} is #{cassette[:size_formatted]} (threshold: #{format_size(threshold)})"
        end
      end
    end
  end
end
