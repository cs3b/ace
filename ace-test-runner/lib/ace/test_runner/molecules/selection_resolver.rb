# frozen_string_literal: true

require "digest"
require_relative "../atoms/line_number_resolver"
require_relative "../models/test_selection_plan"

module Ace
  module TestRunner
    module Molecules
      module SelectionResolver
        module_function

        def resolve(files)
          parsed = Array(files).map { |selector| Atoms::LineNumberResolver.parse_file_with_line(selector) }
          qualified = parsed.count { |entry| entry[:line] }
          if qualified.positive? && qualified != parsed.size
            raise Atoms::LineNumberResolver::SelectionError,
              "Mixed whole-file and file:line selectors are unsupported: #{files.join(', ')}"
          end
          if qualified.zero?
            return Models::TestSelectionPlan.new(files: Array(files), identities: [], source_digests: {})
          end

          sources = {}
          identities = parsed.map do |entry|
            path = File.expand_path(entry.fetch(:file))
            source = sources[path] ||= File.read(path)
            Atoms::LineNumberResolver.resolve_identity(path, entry.fetch(:line), source: source)
          rescue SystemCallError => error
            raise Atoms::LineNumberResolver::SelectionError,
              "Cannot read test selector #{entry[:file]}:#{entry[:line]}: #{error.class}"
          end
          identities = identities.uniq { |entry| entry.values_at(:file, :class_name, :name) }
          Models::TestSelectionPlan.new(files: sources.keys, identities: identities,
            source_digests: sources.transform_values { |source| Digest::SHA256.hexdigest(source) })
        end
      end
    end
  end
end
