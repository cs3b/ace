# frozen_string_literal: true
require_relative "../test_helper"
require "rbconfig"
require "ace/herdr/molecules/bounded_process"

class ProtectedServiceLoadingTest < Minitest::Test
  def test_fixed_policy_and_listener_load_without_broad_configuration_entrypoints
    %w[ace/lab/molecules/protected_service_policy ace/lab/organisms/protected_service_listener ace/lab/molecules/protected_cleanup_owner_admission].each do |entry|
      code = <<~RUBY
        require #{entry.inspect}
        require "ace/lab/molecules/protected_service_policy"
        abort "broad entry loaded" if $LOADED_FEATURES.any? { |path| path.match?(%r{/ace/(assign|lab|herdr)\.rb$}) }
        abort "config loader loaded" if $LOADED_FEATURES.any? { |path| path.end_with?("/ace/support/config.rb") }
        observed = []
        Ace::Lab::Molecules::GrantResolver.define_singleton_method(:trusted_document) { |path| observed << path; {} }
        policy = Ace::Lab::Molecules::ProtectedServicePolicy.new(proposal_resolver: ->(*) { abort "grant resolver called" })
        input = {"target" => {"resource" => "fixture"}}
        digest = Ace::Lab::Atoms::ServiceInput.digest(input)
        result = policy.input_binding(JSON.generate(input), expected_digest: digest, expected_target: Ace::Lab::Atoms::ServiceInput.target(input), operation: "fixture")
        abort "input changed" unless result.fetch(:input) == input
        begin
          policy.visible!(project: "fixture", uid: 12345)
          abort "empty grants authorized"
        rescue SecurityError
        end
        abort "default path changed" unless observed == ["/etc/lab/ace-lab/authorization.yml"]
        proposal = Ace::Lab::Molecules::ServicePolicy.new({}, ->(*) { raise Ace::Assign::Error, "canonical owner refused" })
        begin
          proposal.authorize!("proposal-refused", {})
          abort "proposal refusal authorized"
        rescue SecurityError => error
          abort "proposal refusal changed" unless error.message == "canonical proposal does not authorize this exact effect"
        end
        STDOUT.write("loaded")
      RUBY
      result = Ace::Herdr::Molecules::BoundedProcess.call(
        [RbConfig.ruby, "--disable=gems,rubyopt", "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), "-e", code], timeout_s: 5)
      assert result.status.success?, "#{entry}: #{result.stderr}"
      assert_equal "loaded", result.stdout
      assert_empty result.stderr
    end
  end
end
