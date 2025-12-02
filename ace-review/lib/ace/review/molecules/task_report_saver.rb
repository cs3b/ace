# frozen_string_literal: true

require "fileutils"
require "time"

module Ace
  module Review
    module Molecules
      # Save review reports to task directories with timestamped filenames
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
          rescue => e
            return { success: false, error: "Cannot create reviews directory: #{e.message}" }
          end

          # Generate filename
          filename = generate_filename(review_data)
          output_path = File.join(reviews_dir, filename)

          # Copy review to task directory
          begin
            FileUtils.cp(review_file, output_path)
            { success: true, path: output_path }
          rescue => e
            { success: false, error: "Failed to save review: #{e.message}" }
          end
        end

        # Generate timestamped filename for review report
        # @param review_data [Hash] Review metadata (preset, model, etc.)
        # @return [String] Filename in format: YYYYMMDD-HHMMSS-model-preset-review.md
        def self.generate_filename(review_data)
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")

          # Use full model slug for uniqueness (e.g., "google:gemini-2.5-flash" -> "google-gemini-2-5-flash")
          model = review_data[:model] || "unknown"
          model_slug = Ace::Review::Atoms::SlugGenerator.generate(model)

          preset = review_data[:preset] || "default"

          # Sanitize preset name for filename
          preset_slug = Ace::Review::Atoms::SlugGenerator.generate(preset)

          "#{timestamp}-#{model_slug}-#{preset_slug}-review.md"
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
      end
    end
  end
end
