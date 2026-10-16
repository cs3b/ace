# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Doctor < Ace::Support::Cli::Command
          desc "Check Node, pinned Playwright/axe and Chromium without installing anything"
          option :json, type: :boolean, default: false
          def call(json: false, **)
            result = Molecules::Runtime.new.doctor
            json ? CLI.output(result, json: true) : puts(result["ready"] ? "Browser runtime ready" : "Browser runtime unavailable: #{result['error']}")
            result["ready"] ? 0 : 1
          end
        end
      end
    end
  end
end
