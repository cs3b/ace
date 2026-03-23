# frozen_string_literal: true

require "ace/support/fs"
require "fileutils"
require "yaml"

module Ace
  module Core
    module Molecules
      # Standardized prompt cache management for ace-* gems
      # Provides consistent session directory creation, prompt saving, and metadata management
      #
      # This is a stateless utility class - all methods are class methods.
      class PromptCacheManager
        # Custom exception for prompt cache operations
        class PromptCacheError < StandardError; end
        class << self
          # Create a new session directory with standardized structure
          # @param gem_name [String] Name of the gem (e.g., 'ace-review', 'ace-docs')
          # @param operation [String] Operation name (e.g., 'review', 'analyze-consistency')
          # @param project_root [String, nil] Optional project root (auto-detected if nil)
          # @param timestamp_formatter [Proc, nil] Optional custom timestamp formatter
          # @return [String] Path to created session directory
          def create_session(gem_name, operation, project_root: nil, timestamp_formatter: nil)
            raise ArgumentError, "gem_name cannot be nil or empty" if gem_name.nil? || gem_name.strip.empty?
            raise ArgumentError, "operation cannot be nil or empty" if operation.nil? || operation.strip.empty?

            begin
              root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
              timestamp = timestamp_formatter ? timestamp_formatter.call(Time.now) : Time.now.strftime("%Y%m%d-%H%M%S")
              session_name = "#{operation}-#{timestamp}"
              session_dir = File.join(base_cache_path(root, gem_name), session_name)
              FileUtils.mkdir_p(session_dir)
              session_dir
            rescue Errno::ENOENT, Errno::EACCES => e
              raise PromptCacheError, "Failed to create session directory: #{e.message}"
            rescue => e
              raise PromptCacheError, "Unexpected error creating session: #{e.message}"
            end
          end

          # Save system prompt to session directory
          # @param content [String] Prompt content
          # @param session_dir [String] Session directory path
          # @return [String] Path to saved file
          def save_system_prompt(content, session_dir)
            save_prompt(content, session_dir, "system.prompt.md")
          end

          # Save user prompt to session directory
          # @param content [String] Prompt content
          # @param session_dir [String] Session directory path
          # @return [String] Path to saved file
          def save_user_prompt(content, session_dir)
            save_prompt(content, session_dir, "user.prompt.md")
          end

          # Save metadata to session directory
          # @param metadata [Hash] Metadata hash
          # @param session_dir [String] Session directory path
          # @param validate [Boolean] Whether to validate metadata schema (default: true)
          # @return [String] Path to saved file
          def save_metadata(metadata, session_dir, validate: true)
            raise ArgumentError, "metadata must be a Hash" unless metadata.is_a?(Hash)
            raise ArgumentError, "session_dir cannot be nil or empty" if session_dir.nil? || session_dir.strip.empty?

            validate_metadata(metadata) if validate

            begin
              metadata_path = File.join(session_dir, "metadata.yml")
              File.write(metadata_path, YAML.dump(metadata))
              metadata_path
            rescue Errno::ENOENT, Errno::EACCES => e
              raise PromptCacheError, "Failed to save metadata to #{metadata_path}: #{e.message}"
            rescue => e
              raise PromptCacheError, "Unexpected error saving metadata: #{e.message}"
            end
          end

          # Validate metadata schema
          # @param metadata [Hash] Metadata hash to validate
          # @raise [ArgumentError] If required fields are missing
          def validate_metadata(metadata)
            required_fields = %w[timestamp gem operation]
            missing = required_fields - metadata.keys
            unless missing.empty?
              raise ArgumentError, "Missing required metadata fields: #{missing.join(", ")}"
            end

            # Validate field types
            unless metadata["timestamp"].is_a?(String) || metadata["timestamp"].is_a?(Time)
              raise ArgumentError, "Metadata 'timestamp' must be a String or Time"
            end

            unless metadata["gem"].is_a?(String) && !metadata["gem"].strip.empty?
              raise ArgumentError, "Metadata 'gem' must be a non-empty String"
            end

            unless metadata["operation"].is_a?(String) && !metadata["operation"].strip.empty?
              raise ArgumentError, "Metadata 'operation' must be a non-empty String"
            end
          end

          private

          # Get base cache path for a gem
          # @param project_root [String] Project root path
          # @param gem_name [String] Name of the gem
          # @return [String] Base cache path (.ace-local/{short-gem}/sessions/)
          def base_cache_path(project_root, gem_name)
            short_name = gem_name.to_s.sub(/\Aace-/, "")
            cache_path = File.join(project_root, ".ace-local", short_name, "sessions")
            FileUtils.mkdir_p(cache_path) unless Dir.exist?(cache_path)
            cache_path
          end

          # Save a prompt file
          # @param content [String] Prompt content
          # @param session_dir [String] Session directory path
          # @param filename [String] Filename for the prompt
          # @return [String] Path to saved file
          def save_prompt(content, session_dir, filename)
            raise ArgumentError, "content cannot be nil" if content.nil?
            raise ArgumentError, "session_dir cannot be nil or empty" if session_dir.nil? || session_dir.strip.empty?
            raise ArgumentError, "filename cannot be nil or empty" if filename.nil? || filename.strip.empty?

            begin
              prompt_path = File.join(session_dir, filename)
              File.write(prompt_path, content)
              prompt_path
            rescue Errno::ENOENT, Errno::EACCES => e
              raise PromptCacheError, "Failed to save prompt to #{prompt_path}: #{e.message}"
            rescue => e
              raise PromptCacheError, "Unexpected error saving prompt: #{e.message}"
            end
          end
        end
      end
    end
  end
end
