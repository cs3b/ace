# frozen_string_literal: true
require_relative "../../test_helper"
class InspectorTest < DesignTest
  FakeRuntime = Struct.new(:report, :exit_code, :failure) do
    def node = "node"
    def directory = "/runtime"
    def script(name) = name
    def capture(*args, **)
      raise Ace::Design::Error, failure if failure
      File.write(File.join(args[4], "report.json"), JSON.generate(report))
      {"exit_code" => exit_code, "stderr" => "test runner"}
    end
  end
  def inspector(runtime)
    Ace::Design::Organisms::Inspector.new(config: {"timeout" => 1, "run_root" => "/unused", "node" => "node", "runtime_dir" => "/unused"}, runtime: runtime)
  end
  def test_pass_requires_complete_evidence
    Dir.mktmpdir do |out|
      runtime = FakeRuntime.new({"status" => "pass", "viewports" => []}, 0)
      assert_raises(Ace::Design::Error) { inspector(runtime).run(url: "http://localhost", surface: "site", out: out) }
    end
  end
  def test_runner_failure_cannot_pass
    Dir.mktmpdir do |out|
      runtime = FakeRuntime.new({"status" => "pass", "viewports" => [390,768,1440].map { |w| {"width" => w} }, "errors" => [], "findings" => []}, 1)
      assert_raises(Ace::Design::Error) { inspector(runtime).run(url: "http://localhost", surface: "site", out: out) }
    end
  end
  def test_preserves_existing_outputs_without_writing_error_file
    Dir.mktmpdir do |out|
      File.write(File.join(out, "keep.txt"), "unchanged")
      assert_raises(Ace::Design::Error) { inspector(nil).run(url: "http://localhost", surface: "app", out: out) }
      assert_equal ["keep.txt"], Dir.children(out)
    end
  end
  def test_failure_in_fresh_output_leaves_incomplete_evidence
    Dir.mktmpdir do |out|
      runtime = FakeRuntime.new(nil, nil, "Node missing")
      assert_raises(Ace::Design::Error) { inspector(runtime).run(url: "http://localhost", surface: "app", out: out) }
      assert_equal "incomplete", JSON.parse(File.read(File.join(out, "error.json")))["status"]
    end
  end
  def test_invalid_url_has_no_side_effects
    Dir.mktmpdir do |base|
      out = File.join(base, "new")
      assert_raises(Ace::Design::Error) { inspector(nil).run(url: "file:///secret", surface: "app", out: out) }
      refute File.exist?(out)
    end
  end
  def test_default_outputs_are_distinct_even_with_the_same_timestamp
    Dir.mktmpdir do |root|
      runtime = FakeRuntime.new({"status" => "incomplete", "viewports" => [], "errors" => ["fixture"]}, 2)
      runner = Ace::Design::Organisms::Inspector.new(config: {"timeout" => 1, "run_root" => root}, runtime: runtime)
      Ace::B36ts.stub(:now, "fixed") do
        first = runner.run(url: "http://localhost", surface: "site")
        second = runner.run(url: "http://localhost", surface: "site")
        refute_equal first["report_path"], second["report_path"]
        assert File.file?(first["report_path"])
        assert File.file?(second["report_path"])
      end
    end
  end
end
