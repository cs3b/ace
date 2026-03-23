# frozen_string_literal: true

# Clipboard reader adapted from ace-taskflow's ClipboardReader.
# Kept independent (no ace-taskflow dependency) as per task spec:
# "Shared utilities from ace-taskflow are duplicated rather than centralized."

begin
  require "clipboard"
rescue LoadError
  # clipboard gem not available - will gracefully degrade
end

begin
  require "ace/support/mac_clipboard"
rescue LoadError
  # Not available on this platform
end

module Ace
  module Idea
    module Molecules
      # Reads content from the system clipboard for idea capture.
      # Supports: plain text, RTF, HTML (as text), images (as attachments).
      class IdeaClipboardReader
        MAX_CONTENT_SIZE = 100 * 1024 # 100KB

        # Read clipboard content
        # @return [Hash] Result with :success, :content, :type, :attachments keys
        def self.read
          if macos? && macos_clipboard_available?
            read_macos
          else
            read_generic
          end
        end

        private

        def self.macos?
          RUBY_PLATFORM.include?("darwin")
        end

        def self.macos_clipboard_available?
          defined?(Ace::Support::MacClipboard)
        end

        def self.read_macos
          raw = Ace::Support::MacClipboard::Reader.read
          return {success: false, error: raw[:error]} unless raw[:success]

          parsed = Ace::Support::MacClipboard::ContentParser.parse(raw)

          has_attachments = parsed[:attachments].any?
          type = has_attachments ? :rich : :text
          file_attachments = parsed[:attachments].select { |a| a[:type] == :file }

          {
            success: true,
            platform: :macos,
            type: type,
            content: parsed[:text],
            attachments: parsed[:attachments],
            files: file_attachments.map { |a| a[:source_path] }
          }
        rescue
          read_generic
        end

        def self.read_generic
          unless defined?(Clipboard)
            return {
              success: false,
              error: "Clipboard gem not available. Install 'clipboard' gem for clipboard support."
            }
          end

          content = Clipboard.paste

          if content.nil? || content.strip.empty?
            return {
              success: false,
              error: "Clipboard is empty. Provide text argument or copy content to clipboard."
            }
          end

          if content.bytesize > MAX_CONTENT_SIZE
            return {
              success: false,
              error: "Clipboard content too large (#{content.bytesize} bytes, max #{MAX_CONTENT_SIZE} bytes)"
            }
          end

          if content.encoding == Encoding::ASCII_8BIT || content.include?("\x00")
            return {
              success: false,
              error: "Clipboard contains binary data. Only text content is supported."
            }
          end

          {
            success: true,
            platform: :generic,
            type: :text,
            content: content,
            attachments: [],
            files: []
          }
        rescue => e
          {
            success: false,
            error: "Unable to read clipboard: #{e.message}"
          }
        end
      end
    end
  end
end
