# frozen_string_literal: true

require "test_helper"
require "ace/support/config/models/config_templates"

module Ace
  module Support
    module Config
      module Models
        class ConfigTemplatesTest < TestCase
          def test_reset_clears_memoized_gem_info
            ConfigTemplates.instance_variable_set(:@gem_info, {"ace-demo" => {source: :local, path: "/tmp/ace-demo"}})

            ConfigTemplates.reset!

            assert_nil ConfigTemplates.instance_variable_get(:@gem_info)
          end
        end
      end
    end
  end
end
