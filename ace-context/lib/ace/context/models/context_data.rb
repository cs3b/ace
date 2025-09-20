# frozen_string_literal: true

module Ace
  module Context
    module Models
      # Data model for context information
      class ContextData
        attr_accessor :preset_name, :files, :metadata, :content

        def initialize(preset_name: nil, files: nil, metadata: nil, content: "")
          @preset_name = preset_name
          @files = files || []
          @metadata = metadata || {}
          @content = content
        end

        def to_h
          {
            preset_name: preset_name,
            files: files,
            metadata: metadata,
            content: content
          }
        end

        def add_file(path, content)
          @files << { path: path, content: content }
        end

        def file_count
          @files.size
        end

        def total_size
          @files.sum { |f| f[:content].to_s.bytesize }
        end
      end
    end
  end
end