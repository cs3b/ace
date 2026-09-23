# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesContractTest < AceHermesTestCase
          def test_contract_versions_and_bounds_are_pinned
            assert_equal "ace.hitl.hermes.folder/v1", HermesContract::FOLDER_CONTRACT
            assert_equal "ace.hitl.hermes.message/v1", HermesContract::MESSAGE_SCHEMA
            assert_equal 65_536, HermesContract::MAX_BYTES
            assert_equal 0o640, HermesContract::FILE_MODE
            assert_equal 0o600, HermesContract::TMP_MODE
            assert_equal 0o750, HermesContract::QUARANTINE_DIR_MODE
            assert_equal ".json", HermesContract::MESSAGE_EXT
            assert_equal ".hermes-tmp-", HermesContract::TMP_PREFIX
            assert_equal ".quarantine", HermesContract::QUARANTINE_DIR
          end

          def test_verify_folder_accepts_private_writable_directory
            with_hermes_dir do |folder|
              assert_equal folder, HermesContract.verify_folder!(folder)
            end
          end

          def test_verify_folder_fails_closed_on_missing_non_dir_unwritable_world_writable
            with_hermes_dir do |tmp|
              missing = File.join(tmp, "nope")
              error = assert_raises(ContractError) { HermesContract.verify_folder!(missing) }
              assert_match(/does not exist/, error.message)

              file = write_file(File.join(tmp, "plain"), "x")
              error = assert_raises(ContractError) { HermesContract.verify_folder!(file) }
              assert_match(/not a directory/, error.message)

              ro = File.join(tmp, "ro")
              Dir.mkdir(ro)
              File.chmod(0o555, ro)
              error = assert_raises(ContractError) do
                HermesContract.verify_folder!(File.join(tmp, "ro"))
              end
              assert_match(/not writable/, error.message)

              world = File.join(tmp, "world")
              Dir.mkdir(world)
              File.chmod(0o777, world)
              error = assert_raises(ContractError) { HermesContract.verify_folder!(world) }
              assert_match(/world-writable/, error.message)
            end
          end

          def test_file_name_and_parse_round_trip
            assert_equal "inbox-1.json", HermesContract.file_name("inbox-1")
            assert_equal "inbox-1", HermesContract.parse_file_name("inbox-1.json")
            assert_nil HermesContract.parse_file_name("notes.txt")
            assert_nil HermesContract.parse_file_name(".hidden.json")
            assert_nil HermesContract.parse_file_name("bad/name.json")
            assert_nil HermesContract.parse_file_name(".hermes-tmp-x.tmp")
          end

          def test_message_and_quarantine_paths
            with_hermes_dir do |folder|
              assert_equal File.join(folder, "m1.json"),
                HermesContract.message_path(folder, "m1")
              assert_equal File.join(folder, ".quarantine"),
                HermesContract.quarantine_path(folder)
            end
          end

          def test_schema_asset_is_shipped_and_valid_json
            path = HermesContract.schema_asset_path
            assert File.file?(path), "schema asset missing at #{path}"
            schema = JSON.parse(File.read(path))
            assert_equal HermesContract::MESSAGE_SCHEMA, schema["$id"]
            assert_equal %w[id kind schema sender], schema["required"].sort
            assert_equal HermesContract::MESSAGE_SCHEMA, schema["properties"]["schema"]["const"]
            assert_equal ["question", "answer"], schema["properties"]["kind"]["enum"]
            bodies = schema["oneOf"].map { |branch| branch["required"].sort }
            assert_includes bodies, %w[answer received_at]
            assert_includes bodies, %w[created_at question]
          end
        end
      end
    end
  end
end
