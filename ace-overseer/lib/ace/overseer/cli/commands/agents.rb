# frozen_string_literal: true
require "json"
module Ace
  module Overseer
    module CLI
      module Commands
        class Agents < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "List configured Lab agents"
          def initialize(client: nil)
            super()
            @client = client || Molecules::LabClient.new
          end
          def call(**)
            puts JSON.pretty_generate(@client.call("agents", "--json"))
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
