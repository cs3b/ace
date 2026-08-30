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
            if @input.respond_to?(:tty?) && @input.tty?
              raise Ace::Support::Cli::Error, "prompt text is required on stdin"
            end

            prompt = @input.read
            raise Ace::Support::Cli::Error, "prompt text is required on stdin" if prompt.empty?

            puts @client.call("work", "prompt", work, stdin_data: prompt, json: false)
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
