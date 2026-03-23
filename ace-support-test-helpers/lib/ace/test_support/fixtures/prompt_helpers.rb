# frozen_string_literal: true

module Ace
  module TestSupport
    module Fixtures
      # Helper methods for stubbing prompt resolution in tests
      #
      # These helpers avoid expensive subprocess calls to ace-nav during tests.
      module PromptHelpers
        # Stub resolve_prompt_path on a synthesizer to avoid ace-nav subprocess
        #
        # This saves ~150-400ms per call by using direct path instead of shelling out.
        #
        # @param synthesizer [Object] Any object with a resolve_prompt_path method
        # @param gem_root [String, nil] The gem root directory (auto-detected from caller if nil)
        #
        # @example
        #   stub_prompt_path(synthesizer)  # Auto-detects gem root from caller
        #   stub_prompt_path(synthesizer, "/path/to/gem")  # Explicit gem root
        #
        def stub_prompt_path(synthesizer, gem_root = nil)
          # Auto-detect gem root from caller's location if not provided
          # Works when called from test files in gem/test/ directory
          gem_root ||= detect_gem_root_from_caller

          prompts_dir = File.join(gem_root, "handbook", "prompts")

          synthesizer.define_singleton_method(:resolve_prompt_path) do |prompt_name|
            File.join(prompts_dir, prompt_name)
          end
        end

        # Alias for backwards compatibility with ace-review tests
        alias_method :stub_synthesizer_prompt_path, :stub_prompt_path

        private

        # Detect gem root from caller's location
        # Assumes tests are in gem/test/ directory structure
        #
        # @return [String] Path to gem root
        def detect_gem_root_from_caller
          # Get caller's file location
          caller_file = caller_locations(1, 1).first.absolute_path

          # Go up from test/ directory to gem root
          # Expected: gem_root/test/some_test.rb -> gem_root
          test_index = caller_file.rindex("/test/")
          if test_index
            caller_file[0...test_index]
          else
            # Fallback: assume we're in test/ and go up two levels
            File.expand_path("../..", caller_file)
          end
        end
      end
    end
  end
end
