# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module B36ts
    module Commands
      class ConfigCommandTest < Minitest::Test
        def setup
          Ace::B36ts.reset_config!
        end

        # ===================
        # Basic Output Tests
        # ===================

        def test_execute_returns_success
          capture_io do
            exit_code = ConfigCommand.execute
            assert_equal 0, exit_code
          end
        end

        def test_execute_shows_year_zero
          output, = capture_io do
            ConfigCommand.execute
          end

          assert_match(/year_zero: 2000/, output)
        end

        def test_execute_shows_alphabet
          output, = capture_io do
            ConfigCommand.execute
          end

          assert_match(/alphabet: 0123456789abcdefghijklmnopqrstuvwxyz/, output)
        end

        def test_execute_shows_header
          output, = capture_io do
            ConfigCommand.execute
          end

          assert_match(/Current ace-b36ts configuration/, output)
        end

        # ===================
        # Verbose Mode Tests
        # ===================

        def test_execute_verbose_shows_config_sources
          output, = capture_io do
            ConfigCommand.execute(verbose: true)
          end

          assert_match(/Configuration sources/, output)
          assert_match(/Project config/, output)
          assert_match(/User config/, output)
          assert_match(/Gem defaults/, output)
        end

        def test_execute_verbose_shows_year_range
          output, = capture_io do
            ConfigCommand.execute(verbose: true)
          end

          assert_match(/Year range: 2000 to 2107/, output)
        end

        def test_execute_verbose_shows_id_details
          output, = capture_io do
            ConfigCommand.execute(verbose: true)
          end

          assert_match(/ID length: 6 characters/, output)
          assert_match(/Time precision: ~1.85 seconds/, output)
        end

        def test_execute_non_verbose_hides_extra_details
          output, = capture_io do
            ConfigCommand.execute(verbose: false)
          end

          refute_match(/Configuration sources/, output)
          refute_match(/Year range/, output)
        end
      end
    end
  end
end
