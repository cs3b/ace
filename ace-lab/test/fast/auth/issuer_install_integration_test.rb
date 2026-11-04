# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/organisms/prepare"
require "ace/lab/organisms/verify"

class IssuerInstallIntegrationTest < Minitest::Test
  def manifest
    Ace::Lab::Atoms::InstallSchema.normalize({"schema_version" => 1, "machine" => "fixture",
      "gemset" => {"gem_home" => "/opt/ace/gems", "gems" => [{"name" => "ace-lab", "version" => "0.14.2"}]},
      "session_runtime" => {"node" => "/opt/node", "pi" => "/opt/pi.js", "path" => ["/usr/bin"],
        "provider" => "fixture", "model" => "fixture", "credentials" => "/etc/lab/credentials.json"}}, platform: "linux")
  end

  def test_prepare_propagates_issuer_failure_and_does_not_activate_after_failed_gem_convergence
    calls = []
    issuer = Object.new
    issuer.define_singleton_method(:call) do |**options|
      calls << options
      raise Ace::Lab::Auth::Error, "recovery unconfirmed"
    end
    subject = Ace::Lab::Organisms::Prepare.new(issuer: issuer)
    Ace::Lab::Molecules::InstallManifestLoader.stub(:load, manifest) do
      subject.stub(:prepare_gems, []) do
        result = subject.call
        refute result["ok"]
        assert_equal "recovery unconfirmed", result.dig("issuer", 0, "message")
        assert_equal "/opt/ace/gems/gems/ace-lab-0.14.2", calls.first.fetch(:gem_root)
      end
      calls.clear
      subject.stub(:prepare_gems, [{"status" => "failed"}]) do
        refute subject.call["ok"]
        assert_empty calls
      end
    end
  end

  def test_verify_marks_missing_issuer_failed_not_unknown
    issuer = Object.new
    issuer.define_singleton_method(:verify) { |**| raise Ace::Lab::Auth::Error, "socket unavailable" }
    subject = Ace::Lab::Organisms::Verify.new(issuer: issuer)
    Ace::Lab::Molecules::InstallManifestLoader.stub(:load, manifest) do
      subject.stub(:check_gems, []) do
        result = subject.call
        refute result["ready"]
        assert_equal "fail", result.dig("checks", "issuer", 0, "status")
        assert_equal "socket unavailable", result.dig("checks", "issuer", 0, "reason")
      end
    end
  end
end
