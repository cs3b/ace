# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"

class SourceBundlerTest < AceSimTestCase
  class FakeRunner
    attr_reader :seen_args

    def initialize(success: true)
      @success = success
    end

    def call(args)
      @seen_args = args.dup
      output_path = args[args.index("--output") + 1]
      File.write(output_path, "bundled content") if @success
      {success: @success, stdout: "", stderr: @success ? "" : "boom", exit_code: @success ? 0 : 1}
    end
  end

  def test_creates_bundle_yaml_and_runs_ace_bundle
    Dir.mktmpdir do |dir|
      first = File.join(dir, "a.md")
      second = File.join(dir, "b.md")
      output = File.join(dir, "input.md")
      File.write(first, "a")
      File.write(second, "b")
      runner = FakeRunner.new
      bundler = Ace::Sim::Molecules::SourceBundler.new(command_runner: runner)

      result = bundler.bundle(sources: [first, second], output_path: output)

      # Returns path to bundled content
      assert_equal File.join(dir, "input.md"), result

      # Creates bundle YAML file
      bundle_yaml = File.join(dir, "input.bundle.md")
      assert File.exist?(bundle_yaml)
      yaml_content = File.read(bundle_yaml)
      assert_includes yaml_content, first
      assert_includes yaml_content, second

      # Calls ace-bundle with bundle YAML path (not -f flags)
      assert_equal "ace-bundle", runner.seen_args[0]
      assert_equal bundle_yaml, runner.seen_args[1]
      assert_equal "--output", runner.seen_args[2]
      assert_equal File.join(dir, "input.md"), runner.seen_args[3]

      # Bundled content is created
      assert File.exist?(File.join(dir, "input.md"))
      assert_equal "bundled content", File.read(File.join(dir, "input.md"))
    end
  end

  def test_raises_validation_error_when_bundle_command_fails
    Dir.mktmpdir do |dir|
      output = File.join(dir, "input.md")
      bundler = Ace::Sim::Molecules::SourceBundler.new(command_runner: FakeRunner.new(success: false))

      err = assert_raises(Ace::Sim::ValidationError) do
        bundler.bundle(sources: [File.join(dir, "a.md")], output_path: output)
      end

      assert_match(/ace-bundle failed/, err.message)
    end
  end

  def test_raises_validation_error_when_sources_empty
    Dir.mktmpdir do |dir|
      output = File.join(dir, "input.md")
      bundler = Ace::Sim::Molecules::SourceBundler.new(command_runner: FakeRunner.new)

      err = assert_raises(Ace::Sim::ValidationError) do
        bundler.bundle(sources: [], output_path: output)
      end

      assert_match(/source cannot be empty/, err.message)
    end
  end
end
