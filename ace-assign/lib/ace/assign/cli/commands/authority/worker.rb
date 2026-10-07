# frozen_string_literal: true
require_relative "../../../authority/prepared_worker"

module Ace
  module Assign
    module CLI
      module Commands
        module Authority
          class Worker < Ace::Support::Cli::Command
            desc "Consume the original authenticated prepared subtree as its fixed worker"

            def call(**options)
              raise ArgumentError, "fixed worker accepts no options" unless options.empty?
              Ace::Assign::Authority::PreparedWorker.new.run
            rescue ArgumentError, Ace::Runtime::Error, Ace::Assign::Error => error
              raise Ace::Support::Cli::Error, error.message
            end
          end
        end
      end
    end
  end
end
