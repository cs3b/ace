# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    class ServiceInputTest < Minitest::Test
      def test_canonical_digest_ignores_object_key_order_and_binds_target
        left = {"target" => {"resource" => "release", "artifact_digest" => "a" * 64}, "args" => {"b" => 2, "a" => 1}}
        right = {"args" => {"a" => 1, "b" => 2}, "target" => {"artifact_digest" => "a" * 64, "resource" => "release"}}
        assert_equal Atoms::ServiceInput.digest(left), Atoms::ServiceInput.digest(right)
        assert_equal "release", Atoms::ServiceInput.target(left)["resource"]
      end

      def test_held_input_refuses_links_oversize_and_strict_json_collisions
        Dir.mktmpdir do |dir|
          path = File.join(dir, "input.json")
          File.write(path, '{"target":{"resource":"release"}}')
          assert_equal "release", Atoms::ServiceInput.load(path).fetch("target").fetch("resource")
          link = File.join(dir, "link.json")
          File.symlink(path, link)
          assert_raises(ArgumentError) { Atoms::ServiceInput.load(link) }
          assert_raises(ArgumentError) { Atoms::ServiceInput.load(dir) }
          File.write(path, " " * (Atoms::ServiceInput::MAX_BYTES + 1))
          assert_raises(ArgumentError) { Atoms::ServiceInput.load(path) }
          ['{"target":{},"target":{}}', '{"targ\\u0065t":{},"target":{}}',
            '{/*comment*/"target":{}}', '{"value":NaN}', '{"value":' + '[' * 17 + '0' + ']' * 17 + '}'].each do |raw|
            File.write(path, raw)
            assert_raises(ArgumentError, raw) { Atoms::ServiceInput.load(path) }
          end
        end
      end

      def test_held_input_refuses_path_replacement_during_read
        Dir.mktmpdir do |dir|
          path = File.join(dir, "input.json")
          File.write(path, '{"target":{"resource":"release"}}')
          original = File.method(:open)
          reader = lambda do |selected, *args, &block|
            original.call(selected, *args) do |file|
              real_read = file.method(:read)
              file.stub(:read, lambda { |bound|
                bytes = real_read.call(bound)
                File.rename(path, path + ".old")
                File.write(path, bytes)
                bytes
              }) { block.call(file) }
            end
          end
          File.stub(:open, reader) { assert_raises(ArgumentError) { Atoms::ServiceInput.load(path) } }
        end
      end

      def test_rejects_secret_fields_and_invalid_target
        Dir.mktmpdir do |dir|
          path = File.join(dir, "input.json")
          File.write(path, JSON.generate({"target" => {"resource" => "release"}, "access_token" => "secret"}))
          assert_raises(ArgumentError) { Atoms::ServiceInput.load(path) }
          assert_raises(ArgumentError) { Atoms::ServiceInput.target({"target" => {"artifact_digest" => "abc"}}) }
        end
      end
    end
  end
end
