# frozen_string_literal: true
require_relative "attempt/base"

module Ace
  module Assign
    module CLI
      module Commands
        class InboxBind < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Attempt::Base

          desc "Bind an original protected Inbox registration before scope closure"
          option :mapping, desc: "Exact installed mapping ID"
          option :assignment, desc: "Exact original assignment ID"
          option :attempt, desc: "Exact original attempt ID"
          option :event, desc: "Original Inbox event ID"
          option :inbox_context, desc: "Installed Inbox context ID"
          option :mutation, desc: "Stable original authority mutation ID"
          option :expected_generation, desc: "Original authority mutation generation"

          def call(**options)
            context = protected_context(options)
            raise AttemptErrors::EvidenceUnavailable, "Inbox binding requires installed protected authority" unless context
            usage = "inbox-bind --mapping MAP --assignment ID --attempt ID --event ID --inbox-context ID --mutation ID --expected-generation N"
            client, params, mutation = protected_attempt_request(context, options, usage)
            params.merge!("event_id" => require_option(options, :event, usage),
              "inbox_context_id" => require_option(options, :inbox_context, usage))
            emit_json(protected_call(client, "bind_inbox", params, mutation))
          end
        end
      end
    end
  end
end
