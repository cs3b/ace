# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Atoms
    module Claude
      # Checks if a command file exists in various locations
      # This is a pure utility with no dependencies on other components
      class CommandExistenceChecker
        # Find command file in search paths
        # @param command_name [String] Name of the command (without .md)
        # @param search_paths [Array<Pathname>] Paths to search
        # @return [Pathname, nil] Path to command file if found
        def self.find(command_name, search_paths)
          return nil if command_name.nil? || command_name.empty?
          return nil if search_paths.nil? || search_paths.empty?

          search_paths.each do |path|
            next unless path.is_a?(Pathname) && path.exist? && path.directory?

            command_path = path / "#{command_name}.md"
            return command_path if command_path.exist? && command_path.file?
          end

          nil
        end

        # Check if command exists in any of the search paths
        # @param command_name [String] Name of the command
        # @param search_paths [Array<Pathname>] Paths to search
        # @return [Boolean] True if command exists
        def self.exists?(command_name, search_paths)
          !find(command_name, search_paths).nil?
        end

        # Find all command files in given paths
        # @param search_paths [Array<Pathname>] Paths to search
        # @return [Array<Hash>] Array of hashes with :name and :path
        def self.find_all(search_paths)
          commands = []
          return commands if search_paths.nil? || search_paths.empty?

          search_paths.each do |path|
            next unless path.is_a?(Pathname) && path.exist? && path.directory?

            Dir.glob(File.join(path, '*.md')).each do |file_path|
              pathname = Pathname.new(file_path)
              # Skip README files
              next if pathname.basename.to_s.downcase == 'readme.md'

              commands << {
                name: pathname.basename('.md').to_s,
                path: pathname
              }
            end
          end

          commands.uniq { |cmd| cmd[:name] }
        end
      end
    end
  end
end
