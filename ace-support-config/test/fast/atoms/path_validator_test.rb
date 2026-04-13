# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Atoms
        class PathValidatorTest < TestCase
          # === validate_segment! tests ===

          def test_validate_segment_accepts_valid_segment
            assert PathValidator.validate_segment!("valid_name")
            assert PathValidator.validate_segment!("docs")
            assert PathValidator.validate_segment!("nested-folder")
            assert PathValidator.validate_segment!("file.yml")
          end

          def test_validate_segment_rejects_path_traversal
            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("..")
            end
            assert_match(/path traversal not allowed/i, error.message)

            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("../secret")
            end
            assert_match(/path traversal not allowed/i, error.message)

            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("foo/../bar")
            end
            assert_match(/path traversal not allowed/i, error.message)
          end

          def test_validate_segment_rejects_unix_absolute_paths
            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("/etc/passwd")
            end
            assert_match(/absolute paths not allowed/i, error.message)
          end

          def test_validate_segment_rejects_windows_drive_paths
            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("C:\\Users")
            end
            assert_match(/absolute paths not allowed/i, error.message)

            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("D:")
            end
            assert_match(/absolute paths not allowed/i, error.message)
          end

          def test_validate_segment_rejects_windows_unc_paths
            error = assert_raises(ArgumentError) do
              PathValidator.validate_segment!("\\\\server\\share")
            end
            assert_match(/absolute paths not allowed/i, error.message)
          end

          # === validate_segments! tests ===

          def test_validate_segments_accepts_valid_array
            assert PathValidator.validate_segments!(["config", "nested", "file"])
            assert PathValidator.validate_segments!([])
            assert PathValidator.validate_segments!(["single"])
          end

          def test_validate_segments_rejects_if_any_invalid
            error = assert_raises(ArgumentError) do
              PathValidator.validate_segments!(["config", "..", "secret"])
            end
            assert_match(/path traversal not allowed/i, error.message)
          end

          # === valid_segment? tests (non-raising) ===

          def test_valid_segment_returns_true_for_valid
            assert PathValidator.valid_segment?("valid_name")
          end

          def test_valid_segment_returns_false_for_invalid
            refute PathValidator.valid_segment?("..")
            refute PathValidator.valid_segment?("/absolute")
          end

          # === valid_segments? tests (non-raising) ===

          def test_valid_segments_returns_true_for_valid
            assert PathValidator.valid_segments?(["config", "nested"])
          end

          def test_valid_segments_returns_false_for_invalid
            refute PathValidator.valid_segments?(["config", ".."])
          end
        end
      end
    end
  end
end
