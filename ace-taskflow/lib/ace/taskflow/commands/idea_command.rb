# frozen_string_literal: true

module Ace
  module Taskflow
    module Commands
      class IdeaCommand
        def execute(args)
          content = args.join(" ")
          if content.empty?
            puts "Usage: ace-tf idea <your idea>"
            puts ""
            puts "Examples:"
            puts '  ace-tf idea "Add dark mode support"'
            puts '  ace-tf idea "Refactor authentication module"'
            exit 1
          end

          require_relative "../organisms/idea_writer"
          writer = Organisms::IdeaWriter.new
          path = writer.write(content)
          puts "Idea captured: #{path}"
        rescue => e
          puts "Error capturing idea: #{e.message}"
          exit 1
        end
      end
    end
  end
end