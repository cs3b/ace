# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Adapters
      class RegistryTest < AceHitlTestCase
        def setup
          Adapters.reset_registry!
        end

        def teardown
          Adapters.reset_registry!
        end

        def test_register_and_resolve
          Adapters.register(:fake, ->(_route) { :adapter })
          assert Adapters.registered?(:fake)
          assert_equal :adapter, Adapters.resolve("fake", route: {})
        end

        def test_factory_receives_route_config
          received = nil
          Adapters.register(:fake, ->(route) { received = route; :adapter })
          Adapters.resolve(:fake, route: {"route" => "r1", "adapter" => "fake", "pane" => "p5"})
          assert_equal "p5", received["pane"]
        end

        def test_unknown_adapter_lists_available
          error = assert_raises(UnknownAdapterError) do
            Adapters.resolve("nervus")
          end
          assert_includes error.message, "unknown HITL adapter 'nervus'"
          assert_includes error.message, "available:"
        end

        def test_factory_must_be_callable
          assert_raises(ArgumentError) { Adapters.register(:bad, Object.new) }
        end

        def test_entrypoint_convention_loads_adapter
          Dir.mktmpdir("hitl-adapter-entry") do |dir|
            entry_dir = File.join(dir, "ace", "hitl", "adapters")
            FileUtils.mkdir_p(entry_dir)
            File.write(File.join(entry_dir, "future.rb"), <<~RUBY)
              require "ace/hitl/adapters"
              Ace::Hitl::Adapters.register(:future, ->(_route) { :from_entrypoint })
            RUBY

            original_load_path = $LOAD_PATH.dup
            $LOAD_PATH.unshift(dir)
            begin
              assert_equal :from_entrypoint, Adapters.resolve("future")
            ensure
              $LOAD_PATH.replace(original_load_path)
              $LOADED_FEATURES.reject! { |path| path.include?("ace/hitl/adapters/future") }
            end
          end
        end

        def test_name_pattern_blocks_load_path_traversal
          assert_raises(UnknownAdapterError) { Adapters.resolve("../evil") }
        end

        def test_route_result_helpers
          result = RouteResult.new(route: "r", adapter: "a", status: :delivered, detail: nil)
          assert result.delivered?
          refute RouteResult.new(route: "r", adapter: "a", status: :failed, detail: "x").delivered?
        end
      end
    end
  end
end
