# frozen_string_literal: true

require_relative "../molecules/template_manager"
require_relative "../molecules/prompt_archiver"
require_relative "../molecules/config_loader"

module Ace
  module Prompt
    module Organisms
      # Initialize and reset prompts with templates
      class PromptInitializer
        def initialize(config = nil)
          @config = config || Molecules::ConfigLoader.load
        end

        # Setup new prompt from template
        # @param template_uri [String, nil] Template URI (default from config)
        # @param target_path [String, nil] Target path (default from config)
        # @param force [Boolean] Overwrite if exists
        # @return [String] Path to created file
        def setup(template_uri: nil, target_path: nil, force: false)
          template = template_uri || @config["template"]
          target = target_path || default_prompt_path

          template_content = Molecules::TemplateManager.load(template)
          Molecules::TemplateManager.apply(template_content, target, force: force)

          target
        end

        # Reset prompt to template (archives current first)
        # @param template_uri [String, nil] Template URI (default from config)
        # @param target_path [String, nil] Target path (default from config)
        # @return [String] Path to reset file
        def reset(template_uri: nil, target_path: nil)
          target = target_path || default_prompt_path

          # Archive current prompt if it exists
          if File.exist?(target)
            archive_dir = File.join(File.dirname(target), @config["archive_subdir"])
            archived = Molecules::PromptArchiver.archive(target, archive_dir)

            if archived
              symlink_path = File.join(File.dirname(target), "_previous.md")
              Molecules::PromptArchiver.update_symlink(archived, symlink_path)
            end
          end

          # Setup fresh template
          setup(template_uri: template_uri, target_path: target, force: true)
        end

        private

        def default_prompt_path
          File.join(@config["default_dir"], @config["default_file"])
        end
      end
    end
  end
end
