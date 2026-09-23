# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesQuarantineTest < AceHermesTestCase
          def test_moves_file_and_writes_reason_sidecar
            with_hermes_dir do |folder|
              path = message_file(folder, "bad-1", {"broken" => true})
              now = Time.utc(2026, 9, 24, 10, 0, 0)

              dest = HermesQuarantine.move(
                folder, path, reason: "not valid JSON", now: -> { now }
              )

              assert_equal File.join(folder, ".quarantine", "bad-1.json"), dest
              assert_equal %({"broken":true}), File.read(dest)
              refute File.exist?(path)

              sidecar = File.read("#{dest}#{HermesContract::REASON_EXT}")
              assert_equal "2026-09-24T10:00:00Z not valid JSON\n", sidecar
              assert_equal 0o750, (File.stat(File.join(folder, ".quarantine")).mode & 0o777)
              assert_equal 0o640, (File.stat("#{dest}#{HermesContract::REASON_EXT}").mode & 0o777)
            end
          end

          def test_name_collisions_get_numeric_suffixes
            with_hermes_dir do |folder|
              first = message_file(folder, "bad-1", {"n" => 1})
              dest1 = HermesQuarantine.move(folder, first, reason: "one")
              second = message_file(folder, "bad-1", {"n" => 2})
              dest2 = HermesQuarantine.move(folder, second, reason: "two")

              assert_equal File.join(folder, ".quarantine", "bad-1.json"), dest1
              assert_equal File.join(folder, ".quarantine", "bad-1.json.1"), dest2
              assert File.exist?(dest1)
              assert File.exist?(dest2)
            end
          end
        end
      end
    end
  end
end
