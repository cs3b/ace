# frozen_string_literal: true

require "ace/b36ts"
require "ace/support/items"

module Ace
  module Task
    module Atoms
      # Wraps ItemIdFormatter with the ".t." type marker for tasks.
      #
      # @example Generate and format a task ID
      #   TaskIdFormatter.generate
      #   # => ItemId(prefix: "8pp", type_marker: "t", suffix: "q7w", formatted_id: "8pp.t.q7w")
      #
      # @example Format an existing b36ts ID
      #   TaskIdFormatter.format("8ppq7w")
      #   # => ItemId with formatted_id "8pp.t.q7w"
      class TaskIdFormatter
        TYPE_MARKER = "t"

        # Generate a new task ID from current time
        # @param time [Time] Time to encode (default: now)
        # @return [Ace::Support::Items::Models::ItemId]
        def self.generate(time = Time.now.utc)
          raw = Ace::B36ts.encode(time, format: :"2sec")
          Ace::Support::Items::Atoms::ItemIdFormatter.split(raw, type_marker: TYPE_MARKER)
        end

        # Format an existing 6-char b36ts ID as a task ID
        # @param raw_b36ts [String] 6-character b36ts ID
        # @return [Ace::Support::Items::Models::ItemId]
        def self.format(raw_b36ts)
          Ace::Support::Items::Atoms::ItemIdFormatter.split(raw_b36ts, type_marker: TYPE_MARKER)
        end

        # Reconstruct raw b36ts from a formatted task ID
        # @param formatted_id [String] e.g., "8pp.t.q7w"
        # @return [String] Raw 6-char b36ts ID
        def self.reconstruct(formatted_id)
          Ace::Support::Items::Atoms::ItemIdFormatter.reconstruct(formatted_id)
        end

        # Build folder name from formatted ID and slug
        # @param formatted_id [String] e.g., "8pp.t.q7w"
        # @param slug [String] e.g., "fix-login"
        # @return [String] e.g., "8pp.t.q7w-fix-login"
        def self.folder_name(formatted_id, slug)
          Ace::Support::Items::Atoms::ItemIdFormatter.folder_name(formatted_id, slug)
        end

        # Build spec filename from formatted ID and slug
        # @param formatted_id [String] e.g., "8pp.t.q7w"
        # @param slug [String] e.g., "fix-login"
        # @return [String] e.g., "8pp.t.q7w-fix-login.s.md"
        def self.spec_filename(formatted_id, slug)
          base = folder_name(formatted_id, slug)
          "#{base}.s.md"
        end
      end
    end
  end
end
