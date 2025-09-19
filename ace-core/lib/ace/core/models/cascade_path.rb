# frozen_string_literal: true

module Ace
  module Core
    module Models
      # Represents a configuration cascade path
      class CascadePath
        attr_reader :path, :priority, :exists, :type

        # Initialize cascade path
        # @param path [String] File system path
        # @param priority [Integer] Priority (lower = higher priority)
        # @param exists [Boolean] Whether path exists
        # @param type [Symbol] Type of path (:local, :home, :gem)
        def initialize(path:, priority: 100, exists: false, type: :local)
          @path = path.to_s.freeze
          @priority = priority
          @exists = exists
          @type = type
          freeze
        end

        # Compare paths by priority
        # @param other [CascadePath] Other path to compare
        # @return [Integer] Comparison result
        def <=>(other)
          return nil unless other.is_a?(CascadePath)
          priority <=> other.priority
        end

        # Check if this path should override another
        # @param other [CascadePath] Other path
        # @return [Boolean] true if this path has higher priority
        def overrides?(other)
          return false unless other.is_a?(CascadePath)
          priority < other.priority
        end

        # Convert to string
        # @return [String] The file path
        def to_s
          path
        end

        # Get path as Pathname
        # @return [Pathname] Path object
        def pathname
          require "pathname"
          Pathname.new(path)
        end

        # Check if path is absolute
        # @return [Boolean] true if absolute path
        def absolute?
          pathname.absolute?
        end

        # Check if path is relative
        # @return [Boolean] true if relative path
        def relative?
          !absolute?
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.path == path &&
            other.priority == priority &&
            other.type == type
        end

        def inspect
          attrs = [
            "path=#{path.inspect}",
            "type=#{type}",
            "priority=#{priority}",
            exists ? "exists" : "missing"
          ].join(" ")

          "#<#{self.class.name} #{attrs}>"
        end
      end
    end
  end
end