# frozen_string_literal: true

module Ace
  module Nav
    module Models
      # Represents a parsed resource URI
      class ResourceUri
        VALID_PROTOCOLS = %w[wfi tmpl guide sample task].freeze

        attr_reader :protocol, :source, :path, :raw

        def initialize(raw_uri)
          @raw = raw_uri
          parse_uri(raw_uri)
        end

        def valid?
          !protocol.nil? && VALID_PROTOCOLS.include?(protocol)
        end

        def source_specific?
          !source.nil?
        end

        def cascade_search?
          source.nil?
        end

        def to_s
          raw
        end

        def to_h
          {
            raw: raw,
            protocol: protocol,
            source: source,
            path: path,
            source_specific: source_specific?,
            cascade_search: cascade_search?
          }
        end

        private

        def parse_uri(raw_uri)
          return unless raw_uri.include?("://")

          parts = raw_uri.split("://", 2)
          @protocol = parts[0]

          return unless parts[1]

          # Check for @ prefix indicating source-specific lookup
          if parts[1].start_with?("@")
            # Extract source and path
            # Format: @source/path or just @source
            if parts[1].include?("/")
              source_parts = parts[1].split("/", 2)
              @source = source_parts[0] # includes @
              @path = source_parts[1]
            else
              @source = parts[1] # just @source
              @path = nil
            end
          else
            # No source specified - cascade search
            @source = nil
            @path = parts[1]
          end
        end
      end
    end
  end
end