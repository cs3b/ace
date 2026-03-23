# frozen_string_literal: true

require "uri"

module Ace
  module Support
    module MacClipboard
      class ContentParser
        def self.parse(raw_result)
          return {text: nil, attachments: []} unless raw_result[:success]
          return {text: nil, attachments: []} if raw_result[:types].empty?

          pasteboard = raw_result[:raw_pasteboard]
          types = raw_result[:types]

          text_parts = []
          attachments = []
          image_count = 0

          # Classify all types
          classified = types.map { |uti| [uti, ContentType.classify(uti)] }

          # Process by priority
          ContentType::PRIORITY_ORDER.each do |category|
            relevant_utis = classified.select { |_uti, cat| cat == category }.map(&:first)

            case category
            when :files
              # Read file URLs once (works for both public.file-url and NSFilenamesPboardType)
              file_urls = Reader.read_file_urls(pasteboard)
              file_urls.each do |path|
                attachments << {
                  type: :file,
                  source_path: path,
                  filename: File.basename(path)
                }
              end

            when :image
              relevant_utis.each do |uti|
                data = Reader.read_type(pasteboard, uti)
                next unless data && data.bytesize > 0

                image_count += 1
                format = ContentType.image_format_from_uti(uti)
                ext = ContentType::EXTENSIONS[:image][format]

                attachments << {
                  type: :image,
                  format: format,
                  data: data,
                  filename: "clipboard-image-#{image_count}#{ext}"
                }
                break # Only take the first image format
              end

            when :rtf
              relevant_utis.each do |uti|
                data = Reader.read_type(pasteboard, uti)
                next unless data && data.bytesize > 0

                attachments << {
                  type: :rtf,
                  data: data,
                  filename: "clipboard-content.rtf"
                }
                break # Only take the first RTF format
              end

            when :html
              relevant_utis.each do |uti|
                data = Reader.read_type(pasteboard, uti)
                next unless data && data.bytesize > 0

                attachments << {
                  type: :html,
                  data: data,
                  filename: "clipboard-content.html"
                }
                break # Only take the first HTML format
              end

            when :text
              relevant_utis.each do |uti|
                text = Reader.read_string(pasteboard, uti)
                next unless text && !text.empty?

                text_parts << text
                break # Only take the first text format
              end
            end
          end

          # Combine all text parts
          combined_text = text_parts.join("\n\n").strip
          combined_text = nil if combined_text.empty?

          {
            text: combined_text,
            attachments: attachments
          }
        end

        def self.parse_text(data)
          return nil unless data

          data.force_encoding("UTF-8").strip
        rescue
          nil
        end

        def self.parse_file_urls(data)
          return [] unless data

          # Parse file URL data
          urls = []
          url_str = data.force_encoding("UTF-8").strip

          # Handle file:// URLs
          url_str = url_str.sub(%r{^file://}, "")

          # URL decode
          url_str = begin
            URI.decode_www_form_component(url_str)
          rescue
            url_str
          end

          urls << url_str if File.exist?(url_str)
          urls
        rescue
          []
        end

        def self.parse_image(data, uti)
          return nil unless data && data.bytesize > 0

          format = ContentType.image_format_from_uti(uti)

          {
            format: format,
            data: data
          }
        rescue
          nil
        end

        def self.parse_rtf(data)
          return nil unless data && data.bytesize > 0

          data
        rescue
          nil
        end

        def self.parse_html(data)
          return nil unless data && data.bytesize > 0

          data.force_encoding("UTF-8")
        rescue
          nil
        end
      end
    end
  end
end
