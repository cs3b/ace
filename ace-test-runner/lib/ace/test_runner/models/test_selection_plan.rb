# frozen_string_literal: true

module Ace
  module TestRunner
    module Models
      class TestSelectionPlan
        attr_reader :files, :identities, :source_digests

        def initialize(files:, identities:, source_digests:)
          @files = freeze_values(files)
          @identities = freeze_values(identities)
          @source_digests = freeze_values(source_digests)
          freeze
        end

        def qualified?
          !identities.empty?
        end

        def for_file(file)
          path = File.expand_path(file.sub(/:\d+$/, ""))
          self.class.new(files: [path],
            identities: identities.select { |identity| identity.fetch(:file) == path },
            source_digests: source_digests.select { |key, _| key == path })
        end

        private

        def freeze_values(value)
          case value
          when Hash
            value.to_h { |key, entry| [freeze_values(key), freeze_values(entry)] }.freeze
          when Array
            value.map { |entry| freeze_values(entry) }.freeze
          when String
            value.dup.freeze
          else
            value.freeze
          end
        end
      end
    end
  end
end
