# frozen_string_literal: true

module Ace
  module Nav
    module Models
      # Represents a resource within a handbook
      class Resource
        attr_reader :uri, :path, :source, :protocol, :resource_path

        def initialize(uri:, path:, source:, protocol:, resource_path:)
          @uri = uri
          @path = path
          @source = source
          @protocol = protocol
          @resource_path = resource_path
        end

        def content
          return nil unless File.exist?(path)
          File.read(path)
        end

        def exists?
          File.exist?(path)
        end

        def directory?
          File.directory?(path)
        end

        def to_h
          {
            uri: uri,
            path: path,
            source: source.to_h,
            protocol: protocol,
            resource_path: resource_path,
            exists: exists?
          }
        end
      end
    end
  end
end