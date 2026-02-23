# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/retro_manager"
require_relative "../../atoms/path_formatter"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command for creating a new retrospective reflection note.
        #
        # Dedicated command for `ace-retro create <title>` that treats
        # the positional argument as the retro title directly, avoiding
        # the subaction dispatching in the multi-purpose Retro command.
        class CreateRetro < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Create a new retrospective reflection note"

          argument :title, required: true, desc: "Title for the retro (e.g., 'Session learnings')"

          option :release, type: :string, desc: "Create in specific release"
          option :backlog, type: :boolean, desc: "Create in backlog"
          option :task, type: :string, aliases: %w[-t], desc: "Associate with task reference"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(title:, **options)
            release = determine_release(options)
            manager = Organisms::RetroManager.new
            result = manager.create_retro(title, release: release)

            unless result[:success]
              raise Ace::Core::CLI::Error.new(result[:message])
            end

            puts result[:message]
            relative_path = Atoms::PathFormatter.format_relative_path(result[:path], Dir.pwd)
            puts "Path: #{relative_path}"
          end

          private

          def determine_release(options)
            return "backlog" if options[:backlog]
            options[:release] || "current"
          end
        end
      end
    end
  end
end
