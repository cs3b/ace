# frozen_string_literal: true

require "dry/cli"

module Ace
  module Core
    module CLI
      module DryCli
        # Helper for creating standard version commands in dry-cli.
        #
        # This module provides a factory method to build version commands
        # that display gem version information in a consistent format.
        #
        # @example Creating a version command
        #   require "ace/core/cli/dry_cli/version_command"
        #
        #   # In your CLI registry:
        #   module MyGem
        #     module CLI
        #       extend Dry::CLI::Registry
        #
        #       # Build and register the version command
        #       version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        #         gem_name: "my-gem",
        #         version: MyGem::VERSION
        #       )
        #       register "version", version_cmd
        #       register "--version", version_cmd
        #     end
        #   end
        #
        # @note IMPORTANT: -v is reserved for --verbose (per ADR-018)
        #       Version is ONLY available via --version flag
        #
        # @see https://dry-rb.org/gems/dry-cli/ dry-cli documentation
        module VersionCommand
          # Build a version command class.
          #
          # @param gem_name [String] Name of the gem (e.g., "ace-review")
          # @param version [String] Version string (e.g., "0.1.0")
          # @return [Class] A Dry::CLI::Command subclass
          #
          # @example
          #   version_cmd = VersionCommand.build(
          #     gem_name: "ace-review",
          #     version: "0.5.2"
          #   )
          #   register "version", version_cmd
          def self.build(gem_name:, version:)
            Class.new(Dry::CLI::Command) do
              # Store gem_name and version as class variables
              @gem_name = gem_name
              @version = version

              class << self
                attr_reader :gem_name, :version
              end

              # Command description
              desc "Show version information"

              # Output the version string
              #
              # @return [Integer] Exit code (0 for success)
              def call(*)
                puts "#{self.class.gem_name} #{self.class.version}"
                0
              end
            end
          end

          # Create a version command module for inclusion.
          #
          # This is useful when you want to define a version command
          # as a module that can be included in other classes.
          #
          # @param gem_name [String] Name of the gem
          # @param version [Proc] A proc that returns the version string
          # @return [Module] A module with version command behavior
          #
          # @example
          #   version_module = VersionCommand.module(
          #     gem_name: "my-gem",
          #     version: -> { MyGem::VERSION }
          #   )
          #
          #   class MyCommand < Dry::CLI::Command
          #     include version_module
          #
          #     def call(**options)
          #       if options[:version]
          #         return show_version
          #       end
          #       # ... normal command logic ...
          #     end
          #   end
          def self.module(gem_name:, version:)
            Module.new do
              define_method(:show_version) do
                puts "#{gem_name} #{version.call}"
                0
              end
            end
          end
        end
      end
    end
  end
end
