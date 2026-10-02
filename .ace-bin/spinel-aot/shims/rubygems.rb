# frozen_string_literal: true

# Minimal RubyGems stub for Spinel-compiled ace binaries.
#
# ace gems use exactly one RubyGems API: Gem.loaded_specs["gem-name"]
# with a `.gem_dir` fallback to File.expand_path("../..", __dir__).
# With an empty registry, every caller takes the source-tree fallback,
# which resolves correctly as long as the .rb sources ship beside the
# binary (true for this pilot; embedding defaults for fully standalone
# distribution is a follow-up — see REPORT.md).

module Gem
  class Specification
    def initialize(dir)
      @dir = dir
    end

    def gem_dir
      @dir
    end
  end

  REGISTRY = {}

  def self.loaded_specs
    REGISTRY
  end
end
