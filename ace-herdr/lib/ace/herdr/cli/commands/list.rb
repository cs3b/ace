# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class List < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            List live herdr panes, tabs, or workspaces as one JSON line

            Panes are the default scope; --workspace scopes panes and tabs.
          DESC

          example [
            "                         # Panes across all workspaces",
            "--workspace w1           # Panes in one workspace",
            "--tabs --workspace w1    # Tabs in one workspace",
            "--workspaces             # Workspaces"
          ]

          option :panes, type: :boolean, desc: "List panes (default)"
          option :tabs, type: :boolean, desc: "List tabs"
          option :workspaces, type: :boolean, desc: "List workspaces"
          option :workspace, type: :string, desc: "Scope panes/tabs to a workspace id"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              scope = selected_scope(options)
              cli_error("Use only one of --panes, --tabs, or --workspaces") if scope == :ambiguous
              cli_error("--workspaces does not accept --workspace") if scope == :workspaces && options[:workspace]

              control = Organisms::ControlSurface.new(executor: executor)
              payload =
                case scope
                when :workspaces
                  {workspaces: control.list_workspaces}
                when :tabs
                  {tabs: control.list_tabs(workspace_id: options[:workspace])}
                else
                  {panes: control.list_panes(workspace_id: options[:workspace])}
                end
              puts JSON.generate(payload) unless options[:quiet]
            end
          end

          private

          def selected_scope(options)
            scopes = %i[panes tabs workspaces].select { |key| options[key] }
            return :ambiguous if scopes.length > 1

            scopes.first || :panes
          end
        end
      end
    end
  end
end
