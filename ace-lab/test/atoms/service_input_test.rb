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
