# frozen_string_literal: true

require "ace/bundle"
require "ace/test_support"
require_relative "support/command_mock_helper"
require_relative "support/pr_mock_fixtures"

# AceTestCase is provided by ace-support-test-helpers with all helpers

# Enable command mocking for all tests to ensure deterministic, fast execution
CommandMockHelper.enable_mocking!

# Test suite defaults to exact compression to avoid external LLM agent execution.
unless ENV["ACE_BUNDLE_ALLOW_AGENT_COMPRESSION"] == "1"
  module Ace
    module Bundle
      module Molecules
        class SectionCompressor
          prepend Module.new do
            def initialize(default_mode: "off", compressor_mode: "exact", cache_store: nil, **kwargs)
              super(
                default_mode: default_mode,
                compressor_mode: compressor_mode.to_s == "agent" ? "exact" : compressor_mode,
                cache_store: cache_store,
                **kwargs
              )
            end
          end
        end
      end
    end
  end

  module Ace
    module Compressor
      class << self
        prepend Module.new do
          def compress_text(content, **kwargs)
            super(content, **kwargs.merge(mode: "exact"))
          end
        end
      end
    end
  end
end
