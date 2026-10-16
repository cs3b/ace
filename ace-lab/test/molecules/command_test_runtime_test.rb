# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/molecules/command_test_runtime"

class CommandTestRuntimeTest < Minitest::Test
  def document
    {"schema" => "ruby-test-runtime/v1", "gem_paths" => ["/opt/runtime/gems"],
      "gems" => {"ace-test-runner" => {"version" => "0.28.1", "sha256" => "a" * 64}},
      "source_gems" => {"ace-lab" => "ace-lab", "ace-assign" => "ace-assign", "ace-herdr" => "ace-herdr", "ace-runtime" => "ace-runtime"},
      "package" => "ace-lab", "argv" => ["/usr/bin/ruby", "/opt/runtime/bin/ace-test", "feat", "--config-path", "@configuration", "--report-dir", "@output"],
      "executable_sha256" => "b" * 64, "entrypoint_sha256" => "c" * 64}
  end

  def test_compiled_definition_retains_exact_selector_source_and_external_runtime_paths
    runtime = Ace::Lab::Molecules::CommandTestRuntime.new(document)
    recipe = {"kind" => "ordinary-candidate", "root" => "/var/lib/lab/command-views", "runtime_path" => "/etc/lab/runtime.json", "runtime_sha256" => "d" * 64}
    selection = {"argv" => ["bin/ace-test", "feat"]}
    original = {"argv" => selection.fetch("argv"), "selection" => selection, "source" => recipe,
      "executable_sha256" => "b" * 64, "executor" => {"environment" => {"LANG" => "C"}, "uid" => 1001}}
    candidate = {"head" => "e" * 40, "tree" => "f" * 40, "reference" => {"assignment_id" => "real-assignment"}}
    compiled = runtime.compile(definition: original, execution_id: "run1", candidate: candidate)
    root = "/var/lib/lab/command-views/run1"
    assert_equal selection, compiled.fetch("selection")
    assert_equal candidate.slice("head", "tree"), compiled.fetch("source")
    assert_equal candidate, compiled.fetch("candidate")
    assert_equal "run1", compiled.dig("materialization", "execution_id")
    assert_equal "#{root}/source/ace-lab", compiled.dig("executor", "cwd")
    assert_equal "-rbundler/setup", compiled.fetch("argv")[1]
    assert_includes compiled.fetch("argv").each_cons(2).to_a, ["--config-path", "#{root}/config/runner.json"]
    assert_includes compiled.fetch("argv").each_cons(2).to_a, ["--report-dir", "#{root}/output/reports"]
    environment = compiled.dig("executor", "environment")
    assert_equal "#{root}/config/Gemfile", environment.fetch("BUNDLE_GEMFILE")
    assert_equal "#{root}/output/tmp", environment.fetch("TMPDIR")
    assert_equal "/opt/runtime/gems", environment.fetch("GEM_PATH")
    assert_equal "C", environment.fetch("LANG")
    assert_equal original.fetch("argv"), selection.fetch("argv")
    config = JSON.parse(runtime.configuration(root))
    assert_equal environment.except("LANG"), config.dig("environment", "overrides")
    gemfile = runtime.gemfile(root)
    assert_includes gemfile, 'gem "ace-test-runner", "= 0.28.1"'
    assert_includes gemfile, "path: \"#{root}/source/ace-herdr\""
    refute_includes gemfile, "eval_gemfile"
  end

  def test_profile_refuses_ambient_inference_unknown_keys_paths_and_missing_output_contract
    mutations = [
      ->(doc) { doc["ambient"] = true },
      ->(doc) { doc["source_gems"]["ace-lab"] = "../outside" },
      ->(doc) { doc["gem_paths"] = ["relative"] },
      ->(doc) { doc["gems"]["ace-lab"] = {"version" => "0.8.0", "sha256" => "a" * 64} },
      ->(doc) { doc["argv"].delete("@configuration") },
      ->(doc) { doc["argv"][3] = "--ignored-flag" },
      ->(doc) { doc["argv"] += ["--config-path", "/unselected"] },
      ->(doc) { doc["package"] = "unselected" },
      ->(doc) { doc["gems"]["ace-test-runner"]["version"] = ">= 0" }
    ]
    mutations.each do |change|
      value = document
      change.call(value)
      assert_raises(Ace::Lab::InvalidConfigurationError) { Ace::Lab::Molecules::CommandTestRuntime.new(value) }
    end
  end

  def test_missing_installed_profile_is_truthful_refusal
    assert_raises(Ace::Lab::InvalidConfigurationError) do
      Ace::Lab::Molecules::CommandTestRuntime.load({"runtime_path" => "/nonexistent-ei9-test-runtime.json", "runtime_sha256" => "a" * 64})
    end
  end

  def test_representative_whole_source_closure_stays_within_wire_bounds_without_truncation
    profile = document
    profile["source_gems"] = Dir.glob(File.expand_path("../../../*/ace-*.gemspec", __dir__)).to_h do |path|
      name = File.basename(path, ".gemspec")
      [name, name]
    end
    # Use the real monorepo package inventory; a source runner overrides its
    # installed counterpart instead of declaring two competing authorities.
    assert_operator profile.fetch("source_gems").size, :>=, 40
    profile["gems"].delete("ace-test-runner")
    40.times { |index| profile["gems"]["fixture-dependency-#{index}"] = {"version" => "1.2.3", "sha256" => "a" * 64} }
    runtime = Ace::Lab::Molecules::CommandTestRuntime.new(profile)
    assert_operator JSON.generate(profile).bytesize, :<, 65_536
    root = "/var/lib/lab/command-views/" + "e" * 32
    compiled = runtime.compile(definition: {"argv" => ["bin/ace-test", "feat"], "selection" => {"argv" => ["bin/ace-test", "feat"]},
      "source" => {"kind" => "ordinary-candidate", "root" => "/var/lib/lab/command-views", "runtime_path" => "/etc/lab/runtime.json", "runtime_sha256" => "d" * 64},
      "executable_sha256" => "b" * 64, "executor" => {"environment" => {}, "uid" => 1001}},
      execution_id: "e" * 32, candidate: {"head" => "a" * 40, "tree" => "b" * 40})
    assert_operator JSON.generate(compiled).bytesize, :<, 8192
    assert_equal profile.fetch("source_gems").size, runtime.gemfile(root).scan(/path:/).size
  end
end
