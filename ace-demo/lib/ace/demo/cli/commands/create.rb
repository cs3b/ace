# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Create < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc "Create a new demo tape from shell commands"

          argument :name, required: true, desc: "Tape name (used as filename)"

          option :desc, type: :string, aliases: ["-D"], desc: "Description metadata"
          option :tags, type: :string, aliases: ["-T"], desc: "Comma-separated tags"
          option :width, type: :integer, default: 960, desc: "Terminal width in pixels"
          option :height, type: :integer, default: 480, desc: "Terminal height in pixels"
          option :font_size, type: :integer, default: 16, desc: "Font size"
          option :timeout, type: :string, aliases: ["-t"], default: "2s", desc: "Wait time after each command"
          option :format, type: :string, aliases: ["-f"], default: "gif", desc: "Output format: gif|mp4|webm"
          option :force, type: :boolean, default: false, desc: "Overwrite existing tape"
          option :dry_run, type: :boolean, aliases: ["-n"], default: false, desc: "Preview without writing"

          def call(name:, args: [], **options)
            commands = collect_commands(args)

            creator = Organisms::TapeCreator.new
            result = creator.create(
              name: name,
              commands: commands,
              description: options[:desc],
              tags: options[:tags],
              font_size: options[:font_size],
              width: options[:width],
              height: options[:height],
              timeout: options[:timeout],
              format: options[:format],
              force: options[:force],
              dry_run: options[:dry_run]
            )

            if result[:dry_run]
              puts result[:content]
            else
              puts "Created: #{result[:path]}"
            end
          rescue TapeAlreadyExistsError => e
            raise Ace::Core::CLI::Error, e.message
          end

          private

          def collect_commands(args)
            commands = args.reject { |a| a.strip.empty? }

            if commands.empty? && !$stdin.tty?
              commands = $stdin.read.lines.map(&:strip).reject(&:empty?)
            end

            if commands.empty?
              raise Ace::Core::CLI::Error, "No commands provided. Pass commands after -- or pipe via stdin."
            end

            commands
          end
        end
      end
    end
  end
end
