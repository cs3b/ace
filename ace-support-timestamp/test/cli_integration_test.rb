# frozen_string_literal: true

require_relative "test_helper"

module Ace
  module Support
    module Timestamp
      # End-to-end CLI integration tests that execute the actual binary
      # and validate the full pipeline from command line to output.
      class CLIIntegrationTest < Minitest::Test
        def setup
          @exe_path = File.expand_path("../exe/ace-timestamp", __dir__)
          @bundle_exec = "bundle exec"
        end

        # ===================
        # Encode-Decode Roundtrip
        # ===================

        def test_cli_encode_decode_roundtrip_2sec_format
          # Encode a specific time
          encoded = run_cli("encode '2025-06-15 12:30:45 UTC'")
          assert_match(/\A[0-9a-z]{6}\n\z/, encoded, "Should produce 6-char ID")

          # Decode it back
          decoded = run_cli("decode #{encoded.strip}")
          assert_match(/2025-06-15/, decoded, "Decoded should contain original date")
          assert_match(/12:3\d/, decoded, "Decoded should contain approximate time")
        end

        def test_cli_encode_decode_roundtrip_all_formats
          time = "2025-06-15 12:30:45 UTC"

          # Test each format
          {
            month: { length: 2, date_match: /2025-06/ },
            day: { length: 3, date_match: /2025-06-15/ },
            week: { length: 3, date_match: /2025-06/ },
            "40min": { length: 4, date_match: /2025-06-15/ },
            "2sec": { length: 6, date_match: /2025-06-15/ },
            "50ms": { length: 7, date_match: /2025-06-15/ },
            ms: { length: 8, date_match: /2025-06-15/ }
          }.each do |format, expected|
            encoded = run_cli("encode --format #{format} '#{time}'")
            assert_match(/\A[0-9a-z]{#{expected[:length]}}\n\z/, encoded,
                         "#{format} format should produce #{expected[:length]}-char ID")

            decoded = run_cli("decode #{encoded.strip}")
            assert_match(expected[:date_match], decoded,
                         "#{format} decoded should match expected date pattern")
          end
        end

        # ===================
        # Error Handling
        # ===================

        def test_cli_decode_invalid_id_returns_error
          result = run_cli("decode invalid!!!", expect_error: true)
          assert_match(/error/i, result)
        end

        def test_cli_encode_invalid_format_returns_error
          result = run_cli("encode --format nonexistent '2025-06-15'", expect_error: true)
          assert_match(/error/i, result)
        end

        # ===================
        # Help and Version
        # ===================

        def test_cli_help
          # Note: dry-cli returns exit code 1 for --help (standard behavior)
          result = run_cli("--help", expect_error: true)
          assert_match(/encode/i, result)
          assert_match(/decode/i, result)
        end

        def test_cli_version
          result = run_cli("version")
          assert_match(/\d+\.\d+\.\d+/, result)
        end

        private

        def run_cli(args, expect_error: false)
          cmd = "#{@bundle_exec} ruby #{@exe_path} #{args} 2>&1"
          output = `#{cmd}`
          status = $?.exitstatus

          if expect_error
            # For error cases, we expect non-zero exit and return stderr output
            output
          else
            assert_equal 0, status, "CLI should exit with 0 for: #{args}\nOutput: #{output}"
            output
          end
        end
      end
    end
  end
end
