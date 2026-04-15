# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Internal command used by tmux-backed fork panes to launch the provider session once.
        class ForkSession < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Run one provider-backed fork session for a subtree"

          option :assignment, required: true, desc: "Target assignment ID"
          option :root, required: true, desc: "Fork subtree root step number"
          option :provider, desc: "LLM provider:model override (e.g., codex:gpt-5, claude:sonnet)"
          option :cli_args, desc: "Extra CLI args for provider process"
          option :timeout, type: :integer, desc: "Execution timeout in seconds"
          option :cache_dir, desc: "Assignment cache directory override"
          option :last_message_file, desc: "Explicit path for fork last-message capture"
          option :session_meta_file, desc: "Explicit path for fork session metadata"

          def initialize(launcher: nil)
            super()
            @launcher = launcher || Molecules::ForkSessionLauncher.new
          end

          def call(**options)
            launcher.launch_provider_session(
              assignment_id: options[:assignment],
              fork_root: options[:root],
              provider: options[:provider],
              cli_args: options[:cli_args],
              timeout: options[:timeout],
              cache_dir: options[:cache_dir],
              last_message_file: options[:last_message_file],
              session_meta_file: options[:session_meta_file]
            )

            0
          rescue Error, Ace::LLM::Error => e
            warn e.message
            1
          end

          private

          attr_reader :launcher
        end
      end
    end
  end
end
