# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/organisms/navigation_engine"

module Ace
  module Support
    module Nav
      module Organisms
        class NavigationEngineTest < Minitest::Test
          Template = Struct.new(:protocol, :path, :content, keyword_init: true)

          def test_create_defaults_to_ace_handbook_root
            test_dir = create_temp_ace_directory
            template = Template.new(
              protocol: "wfi",
              path: "/tmp/release/publish.wf.md",
              content: "# Publish"
            )
            resolver = Struct.new(:template) do
              def resolve(_uri_string)
                template
              end
            end.new(template)

            Dir.chdir(test_dir) do
              engine = NavigationEngine.new(resource_resolver: resolver)
              result = engine.create("wfi://release/publish")

              assert_equal File.join(test_dir, ".ace-handbook", "workflow-instructions", "publish.wf.md"), result[:created]
              assert_equal "# Publish", File.read(result[:created])
            end
          ensure
            cleanup_temp_directory(test_dir)
          end
        end
      end
    end
  end
end
