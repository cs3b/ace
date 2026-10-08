# frozen_string_literal: true
require_relative "../test_helper"
load File.expand_path("../../../.ace-bin/ace-rubygems-publish", __dir__)

class ScopedRubygemsPublishTest < Ace::Handbook::TestCase
  def response(code, text)
    value = Gem::Net::HTTPResponse::CODE_TO_OBJ.fetch(code).new("1.1", code, "fixture")
    value.instance_variable_set(:@read, true)
    value.body = text
    value
  end

  def test_mfa_is_a_typed_stop_before_rubygems_automatic_retry
    publisher = ScopedPublicationPush.new
    missing = response("401", "You have enabled multifactor authentication. Missing OTP")
    previous = ENV.delete("GEM_HOST_OTP_CODE")
    error = assert_raises(ScopedPublicationPush::Stop) { publisher.mfa_unauthorized?(missing) }
    assert_equal "otp-required", error.classification
    secret = (1..6).to_a.join
    ENV["GEM_HOST_OTP_CODE"] = secret
    error = assert_raises(ScopedPublicationPush::Stop) { publisher.mfa_unauthorized?(missing) }
    assert_equal "otp-rejected", error.classification
    expired = response("401", "You have enabled multifactor authentication. OTP expired")
    error = assert_raises(ScopedPublicationPush::Stop) { publisher.mfa_unauthorized?(expired) }
    assert_equal "otp-expired", error.classification
    refute_includes error.message, secret
  ensure
    previous ? ENV["GEM_HOST_OTP_CODE"] = previous : ENV.delete("GEM_HOST_OTP_CODE")
  end

  def test_success_is_not_approval_without_independent_registry_digest
    publisher = ScopedPublicationPush.new
    publisher.with_response(response("200", "Successfully registered gem"))
    assert_equal({"classification" => "uncertain", "code" => "registry_verification_required"}, publisher.instance_variable_get(:@scoped_result))
    publisher.with_response(response("403", "private provider error"))
    assert_equal({"classification" => "failed", "code" => "provider_rejected_non_otp"}, publisher.instance_variable_get(:@scoped_result))
    publisher.with_response(response("500", "possibly already stored"))
    assert_equal "uncertain", publisher.instance_variable_get(:@scoped_result).fetch("classification")
    refute publisher.api_key_forbidden?(response("403", "API key scope insufficient"))
  end

  def test_artifact_metadata_and_exact_digest_are_checked_before_push
    Dir.mktmpdir do |directory|
      path = File.join(directory, "exact.gem")
      spec = Gem::Specification.new do |value|
        value.name = "scoped-fixture"
        value.version = "1.0.0"
        value.summary = "fixture"
        value.authors = ["ACE"]
        value.files = []
      end
      capture_io { Gem::Package.build(spec, true, false, path) }
      input = {"artifact" => path, "artifact_digest" => Digest::SHA256.file(path).hexdigest,
        "gem_name" => "scoped-fixture", "version" => "1.0.0"}
      invocations = []
      runner = Object.new
      runner.define_singleton_method(:publish_artifact) { |selected| invocations << selected; {"classification" => "otp-required", "code" => "provider_rejected_before_acceptance"} }
      ScopedPublicationPush.stub(:new, runner) do
        assert_equal "otp-required", scoped_publish_one(input).fetch("classification")
        assert_equal "failed", scoped_publish_one(input.merge("artifact_digest" => "0" * 64)).fetch("classification")
        assert_equal "failed", scoped_publish_one(input.merge("version" => "1.0.1")).fetch("classification")
      end
      assert_equal [path], invocations
    end
  end
end
