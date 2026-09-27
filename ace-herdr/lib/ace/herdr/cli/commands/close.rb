# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Close < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Rename and/or close a finished agent pane, returning the result
          DESC

          example [
            "--pane p5 --rename done",
            "--pane p5",
            "--pane p5 --keep --rename 'review done'"
          ]

          option :pane, type: :string, desc: "Target pane id"
          option :rename, type: :string, desc: "New pane label applied before closing"
          option :keep, type: :boolean, desc: "Rename only; do not close the pane"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              cli_error("--pane is required") if options[:pane].to_s.empty?
              renamed = false
              closed = false
              if options[:rename]
                executor.pane_rename(options.fetch(:pane), options[:rename])
                renamed = true
              end
              unless options[:keep]
                executor.pane_close(options.fetch(:pane))
                closed = true
              end
              puts JSON.generate(pane: options.fetch(:pane), renamed: renamed, closed: closed)
            end
          end
        end
      end
    end
  end
end
