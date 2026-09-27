# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Guards
      # ace-herdr is a deterministic, zero-token wrapper (spec 8wm.t.vs0):
      # no LLM integration may enter the gem.
      class NoLlmGuardTest < Minitest::Test
        FORBIDDEN = %w[
          ace-llm
          ace_llm
          OpenAI
          Anthropic
        ].freeze

        def test_no_llm_references_in_library_or_gemspec
          files = Dir.glob(File.expand_path("lib/**/*.rb", gem_root)) +
            Dir.glob(File.expand_path("*.gemspec", gem_root))

          assert files.length >= 10, "guard must scan the real sources"

          files.each do |path|
            body = File.read(path)
            FORBIDDEN.each do |marker|
              refute body.include?(marker),
                "#{path} must not reference #{marker.inspect} (zero-token rule)"
            end
          end
        end

        private

        def gem_root
          File.expand_path("../..", __dir__)
        end
      end
    end
  end
end
