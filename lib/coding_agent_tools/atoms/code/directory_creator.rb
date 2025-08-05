# frozen_string_literal: true

require 'fileutils'

module CodingAgentTools
  module Atoms
    module Code
      # Creates directories with proper permissions
      # This is an atom - it has no dependencies on other gem components
      class DirectoryCreator
        # Create a directory with parents if needed
        # @param path [String] directory path to create
        # @return [Hash] {success: Boolean, error: String}
        def create(path)
          validate_path(path)

          begin
            FileUtils.mkdir_p(path)
            {
              success: true,
              error: nil
            }
          rescue Errno::EACCES
            {
              success: false,
              error: "Permission denied: #{path}"
            }
          rescue Errno::ENOTDIR
            {
              success: false,
              error: "Parent is not a directory: #{path}"
            }
          rescue => e
            {
              success: false,
              error: "Error creating directory: #{e.message}"
            }
          end
        end

        # Create directory only if it doesn't exist
        # @param path [String] directory path to create
        # @return [Hash] {success: Boolean, created: Boolean, error: String}
        def create_if_not_exists(path)
          validate_path(path)

          if File.exist?(path)
            if File.directory?(path)
              {
                success: true,
                created: false,
                error: nil
              }
            else
              {
                success: false,
                created: false,
                error: "Path exists but is not a directory: #{path}"
              }
            end
          else
            result = create(path)
            {
              success: result[:success],
              created: result[:success],
              error: result[:error]
            }
          end
        end

        # Check if directory exists
        # @param path [String] directory path
        # @return [Boolean] true if directory exists
        def exists?(path)
          File.exist?(path) && File.directory?(path)
        end

        # Check if directory is writable
        # @param path [String] directory path
        # @return [Boolean] true if directory exists and is writable
        def writable?(path)
          exists?(path) && File.writable?(path)
        end

        # Create a temporary directory
        # @param prefix [String] directory name prefix
        # @param tmpdir [String] parent directory for temp dir (default: system temp)
        # @return [Hash] {path: String, success: Boolean, error: String}
        def create_temp(prefix = 'review', tmpdir = nil)
          require 'tmpdir'

          begin
            temp_path = Dir.mktmpdir(prefix, tmpdir)
            {
              path: temp_path,
              success: true,
              error: nil
            }
          rescue => e
            {
              path: nil,
              success: false,
              error: "Error creating temp directory: #{e.message}"
            }
          end
        end

        private

        # Validate directory path
        # @param path [String] directory path
        # @raise [ArgumentError] if path is invalid
        def validate_path(path)
          raise ArgumentError, 'Path cannot be nil' if path.nil?
          raise ArgumentError, 'Path cannot be empty' if path.empty?
          raise ArgumentError, 'Path must be a string' unless path.is_a?(String)
        end
      end
    end
  end
end
