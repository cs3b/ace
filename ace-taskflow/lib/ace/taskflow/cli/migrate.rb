# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/migrate_command"
require_relative "shared_options"

module Ace
  module Taskflow
    module CLI
      class Migrate < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base
        extend SharedOptions

        desc "Migrate folder structure to new naming convention"
        example [
          '             # Run migration',
          '--dry-run    # Preview changes',
          '--no-git     # Skip git mv'
        ]

        use_standard_options
        use_display_options
        use_action_options

        # Migrate-specific options
        option :no_git, type: :boolean, desc: "Don't use git mv (copy/delete instead)"

        def call(**options)
          args = options[:args] || []
          clean_options = options.reject { |k, _| k == :args }
          Commands::MigrateCommand.new.execute(args, clean_options)
        end
      end
    end
  end
end
