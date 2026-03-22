# frozen_string_literal: true

require "ace/core/molecules/frontmatter_free_policy"

module Ace
  module Docs
    module Atoms
      # Matches markdown files that are managed without frontmatter.
      class FrontmatterFreeMatcher
        def self.match?(path, patterns:, project_root: Dir.pwd)
          Ace::Core::Molecules::FrontmatterFreePolicy.match?(
            path,
            patterns: patterns,
            project_root: project_root
          )
        end
      end
    end
  end
end
