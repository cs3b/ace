# frozen_string_literal: true
require "json"
require_relative "../../../authority/client"
module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class Status < Ace::Support::Cli::Command
            desc "Inspect canonical protected launch ownership"
            option :mapping, required: true, desc: "Installed launch mapping ID"
            option :assignment, required: true, desc: "Assignment ID"
            option :attempt, required: true, desc: "Attempt ID"
            def call(**options)
              reply = Ace::Assign::Authority::Client.new(mapping_id: options.fetch(:mapping)).call("attempt_status",
                {"assignment_id" => options.fetch(:assignment), "attempt_id" => options.fetch(:attempt)})
              puts JSON.generate(reply.data)
            rescue ArgumentError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            end
          end
        end
      end
    end
  end
end
