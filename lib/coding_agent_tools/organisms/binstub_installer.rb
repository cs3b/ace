# frozen_string_literal: true

require_relative "../atoms/yaml_reader"
require_relative "../molecules/binstub_generator"
require_relative "../molecules/file_operation_confirmer"

module CodingAgentTools
  module Organisms
    # BinstubInstaller - Organism for installing and managing binstubs
    #
    # Responsibilities:
    # - Coordinate the binstub installation process
    # - Load configuration and generate binstubs
    # - Write binstub files to the filesystem
    # - Handle file permissions and confirmations
    # - Provide comprehensive installation reporting
    class BinstubInstaller
      attr_reader :config_path, :target_directory

      def initialize(config_path, target_directory)
        @config_path = config_path
        @target_directory = target_directory
        @operation_confirmer = CodingAgentTools::Molecules::FileOperationConfirmer.new
      end

      # Installs all binstubs defined in the configuration
      #
      # @param options [Hash] Installation options
      # @option options [Boolean] :force (false) Whether to overwrite existing files
      # @option options [Boolean] :verbose (false) Whether to provide verbose output
      # @return [Hash] Installation results
      def install_all(options = {})
        force = options.fetch(:force, false)
        verbose = options.fetch(:verbose, false)

        # Load configuration
        config = CodingAgentTools::Atoms::YamlReader.read_file(config_path)
        puts "Loaded binstub configuration from #{config_path}" if verbose

        # Generate binstubs
        binstubs = CodingAgentTools::Molecules::BinstubGenerator.generate_all_binstubs(config)
        puts "Generated #{binstubs.size} binstubs" if verbose

        # Install each binstub
        results = {
          installed: [],
          skipped: [],
          errors: []
        }

        binstubs.each do |alias_name, content|
          file_path = File.join(target_directory, alias_name)

          begin
            if File.exist?(file_path) && !force
              if should_overwrite?(file_path, alias_name)
                write_binstub_file(file_path, content, verbose)
                results[:installed] << alias_name
              else
                results[:skipped] << alias_name
                puts "Skipped: #{alias_name}" if verbose
              end
            else
              write_binstub_file(file_path, content, verbose)
              results[:installed] << alias_name
            end
          rescue => e
            results[:errors] << {alias: alias_name, error: e.message}
            puts "Error installing #{alias_name}: #{e.message}" if verbose
          end
        end

        results
      end

      # Installs a specific binstub by name
      #
      # @param alias_name [String] Name of the binstub to install
      # @param options [Hash] Installation options
      # @return [Boolean] Whether installation was successful
      def install_specific(alias_name, options = {})
        force = options.fetch(:force, false)
        verbose = options.fetch(:verbose, false)

        config = CodingAgentTools::Atoms::YamlReader.read_file(config_path)

        unless config["aliases"]&.key?(alias_name)
          raise CodingAgentTools::Error, "Alias '#{alias_name}' not found in configuration"
        end

        alias_config = config["aliases"][alias_name]
        content = CodingAgentTools::Molecules::BinstubGenerator.generate_shell_binstub(alias_name, alias_config)

        file_path = File.join(target_directory, alias_name)

        if File.exist?(file_path) && !force
          return false unless should_overwrite?(file_path, alias_name)
        end

        write_binstub_file(file_path, content, verbose)
        true
      end

      # Lists all available binstub aliases from configuration
      #
      # @return [Array<String>] List of alias names
      def list_available_aliases
        config = CodingAgentTools::Atoms::YamlReader.read_file(config_path)
        config["aliases"]&.keys || []
      end

      private

      # Asks user whether to overwrite an existing file
      #
      # @param file_path [String] Path to the existing file
      # @param alias_name [String] Name of the alias
      # @return [Boolean] Whether to overwrite
      def should_overwrite?(file_path, alias_name)
        result = @operation_confirmer.confirm_overwrite(file_path)
        result.confirmed?
      end

      # Writes binstub content to file with proper permissions
      #
      # @param file_path [String] Target file path
      # @param content [String] Binstub content
      # @param verbose [Boolean] Whether to provide verbose output
      def write_binstub_file(file_path, content, verbose)
        File.write(file_path, content)
        File.chmod(0o755, file_path)  # Make executable
        puts "Installed: #{File.basename(file_path)}" if verbose
      end
    end
  end
end
