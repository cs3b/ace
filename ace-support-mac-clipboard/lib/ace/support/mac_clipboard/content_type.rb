# frozen_string_literal: true

module Ace
  module Support
    module MacClipboard
      module ContentType
        # UTI (Uniform Type Identifier) mappings for macOS clipboard types
        UTI_TYPES = {
          # Text types
          "public.utf8-plain-text" => :text,
          "public.plain-text" => :text,
          "NSStringPboardType" => :text,

          # Image types
          "public.png" => :image,
          "public.jpeg" => :image,
          "public.tiff" => :image,
          "com.apple.icns" => :image,

          # File URLs
          "public.file-url" => :files,
          "NSFilenamesPboardType" => :files,

          # Rich text types
          "public.rtf" => :rtf,
          "com.apple.rtfd" => :rtf,

          # HTML
          "public.html" => :html,
          "NSHTMLPboardType" => :html
        }.freeze

        # Priority order for processing (higher priority first)
        PRIORITY_ORDER = [:files, :image, :rtf, :html, :text].freeze

        # File extensions for auto-generated filenames
        EXTENSIONS = {
          image: { png: ".png", jpeg: ".jpg", tiff: ".tiff" },
          rtf: ".rtf",
          html: ".html"
        }.freeze

        def self.classify(uti)
          UTI_TYPES[uti] || :unknown
        end

        def self.image_format_from_uti(uti)
          case uti
          when "public.png" then :png
          when "public.jpeg" then :jpeg
          when "public.tiff" then :tiff
          else :png
          end
        end
      end
    end
  end
end
