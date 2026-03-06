# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Represents a named slice of the review subject for independent processing.
      #
      # When a large diff spans multiple packages or concern types, a PartitionBuilder
      # splits it into Partition objects. Each partition is reviewed independently,
      # producing its own synthesis output under a separate subdirectory.
      #
      # @example Creating a partition
      #   partition = Partition.new(
      #     id: "ace-review",
      #     label: "ace-review package",
      #     files: ["ace-review/lib/foo.rb", "ace-review/test/foo_test.rb"],
      #     strategy: "by_package"
      #   )
      #
      class Partition
        attr_reader :id, :label, :files, :strategy, :metadata

        # @param id [String] URL-safe identifier (used as subdirectory name)
        # @param label [String] Human-readable description shown in output
        # @param files [Array<String>] File paths belonging to this partition
        # @param strategy [String] Strategy that produced this partition ("by_package" / "by_concern")
        # @param metadata [Hash] Extra data (e.g., package name, concern type)
        def initialize(id:, label:, files:, strategy:, metadata: {})
          @id = id.to_s
          @label = label.to_s
          @files = Array(files)
          @strategy = strategy.to_s
          @metadata = metadata || {}
        end

        def to_h
          {
            "id" => id,
            "label" => label,
            "files" => files,
            "strategy" => strategy,
            "metadata" => metadata
          }
        end

        def ==(other)
          return false unless other.is_a?(Partition)

          id == other.id && label == other.label && files == other.files && strategy == other.strategy
        end
      end
    end
  end
end
