# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../molecules/config_loader"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the config command
        #
        # This command shows the current ace-taskflow configuration.
        class Config < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Show current ace-taskflow configuration"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"

          def call(**options)
            config_loader = Molecules::ConfigLoader.load

            puts "ace-taskflow Configuration:"
            puts "=" * 50
            puts "Root directory: #{config_loader['root']}"
            puts "Task directory: #{config_loader['task_dir']}"
            puts "Active strategy: #{config_loader['active_strategy']}"
            puts "Allow multiple active: #{config_loader['allow_multiple_active']}"
            puts ""
            puts "References:"
            puts "  Allow qualified: #{config_loader['references']['allow_qualified']}"
            puts "  Allow cross-release: #{config_loader['references']['allow_cross_release']}"
            puts ""
            puts "Defaults:"
            puts "  Idea location: #{config_loader['defaults']['idea_location']}"
            puts "  Task location: #{config_loader['defaults']['task_location']}"
          end
        end
      end
    end
  end
end
