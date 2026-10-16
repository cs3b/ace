# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Inspect < Ace::Support::Cli::Command
          desc "Capture three widths and automatic findings; manual/source review remains separate"
          argument :url, required: true, desc: "HTTP(S) URL"
          option :surface, type: :string, required: true, desc: "site or app"
          option :out, type: :string, desc: "New or empty evidence directory"
          option :json, type: :boolean, default: false
          def call(url:, surface: nil, out: nil, json: false, **)
            report = Organisms::Inspector.new.run(url: url, surface: surface, out: out)
            json ? CLI.output(report.slice("status", "surface", "report_path", "errors"), json: true) : puts("#{report['status']}: #{report['report_path']} #{Array(report['errors']).join('; ')}")
            {"pass" => 0, "findings" => 1, "incomplete" => 2}.fetch(report["status"])
          end
        end
      end
    end
  end
end
