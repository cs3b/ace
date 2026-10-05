# frozen_string_literal: true
require "json"
require_relative "../../../authority/launch_driver"
module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class Terminate < Ace::Support::Cli::Command
            desc "Close the original gated native child and request proven abort"
            option :mapping, required: true, desc: "Installed launch mapping ID"
            option :assignment, required: true, desc: "Assignment ID"
            option :attempt, required: true, desc: "Attempt ID"
            def call(**options)
              client = Ace::Assign::Authority::Client.new(mapping_id: options.fetch(:mapping))
              state = client.call("inspect_launch", {"assignment_id" => options.fetch(:assignment), "attempt_id" => options.fetch(:attempt)}).data
              binding = state.fetch("process_binding") { raise ArgumentError, "no positively recorded original child; supervisor inspection required" }
              result = Ace::Assign::Authority::LaunchDriver.new(mapping_id: options.fetch(:mapping)).terminate(
                state: state, binding: binding, evidence: "launcher observed exact original native close and pre-acquired child pidfd exit")
              puts JSON.generate(result)
            rescue ArgumentError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            end
          end
        end
      end
    end
  end
end
