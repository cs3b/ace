# frozen_string_literal: true

require "ace/support/cli"
require_relative "lifecycle_command"
require_relative "../../proposals/evaluator"

module Ace
  module Hitl
    module CLI
      module Commands
        class Proposal < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand
          argument :operation, required: true, desc: "create, show, revise, history or resolve-due"
          argument :id, required: false, desc: "Exact proposal ID"
          option :assignment, type: :string
          option :attempt, type: :string
          option :project, type: :string
          option :file, type: :string
          option :"expected-revision", type: :integer, desc: "Exact source revision for revise"
          option :"operation-id", type: :string, desc: "Caller-persisted revision- plus 24 lowercase hex digits"
          option :format, type: :string, default: "json"
          option :now, type: :string, desc: "Unavailable in production; inject a fixture clock in tests"
          option :"history-after", type: :integer, desc: "Read the next bounded history page from history_next"
          option :query, type: :string, desc: "Relevant prior decisions containing this text"
          option :after, type: :string, desc: "History-list cursor from next"

          def call(operation:, id: nil, **options)
            raise_lifecycle_error("only --format json is supported") unless options[:format] == "json"
            raise_lifecycle_error("--now is restricted to injected test fixtures; production uses trusted UTC clock") if options[:now]
            result = case operation
            when "create"
              %i[assignment attempt project].each { |key| raise_lifecycle_error("--#{key} required") if options[key].to_s.empty? }
              raise_lifecycle_error("stable proposal ID required") if id.to_s.empty?
              lifecycle_client.proposal_create(id: id, assignment: options[:assignment], attempt: options[:attempt],
                project: options[:project], document: load_document(options[:file]))
            when "show"
              raise_lifecycle_error("proposal ID required") if id.to_s.empty?
              raise_lifecycle_error("--project required") if options[:project].to_s.empty?
              lifecycle_client.proposal_show(id, project: options[:project], history_after: options[:"history-after"] || 0)
            when "revise"
              raise_lifecycle_error("proposal ID required") if id.to_s.empty?
              raise_lifecycle_error("--expected-revision required") unless options[:"expected-revision"]
              raise_lifecycle_error("--operation-id required") if options[:"operation-id"].to_s.empty?
              raise_lifecycle_error("--project required") if options[:project].to_s.empty?
              lifecycle_client.proposal_revise(id, project: options[:project], expected_revision: options[:"expected-revision"],
                operation_id: options[:"operation-id"], document: load_document(options[:file]))
            when "resolve-due"
              raise_lifecycle_error("--project required") if options[:project].to_s.empty?
              Proposals::Evaluator.new(boundary: lifecycle_client, project: options[:project]).call
            when "history"
              raise_lifecycle_error("--project required") if options[:project].to_s.empty?
              lifecycle_client.proposal_history(project: options[:project], query: options[:query] || "", after: options[:after])
            else raise_lifecycle_error("choose create, show, revise, history or resolve-due")
            end
            emit(result)
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end

          private

          def load_document(path)
            raise_lifecycle_error("--file required") if path.to_s.empty?
            content = File.open(path, "rb") { |file| file.read(4097) }
            raise_lifecycle_error("proposal file exceeds 4096 bytes") if content.bytesize > 4096
            JSON.parse(content)
          rescue JSON::ParserError, SystemCallError
            raise_lifecycle_error("proposal file must be readable JSON")
          end
        end
      end
    end
  end
end
