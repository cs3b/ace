# frozen_string_literal: true

module Ace
  module Bundle
    module Models
      # Data model for bundle information
      class BundleData
        attr_accessor :preset_name, :files, :metadata, :content, :commands, :sections

        def initialize(preset_name: nil, files: nil, metadata: nil, content: "", commands: nil, sections: nil)
          @preset_name = preset_name
          @files = files || []
          @metadata = metadata || {}
          @content = content
          @commands = commands || []
          @sections = sections || {}
        end

        def to_h
          {
            preset_name: preset_name,
            files: files,
            metadata: metadata,
            content: content,
            commands: commands,
            sections: sections
          }
        end

        def add_file(path, content)
          @files << {path: path, content: content}
        end

        def file_count
          @files.size
        end

        def total_size
          @files.sum { |f| f[:content].to_s.bytesize }
        end

        # Section-related methods
        def add_section(name, section_data)
          @sections[name] = section_data
        end

        def get_section(name)
          @sections[name]
        end

        def has_sections?
          !@sections.empty?
        end

        def section_count
          @sections.size
        end

        def sorted_sections
          # In Ruby 3.2+, hash insertion order is preserved
          # This returns sections in the order they appear in the YAML file
          @sections.to_a
        end

        def section_names
          @sections.keys
        end

        def clear_sections
          @sections.clear
        end
      end
    end
  end
end
