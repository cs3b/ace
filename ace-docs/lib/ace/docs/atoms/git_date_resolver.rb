# frozen_string_literal: true

require_relative "../molecules/git_date_resolver"

module Ace
  module Docs
    module Atoms
      # Compatibility shim: delegated to molecule implementation.
      class GitDateResolver
        def self.last_updated_for(path)
          Molecules::GitDateResolver.last_updated_for(path)
        end
      end
    end
  end
end
