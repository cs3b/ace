# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          desc "Show saved worker status and artifact paths"
          argument :session, required: true, desc: "Session token or directory"
          option :json, type: :boolean, default: false
          def call(session:, json: false, **)
            CLI.output(Organisms::DesignRun.new(CLI.session_path(session)).status, json: json)
          end
        end
        class Resume < Ace::Support::Cli::Command
          desc "Retry unfinished workers using saved inputs; preserve completed variants"
          argument :session, required: true, desc: "Session token or directory"
          option :json, type: :boolean, default: false
          def call(session:, json: false, **)
            result = Organisms::DesignRun.new(CLI.session_path(session)).resume
            CLI.output(result, json: json)
            result["status"] == "succeeded" ? 0 : 2
          end
        end
        class Revise < Ace::Support::Cli::Command
          desc "Revise one variant; preserve its last usable version on failure"
          argument :session, required: true, desc: "Session token or directory"
          option :variant, type: :string, required: true, desc: "Declared variant ID"
          option :prompt, type: :string, required: true, desc: "Targeted feedback"
          option :json, type: :boolean, default: false
          def call(session:, variant:, prompt:, json: false, **)
            result = Organisms::DesignRun.new(CLI.session_path(session)).revise(variant: variant, prompt: prompt)
            CLI.output(result, json: json)
            result.fetch("workers").fetch(variant)["status"] == "succeeded" ? 0 : 2
          end
        end
        class Select < Ace::Support::Cli::Command
          desc "Record an explicit selection bound to current variant and fixture bytes"
          argument :session, required: true, desc: "Session token or directory"
          option :variant, type: :string, required: true, desc: "Declared variant ID"
          option :decision, type: :string, required: true, desc: "Accepted decision; repeat for several"
          option :json, type: :boolean, default: false
          def call(session:, variant:, decision:, json: false, **)
            result = Organisms::DesignRun.new(CLI.session_path(session)).select(variant: variant, decisions: CLI.entries(decision))
            CLI.output(result.merge("status" => "selected"), json: json)
          end
        end
      end
    end
  end
end
