# frozen_string_literal: true

require_relative "../molecules/template_resolver"
require_relative "../molecules/template_manager"
require "ace/support/fs"

module Ace
  module PromptPrep
    module Organisms
      # Handles prompt initialization and reset operations
      class PromptInitializer
        DEFAULT_TEMPLATE_URI = "tmpl://the-prompt-base"
        DEFAULT_PROMPT_FILE = "the-prompt.md"

        class << self
          # Get default prompt directory (project-local)
          def default_prompt_dir
            project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            File.join(project_root, ".ace-local", "prompt-prep", "prompts")
          end
        end

        class << self
          # Setup prompt with template
          #
          # @param template_uri [String] Template URI (default: DEFAULT_TEMPLATE_URI)
          # @param target_dir [String] Target directory (default: project-local .cache dir, resolved by CLI)
          # @param force [Boolean] Skip archiving existing file (overwrite directly)
          # @return [Hash] Result with :success, :path, :archive_path, :error keys
          def setup(template_uri: DEFAULT_TEMPLATE_URI, target_dir: nil, force: false)
            target_dir ||= default_prompt_dir
            # Resolve template URI to file path
            resolve_result = Molecules::TemplateResolver.call(uri: template_uri)

            unless resolve_result[:success]
              return {
                success: false,
                path: nil,
                archive_path: nil,
                error: resolve_result[:error]
              }
            end

            template_path = resolve_result[:path]
            target_path = File.join(target_dir, DEFAULT_PROMPT_FILE)
            archive_dir = File.join(target_dir, "archive")

            # If force is false, use restore_template (which archives)
            # If force is true, use copy_template (which overwrites)
            if force
              copy_result = Molecules::TemplateManager.copy_template(
                template_path: template_path,
                target_path: target_path,
                force: true
              )

              unless copy_result[:success]
                return {
                  success: false,
                  path: nil,
                  archive_path: nil,
                  error: copy_result[:error]
                }
              end

              {
                success: true,
                path: copy_result[:path],
                archive_path: nil,
                error: nil
              }
            else
              # Use restore_template to archive existing file
              restore_result = Molecules::TemplateManager.restore_template(
                template_path: template_path,
                target_path: target_path,
                archive_dir: archive_dir,
                force: false
              )

              unless restore_result[:success]
                return {
                  success: false,
                  path: nil,
                  archive_path: nil,
                  error: restore_result[:error]
                }
              end

              {
                success: true,
                path: restore_result[:path],
                archive_path: restore_result[:archive_path],
                error: nil
              }
            end
          rescue => e
            {
              success: false,
              path: nil,
              archive_path: nil,
              error: "Setup failed: #{e.message}"
            }
          end

          # Reset prompt to template (archive current)
          #
          # @param template_uri [String] Template URI (default: DEFAULT_TEMPLATE_URI)
          # @param target_dir [String] Target directory (default: project-local .cache dir, resolved by CLI)
          # @param force [Boolean] Skip archiving current file
          # @return [Hash] Result with :success, :path, :archive_path, :error keys
          def reset(template_uri: DEFAULT_TEMPLATE_URI, target_dir: nil, force: false)
            target_dir ||= default_prompt_dir
            # Resolve template URI to file path
            resolve_result = Molecules::TemplateResolver.call(uri: template_uri)

            unless resolve_result[:success]
              return {
                success: false,
                path: nil,
                archive_path: nil,
                error: resolve_result[:error]
              }
            end

            template_path = resolve_result[:path]
            target_path = File.join(target_dir, DEFAULT_PROMPT_FILE)
            archive_dir = File.join(target_dir, "archive")

            # Restore template (archive current if exists)
            restore_result = Molecules::TemplateManager.restore_template(
              template_path: template_path,
              target_path: target_path,
              archive_dir: archive_dir,
              force: force
            )

            unless restore_result[:success]
              return {
                success: false,
                path: nil,
                archive_path: nil,
                error: restore_result[:error]
              }
            end

            {
              success: true,
              path: restore_result[:path],
              archive_path: restore_result[:archive_path],
              error: nil
            }
          rescue => e
            {
              success: false,
              path: nil,
              archive_path: nil,
              error: "Reset failed: #{e.message}"
            }
          end
        end
      end
    end
  end
end
