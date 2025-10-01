# frozen_string_literal: true

module Ace
  module Taskflow
    module Models
      class Idea
        attr_reader :id, :filename, :title, :content, :path, :created_at, :context, :tags, :status

        def initialize(data)
          # Normalize to symbol keys to support both string and symbol keys
          attrs = data.transform_keys(&:to_sym)

          @id = attrs[:id]
          @filename = attrs[:filename]
          @title = attrs[:title] || extract_title_from_filename(attrs[:filename])
          @content = attrs[:content]
          @path = attrs[:path]
          @created_at = attrs[:created_at]
          @context = attrs[:context] || "current"
          @tags = attrs[:tags] || []
          @status = attrs[:status] || "pending"
        end

        def to_h
          {
            id: @id,
            filename: @filename,
            title: @title,
            content: @content,
            path: @path,
            created_at: @created_at,
            context: @context,
            tags: @tags,
            status: @status
          }
        end

        private

        def extract_title_from_filename(filename)
          return nil unless filename

          # Remove timestamp prefix and .md extension
          title = filename.sub(/^\d{8}-\d{6}-/, "").sub(/\.md$/, "")
          # Convert dashes to spaces
          title.tr("-", " ").strip
        end
      end
    end
  end
end