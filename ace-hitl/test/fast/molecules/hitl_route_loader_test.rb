# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Hitl
    module Molecules
      class HitlRouteLoaderTest < AceHitlTestCase
        def config(routes)
          {"hitl" => {"adapters" => {"routes" => routes}}}
        end

        def test_loads_single_route_with_default_name
          routes = HitlRouteLoader.load(config([{"adapter" => "terminal", "runtime" => "tmux", "pane" => "p5"}]))
          assert_equal 1, routes.size
          assert_equal "terminal", routes.first["route"]
          assert_equal "terminal", routes.first["adapter"]
          assert_equal "p5", routes.first["pane"]
        end

        def test_loads_multiple_routes_with_explicit_names
          routes = HitlRouteLoader.load(config([
            {"route" => "lab-terminal", "adapter" => "terminal", "runtime" => "herdr", "pane" => "p1"},
            {"route" => "captain-telegram", "adapter" => "hermes", "channel" => "project"}
          ]))
          assert_equal %w[lab-terminal captain-telegram], routes.map { |r| r["route"] }
        end

        def test_missing_routes_is_a_concrete_error
          error = assert_raises(HitlRouteLoader::NoRoutesError) do
            HitlRouteLoader.load({"hitl" => {}})
          end
          assert_includes error.message, "no adapter routes configured"
          assert_includes error.message, "hitl.adapters.routes"
        end

        def test_empty_routes_array_is_a_concrete_error
          assert_raises(HitlRouteLoader::NoRoutesError) do
            HitlRouteLoader.load(config([]))
          end
        end

        def test_non_array_routes_is_a_concrete_error
          assert_raises(HitlRouteLoader::NoRoutesError) do
            HitlRouteLoader.load(config({"adapter" => "terminal"}))
          end
        end

        def test_non_hash_entry_is_invalid
          error = assert_raises(HitlRouteLoader::InvalidRouteError) do
            HitlRouteLoader.load(config(["just-a-string"]))
          end
          assert_includes error.message, "must be a mapping"
        end

        def test_blank_adapter_is_invalid
          error = assert_raises(HitlRouteLoader::InvalidRouteError) do
            HitlRouteLoader.load(config([{"route" => "r"}]))
          end
          assert_includes error.message, "missing required 'adapter'"
        end

        def test_duplicate_route_names_are_invalid
          error = assert_raises(HitlRouteLoader::InvalidRouteError) do
            HitlRouteLoader.load(config([
              {"route" => "dup", "adapter" => "terminal", "runtime" => "tmux", "pane" => "p1"},
              {"route" => "dup", "adapter" => "terminal", "runtime" => "herdr", "pane" => "p2"}
            ]))
          end
          assert_includes error.message, "duplicate route name(s) dup"
        end

        def test_symbol_keys_are_normalized
          routes = HitlRouteLoader.load(config([{adapter: "terminal", runtime: "tmux", pane: "p9"}]))
          assert_equal "p9", routes.first["pane"]
        end

        def test_dotted_route_name_is_invalid_before_any_delivery
          error = assert_raises(HitlRouteLoader::InvalidRouteError) do
            HitlRouteLoader.load(config([{"route" => "captain.telegram", "adapter" => "hermes", "channel" => "project"}]))
          end
          assert_includes error.message, "'captain.telegram' is invalid"
          assert_includes error.message, "delivery retention keys route names literally"
        end

        def test_dashed_route_name_remains_supported
          routes = HitlRouteLoader.load(config([
            {"route" => "captain-telegram", "adapter" => "hermes", "channel" => "project"}
          ]))
          assert_equal "captain-telegram", routes.first["route"]
        end

        def test_invalid_recipient_selector_fails_before_delivery
          [[], "captain", [""], [false]].each do |invalid|
            assert_raises(HitlRouteLoader::InvalidRouteError) do
              HitlRouteLoader.load(config([{"adapter" => "terminal", "recipients" => invalid}]))
            end
          end
        end

        def test_matching_alias_does_not_hide_a_broken_selector
          cfg = config([{"adapter" => "terminal", "recipients" => ["captain", "missing"]}])
          address = {"machine" => "lab", "panel" => "captain"}
          cfg["hitl"]["recipients"] = {"captain" => address}
          assert_raises(HitlRouteLoader::InvalidRouteError) do
            HitlRouteLoader.for_recipient(HitlRouteLoader.load(cfg), recipient: address, config: cfg)
          end
        end
      end
    end
  end
end
