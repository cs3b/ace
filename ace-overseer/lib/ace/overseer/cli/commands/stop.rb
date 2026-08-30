# frozen_string_literal: true
module Ace
  module Overseer
    module CLI
      module Commands
        class Stop < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Stop a Lab Work"
          option :work, required: true, desc: "Work ID"
          def initialize(client: nil)
            super()
            @client = client || Molecules::LabClient.new
          end
          def call(work:, **)
            puts @client.call("work", "stop", work, json: false)
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
