# frozen_string_literal: true

require 'pathname'
require_relative '../atoms/file_reader'
require_relative '../molecules/preset_manager'
require_relative '../models/context_data'

module Ace
  module Context
    module Organisms
      # Main context loader that orchestrates preset loading
      class ContextLoader
        def initialize(options = {})
          @options = options
          @preset_manager = Molecules::PresetManager.new
        end

        def load_preset(preset_name)
          preset = @preset_manager.get_preset(preset_name)
          unless preset
            return Models::ContextData.new(
              preset_name: preset_name,
              metadata: { error: "Preset '#{preset_name}' not found" }
            )
          end

          load_from_config(preset)
        end

        def load_file(path)
          max_size = @options[:max_size] || Atoms::FileReader::MAX_FILE_SIZE
          result = Atoms::FileReader.read_file(path, max_size: max_size)

          context = Models::ContextData.new
          if result[:success]
            context.add_file(path, result[:content])
          else
            context.metadata[:error] = result[:error]
          end

          context
        end

        def load_from_config(config)
          context = Models::ContextData.new(
            preset_name: config[:name],
            metadata: config[:metadata] || {}
          )

          # Process include patterns
          config[:include].each do |pattern|
            files = Atoms::FileReader.glob_files(pattern)

            # Apply exclusions
            if config[:exclude].any?
              exclude_patterns = config[:exclude]
              files = files.reject do |file|
                # Convert absolute path to relative for matching
                relative_path = file.start_with?('/') ?
                  Pathname.new(file).relative_path_from(Pathname.pwd).to_s :
                  file
                exclude_patterns.any? { |ex| File.fnmatch(ex, relative_path, File::FNM_PATHNAME) }
              end
            end

            # Read each file
            files.each do |file|
              max_size = @options[:max_size] || Atoms::FileReader::MAX_FILE_SIZE
              result = Atoms::FileReader.read_file(file, max_size: max_size)
              if result[:success]
                context.add_file(file, result[:content])
              end
            end
          end

          # Format output
          format_context(context, config[:format])
        end

        private

        def format_context(context, format)
          case format
          when 'markdown'
            format_markdown(context)
          when 'yaml'
            format_yaml(context)
          else
            context
          end
        end

        def format_markdown(context)
          output = []
          output << "# Context"
          output << ""
          output << "## Files"
          output << ""

          context.files.each do |file_info|
            output << "<file path=\"#{file_info[:path]}\">"
            output << file_info[:content]
            output << "</file>"
            output << ""
          end

          context.content = output.join("\n")
          context
        end

        def format_yaml(context)
          require 'yaml'
          context.content = context.to_h.to_yaml
          context
        end
      end
    end
  end
end