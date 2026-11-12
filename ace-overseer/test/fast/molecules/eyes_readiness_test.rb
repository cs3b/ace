# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/eyes_readiness"

class EyesReadinessTest < Minitest::Test
  def test_checks_actual_session_even_when_obsolete_marker_is_inherited
    calls = []
    local = Object.new
    local.define_singleton_method(:ready?) { |**args| calls << args; false }
    reader = Ace::Overseer::Molecules::EyesReadiness.new(env: {"ACE_LAB_SESSION" => "1"}, local: local)
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, ".ace-local/overseer"))
      File.write(File.join(root, ".ace-local/overseer/eyes.json"), JSON.generate({scope: "all", recipient: "overseer"}))
      args = {pane: "w1:p2", root: root, prompt: "start", required_sources: ["tasks"]}
      refute reader.ready?(**args)
      assert_equal [args.merge(expected_config: {"scope" => "all", "recipient" => "overseer"})], calls
    end
  end
end
