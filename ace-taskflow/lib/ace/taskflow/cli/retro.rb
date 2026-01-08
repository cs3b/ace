# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/retro_command"

module Ace
  module Taskflow
    module CLI
      class Retro < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Operations on single retrospective notes"
        example ['create "Session learnings"']

        option :quiet, type: :boolean, aliases: %w[-q]
        option :verbose, type: :boolean, aliases: %w[-v]
        option :debug, type: :boolean, aliases: %w[-d]

        def call(**options)
          args = options[:args] || []
          Commands::RetroCommand.new.execute(args)
        end
      end
    end
  end
end
