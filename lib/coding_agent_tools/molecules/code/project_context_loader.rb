# frozen_string_literal: true

require_relative "../../atoms/code/file_content_reader"
require_relative "../../atoms/yaml_reader"
require_relative "../../models/code/review_context"

module CodingAgentTools
  module Molecules
    module Code
      # Loads project context based on mode
      # This is a molecule - it composes atoms to load project context
      class ProjectContextLoader
        # Standard project documents for auto mode
        AUTO_DOCUMENTS = {
          blueprint: "docs/blueprint.md",
          vision: "docs/what-do-we-build.md",
          architecture: "docs/architecture.md"
        }.freeze

        def initialize
          @file_reader = Atoms::Code::FileContentReader.new
          @yaml_reader = Atoms::YamlReader.new
        end

        # Load context based on mode
        # @param mode [String] context mode ('auto', 'none', 'custom')
        # @param custom_path [String, nil] path for custom context
        # @return [Models::Code::ReviewContext] loaded context
        def load_context(mode, custom_path = nil)
          case mode
          when "auto"
            load_auto_context
          when "none"
            load_none_context
          when "custom"
            load_custom_context(custom_path || mode)
          else
            # If mode looks like a file path, treat as custom
            if File.exist?(mode)
              load_custom_context(mode)
            else
              Models::Code::ReviewContext.new(
                mode: mode,
                documents: [],
                loaded_at: Time.now
              )
            end
          end
        end

        # Check if standard project documents are available
        # @return [Hash] {available: Boolean, found: Array, missing: Array}
        def check_auto_availability
          found = []
          missing = []
          
          AUTO_DOCUMENTS.each do |type, path|
            if @file_reader.readable?(path)
              found << { type: type.to_s, path: path }
            else
              missing << { type: type.to_s, path: path }
            end
          end
          
          {
            available: found.any?,
            found: found,
            missing: missing
          }
        end

        private

        # Load automatic project context
        # @return [Models::Code::ReviewContext] context with auto documents
        def load_auto_context
          documents = []
          
          AUTO_DOCUMENTS.each do |type, path|
            result = @file_reader.read(path)
            if result[:success]
              documents << {
                type: type.to_s,
                path: path,
                content: result[:content]
              }
            end
          end
          
          Models::Code::ReviewContext.new(
            mode: "auto",
            documents: documents,
            loaded_at: Time.now
          )
        end

        # Load none context (empty)
        # @return [Models::Code::ReviewContext] empty context
        def load_none_context
          Models::Code::ReviewContext.new(
            mode: "none",
            documents: [],
            loaded_at: Time.now
          )
        end

        # Load custom context from file
        # @param path [String] custom file path
        # @return [Models::Code::ReviewContext] context with custom document
        def load_custom_context(path)
          result = @file_reader.read(path)
          
          if result[:success]
            documents = [{
              type: "custom",
              path: path,
              content: result[:content]
            }]
          else
            documents = []
          end
          
          Models::Code::ReviewContext.new(
            mode: "custom",
            documents: documents,
            loaded_at: Time.now
          )
        end
      end
    end
  end
end