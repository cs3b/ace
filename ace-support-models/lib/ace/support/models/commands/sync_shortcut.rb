# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module Commands
        # Top-level shortcut for cache sync
        class SyncShortcut < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Sync from models.dev (shortcut for: cache sync)"

          option :force, type: :boolean, aliases: ["-f"], desc: "Force sync even if cache is fresh"
          option :json, type: :boolean, desc: "Output as JSON"

          example [
            "          # Sync cache",
            "--force   # Force sync even if cache is fresh"
          ]

          def call(**options)
            Cache::Sync.new.call(**options)
          end
        end
      end
    end
  end
end
