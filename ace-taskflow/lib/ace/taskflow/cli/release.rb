# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/release_command"

module Ace
  module Taskflow
    module CLI
      class Release < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Operations on single releases"
        example [
          '                 # Show active release',
          'start           # Start a new release'
        ]

        option :quiet, type: :boolean, aliases: %w[-q]
        option :verbose, type: :boolean, aliases: %w[-v]
        option :debug, type: :boolean, aliases: %w[-d]

        def call(**options)
          args = options[:args] || []
          Commands::ReleaseCommand.new.execute(args)
        end
      end
    end
  end
end
