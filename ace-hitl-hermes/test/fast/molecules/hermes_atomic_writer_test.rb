# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesAtomicWriterTest < AceHermesTestCase
          def test_writes_atomically_with_contract_permissions
            with_hermes_dir do |folder|
              final = File.join(folder, "m1.json")
              result = HermesAtomicWriter.write(final, %({"id":"m1"}))

              assert_equal final, result
              assert_equal %({"id":"m1"}), File.read(final)
              assert_equal 0o640, (File.stat(final).mode & 0o777)
              assert_empty tmp_leftovers(folder)
            end
          end

          def test_refuses_root_fail_closed
            with_hermes_dir do |folder|
              final = File.join(folder, "m1.json")
              error = assert_raises(RootUserError) do
                HermesAtomicWriter.write(final, "x", euid_provider: -> { 0 })
              end
              assert_match(/without root/, error.message)
              refute File.exist?(final)
              assert_empty tmp_leftovers(folder)
            end
          end

          def test_collision_refuses_without_touching_the_existing_file
            with_hermes_dir do |folder|
              final = File.join(folder, "m1.json")
              write_file(final, "original")

              error = assert_raises(CollisionError) do
                HermesAtomicWriter.write(final, "replacement")
              end
              assert_match(/already exists/, error.message)
              assert_equal "original", File.read(final)
              assert_empty tmp_leftovers(folder)
            end
          end

          def test_folder_contract_is_enforced_before_writing
            with_hermes_dir do |folder|
              world = File.join(File.dirname(folder), "world")
              Dir.mkdir(world)
              File.chmod(0o777, world)
              error = assert_raises(ContractError) do
                HermesAtomicWriter.write(File.join(world, "m1.json"), "x")
              end
              assert_match(/world-writable/, error.message)
            end
          end
        end
      end
    end
  end
end
