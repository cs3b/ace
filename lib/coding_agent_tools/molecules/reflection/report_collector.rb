# frozen_string_literal: true

require_relative '../../models/result'

module CodingAgentTools
  module Molecules
    module Reflection
      # Collects and validates reflection note files for synthesis
      class ReportCollector
        def initialize
          @valid_extensions = ['.md', '.markdown']
        end

        def collect_reports(reflection_paths)
          expanded_paths = expand_glob_patterns(reflection_paths)
          valid_reports = []
          errors = []

          expanded_paths.each do |path|
            if File.exist?(path)
              if valid_reflection_file?(path)
                valid_reports << path
              else
                errors << "Invalid reflection file: #{path}"
              end
            else
              errors << "File not found: #{path}"
            end
          end

          if errors.any?
            Models::Result.failure(errors.join(', '))
          elsif valid_reports.empty?
            Models::Result.failure('No valid reflection files found')
          else
            Models::Result.success(reports: valid_reports.sort)
          end
        end

        private

        def expand_glob_patterns(paths)
          expanded = []
          paths.each do |path|
            if path.include?('*')
              expanded.concat(Dir.glob(path))
            else
              expanded << path
            end
          end
          expanded.uniq
        end

        def valid_reflection_file?(path)
          return false unless @valid_extensions.include?(File.extname(path).downcase)
          return false unless File.readable?(path)
          return false if File.zero?(path)

          # Basic content validation - check for reflection-like structure
          content = File.read(path, encoding: 'utf-8')
          has_reflection_markers?(content)
        end

        def has_reflection_markers?(content)
          # Look for common reflection note patterns
          reflection_patterns = [
            /^#.*[Rr]eflection/,
            /^##.*What.*[Ww]ent.*[Ww]ell/,
            /^##.*What.*[Cc]ould.*[Bb]e.*[Ii]mproved/,
            /^##.*[Kk]ey.*[Ll]earnings/,
            /^##.*[Aa]ction.*[Ii]tems/,
            /\*\*[Dd]ate\*\*/,
            /\*\*[Cc]ontext\*\*/
          ]

          # File is considered a reflection if it has at least 2 reflection markers
          matches = reflection_patterns.count { |pattern| content.match?(pattern) }
          matches >= 2
        end
      end
    end
  end
end
