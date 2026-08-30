# frozen_string_literal: true
module Ace
  module Overseer
    module CLI
      module Commands
        class Review < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Start an exact-head Lab review"
          option :work, required: true, desc: "Work ID"
          option :pr, required: true, type: :integer, desc: "Forgejo PR number"
          def initialize(client: nil)
            super()
            @client = client || Molecules::LabClient.new
          end
          def call(work:, pr:, **)
            puts @client.call("work", "review", work, "--pr", pr, json: false)
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
