# frozen_string_literal: true
require_relative "../test_helper"

class AdjustmentTest < DesignTest
  class Composer
    attr_reader :calls
    attr_accessor :conflict, :malformed, :callback
    def initialize
      @calls = []
    end
    def validate_model(*)
    end
    def call(workspace:, **)
      input = JSON.parse(File.read(File.join(workspace, "request.json")))
      @calls << input
      nodes = {}
      input.fetch("contexts").each do |node|
        parent = node["parent"] && (nodes[node["parent"]]&.fetch("design") || node.fetch("parent_design"))
        nodes[node.fetch("id")] = {"design" => "#{parent}\n#{node.fetch('new_defaults')}\n#{node.fetch('user')}",
          "added_rules" => ["Current defaults"], "preserved_exceptions" => [node.fetch("user")], "omitted_defaults" => []}
      end
      File.write(File.join(workspace, "result.json"), JSON.generate(malformed || {
        "contexts" => nodes, "conflicts" => conflict ? ["Clarify conflicting instructions"] : []}))
      callback&.call
      {"execution" => {"status" => "succeeded", "provider" => "fixture-cli", "model" => "fixture"}}
    end
  end
  C = Ace::Design::Molecules::DesignContext
  def with_contexts
    Dir.mktmpdir("design-adjust") do |project|
      library = File.join(project, "library")
      FileUtils.cp_r(File.join(Ace::Design.gem_root, ".ace-defaults/design/contexts"), library)
      contexts = C.new(project: project, library: library)
      agent = Composer.new
      adjuster = Ace::Design::Organisms::Adjuster.new(contexts: contexts, executor: agent)
      yield adjuster, agent, contexts, project, library
    end
  end
  def test_dry_run_does_not_write_or_invoke_composer
    with_contexts do |adjuster, agent, contexts, _, _|
      result = adjuster.adjust(surface: "app", prompt: "Compact", dry_run: true)
      assert_equal "planned", result["status"]
      assert_empty agent.calls
      assert_empty contexts.repository.read
      refute File.exist?(contexts.repository.runs)
    end
  end
  def test_library_contexts_and_context_id_validation_do_not_create_project_assets
    with_contexts do |_, _, contexts, project, _|
      view = contexts.snapshot(surface: "app", kind: "view")
      component = contexts.snapshot(surface: "site", kind: "component")
      assert_equal "library", view["source"]
      assert_includes view["document"], "Application view"
      assert_includes component["document"], "Website component"
      refute_includes component["document"], "Application view"
      refute_includes component["document"], "Authoritative user decisions"
      refute File.exist?(File.join(project, ".ace-config"))
      %w[../app/view app/view/../../site/view app//view site/component app/component].each do |id|
        assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "app", kind: "view", context: id) }
      end
      assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "app", kind: "widget") }
      assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "app", kind: "view", context: "app/view/not-initialized") }
    end
  end
  def test_init_inheritance_custom_context_and_idempotence
    with_contexts do |adjuster, agent, contexts, _, _|
      result = adjuster.adjust(surface: "app", prompt: "Keep routine actions visible")
      assert_equal "published", result["status"]
      assert_equal ["", "app", "app/component", "app/view"], result["contexts"]
      tree = contexts.repository.read
      assert_equal 12, tree.size
      assert_includes contexts.snapshot(surface: "app", kind: "component")["document"], "Keep routine actions visible"
      result = adjuster.adjust(surface: "app", kind: "component", profile: "app/component/table", prompt: "Use compact rows")
      assert_equal "published", result["status"]
      assert_equal ["app/component/table"], result["changed_contexts"]
      after = contexts.repository.read
      tree.each { |file, bytes| assert_equal bytes, after.fetch(file), file }
      assert_empty result["stale_contexts"]
      assert_equal after.fetch("app/component/table/design.md"), File.binread(File.join(result["report_dir"], "candidate/app/component/table/design.md"))
      assert_includes agent.calls.last.fetch("contexts").first.fetch("parent_design"), "Keep routine actions visible"
      output = contexts.snapshot(surface: "app", kind: "component", context: "app/component/table")["document"]
      assert_includes output, "Keep routine actions visible"
      assert_includes output, "Use compact rows"
      assert_equal "unchanged", adjuster.adjust(surface: "app", kind: "component", profile: "app/component/table")["status"]
      assert_equal 2, agent.calls.size
      assert File.file?(File.join(result["report_dir"], "changes.diff"))
    end
  end
  def test_refresh_adds_and_removes_defaults_without_rewriting_user_bytes
    with_contexts do |adjuster, _, contexts, _, library|
      adjuster.adjust(surface: "app", prompt: "Use compact rows; keep actions visible")
      before = contexts.repository.read
      pinned = contexts.snapshot(surface: "app", kind: "view")["document"]
      File.write(File.join(library, "app.md"), "# New app rules\n\nPrefer explicit recovery.\n")
      assert_equal pinned, contexts.snapshot(surface: "app", kind: "view")["document"]
      result = adjuster.adjust(surface: "app", refresh: true)
      assert_equal "published", result["status"]
      after = contexts.repository.read
      before.keys.grep(/user\.md$/).each { |file| assert_equal before[file], after[file] }
      output = contexts.snapshot(surface: "app", kind: "view")["document"]
      assert_includes output, "Prefer explicit recovery"
      assert_includes output, "Use compact rows; keep actions visible"
      refute_includes output, "experienced users may need compact interfaces"
      assert_raises(Ace::Design::Error) { adjuster.adjust(surface: "app", refresh: true, prompt: "Do not merge these modes") }
    end
  end
  def test_dry_run_conflicts_malformed_outputs_and_manual_edits_leave_tree_unchanged
    with_contexts do |adjuster, agent, contexts, _, _|
      proposal = adjuster.adjust(surface: "site", prompt: "Calm typography", propose: true)
      assert_equal "proposed", proposal["status"]
      assert_empty contexts.repository.read
      assert File.file?(File.join(proposal["report_dir"], "candidate/site/user.md"))
      adjuster.adjust(surface: "site", prompt: "Calm typography")
      before = contexts.repository.read
      agent.conflict = true
      assert_equal "conflict", adjuster.adjust(surface: "site", prompt: "Ambiguous request")["status"]
      assert_equal before, contexts.repository.read
      agent.conflict = false
      agent.malformed = {"contexts" => {}, "conflicts" => []}
      assert_raises(Ace::Design::Error) { adjuster.adjust(surface: "site", prompt: "New instruction") }
      assert_equal before, contexts.repository.read
      agent.malformed = nil
      design = File.join(contexts.repository.root, "site/design.md")
      File.open(design, "a") { |file| file.puts "Manual change" }
      count = agent.calls.size
      error = assert_raises(Ace::Design::Error) { adjuster.adjust(surface: "site", refresh: true) }
      assert_includes error.message, "Manually changed"
      assert_equal count, agent.calls.size
      assert File.read(design).end_with?("Manual change\n")
    end
  end
  def test_user_parent_and_default_edits_require_recomposition_and_other_branches_become_stale
    with_contexts do |adjuster, _, contexts, _, _|
      adjuster.adjust(surface: "site")
      adjuster.adjust(surface: "app")
      root_user = File.join(contexts.repository.root, "user.md")
      File.write(root_user, "Never hide primary actions\n")
      assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "app", kind: "view") }
      result = adjuster.adjust(surface: "app")
      assert_includes result["stale_contexts"], "site"
      assert_includes contexts.snapshot(surface: "app", kind: "view")["document"], "Never hide primary actions"
      assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "site", kind: "view") }
      adjuster.adjust(surface: "site")
      defaults = File.join(contexts.repository.root, "site/defaults.md")
      File.open(defaults, "a") { |file| file.puts "Additional source rule" }
      assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "site", kind: "view") }
    end
  end
  def test_concurrent_edit_is_not_overwritten_and_symlinks_are_rejected
    with_contexts do |adjuster, agent, contexts, project, _|
      adjuster.adjust(surface: "app")
      user = File.join(contexts.repository.root, "app/user.md")
      agent.callback = -> { File.write(user, "Concurrent human edit\n") }
      error = assert_raises(Ace::Design::Error) { adjuster.adjust(surface: "app", prompt: "New preference") }
      assert_includes error.message, "changed during adjust"
      assert_equal "Concurrent human edit\n", File.read(user)
      File.unlink(user)
      outside = File.join(project, "outside.md")
      File.write(outside, "Untouched")
      File.symlink(outside, user)
      assert_raises(Ace::Design::Error) { contexts.snapshot(surface: "app", kind: "view") }
      assert_equal "Untouched", File.read(outside)
    end
  end
  def test_failed_publication_restores_complete_previous_tree_and_recovers_a_crash
    with_contexts do |adjuster, _, contexts, _, _|
      adjuster.adjust(surface: "app", prompt: "Original")
      before = contexts.repository.read
      rename = File.method(:rename)
      failed = false
      injected = lambda do |from, to|
        if !failed && from.end_with?("/publishing") && to == contexts.repository.root
          failed = true
          raise Errno::EIO, "injected publication failure"
        end
        rename.call(from, to)
      end
      assert_raises(Errno::EIO) { File.stub(:rename, injected) { adjuster.adjust(surface: "app", prompt: "Replacement") } }
      assert_equal before, contexts.repository.read
      token = "abc123"
      backup = File.join(contexts.repository.runs, token, "previous")
      FileUtils.mkdir_p(File.dirname(backup))
      File.rename(contexts.repository.root, backup)
      journal = File.join(File.dirname(contexts.repository.runs), "context-transaction.json")
      File.write(journal, JSON.generate({"token" => token, "had_root" => true}))
      assert_equal before, contexts.repository.read
      refute File.exist?(journal)
    end
  end
  def test_agent_failure_and_interruption_leave_previous_contexts_available
    with_contexts do |adjuster, agent, contexts, _, _|
      adjuster.adjust(surface: "app")
      before = contexts.repository.read
      agent.callback = -> { raise Interrupt }
      assert_raises(Interrupt) { adjuster.adjust(surface: "app", prompt: "New preference") }
      assert_equal before, contexts.repository.read
      reports = Dir.glob(File.join(contexts.repository.runs, "*/report.json"))
      assert reports.any? { |file| JSON.parse(File.read(file))["status"] == "interrupted" }
    end
  end
  def test_cli_conflict_status_and_context_reader_use_real_adjustment
    with_contexts do |adjuster, agent, contexts, project, _|
      agent.conflict = true
      output, = capture_io do
        Ace::Design::Organisms::Adjuster.stub(:new, adjuster) do
          assert_equal 2, Ace::Design::CLI.start(["profile", "adjust", "--json", "--surface", "app", "--prompt", "Ambiguous"])
        end
      end
      assert_equal "conflict", JSON.parse(output)["status"]
      assert_empty contexts.repository.read
      agent.conflict = false
      adjuster.adjust(surface: "app", prompt: "Visible actions")
      output, = capture_io do
        Dir.chdir(project) do
          assert_equal 0, Ace::Design::CLI.start(["profile", "show", "--surface", "app", "--kind", "component"])
        end
      end
      assert_includes output, "Visible actions"
    end
  end

end
