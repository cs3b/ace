# frozen_string_literal: true

require "ace/support/timestamp"

module Ace
  module Taskflow
    module Models
      class Idea
        attr_reader :id, :filename, :title, :content, :path, :created_at, :release, :tags, :status

        def initialize(data)
          # Normalize to symbol keys to support both string and symbol keys
          attrs = data.transform_keys(&:to_sym)

          @id = attrs[:id]
          @filename = attrs[:filename]
          @title = attrs[:title] || extract_title_from_filename(attrs[:filename])
          @content = attrs[:content]
          @path = attrs[:path]
          @created_at = attrs[:created_at]
          @release = attrs[:release] || "current"
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
            release: @release,
            tags: @tags,
            status: @status
          }
        end

        private

        def extract_title_from_filename(filename)
          return nil unless filename

          # Get basename (handle directory-style ideas like "xyz789-directory-idea/idea.s.md")
          basename = File.basename(filename)

          # Remove .s.md or .md extension first
          basename = basename.sub(/\.s\.md$/, "").sub(/\.md$/, "")

          # Try timestamp prefix first: "20250115-103045-my-idea"
          if basename =~ /^(\d{8}-\d{6})-(.*)$/
            title = $2
          # Try Base36 ID prefix with validation: "abc123-my-idea"
          elsif basename =~ /^([0-9a-z]{6})-(.*)$/i
            potential_id = $1
            if Ace::Support::Timestamp.detect_format(potential_id) == :compact
              title = $2
            else
              # Not a valid Base36 ID, treat entire basename as title
              title = basename
            end
          else
            # No recognized ID prefix, use entire basename as title
            title = basename
          end

          # Convert dashes to spaces and strip
          title.tr("-", " ").strip
        end
      end
    end
  end
end