# frozen_string_literal: true
module Ace
  module Overseer
    module CLI
      module Commands
        class Prompt < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Prompt a running Lab Work from stdin"
          option :work, required: true, desc: "Work ID"
          def initialize(client: nil, input: $stdin)
            super()
            @client = client || Molecules::LabClient.new
            @input = input
          end
          def call(work:, **)
            puts @client.call("work", "prompt", work, stdin_data: @input.read, json: false)
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
