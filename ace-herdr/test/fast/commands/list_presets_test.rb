# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class ListPresetsTest < Minitest::Test
          # Control-surface stub with a fixed in-memory inventory
          class StubControl
            PRESET_TYPES = %w[workspaces tabs].freeze

            def initialize(presets)
              @presets = presets
            end

            def list_presets(type: nil)
              unless type.nil? || PRESET_TYPES.include?(type)
                raise Ace::Herdr::ValidationError,
                  "Unknown preset type '#{type}' (available: #{PRESET_TYPES.join(', ')})"
              end

              return @presets unless type

              {type => @presets.fetch(type, [])}
            end
          end

          def stub_control
            StubControl.new("workspaces" => ["development"], "tabs" => ["agent"])
          end

          def test_lists_all_types_as_json
            cmd = ListPresets.new(control: stub_control)

            out, = capture_io { cmd.call(type: nil) }

            parsed = JSON.parse(out)
            assert_equal ["development"], parsed["workspaces"]
            assert_equal ["agent"], parsed["tabs"]
          end

          def test_scopes_to_one_type
            cmd = ListPresets.new(control: stub_control)

            out, = capture_io { cmd.call(type: "tabs") }

            parsed = JSON.parse(out)
            assert_equal ["agent"], parsed["tabs"]
            assert_nil parsed["workspaces"]
          end

          def test_rejects_unknown_type
            cmd = ListPresets.new(control: stub_control)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(type: "sessions")
            end

            assert_match(/Unknown preset type/, error.message)
          end
        end
      end
    end
  end
end
