# frozen_string_literal: true

require_relative "../atoms/uri_parser"
require_relative "../models/resource"
require_relative "../models/resource_uri"
require_relative "protocol_scanner"

module Ace
  module Nav
    module Molecules
      # Resolves resource URIs to file paths
      class ResourceResolver
        def initialize(handbook_scanner: nil, uri_parser: nil, protocol_scanner: nil)
          # Support legacy handbook_scanner parameter
          @protocol_scanner = protocol_scanner || handbook_scanner || ProtocolScanner.new
          @uri_parser = uri_parser || Atoms::UriParser.new
        end

        def resolve(uri_string)
          # Parse the URI
          uri = Models::ResourceUri.new(uri_string)
          return nil unless uri.valid?

          if uri.source_specific?
            resolve_source_specific(uri)
          else
            resolve_cascade(uri)
          end
        end

        def resolve_pattern(uri_string)
          # Parse the URI
          uri = Models::ResourceUri.new(uri_string)
          return [] unless uri.valid?

          pattern = uri.path || "*"

          if uri.source_specific?
            resolve_pattern_source_specific(uri, pattern)
          else
            resolve_pattern_cascade(uri, pattern)
          end
        end

        private

        def resolve_source_specific(uri)
          # Get the specific source
          source = @protocol_scanner.scan_source_by_alias(uri.source)
          return nil unless source

          # Find the resource in that source
          resources = @protocol_scanner.find_resources_in_source(
            source,
            uri.protocol,
            uri.path || "*"
          )

          return nil if resources.empty?

          # Return the first match as a Resource
          resource_info = resources.first
          Models::Resource.new(
            uri: uri.to_s,
            path: resource_info[:path],
            source: resource_info[:source],
            protocol: uri.protocol,
            resource_path: resource_info[:relative_path]
          )
        end

        def resolve_cascade(uri)
          # Use protocol scanner to find resources directly
          resources = @protocol_scanner.find_resources(uri.protocol, uri.path || "*")

          return nil if resources.empty?

          # Return the first match (already sorted by priority)
          resource_info = resources.first
          Models::Resource.new(
            uri: uri.to_s,
            path: resource_info[:path],
            source: resource_info[:source],
            protocol: uri.protocol,
            resource_path: resource_info[:relative_path]
          )
        end

        def resolve_pattern_source_specific(uri, pattern)
          # Get the specific source
          source = @protocol_scanner.scan_source_by_alias(uri.source)
          return [] unless source

          # Find matching resources in that source
          resources = @protocol_scanner.find_resources_in_source(
            source,
            uri.protocol,
            pattern
          )

          resources.map do |resource_info|
            Models::Resource.new(
              uri: "#{uri.protocol}://#{uri.source}/#{resource_info[:relative_path]}",
              path: resource_info[:path],
              source: resource_info[:source],
              protocol: uri.protocol,
              resource_path: resource_info[:relative_path]
            )
          end
        end

        def resolve_pattern_cascade(uri, pattern)
          # Use protocol scanner to find all matching resources
          resources = @protocol_scanner.find_resources(uri.protocol, pattern)
          all_resources = []

          resources.each do |resource_info|
            all_resources << Models::Resource.new(
              uri: "#{uri.protocol}://#{resource_info[:relative_path]}",
              path: resource_info[:path],
              source: resource_info[:source],
              protocol: uri.protocol,
              resource_path: resource_info[:relative_path]
            )
          end

          all_resources
        end
      end
    end
  end
end