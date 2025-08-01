# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/idea_capture"

module CodingAgentTools
  module Cli
    module Commands
      module Ideas
        class Capture < Dry::CLI::Command
          desc "Capture and enhance raw ideas for the project"

          argument :idea_text, desc: "Raw idea text to capture and enhance"

          option :clipboard, type: :boolean, default: false, desc: "Read idea from clipboard"
          option :file, type: :string, desc: "Read idea from file path"
          option :model, type: :string, default: "google:gemini-2.5-flash-lite", desc: "LLM model to use for enhancement"
          option :debug, type: :boolean, default: false, desc: "Show detailed error information and processing flow"
          option :big_user_input_allowed, type: :boolean, default: false, desc: "Allow inputs over 1000 words"
          option :commit, type: :boolean, default: false, desc: "Automatically commit the generated idea file"

          def call(idea_text: nil, **options)
            # Initialize idea capture organism
            idea_capture = CodingAgentTools::Organisms::IdeaCapture.new(
              model: options[:model],
              debug: options[:debug],
              big_user_input_allowed: options[:big_user_input_allowed],
              commit_after_capture: options[:commit]
            )

            # Determine input source
            input_text = determine_input(idea_text, options)

            # Capture and enhance the idea
            result = idea_capture.capture_idea(input_text)

            if result.success?
              puts "Created: #{result.output_path}"
            else
              puts "Error: #{result.error_message}"
              exit 1
            end
          rescue => e
            if options[:debug]
              puts "Debug: Full error details:"
              puts e.message
              puts e.backtrace.join("\n")
            else
              puts "Error: #{e.message}"
            end
            exit 1
          end

          private

          def determine_input(idea_text, options)
            if options[:clipboard]
              read_from_clipboard
            elsif options[:file]
              read_from_file(options[:file])
            elsif idea_text && !idea_text.strip.empty?
              idea_text
            else
              puts "Error: No input provided. Use idea text argument, --clipboard, or --file options."
              puts "Usage: capture-it 'your idea text'"
              puts "       capture-it --clipboard"
              puts "       capture-it --file path/to/file.txt"
              exit 1
            end
          end

          def read_from_clipboard
            # Try different clipboard commands based on OS
            clipboard_commands = [
              "pbpaste",  # macOS
              "xclip -selection clipboard -o",  # Linux with xclip
              "xsel --clipboard --output",  # Linux with xsel
              "powershell.exe Get-Clipboard"  # Windows with WSL
            ]

            clipboard_commands.each do |cmd|
              content = `#{cmd} 2>/dev/null`.strip
              return content unless content.empty? || $?.exitstatus != 0
            rescue
              next
            end

            puts "Error: Could not read from clipboard. Please install pbpaste (macOS), xclip/xsel (Linux), or use text input."
            exit 1
          end

          def read_from_file(file_path)
            unless File.exist?(file_path)
              puts "Error: File not found: #{file_path}"
              exit 1
            end

            unless File.readable?(file_path)
              puts "Error: File not readable: #{file_path}"
              exit 1
            end

            begin
              content = File.read(file_path).strip
              if content.empty?
                puts "Error: File is empty: #{file_path}"
                exit 1
              end
              content
            rescue => e
              puts "Error reading file #{file_path}: #{e.message}"
              exit 1
            end
          end
        end
      end
    end
  end
end
