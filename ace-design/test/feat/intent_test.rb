# frozen_string_literal: true
require_relative "../generation_fixtures"

class IntentTest < DesignTest
  include GenerationFixtures
  def test_dry_run_resolves_without_writes_or_models_and_rejects_bad_combinations
    with_runner do |runner, agent, base|
      result = runner.generate(surface: "app", prompt: "Workspace", dry_run: true)
      assert_equal "planned", result.fetch("status")
      assert_equal %w[a b c], result.dig("resolved", "variants").map { |s| s["id"] }
      refute Dir.exist?(File.join(base, "runs"))
      assert_empty agent.calls
      assert_raises(Ace::Design::Error) { runner.generate(surface: "app", prompt: "X", from: "missing.png") }
      assert_raises(Ace::Design::Error) { runner.generate(surface: "app", intent: "recreate") }
      assert_raises(Ace::Design::Error) { runner.generate(surface: "app", prompt: "X", profile: "site/view") }
      assert_raises(Ace::Design::Error) { runner.generate(surface: "app", prompt: "X", preset: "taste-v2") }
    end
  end

  def test_missing_shared_inputs_fail_before_allocating_or_invoking_agents
    with_runner do |runner, agent, base|
      error = assert_raises(Ace::Design::Error) { runner.generate(surface: "app", prompt: "X", fixtures: File.join(base, "missing.json")) }
      assert_match(/Cannot read --fixtures/, error.message)
      assert_empty agent.calls
      refute Dir.exist?(File.join(base, "runs"))
      root = runner.generate(surface: "app", prompt: "Workspace").fetch("session")
      File.unlink(File.join(root, "design.md"))
      calls = agent.calls.size
      sessions = Dir.children(File.join(base, "runs"))
      error = assert_raises(Ace::Design::Error) { runner.generate(intent: "reimagine", from: "session:#{File.basename(root)}/b") }
      assert_match(/missing readable design.md/, error.message)
      assert_equal calls, agent.calls.size
      assert_equal sessions, Dir.children(File.join(base, "runs"))
    end
  end

  def test_prompt_append_composes_and_freezes_session_briefs
    with_runner do |runner, agent, _|
      original = agent.method(:call)
      agent.define_singleton_method(:call) do |**args|
        result = original.call(**args)
        if File.basename(File.dirname(args.fetch(:workspace))) == "preparation"
          File.write(File.join(args.fetch(:workspace), "source-analysis.md"), "Observed: button. Assumed: submit action.")
        end
        result
      end
      parent = runner.generate(surface: "app", prompt: "Button", prompt_append: ["Visible focus"]).fetch("session")
      source = "session:#{File.basename(parent)}/b"
      planned = runner.generate(intent: "reimagine", from: source, prompt_append: ["Large targets", "Quiet colors"], dry_run: true)
      expected = "Button\n\nVisible focus\n\nLarge targets\n\nQuiet colors"
      assert_equal expected, planned.fetch("brief")
      assert_equal "session", planned.dig("resolved", "brief_inputs", "origin")
      assert_equal ["Large targets", "Quiet colors"], planned.dig("resolved", "brief_inputs", "append")
      replaced = runner.generate(intent: "recreate", from: source, prompt: "New brief", prompt_append: ["One addition"], dry_run: true)
      assert_equal "New brief\n\nOne addition", replaced.fetch("brief")
      assert_equal "explicit", replaced.dig("resolved", "brief_inputs", "origin")
      result = runner.generate(intent: "reimagine", from: source, prompt_append: ["Large targets", "Quiet colors"])
      root = result.fetch("session")
      assert_equal "succeeded", result.fetch("status")
      assert_equal expected, File.read(File.join(root, "brief.md"))
      File.write(File.join(parent, "brief.md"), "Changed parent")
      controller(root, agent).resume
      controller(root, agent).revise(variant: "b", prompt: "More whitespace")
      assert_equal expected, File.read(File.join(agent.calls.last.fetch(:workspace), "brief.md"))
      stored = JSON.parse(File.read(File.join(root, "resolved.json")))
      assert_equal planned.dig("resolved", "brief_inputs"), stored.fetch("brief_inputs")
    end
  end

  def test_prompt_append_requires_nonempty_additions_and_explore_base
    with_runner do |runner, agent, base|
      assert_raises(Ace::Design::Error) { runner.generate(surface: "app", prompt_append: ["Only addition"], dry_run: true) }
      assert_raises(Ace::Design::Error) { runner.generate(surface: "app", prompt: "Base", prompt_append: ["  "], dry_run: true) }
      planned = runner.generate(surface: "app", intent: "reimagine", from: "https://example.com", prompt_append: ["Map focus"], dry_run: true)
      assert_equal "default", planned.dig("resolved", "brief_inputs", "origin")
      assert planned.fetch("brief").end_with?("\n\nMap focus")
      assert_empty agent.calls
      refute Dir.exist?(File.join(base, "runs"))
    end
  end

  def test_image_source_is_copied_and_analysis_runs_once_across_revision
    with_runner do |runner, agent, base|
      source = File.join(base, "screen.png")
      File.binwrite(source, "PNG fixture bytes")
      original = agent.method(:call)
      agent.define_singleton_method(:call) do |**args|
        result = original.call(**args)
        if File.basename(File.dirname(args.fetch(:workspace))) == "preparation"
          File.write(File.join(args.fetch(:workspace), "source-analysis.md"), "Observed: a queue. Assumed: sorting behavior.")
        end
        result
      end
      result = runner.generate(surface: "app", intent: "recreate", from: source)
      assert_equal "succeeded", result["status"], result.inspect
      root = result.fetch("session")
      assert_equal ["a"], result.fetch("workers").keys
      File.binwrite(source, "changed original")
      controller(root, agent).revise(variant: "a", prompt: "Match spacing")
      assert_equal 1, agent.calls.count { |call| call[:id] == "preparation" }
      agent.calls.each do |call|
        assert_equal "PNG fixture bytes", File.binread(File.join(call[:workspace], "source/mockup.png"))
        assert_includes call[:prompt], "Faithfully reproduce"
      end
      File.write(File.join(root, "source/mockup.png"), "tampered")
      assert_raises(Ace::Design::Error) { controller(root, agent).resume }
    end
  end

  def test_session_source_inherits_scope_and_snapshots_original_variant
    with_runner do |runner, agent, base|
      root = runner.generate(surface: "app", kind: "component", prompt: "Button").fetch("session")
      token = File.basename(root)
      request = runner.generate(intent: "reimagine", from: "session:#{token}/b", dry_run: true)
      assert_equal "app", request.dig("resolved", "surface")
      assert_equal "component", request.dig("resolved", "kind")
      assert_raises(Ace::Design::Error) do
        runner.generate(intent: "reimagine", from: "session:#{token}/b", surface: "site", dry_run: true)
      end
      source = Ace::Design::Molecules::DesignSource.new("session:#{token}/b", config: Ace::Design.config.merge("run_root" => File.join(base, "runs")))
      destination = File.join(base, "copy")
      source.snapshot(destination)
      assert_equal File.binread(File.join(root, "variants/b/index.html")), File.binread(File.join(destination, "source/variant/index.html"))
    end
  end

  def test_url_source_is_captured_once_and_dry_run_does_not_capture
    with_runner do |runner, agent, base|
      calls = []
      runtime = Object.new
      def runtime.node; "node"; end
      def runtime.directory; "runtime"; end
      def runtime.script(name); name; end
      runtime.define_singleton_method(:capture) do |*args, **|
        calls << args
        File.write(File.join(args.last, "mockup.png"), "frozen pixels")
        File.write(File.join(args.last, "visible.txt"), "Source content")
        {"exit_code" => 0}
      end
      original = agent.method(:call)
      agent.define_singleton_method(:call) do |**args|
        result = original.call(**args)
        if File.basename(File.dirname(args.fetch(:workspace))) == "preparation"
          File.write(File.join(args.fetch(:workspace), "source-analysis.md"), "Observed goal. Assumed behavior.")
        end
        result
      end
      Ace::Design::Molecules::Runtime.stub(:new, runtime) do
        planned = runner.generate(surface: "site", intent: "reimagine", from: "https://example.com", dry_run: true)
        assert_empty calls
        assert_includes planned.fetch("requirements").first.fetch("name"), "Source capture"
        result = runner.generate(surface: "site", intent: "reimagine", from: "https://example.com")
        assert_equal "succeeded", result["status"], result.inspect
        controller(result.fetch("session"), agent).revise(variant: "b", prompt: "Calmer")
        assert_equal 1, calls.size
        assert_equal "frozen pixels", File.read(File.join(agent.calls.last.fetch(:workspace), "source/mockup.png"))
      end
    end
  end

  def test_catalog_and_explicit_preset_counts_model_overrides_and_compatibility
    config = Ace::Design.config
    resolved = Ace::Design::Molecules::Preset.load(name: "ace-vs-taste", surface: "site", config: config, model: "fixture:one")
    assert_equal %w[a b c d], resolved.fetch("variants").map { |s| s["id"] }
    assert_equal %w[ace ace ace external], resolved.fetch("variants").map { |s| s.fetch("process") }
    assert_equal ["fixture:one"], resolved.fetch("variants").map { |s| s["model"] }.uniq
    assert_equal "fixture:one", resolved["preparation_model"]
    assert_equal "lead", resolved.fetch("variants").last.fetch("skills").first.fetch("role")
    assert_raises(Ace::Design::Error) do
      Ace::Design::Molecules::Preset.load(name: "ace-vs-taste", surface: "app")
    end
  end

  def test_artifact_types_validate_and_render_without_executing_untrusted_urls
    with_runner do |runner, agent, _|
      root = runner.generate(surface: "site", prompt: "Gallery").fetch("session")
      artifacts = Ace::Design::Molecules::Artifacts
      a = File.join(root, "variants/a")
      File.binwrite(File.join(a, "preview.png"), "image fixture")
      artifacts.json(File.join(a, "artifact.json"), {"type" => "image", "entry" => "preview.png", "status" => "complete", "checks" => [{"name" => "render", "status" => "passed"}]})
      artifacts.validate_variant(a, types: ["image"], shared_reference: false)
      b = File.join(root, "variants/b")
      artifacts.json(File.join(b, "artifact.json"), {"type" => "url", "entry" => "https://example.com/design", "status" => "complete", "checks" => [{"name" => "render", "status" => "passed"}]})
      artifacts.validate_variant(b, types: ["url"], shared_reference: false)
      gallery = File.read(Ace::Design::Molecules::Session.new(root).write_gallery)
      assert_includes gallery, "variants/a/preview.png"
      assert_includes gallery, 'href="https://example.com/design"'
      assert_equal 1, gallery.scan("<iframe").size
      artifacts.json(File.join(b, "artifact.json"), {"type" => "url", "entry" => "javascript:alert(1)"})
      assert_raises(Ace::Design::Error) { artifacts.descriptor(b) }
      artifacts.json(File.join(b, "artifact.json"), {"type" => "html", "entry" => "../../brief.md"})
      assert_raises(Ace::Design::Error) { artifacts.descriptor(b) }
    end
  end
end
