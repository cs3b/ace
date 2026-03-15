# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Attach < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc "Attach an existing demo recording to a PR"

          argument :file, required: true, desc: "Recording file path (GIF, MP4, or WebM)"
          option :pr, type: :string, desc: "PR number"
          option :dry_run, type: :boolean, aliases: ["-n"], default: false, desc: "Preview only"

          def call(file:, **options)
            pr = options[:pr]
            raise Ace::Core::CLI::Error, "PR number is required. Use --pr <number>." if pr.to_s.strip.empty?

            attacher = Organisms::DemoAttacher.new
            result = attacher.attach(file: file, pr: pr, dry_run: options[:dry_run])
            Atoms::AttachOutputPrinter.print(result)
          rescue ArgumentError, PrNotFoundError, GhAuthenticationError, GhUploadError, GhCommentError, GhCommandError => e
            raise Ace::Core::CLI::Error, e.message
          end
        end
      end
    end
  end
end
