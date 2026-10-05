# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "tmpdir"
require "json"
require "yaml"

class SuiteConfigCliTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  EXE = File.join(ROOT, "ace-test-runner/exe/ace-test-suite")

  def with_config
    Dir.mktmpdir("suite-config") do |root|
      FileUtils.mkdir_p(File.join(root, ".git"))
      FileUtils.mkdir_p(File.join(root, ".ace/test"))
      File.write(File.join(root, ".ace/test/suite.yml"), YAML.dump(config("cascade")))
      yield root
    end
  end

  def config(name)
    {"test_suite" => {"max_parallel" => 1, "packages" => [{"name" => name, "path" => "./#{name}"}]}}
  end

  def run_cli(root, *args)
    # Stop at the execution boundary: exercise actual option parsing and real
    # configuration loading without starting the monorepo's package processes.
    boot = <<~RUBY
      require "ace/core"
      require "ace/test_runner/suite"
      require "json"
      Ace::Support::Config.test_mode = false
      Ace::TestRunner::Suite.define_singleton_method(:run) { |config| puts "SELECTED=" + JSON.generate(config); 0 }
      load #{EXE.inspect}
    RUBY
    stdout, stderr, status = Open3.capture3({"BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"), "HOME" => root},
      RbConfig.ruby, "-rbundler/setup", "-e", boot, "--", *args, chdir: root)
    [stdout + stderr, status]
  end

  def selected(output)
    line = output.lines.find { |entry| entry.start_with?("SELECTED=") }
    refute_nil line, output
    JSON.parse(line.delete_prefix("SELECTED="))
  end

  def test_explicit_relative_and_absolute_files_replace_the_cascade
    with_config do |root|
      path = File.join(root, "chosen.yml")
      File.write(path, YAML.dump(config("chosen")))
      ["chosen.yml", path].each do |argument|
        output, status = run_cli(root, "--config", argument)
        assert status.success?, output
        assert_equal config("chosen"), selected(output)
      end
    end
  end

  def test_without_explicit_file_uses_existing_namespace_cascade
    with_config do |root|
      output, status = run_cli(root)
      assert status.success?, output
      assert_equal ["cascade"], selected(output).fetch("test_suite").fetch("packages").map { |item| item.fetch("name") }
    end
  end

  def test_missing_explicit_file_refuses_instead_of_using_cascade
    with_config do |root|
      output, status = run_cli(root, "--config", "missing.yml")
      refute status.success?, output
      assert_includes output, "missing.yml"
      refute_includes output, "SELECTED="
    end
  end

  def test_malformed_yaml_and_invalid_shape_refuse_instead_of_using_cascade
    with_config do |root|
      ["test_suite: [", "- not-a-suite", "test_suite: wrong"].each do |bytes|
        File.write(File.join(root, "invalid.yml"), bytes)
        output, status = run_cli(root, "--config", "invalid.yml")
        refute status.success?, output
        assert_includes output, "invalid.yml"
        refute_includes output, "SELECTED="
      end
    end
  end
end
