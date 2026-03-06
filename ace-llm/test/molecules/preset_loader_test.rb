# frozen_string_literal: true

require "test_helper"

module Ace
  module LLM
    module Molecules
      class PresetLoaderTest < AceLlmTestCase
        StubConfigResult = Struct.new(:data) do
          def to_h
            data
          end
        end

        class StubResolver
          attr_reader :calls

          def initialize(result_data_by_filename = {}, errors_by_filename = {})
            @result_data_by_filename = result_data_by_filename
            @errors_by_filename = errors_by_filename
            @calls = []
          end

          def resolve_namespace(namespace, filename:)
            @calls << [namespace, filename]
            error = @errors_by_filename[filename]
            raise error if error

            StubConfigResult.new(@result_data_by_filename.fetch(filename, {}))
          end
        end

        def test_load_resolves_preset_from_llm_namespace
          resolver = StubResolver.new("presets/review-fast" => { "timeout" => 300, "max_tokens" => 2000 })

          Ace::Support::Config.stub(:create, resolver) do
            preset = PresetLoader.load("review-fast")

            assert_equal({ "timeout" => 300, "max_tokens" => 2000 }, preset)
          end

          assert_equal [["llm", "presets/review-fast"]], resolver.calls
        end

        def test_load_raises_error_when_preset_missing
          resolver = StubResolver.new

          Ace::Support::Config.stub(:create, resolver) do
            error = assert_raises(Ace::LLM::ConfigurationError) do
              PresetLoader.load("review-fast")
            end

            assert_match(/Preset 'review-fast' not found/, error.message)
          end
        end

        def test_load_raises_error_for_blank_name
          error = assert_raises(Ace::LLM::ConfigurationError) do
            PresetLoader.load("   ")
          end

          assert_match(/Preset name cannot be empty/, error.message)
        end

        def test_load_for_provider_overlays_provider_preset_on_global
          resolver = StubResolver.new(
            "presets/review-deep" => {
              "timeout" => 300,
              "max_tokens" => 8192,
              "cli_args" => ["--verbose"],
              "subprocess_env" => { "MODE" => "global", "SHARED" => "global" }
            },
            "presets/codex/review-deep" => {
              "timeout" => 900,
              "cli_args" => ["--model", "gpt-5.3-codex"],
              "subprocess_env" => { "MODE" => "codex" }
            }
          )

          Ace::Support::Config.stub(:create, resolver) do
            preset = PresetLoader.load_for_provider("codex", "review-deep")

            assert_equal 900, preset["timeout"]
            assert_equal 8192, preset["max_tokens"]
            assert_equal ["--model", "gpt-5.3-codex"], preset["cli_args"]
            assert_equal({ "MODE" => "codex", "SHARED" => "global" }, preset["subprocess_env"])
          end

          assert_equal [
            ["llm", "presets/review-deep"],
            ["llm", "presets/codex/review-deep"]
          ], resolver.calls
        end

        def test_load_for_provider_falls_back_to_global_when_provider_specific_missing
          resolver = StubResolver.new(
            "presets/review-fast" => { "timeout" => 300, "max_tokens" => 2000 }
          )

          Ace::Support::Config.stub(:create, resolver) do
            preset = PresetLoader.load_for_provider("codex", "review-fast")
            assert_equal({ "timeout" => 300, "max_tokens" => 2000 }, preset)
          end
        end

        def test_load_for_provider_supports_provider_only_preset
          resolver = StubResolver.new(
            "presets/codex/review-fast" => { "timeout" => 600, "max_tokens" => 4000 }
          )

          Ace::Support::Config.stub(:create, resolver) do
            preset = PresetLoader.load_for_provider("codex", "review-fast")
            assert_equal({ "timeout" => 600, "max_tokens" => 4000 }, preset)
          end
        end

        def test_load_for_provider_raises_when_global_and_provider_specific_missing
          resolver = StubResolver.new

          Ace::Support::Config.stub(:create, resolver) do
            error = assert_raises(Ace::LLM::ConfigurationError) do
              PresetLoader.load_for_provider("codex", "review-fast")
            end

            assert_match(/Preset 'review-fast' not found for provider 'codex'/, error.message)
          end
        end

        def test_load_for_provider_normalizes_provider_name_for_lookup
          resolver = StubResolver.new(
            "presets/codexoai/review-deep" => { "timeout" => 900 }
          )

          Ace::Support::Config.stub(:create, resolver) do
            preset = PresetLoader.load_for_provider("codex_oai", "review-deep")
            assert_equal({ "timeout" => 900 }, preset)
          end
        end

        def test_load_for_provider_raises_when_provider_name_blank
          error = assert_raises(Ace::LLM::ConfigurationError) do
            PresetLoader.load_for_provider(" ", "review-deep")
          end

          assert_match(/Provider name cannot be empty/, error.message)
        end

        def test_load_for_provider_preserves_invalid_provider_preset_error
          resolver = StubResolver.new(
            { "presets/review-fast" => { "timeout" => 300 } },
            { "presets/codex/review-fast" => StandardError.new("bad yaml") }
          )

          Ace::Support::Config.stub(:create, resolver) do
            error = assert_raises(Ace::LLM::ConfigurationError) do
              PresetLoader.load_for_provider("codex", "review-fast")
            end

            assert_match(/Failed to load preset 'review-fast' for provider 'codex'/, error.message)
            assert_match(/bad yaml/, error.message)
          end
        end
      end
    end
  end
end
