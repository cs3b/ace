# frozen_string_literal: true

require "fileutils"
require_relative "../molecules/prompt_reader"
require_relative "../molecules/prompt_archiver"
require_relative "../atoms/frontmatter_extractor"
require_relative "../molecules/bundle_loader"
require_relative "../molecules/enhancement_tracker"
require_relative "prompt_enhancer"

module Ace
  module PromptPrep
    module Organisms
      # Orchestrates read → archive → bundle → output flow
      class PromptProcessor
        # Process prompt: read, archive, optionally process via bundle and/or enhance, return content
        #
        # @param input_path [String, nil] Optional custom input path (resolved by CLI)
        # @param bundle [Boolean] Whether to process via ace-bundle SDK
        # @param enhance [Boolean] Whether to enhance prompt via LLM
        # @param model [String, nil] LLM model alias or provider:model
        # @param system_prompt [String, nil] Custom system prompt path
        # @return [Hash] Hash with :content, :archive_path, :success, :error keys
        def self.call(input_path: nil, bundle: false, enhance: false, model: nil, system_prompt: nil)
          # Use provided input path (already resolved by CLI)
          final_input_path = input_path

          # Read prompt
          read_result = Molecules::PromptReader.call(path: final_input_path)
          unless read_result[:success]
            return {
              content: nil,
              archive_path: nil,
              success: false,
              error: read_result[:error]
            }
          end

          original_content = read_result[:content]

          # Determine archive directory and symlink path based on prompt location
          archive_dir, symlink_path = if final_input_path
            prompt_dir = File.dirname(final_input_path)
            [File.join(prompt_dir, "archive"), File.join(prompt_dir, "_previous.md")]
          else
            [nil, nil] # Use defaults
          end

          # Archive ORIGINAL content (before context expansion)
          archive_result = Molecules::PromptArchiver.call(
            content: original_content,
            archive_dir: archive_dir,
            symlink_path: symlink_path
          )
          unless archive_result[:success]
            return {
              content: original_content,
              archive_path: nil,
              success: false,
              error: archive_result[:error]
            }
          end

          # Check if bundle is explicitly disabled in frontmatter
          extracted = Atoms::FrontmatterExtractor.extract(original_content)
          bundle_enabled = if extracted[:has_frontmatter] && extracted[:frontmatter]["bundle"]
            extracted[:frontmatter]["bundle"]["enabled"] != false
          else
            true # Default to enabled if not specified
          end

          # Determine output content based on bundle flag and frontmatter
          output_content = if bundle && bundle_enabled
            # ace-bundle handles entire file processing (including frontmatter)
            bundle_content = Molecules::BundleLoader.call(read_result[:path])
            if bundle_content.empty?
              # Fallback: extract body ONLY if ace-bundle fails
              warn "Warning: ace-bundle failed, extracting prompt body only"
              extracted[:body]
            else
              # Use ace-bundle processed content (includes frontmatter handling)
              bundle_content
            end
          else
            # No bundle or bundle disabled - just strip frontmatter for clean output
            extracted[:body]
          end

          # Track the final archive path (may change if enhanced)
          final_archive_path = archive_result[:archive_path]
          final_symlink_path = archive_result[:symlink_path]
          symlink_was_updated = archive_result[:symlink_updated]

          # Apply enhancement if requested
          if enhance
            # Get config values if not provided
            config = Ace::PromptPrep.config["enhance"] || {}
            final_model = model || config["model"]
            final_system_prompt = system_prompt || config["system_prompt"]
            temperature = config["temperature"] || 0.3

            # Enhance the content
            enhance_result = PromptEnhancer.call(
              content: output_content,
              model: final_model,
              system_prompt_uri: final_system_prompt,
              temperature: temperature
            )

            # Archive enhanced version if enhancement succeeded
            if enhance_result[:enhanced]
              # Calculate next iteration number
              timestamp = File.basename(archive_result[:archive_path], ".md")
              iteration = Molecules::EnhancementTracker.next_iteration(timestamp)
              enhanced_filename = Molecules::EnhancementTracker.enhancement_filename(timestamp, iteration)

              # Archive enhanced content with _eNNN suffix
              enhanced_archive_path = File.join(
                File.dirname(archive_result[:archive_path]),
                enhanced_filename
              )
              File.write(enhanced_archive_path, enhance_result[:content], encoding: "utf-8")

              # Update symlink to point to enhanced version
              symlink_result = Molecules::PromptArchiver.update_symlink(final_symlink_path, enhanced_archive_path)

              # Update final archive path to enhanced version
              final_archive_path = enhanced_archive_path
              symlink_was_updated = symlink_result[:success]

              # Update output content to enhanced version
              output_content = enhance_result[:content]

              # Write enhanced content back to source file (preserve frontmatter)
              original_extracted = Atoms::FrontmatterExtractor.extract(original_content)
              write_content = if original_extracted[:has_frontmatter] && original_extracted[:raw_frontmatter]
                "---\n#{original_extracted[:raw_frontmatter]}---\n\n#{enhance_result[:content]}"
              else
                enhance_result[:content]
              end
              File.write(read_result[:path], write_content, encoding: "utf-8")
            end
          end

          # Track if enhancement actually occurred
          enhancement_occurred = enhance && defined?(enhance_result) && enhance_result&.dig(:enhanced)

          # Return content and archive info
          {
            content: output_content,
            archive_path: final_archive_path,
            symlink_path: final_symlink_path,
            symlink_updated: symlink_was_updated,
            source_path: read_result[:path],
            source_updated: enhancement_occurred,
            success: true,
            error: nil
          }
        end
      end
    end
  end
end
