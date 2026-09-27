# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Send < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Send a command, raw text, or named keys to a pane

            Input reaches the pane in declaration order. Panes hosting a
            live agent get prompt semantics: text becomes one self-submitting
            agent prompt (agent_blocked is rejected pre-send) and a single
            trailing --key Enter is dropped and reported.
          DESC

          example [
            "--pane p5 --cmd 'bundle exec rake test'",
            "--pane p5 --msg 'continue with option 2' --key Enter",
            "--pane p5 --key Esc --cmd 'reset'",
            "--pane p5 --key Enter",
            "--pane p5 --cmd 'y' --quiet"
          ]

          option :pane, type: :string, desc: "Target pane id"
          option :cmd, type: :string, aliases: %w[-c], desc: "Command text to submit (at most one, before any --key)"
          option :msg, type: :string, aliases: %w[-m], repeat: true, desc: "Literal text to type without submitting"
          option :key, type: :string, aliases: %w[-k], repeat: true, desc: "Named key to send (for example enter, esc, ctrl+c)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil, argv_source: nil)
            @executor = executor
            @argv_source = argv_source
          end

          def call(**options)
            translate_errors do
              cli_error("--pane is required") if options[:pane].to_s.empty?
              control = Organisms::ControlSurface.new(executor: executor)
              result = control.send_input(pane: options.fetch(:pane), tokens: input_tokens(options))
              puts JSON.generate(result) unless options[:quiet]
            end
          end

          private

          # Declaration order carries meaning (spec 8wq.t.k84), so the argv
          # token stream is the source of truth for real invocations. Parsed
          # option arrays only back programmatic calls with no input flags on
          # the command line (canonical order: cmd, msgs, keys).
          def input_tokens(options)
            argv_tokens(@argv_source || ARGV) || option_tokens(options)
          end

          def argv_tokens(argv)
            tokens = []
            seen_input_flag = false
            index = 0
            while index < argv.length
              token = argv[index]
              if (match = token.match(/\A(--cmd|-c|--msg|-m|--key|-k)=(.*)\z/m))
                seen_input_flag = true
                tokens << {type: flag_type(match[1]), value: match[2]}
                index += 1
              elsif (flag = %w[--cmd -c --msg -m --key -k].include?(token) && token)
                seen_input_flag = true
                tokens << {type: flag_type(flag), value: argv[index + 1]}
                index += 2
              else
                index += 1
              end
            end
            seen_input_flag ? tokens : nil
          end

          def flag_type(flag)
            case flag
            when "--cmd", "-c" then :cmd
            when "--msg", "-m" then :msg
            else :key
            end
          end

          def option_tokens(options)
            tokens = []
            tokens << {type: :cmd, value: options[:cmd]} if options[:cmd]
            Array(options[:msg]).each { |value| tokens << {type: :msg, value: value} }
            Array(options[:key]).each { |value| tokens << {type: :key, value: value} }
            tokens
          end
        end
      end
    end
  end
end
