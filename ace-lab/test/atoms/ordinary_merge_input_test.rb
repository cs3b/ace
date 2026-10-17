# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    class OrdinaryMergeInputTest < Minitest::Test
      def test_canonical_digest_ignores_object_key_order
        left = {"target" => {"resource" => "release"}, "args" => {"b" => 2, "a" => 1}}
        right = {"args" => {"a" => 1, "b" => 2}, "target" => {"resource" => "release"}}
        assert_equal Atoms::OrdinaryMergeInput.digest(left), Atoms::OrdinaryMergeInput.digest(right)
      end

      def test_held_input_refuses_links_oversize_and_strict_json_collisions
        Dir.mktmpdir do |dir|
          path = File.join(dir, "input.json")
          File.write(path, '{"target":{"resource":"release"}}')
          assert_equal "release", Atoms::OrdinaryMergeInput.load(path).fetch("target").fetch("resource")
          link = File.join(dir, "link.json")
          File.symlink(path, link)
          assert_raises(ArgumentError) { Atoms::OrdinaryMergeInput.load(link) }
          assert_raises(ArgumentError) { Atoms::OrdinaryMergeInput.load(dir) }
          File.write(path, " " * (Atoms::OrdinaryMergeInput::MAX_BYTES + 1))
          assert_raises(ArgumentError) { Atoms::OrdinaryMergeInput.load(path) }
          ['{"target":{},"target":{}}', '{"targ\\u0065t":{},"target":{}}',
            '{/*comment*/"target":{}}', '{"value":NaN}', '{"value":' + '[' * 17 + '0' + ']' * 17 + '}'].each do |raw|
            File.write(path, raw)
            assert_raises(ArgumentError, raw) { Atoms::OrdinaryMergeInput.load(path) }
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
          File.stub(:open, reader) { assert_raises(ArgumentError) { Atoms::OrdinaryMergeInput.load(path) } }
        end
      end

      def test_rejects_secret_fields
        Dir.mktmpdir do |dir|
          path = File.join(dir, "input.json")
          File.write(path, JSON.generate({"target" => {"resource" => "release"}, "access_token" => "secret"}))
          assert_raises(ArgumentError) { Atoms::OrdinaryMergeInput.load(path) }
        end
      end
    end
  end
end
