# frozen_string_literal: true

require "dry/cli"

module Ace
  module Idea
    module CLI
      module Commands
        # dry-cli Command class for ace-idea show
        class Show < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Show idea details

            Displays an idea by reference (full 6-char ID or last 3-char shortcut).

          DESC

          example [
            'q7w                    # Formatted display (default)',
            '8ppq7w --path          # Print file path only',
            'q7w --content          # Print raw markdown content'
          ]

          argument :ref, required: true, desc: "Idea reference (6-char ID or 3-char shortcut)"

          option :path,    type: :boolean, desc: "Print file path only"
          option :content, type: :boolean, desc: "Print raw markdown content"

          option :quiet,   type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug,   type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            manager = Ace::Idea::Organisms::IdeaManager.new
            idea = manager.show(ref)

            unless idea
              raise Ace::Core::CLI::Error.new("Idea '#{ref}' not found")
            end

            if options[:path]
              puts idea.file_path
            elsif options[:content]
              puts File.read(idea.file_path)
            else
              puts Ace::Idea::Molecules::IdeaDisplayFormatter.format(idea, show_content: true)
            end
          end
        end
      end
    end
  end
end
