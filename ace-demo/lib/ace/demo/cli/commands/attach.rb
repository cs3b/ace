# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Demo
    module CLI
      module Commands
        class Attach < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Attach an existing demo recording to a PR"

          argument :file, required: true, desc: "Recording file path (GIF, MP4, WebM, or .cast)"
          option :pr, type: :string, desc: "PR number"
          option :dry_run, type: :boolean, aliases: ["-n"], default: false, desc: "Preview only"

          def call(file:, **options)
            pr = options[:pr]
            raise Ace::Support::Cli::Error, "PR number is required. Use --pr <number>." if pr.to_s.strip.empty?

            attacher = Organisms::DemoAttacher.new
            result = attacher.attach(file: file, pr: pr, dry_run: options[:dry_run])
            Atoms::AttachOutputPrinter.print(result)
          rescue ArgumentError, PrNotFoundError, GhAuthenticationError, GhUploadError, GhCommentError, GhCommandError,
            AggNotFoundError, AggExecutionError => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
