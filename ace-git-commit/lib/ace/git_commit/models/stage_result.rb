# frozen_string_literal: true

module Ace
  module GitCommit
    module Models
      # StageResult represents the outcome of staging a file or set of files
      class StageResult
        attr_reader :file_path, :success, :error_message, :file_size, :status

        def initialize(file_path:, success:, error_message: nil, file_size: nil, status: nil)
          @file_path = file_path
          @success = success
          @error_message = error_message
          @file_size = file_size
          @status = status # :modified, :new, :deleted, etc.
        end

        # Check if staging was successful
        # @return [Boolean] True if successful
        def success?
          @success
        end

        # Check if this is a large file (>50MB)
        # @return [Boolean] True if file is large
        def large_file?
          return false unless @file_size
          @file_size > 50 * 1024 * 1024 # 50MB in bytes
        end

        # Get a human-readable file size
        # @return [String] File size with unit
        def human_file_size
          return nil unless @file_size

          if @file_size < 1024
            "#{@file_size} B"
          elsif @file_size < 1024 * 1024
            "#{(@file_size / 1024.0).round(1)} KB"
          elsif @file_size < 1024 * 1024 * 1024
            "#{(@file_size / (1024.0 * 1024.0)).round(2)} MB"
          else
            "#{(@file_size / (1024.0 * 1024.0 * 1024.0)).round(2)} GB"
          end
        end

        # Get status indicator emoji
        # @return [String] Status emoji
        def status_indicator
          if success?
            "✓"
          else
            "✗"
          end
        end

        # Convert to hash for debugging
        # @return [Hash] Result as hash
        def to_h
          {
            file_path: @file_path,
            success: @success,
            error_message: @error_message,
            file_size: @file_size,
            status: @status
          }
        end
      end
    end
  end
end
