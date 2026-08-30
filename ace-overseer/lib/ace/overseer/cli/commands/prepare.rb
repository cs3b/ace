# frozen_string_literal: true
module Ace
  module Overseer
    module CLI
      module Commands
        class Prepare < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "Prepare a Work through the Lab runtime"
          option :runtime, required: true, desc: "Runtime (lab)"
          option :project, required: true, desc: "Lab project slug"
          option :source, required: true, desc: "Source KIND:ID"
          option :work, required: true, desc: "Work ID"
          option :planner, required: true, desc: "Planner agent ID"
          option :title, required: true, desc: "Reviewed Work title"
          def initialize(client: nil)
            super()
            @client = client || Molecules::LabClient.new
          end
          def call(runtime:, project:, source:, work:, planner:, title:, **)
            raise Ace::Support::Cli::Error, "unsupported runtime: #{runtime}" unless runtime == "lab"
            puts @client.call(
              "work", "prepare", project,
              "--source", source,
              "--work", work,
              "--planner", planner,
              "--title", title,
              json: false
            )
          rescue Ace::Support::Cli::Error
            raise
          rescue => error
            raise Ace::Support::Cli::Error.new(error.message)
          end
        end
      end
    end
  end
end
