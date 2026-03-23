# frozen_string_literal: true

require_relative "../molecules/config_loader"

module Ace
  module Support
    module Nav
      module Atoms
        # Parses resource URIs
        class UriParser
          def initialize(config_loader: nil)
            @config_loader = config_loader || Molecules::ConfigLoader.new
          end

          def parse(uri_string)
            return nil unless uri_string.is_a?(String)
            return nil unless uri_string.include?("://")

            parts = uri_string.split("://", 2)
            protocol = parts[0]
            rest = parts[1]

            return nil unless valid_protocol?(protocol)
            return {protocol: protocol, source: nil, path: nil} if rest.nil? || rest.empty?

            # Check for source-specific syntax (@source/path or @source)
            if rest.start_with?("@")
              parse_source_specific(protocol, rest)
            else
              {protocol: protocol, source: nil, path: rest}
            end
          end

          def valid_protocol?(protocol)
            @config_loader.valid_protocol?(protocol)
          end

          def valid_protocols
            @config_loader.valid_protocols
          end

          def extract_protocol(uri_string)
            return nil unless uri_string.include?("://")
            uri_string.split("://", 2)[0]
          end

          private

          def parse_source_specific(protocol, rest)
            # Format: @source/path or just @source
            if rest.include?("/")
              source_parts = rest.split("/", 2)
              {protocol: protocol, source: source_parts[0], path: source_parts[1]}
            else
              {protocol: protocol, source: rest, path: nil}
            end
          end
        end
      end
    end
  end
end
