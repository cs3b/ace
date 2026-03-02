# frozen_string_literal: true

require "fileutils"
require "time"
require "ace/b36ts"

module Ace
  module Review
    module Molecules
      # Save review reports to task directories with compact ID filenames
      class TaskReportSaver
        # Save a review report to a task's reviews/ directory
        # @param task_dir [String] Path to the task directory
        # @param review_file [String] Path to the review file to copy
        # @param review_data [Hash] Review metadata (preset, model, etc.)
        # @return [Hash] Result with :success, :path, or :error
        def self.save(task_dir, review_file, review_data)
          # Validate inputs
          return { success: false, error: "Task directory not found: #{task_dir}" } unless Dir.exist?(task_dir)
          return { success: false, error: "Review file not found: #{review_file}" } unless File.exist?(review_file)

          # Create reviews/ subdirectory if it doesn't exist
          reviews_dir = File.join(task_dir, "reviews")
          begin
            FileUtils.mkdir_p(reviews_dir)
          rescue SystemCallError, IOError => e
            return { success: false, error: "Cannot create reviews directory: #{e.message}" }
          end

          # Generate filename
          filename = generate_filename(review_data)
          output_path = File.join(reviews_dir, filename)

          # Copy review to task directory
          begin
            FileUtils.cp(review_file, output_path)
            { success: true, path: output_path }
          rescue SystemCallError, IOError => e
            { success: false, error: "Failed to save review: #{e.message}" }
          end
        end

        # Generate filename with compact ID for review report
        # @param review_data [Hash] Review metadata (preset, model, etc.)
        # @return [String] Filename with format: {compact_id}-model-preset-review.md
        def self.generate_filename(review_data)
          compact_id = Ace::B36ts.encode(Time.now)

          # Use full model slug for uniqueness (e.g., "google:gemini-2.5-flash" -> "google-gemini-2-5-flash")
          model = review_data[:model] || "unknown"
          model_slug = Ace::Review::Atoms::SlugGenerator.generate(model)

          preset = review_data[:preset] || "default"

          # Sanitize preset name for filename
          preset_slug = Ace::Review::Atoms::SlugGenerator.generate(preset)

          "#{compact_id}-#{model_slug}-#{preset_slug}-review.md"
        end

        # Extract provider name from model string
        # @param model [String] Model identifier (e.g., "google:gemini-2.5-flash", "gpt-4")
        # @return [String] Provider name or sanitized model name
        def self.extract_provider(model)
          # Check for provider prefix (e.g., "google:", "openai:")
          if model.include?(":")
            provider = model.split(":").first
            provider.gsub(/[^a-zA-Z0-9\-_]/, '-').downcase
          else
            # Use first part of model name (e.g., "gpt-4" -> "gpt", "claude-3" -> "claude")
            parts = model.split("-")
            if parts.length > 1 && parts.first =~ /^[a-z]+$/i
              parts.first.downcase
            else
              # Fallback: sanitize entire model name
              model.gsub(/[^a-zA-Z0-9\-_]/, '-').downcase.split('-').first
            end
          end
        end

        # ============================================================================
        # Feedback Methods
        # ============================================================================

        # Get the feedback directory path for a task
        # @param task_path [String] Path to the task directory
        # @return [String] The feedback directory path
        def self.feedback_path(task_path)
          File.join(task_path, "feedback")
        end

        # Get the feedback archive directory path for a task
        # @param task_path [String] Path to the task directory
        # @return [String] The feedback archive directory path
        def self.feedback_archive_path(task_path)
          File.join(task_path, "feedback", "_archived")
        end

        # Save a feedback file to a task's feedback/ directory
        # @param task_path [String] Path to the task directory
        # @param feedback_file [String] Path to the feedback file to copy
        # @param feedback_data [Hash] Optional metadata (currently unused, for future extension)
        # @return [Hash] Result with :success, :path, or :error
        def self.save_feedback(task_path, feedback_file, feedback_data = {})
          # Validate inputs
          return { success: false, error: "Task directory not found: #{task_path}" } unless Dir.exist?(task_path)
          return { success: false, error: "Feedback file not found: #{feedback_file}" } unless File.exist?(feedback_file)

          # Create feedback/ subdirectory if it doesn't exist
          feedback_dir = feedback_path(task_path)
          begin
            FileUtils.mkdir_p(feedback_dir)
          rescue SystemCallError, IOError => e
            return { success: false, error: "Cannot create feedback directory: #{e.message}" }
          end

          # Use original filename for feedback files (they already have meaningful names)
          filename = File.basename(feedback_file)
          output_path = File.join(feedback_dir, filename)

          # Copy feedback file to task directory
          begin
            FileUtils.cp(feedback_file, output_path)
            { success: true, path: output_path }
          rescue SystemCallError, IOError => e
            { success: false, error: "Failed to save feedback: #{e.message}" }
          end
        end

        # Archive a feedback file by moving it to the task's feedback/_archived/ directory
        # @param task_path [String] Path to the task directory
        # @param feedback_file [String] Path to the feedback file to archive
        # @return [Hash] Result with :success, :path, or :error
        def self.archive_feedback(task_path, feedback_file)
          # Validate inputs
          return { success: false, error: "Task directory not found: #{task_path}" } unless Dir.exist?(task_path)
          return { success: false, error: "Feedback file not found: #{feedback_file}" } unless File.exist?(feedback_file)

          # Create feedback/_archived/ subdirectory if it doesn't exist
          archive_dir = feedback_archive_path(task_path)
          begin
            FileUtils.mkdir_p(archive_dir)
          rescue SystemCallError, IOError => e
            return { success: false, error: "Cannot create archive directory: #{e.message}" }
          end

          # Move feedback file to archive
          filename = File.basename(feedback_file)
          archive_path = File.join(archive_dir, filename)

          begin
            FileUtils.mv(feedback_file, archive_path)
            { success: true, path: archive_path }
          rescue SystemCallError, IOError => e
            { success: false, error: "Failed to archive feedback: #{e.message}" }
          end
        end
      end
    end
  end
end
