# frozen_string_literal: true

require_relative "test_helper"
require "open3"

# Executes the extension's real JavaScript test suite through
# `node --test` so `ace-test ace-wake` runs the same tests the
# extension ships with (task 8xs.t.pu0.0: include ace-wake in
# monorepo test discovery). A missing `node` is a readiness
# failure, never a silent skip: the extension runtime is Node.
class WakeJsSuiteTest < Minitest::Test
  PACKAGE_ROOT = File.expand_path("..", __dir__)
  TEST_GLOBS = ["test/*.test.mjs", "test/acceptance/*.test.mjs"].freeze

  def test_javascript_suite_passes
    files = TEST_GLOBS.flat_map { |glob| Dir.glob(File.join(PACKAGE_ROOT, glob)) }.sort
    refute_empty files, "ace-wake JavaScript tests not found under #{PACKAGE_ROOT}/test"

    out, err, status = Open3.capture3({ "NODE_OPTIONS" => nil },
      "node", "--test", *files, chdir: PACKAGE_ROOT)

    assert status.success?,
      "ace-wake node --test failed (exit #{status.exitstatus}):\n#{summarize(out, err)}"
  end

  private

  # Node's TAP-ish output is verbose; surface the tail plus failures.
  def summarize(out, err)
    lines = (out + err).lines.map(&:chomp)
    failures = lines.select { |line| line.start_with?("✖", "not ok") }
    body = failures.empty? ? lines.last(20) : failures.last(20)
    body.join("\n")
  end
end
