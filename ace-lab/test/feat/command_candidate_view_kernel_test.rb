# frozen_string_literal: true
require_relative "../test_helper"
require "open3"
require "rbconfig"

class CommandCandidateViewKernelTest < Minitest::Test
  def test_source_only_controlled_runtime_seals_real_bundle_and_drops_before_gemspec_evaluation
    skip "requires disposable Linux root; no installed runner acceptance" unless RUBY_PLATFORM.include?("linux") && Process.uid.zero? && Process.euid.zero?
    script = File.expand_path("../support/command_candidate_view_probe.rb", __dir__)
    output, error, status = Open3.capture3(RbConfig.ruby, "-I", $LOAD_PATH.join(File::PATH_SEPARATOR), script, stdin_data: "")
    assert status.success?, error
    assert_empty error
    result = JSON.parse(output)
    assert_equal "source-only-controlled-runtime-no-canonical-proof", result.fetch("scope")
    uid = Etc.getpwnam("nobody").uid
    assert_equal uid, result.dig("child", "uid")
    assert_equal uid, result.fetch("evaluated_uid")
    assert result.dig("child", "source_denied")
    assert result.fetch("clean")
    assert_equal "lib/value.rb", result.fetch("alias")
    assert_operator result.fetch("lock_bytes"), :>, 0
    assert_equal 0, result.fetch("config_owner")
    assert_equal uid, result.fetch("lock_owner")
    assert_equal %w[writable undeclared], result.fetch("runtime_denied")
    assert_equal %w[dangling escaping], result.fetch("link_denied")
    assert_equal "REFUSED", result.fetch("unobservable_runtime")
    assert result.fetch("existing_view_refused")
    assert result.fetch("existing_output_preserved")
    assert_equal %w[dangling escaping], result.fetch("failed_views_removed")
  end
end
