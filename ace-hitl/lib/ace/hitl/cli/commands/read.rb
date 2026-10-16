# frozen_string_literal: true
require "ace/support/cli"
require_relative "lifecycle_command"
module Ace
  module Hitl
    module CLI
      module Commands
        class Read < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include LifecycleCommand
          desc "Read authenticated nonsecret lifecycle facts for one request"
          argument :id, required: true, desc: "Request ID"
          def call(id:, **)
            emit(lifecycle_client.read(id))
          rescue Lifecycle::Error, Providers::ProviderUnavailableError => e
            raise_lifecycle_error(e.message)
          end
        end
      end
    end
  end
end
