# frozen_string_literal: true

module Ace
  module Nav
    module Models
      # Represents a source registration for a protocol
      class ProtocolSource
        attr_reader :name, :type, :path, :priority, :description, :origin, :config_file, :alias_name

        def initialize(name:, type:, path:, priority:, description: nil, origin: nil, config_file: nil)
          @name = name
          @type = type
          @path = path
          @priority = priority
          @description = description
          @origin = origin
          @config_file = config_file
          @alias_name = "@#{name}"
        end

        # Get the full path for this source
        def full_path
          # All sources are now directory-based
          File.expand_path(path)
        end

        def exists?
          Dir.exist?(full_path)
        end

        def to_h
          {
            name: name,
            type: type,
            path: path,
            full_path: full_path,
            priority: priority,
            description: description,
            origin: origin,
            exists: exists?
          }
        end

        def to_s
          "#{name} (#{type}): #{full_path}"
        end
      end
    end
  end
end