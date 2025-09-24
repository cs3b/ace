# frozen_string_literal: true

module Ace
  module Taskflow
    module Models
      class Idea
        attr_reader :id, :filename, :title, :content, :path, :created_at, :context

        def initialize(data)
          @id = data[:id]
          @filename = data[:filename]
          @title = data[:title] || extract_title_from_filename(data[:filename])
          @content = data[:content]
          @path = data[:path]
          @created_at = data[:created_at] || Time.now
          @context = data[:context] || "current"
        end

        def to_h
          {
            id: @id,
            filename: @filename,
            title: @title,
            content: @content,
            path: @path,
            created_at: @created_at,
            context: @context
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