# frozen_string_literal: true

require "dry/cli"
require_relative "../molecules/config_loader"

module Ace
  module Taskflow
    module CLI
      class Config < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Show current ace-taskflow configuration"

        option :quiet, type: :boolean, aliases: %w[-q]
        option :verbose, type: :boolean, aliases: %w[-v]
        option :debug, type: :boolean, aliases: %w[-d]

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
          0
        end
      end
    end
  end
end
