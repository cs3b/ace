# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Adjust < Ace::Support::Cli::Command
          desc "Update project decisions and compose effective design profiles"
          option :surface, type: :string, desc: "site or app; inferred from profile"
          option :kind, type: :string, desc: "view or component"
          option :profile, type: :string, desc: "Profile and ancestors; otherwise the surface branch"
          option :prompt, type: :string, desc: "New user decision (adjust only)"
          option :dry_run, type: :boolean, default: false, desc: "Resolve without model calls or writes"
          option :propose, type: :boolean, default: false, desc: "Compose with a model without publishing"
          option :model, type: :string, desc: "Override composition model"
          option :json, type: :boolean, default: false
          def call(json: false, **options)
            result = Organisms::Adjuster.new.adjust(refresh: self.is_a?(Refresh), **options.except(:args))
            CLI.output(result, json: json)
            %w[planned published proposed unchanged].include?(result["status"]) ? 0 : 2
          end
        end
        class Refresh < Adjust
          desc "Refresh installed library defaults; preserve user.md bytes"
        end
        class Context < Ace::Support::Cli::Command
          desc "Read effective design assumptions without models"
          option :surface, type: :string
          option :kind, type: :string
          option :profile, type: :string
          option :json, type: :boolean, default: false
          def call(surface: nil, kind: nil, profile: nil, json: false, **)
            surface, kind = Molecules::DesignSource.scope(surface: surface, kind: kind, profile: profile)
            result = Molecules::DesignContext.new.snapshot(surface: surface, kind: kind, context: profile)
            json ? CLI.output(result, json: true) : puts(result.fetch("document"))
            0
          end
        end
      end
    end
  end
end
