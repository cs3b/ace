# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Atoms
        # Validates that verifier-visible artifact paths are explicitly declared by
        # runner instructions or scenario setup, and normalizes grouped capture
        # shorthand such as `foo.stdout`, `.stderr`, `.exit`.
        class ArtifactContractValidator
          Reference = Struct.new(:path, :optional, :source, :line, keyword_init: true)

          FULL_PATH_PATTERN = /
            (?:`|"|')?
            (results\/tc\/\d{2}\/[^\s`)"']+|results\/tc\/\d{2}\/)
            (?:`|"|')?
            (\s*\(optional\))?
          /ix
          SUFFIX_PATTERN = /,\s*(?:`|"|')?(\.[A-Za-z0-9*._-]+)(?:`|"|')?(\s*\(optional\))?/i
          WILDCARD_PATTERN = /[*?\[]/.freeze

          class << self
            def extract(markdown, source:)
              markdown.to_s.each_line.with_index(1).flat_map do |line, line_number|
                extract_from_line(line, source: source, line_number: line_number)
              end
            end

            def references_from_paths(paths, source:)
              Array(paths).filter_map do |path|
                normalized = normalize(path)
                next if normalized.nil?

                Reference.new(path: normalized, optional: false, source: source, line: nil)
              end
            end

            def validate!(tc_id:, scenario_dir:, runner_references:, verifier_references:, scenario_references:)
              invalid_wildcards = (runner_references + verifier_references + scenario_references).select do |reference|
                wildcard?(reference.path)
              end
              unless invalid_wildcards.empty?
                raise ArgumentError,
                  "Wildcard artifact path(s) are not supported for #{tc_id} in #{scenario_dir}: " \
                  "#{format_references(invalid_wildcards)}"
              end

              declared_paths = normalized_paths(scenario_references + runner_references)
              undeclared = verifier_references.reject do |reference|
                declared_paths.include?(normalize(reference.path))
              end
              return if undeclared.empty?

              raise ArgumentError,
                "Verifier references undeclared artifact(s) for #{tc_id} in #{scenario_dir}: " \
                "#{format_references(undeclared)}. " \
                "Declare exact artifact paths in the runner file or scenario.yml sandbox-layout."
            end

            private

            def extract_from_line(line, source:, line_number:)
              matches = []
              line.to_enum(:scan, FULL_PATH_PATTERN).each do
                matches << {
                  start: Regexp.last_match.begin(0),
                  end: Regexp.last_match.end(0),
                  path: normalize(Regexp.last_match[1]),
                  optional: !Regexp.last_match[2].to_s.empty?
                }
              end

              matches.each_with_index.flat_map do |match, index|
                refs = [
                  Reference.new(
                    path: match[:path],
                    optional: match[:optional],
                    source: source,
                    line: line_number
                  )
                ]

                next_match = matches[index + 1]
                suffix_region = line[match[:end]...(next_match ? next_match[:start] : line.length)].to_s
                suffix_base = suffix_base_for(match[:path])
                next refs if suffix_base.nil?

                suffix_region.to_enum(:scan, SUFFIX_PATTERN).each do
                  refs << Reference.new(
                    path: "#{suffix_base}#{Regexp.last_match[1]}",
                    optional: !Regexp.last_match[2].to_s.empty?,
                    source: source,
                    line: line_number
                  )
                end
                refs
              end
            end

            def suffix_base_for(path)
              return nil if path.nil?
              return nil if path.match?(%r{\Aresults/tc/\d{2}\z})

              path.sub(/\.[^.\/]+\z/, "").tap do |value|
                return nil if value == path
              end
            end

            def normalized_paths(references)
              references.map { |reference| normalize(reference.path) }.compact.uniq
            end

            def normalize(path)
              value = path.to_s.strip
              return nil unless value.start_with?("results/tc/")

              value.sub(%r{/+\z}, "")
            end

            def wildcard?(path)
              path.to_s.match?(WILDCARD_PATTERN)
            end

            def format_references(references)
              references.uniq { |reference| [reference.path, reference.source, reference.line] }.map do |reference|
                if reference.line
                  "#{reference.path} (#{reference.source}:#{reference.line})"
                else
                  "#{reference.path} (#{reference.source})"
                end
              end.join(", ")
            end
          end
        end
      end
    end
  end
end
