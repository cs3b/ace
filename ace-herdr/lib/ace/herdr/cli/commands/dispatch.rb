# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Dispatch < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Start an agent in one command: tab + agent start + prompt

            Defaults are deterministic: the caller's workspace, the label as
            agent and pane name, the prompt from a file or stdin. Zero-token.
          DESC

          example [
            "--label 8wm.t.vs0 --kind pi --prompt-file prompt.md",
            "--label review --pane p7 --cwd /Users/me/project",
            "--label 8wm.t.vs0 --no-prompt"
          ]

          option :label, type: :string, desc: "Agent and pane label (typically the task id)"
          option :kind, type: :string, desc: "Agent kind (default: config default_agent_kind)"
          option :workspace, type: :string, desc: "Target workspace (default: caller's workspace)"
          option :pane, type: :string, desc: "Existing pane (default: create a new tab)"
          option :cwd, type: :string, desc: "Working directory for a created tab"
          option :prompt_file, type: :string, desc: "Prompt file (default: stdin)"
          option :no_prompt, type: :boolean, desc: "Start the agent without submitting a prompt"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              cli_error("--label is required") if options[:label].to_s.empty?
              prompt =
                if options[:no_prompt]
                  ""
                else
                  read_content(options[:prompt_file], what: "prompt")
                end
              dispatcher = Organisms::Dispatcher.from_config(executor: executor, config: config)
              outcome = dispatcher.dispatch(
                label: options.fetch(:label), prompt: prompt,
                kind: options[:kind], workspace_id: options[:workspace],
                pane: options[:pane], cwd: options[:cwd]
              )
              puts JSON.generate(outcome.to_h)
            end
          end
        end
      end
    end
  end
end
