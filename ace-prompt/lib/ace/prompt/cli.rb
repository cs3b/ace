# frozen_string_literal: true

require "thor"
require_relative "organisms/prompt_processor"

module Ace
  module Prompt
    # Thor CLI for ace-prompt
    class CLI < Thor
      def self.exit_on_failure?
        false
      end

      desc "process", "Read prompt, archive it, and output to stdout or file (default command)"
      long_desc <<~DESC
        Read prompt file, archive it with timestamp, update symlink, and output content.

        By default:
        - Reads from .cache/ace-prompt/prompts/the-prompt.md
        - Archives to .cache/ace-prompt/prompts/archive/YYYYMMDD-HHMMSS.md
        - Updates _previous.md symlink
        - Outputs to stdout

        EXAMPLES:

          # Basic usage (stdout)
          $ ace-prompt

          # Output to file
          $ ace-prompt --output /tmp/prompt.md

          # Explicit stdout
          $ ace-prompt --output -

        OUTPUT:

          By default, content is printed to stdout.
          Use --output to save to a file instead.
      DESC
      option :output, type: :string, aliases: "-o",
                      desc: "Write content to file instead of stdout (use '-' for explicit stdout)"
      def process
        # Process prompt
        result = Organisms::PromptProcessor.call

        unless result[:success]
          warn "Error: #{result[:error]}"
          return 1
        end

        # Handle output
        output_mode = options[:output] || "-"

        if output_mode == "-"
          # Output to stdout
          puts result[:content]
          return 0
        else
          # Write to file
          require "fileutils"
          FileUtils.mkdir_p(File.dirname(output_mode))

          begin
            File.write(output_mode, result[:content], encoding: "utf-8")
            # Output summary to stdout
            $stdout.puts "Prompt archived and saved:"
            $stdout.puts "  Archive: #{result[:archive_path]}"
            $stdout.puts "  Output:  #{File.expand_path(output_mode)}"
            return 0
          rescue StandardError => e
            warn "Error writing output file: #{e.message}"
            return 1
          end
        end
      rescue Ace::Prompt::Error => e
        warn "Error: #{e.message}"
        return 1
      end

      default_task :process

      desc "version", "Show version"
      def version
        puts Ace::Prompt::VERSION
      end

      map %w[-v --version] => :version
    end
  end
end
