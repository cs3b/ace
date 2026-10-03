# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Task
    module CLI
      module Commands
        class IssueLink < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Link a task to one validated issue or clear its owned tracking artifacts"
          argument :ref, required: true, desc: "Task reference"
          option :issue, type: :string, desc: "Issue number or URL"
          option :clear, type: :boolean, desc: "Clear the existing issue link"
          option :server, type: :string, desc: "Named forge server"
          option :"default-server", type: :boolean, desc: "Use configured default forge server"

          def call(ref:, **options)
            if options[:clear] && (options[:issue] || options[:server] || options[:"default-server"])
              raise Ace::Support::Cli::Error, "--clear cannot combine with issue or server selection"
            end
            result = Ace::Task::Organisms::TaskManager.new.issue_link(
              ref, issue: options[:issue], clear: options[:clear],
              server_name: options[:server], use_default: options[:"default-server"]
            )
            raise Ace::Support::Cli::Error, "Task #{ref.inspect} not found" unless result

            puts(options[:clear] ? "Cleared issue link for #{result.id}" :
              "Linked #{result.id} to #{result.metadata.fetch('remote_issue').fetch('url')}")
          rescue Ace::Git::Error, ArgumentError => e
            raise Ace::Support::Cli::Error, e.message
          end
        end
      end
    end
  end
end
