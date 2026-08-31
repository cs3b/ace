# frozen_string_literal: true
module Ace
  module Overseer
    module CLI
      module Commands
        class Prompt < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Prompt a running Lab Work from stdin"
          option :work, required: true, desc: "Work ID"
          option :file, desc: "Read prompt text from a file instead of stdin"
          def initialize(client: nil, input: $stdin)
            super()
            @client = client || Molecules::LabClient.new
            @input = input
          end
          def call(work:, file: nil, **)
            if file
              prompt = File.read(file)
            else
              if @input.respond_to?(:tty?) && @input.tty?
                raise Ace::Support::Cli::Error, "prompt text is required via --file or stdin"
              end
              prompt = @input.read
            end
            raise Ace::Support::Cli::Error, "prompt text must contain non-whitespace characters" if prompt.strip.empty?

            puts @client.call("work", "prompt", work, stdin_data: prompt, json: false)
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
