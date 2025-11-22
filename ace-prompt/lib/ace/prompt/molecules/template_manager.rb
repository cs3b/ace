# frozen_string_literal: true

require "fileutils"
require_relative "template_resolver"

module Ace
  module Prompt
    module Molecules
      # Load and apply templates
      class TemplateManager
        # Load template content
        # @param template_uri [String] Template URI or path
        # @return [String] Template content
        def self.load(template_uri)
          template_path = TemplateResolver.resolve(template_uri)
          File.read(template_path)
        rescue => e
          raise Ace::Prompt::Error, "Failed to load template: #{e.message}"
        end

        # Apply template to file
        # @param template_content [String] Template content
        # @param target_path [String] Target file path
        # @param force [Boolean] Overwrite if exists
        # @return [Boolean] True if successful
        def self.apply(template_content, target_path, force: false)
          if File.exist?(target_path) && !force
            raise Ace::Prompt::Error, "File already exists: #{target_path}. Use --force to overwrite."
          end

          FileUtils.mkdir_p(File.dirname(target_path))
          File.write(target_path, template_content)
          true
        end
      end
    end
  end
end
