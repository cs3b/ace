# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Validate < Ace::Support::Cli::Command
          desc "Validate shipped/custom knowledge cards, or a session and its selection"
          argument :session, required: false, desc: "Optional session directory"
          option :catalog, type: :string, desc: "Custom catalog directory"
          option :json, type: :boolean, default: false
          def call(session: nil, catalog: nil, json: false, **)
            raise Error, "Choose SESSION or --catalog, not both" if session && catalog
            result = if session
              Molecules::Session.new(CLI.session_path(session)).validate
            else
              Molecules::Catalog.new.validate(catalog || File.join(Design.gem_root, "handbook/catalog"))
            end
            json ? CLI.output(result, json: true) : puts(YAML.dump(result))
            result.fetch("errors", []).empty? ? 0 : 1
          end
        end
      end
    end
  end
end
