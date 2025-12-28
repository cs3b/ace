# frozen_string_literal: true

require "test_helper"

module Ace
  module Config
    module Models
      class ConfigTest < TestCase
        def test_initialize_with_data
          config = Config.new({ "key" => "value" }, source: "test")

          assert_equal({ "key" => "value" }, config.data)
          assert_equal "test", config.source
        end

        def test_get_value
          config = Config.new({ "a" => { "b" => { "c" => "value" } } })

          assert_equal "value", config.get("a", "b", "c")
          assert_equal({ "b" => { "c" => "value" } }, config.get("a"))
        end

        def test_get_with_symbols
          config = Config.new({ "a" => { "b" => "value" } })

          assert_equal "value", config.get(:a, :b)
        end

        def test_get_missing_key_returns_nil
          config = Config.new({ "a" => 1 })

          assert_nil config.get("missing")
          assert_nil config.get("a", "b", "c")
        end

        def test_key?
          config = Config.new({ "a" => { "b" => "value" } })

          assert config.key?("a")
          assert config.key?("a", "b")
          refute config.key?("missing")
        end

        def test_to_h
          data = { "key" => "value" }
          config = Config.new(data)

          result = config.to_h

          assert_equal data, result
          refute_same data, result # Should be a copy
        end

        def test_keys
          config = Config.new({ "a" => 1, "b" => 2 })

          assert_equal %w[a b], config.keys
        end

        def test_empty?
          assert Config.new({}).empty?
          refute Config.new({ "a" => 1 }).empty?
        end

        def test_each
          config = Config.new({ "a" => 1, "b" => 2 })
          collected = []

          config.each { |k, v| collected << [k, v] }

          assert_equal [["a", 1], ["b", 2]], collected
        end

        def test_with_merges_data
          config = Config.new({ "a" => 1, "b" => 2 })

          result = config.with({ "b" => 3, "c" => 4 })

          assert_equal({ "a" => 1, "b" => 3, "c" => 4 }, result.data)
          assert_includes result.source, "+merged"
        end

        def test_equality
          config1 = Config.new({ "a" => 1 }, source: "test", merge_strategy: :deep)
          config2 = Config.new({ "a" => 1 }, source: "test", merge_strategy: :deep)
          config3 = Config.new({ "a" => 2 }, source: "test", merge_strategy: :deep)

          assert_equal config1, config2
          refute_equal config1, config3
        end

        def test_frozen
          config = Config.new({ "a" => 1 })

          assert config.frozen?
        end
      end
    end
  end
end
