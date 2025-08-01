# frozen_string_literal: true

require 'set'

module CodingAgentTools::Atoms
  # Atom for extracting file references from document content
  # Handles markdown links and context loading patterns
  class FileReferenceExtractor
    # Extract markdown links in the format [text](link)
    # Returns array of [text, link] pairs
    def extract_markdown_links(content)
      content.scan(/\[([^\]]+)\]\(([^)]+)\)/)
    end

    # Extract file references from context loading patterns
    # Matches patterns like "Load project objectives: `docs/file.md`"
    def extract_context_references(content)
      content.scan(/(?:Load|load|Check|check|Read|read|See|see).*?[:\s]+`([^`]+\.(?:md|wf\.md|g\.md))`/i)
             .map(&:first)
    end

    # Extract all file references from content
    # Returns a set of file paths referenced in the content
    def extract_all_references(content)
      references = Set.new

      # Process markdown links
      extract_markdown_links(content).each do |_text, link|
        # Skip external links and anchors
        next if link.start_with?('http://', 'https://', '#')

        references << link
      end

      # Process context references
      extract_context_references(content).each do |ref|
        references << ref
      end

      references
    end

    # Check if a link is external (http/https)
    def external_link?(link)
      link.start_with?('http://', 'https://')
    end

    # Check if a link is an anchor (starts with #)
    def anchor_link?(link)
      link.start_with?('#')
    end

    # Check if a link is internal (not external or anchor)
    def internal_link?(link)
      !external_link?(link) && !anchor_link?(link)
    end
  end
end
