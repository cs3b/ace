# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Retro
    module CLI
      module Commands
        # ace-support-cli Command class for ace-retro show
        class Show < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Show retro details

            Displays a retro by reference (full 6-char ID or last 3-char shortcut).

          DESC

          example [
            "q7w                    # Formatted display (default)",
            "8ppq7w --path          # Print file path only",
            "q7w --content          # Print raw markdown content"
          ]

          argument :ref, required: true, desc: "Retro reference (6-char ID or 3-char shortcut)"

          option :path, type: :boolean, desc: "Print file path only"
          option :content, type: :boolean, desc: "Print raw markdown content"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref:, **options)
            manager = Ace::Retro::Organisms::RetroManager.new
            retro = manager.show(ref)

            unless retro
              raise Ace::Support::Cli::Error.new("Retro '#{ref}' not found")
            end

            if options[:path]
              puts retro.file_path
            elsif options[:content]
              puts File.read(retro.file_path)
            else
              puts Ace::Retro::Molecules::RetroDisplayFormatter.format(retro, show_content: true)
            end
          end
        end
      end
    end
  end
end
