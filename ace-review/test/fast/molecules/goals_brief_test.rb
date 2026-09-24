# frozen_string_literal: true

require "test_helper"
require "fileutils"

class GoalsBriefTest < AceReviewTest
  class FakeExecutor
    attr_reader :calls

    def initialize
      @calls = []
    end

    def execute(**args)
      @calls << args
      {success: true, response: {
        objective: {text: "Review the admin-publication flow", status: "proposed", sources: ["head:.ace-tasks/task.s.md"]},
        accepted_requirements: [{text: "Public reads use projections", sources: ["base:docs/contract.md"]}],
        constraints: [], proposed_constraints: [], proposed_changes: [{text: "Add a new route", sources: ["head:.ace-tasks/task.s.md"]}],
        deferred: []
      }.to_json, execution: {provider: "pi", model: "zai/glm-5.3-flash"}}
    end
  end

  def setup
    super
    @session_dir = File.join(@test_dir, "session")
    FileUtils.mkdir_p(@session_dir)
    @base = File.join(@test_dir, "base.md")
    @head = File.join(@test_dir, "head.md")
    File.write(@base, "Public reads use projections; café titles remain localized\n")
    File.write(@head, "Add a new route\n")
    @executor = FakeExecutor.new
    @brief = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: @executor, model_resolver: ->(candidate) { candidate })
  end

  def sources
    [{path: "docs/contract.md", ref: "base", authority: "accepted", snapshot: @base},
      {path: ".ace-tasks/task.s.md", ref: "head", authority: "proposed", snapshot: @head}]
  end

  def test_generates_once_and_reuses_content_addressed_cache
    first = @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    second = @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir)

    assert first[:success], first[:error]
    assert second[:success], second[:error]
    refute first[:cache_hit]
    assert second[:cache_hit]
    assert_equal second[:path], first[:path]
    assert File.file?(first[:path])
    assert_equal 1, @executor.calls.size
    assert_includes second[:content], "Proposed changes (not accepted authority)"
    assert_includes second[:content], "base:docs/contract.md [accepted]"
  end

  def test_new_pr_head_url_reuses_goal_cache_and_renders_current_link
    first_sources = sources.map(&:dup)
    first_sources.last[:url] = "https://github.com/cs3b/ace/blob/old/.ace-tasks/task.s.md"
    first = @brief.prepare(sources: first_sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    next_session = Dir.mktmpdir("goals-new-head")
    second_sources = sources.map(&:dup)
    second_sources.last[:url] = "https://github.com/cs3b/ace/blob/new/.ace-tasks/task.s.md"
    second = @brief.prepare(sources: second_sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: next_session)

    assert first[:success], first[:error]
    assert second[:success], second[:error]
    assert second[:cache_hit]
    assert_equal 1, @executor.calls.size
    assert_includes File.read(second[:path]), "/blob/new/"
    refute_includes File.read(second[:path]), "/blob/old/"
  ensure
    FileUtils.remove_entry(next_session) if next_session && File.exist?(next_session)
  end

  def test_reasoning_suffix_keeps_cache_identity_without_changing_model_identity
    result = @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash:max"],
      session_dir: @session_dir, generate: true)
    assert result[:success], result[:error]
    assert_equal "pi:zai/glm-5.3-flash:max", result.dig(:metadata, "resolved_model")
  end

  def test_provider_only_selector_is_rejected_before_generation
    result = @brief.prepare(sources: sources, models: ["pi:"],
      session_dir: @session_dir, generate: true)
    refute result[:success]
    assert_match(/must name a model/, result[:error])
    assert_empty @executor.calls
  end

  def test_source_change_invalidates_cache_without_recompressing_unchanged_sources
    @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    File.write(@head, "Add a different route\n")
    missing = @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir)

    refute missing[:success]
    assert_match(/not cached/, missing[:error])
    regenerated = @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    assert regenerated[:success]
    assert_equal 2, @executor.calls.size
  end

  def test_different_model_has_separate_cache_identity
    @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    other = @brief.prepare(sources: sources, models: ["gemini:gemini-3-flash-preview"],
      session_dir: @session_dir)

    refute other[:success]
    assert_match(/not cached/, other[:error])
  end

  def test_changed_summarization_instructions_invalidate_cache
    @brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    changed = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: @executor, model_resolver: ->(candidate) { candidate },
      system_prompt: "A revised summarization contract")

    result = changed.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir)

    refute result[:success]
    assert_match(/not cached/, result[:error])
  end

  def test_unavailable_preferred_model_uses_available_substitute
    brief = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: @executor,
      model_resolver: ->(candidate) { (candidate == "unavailable:model") ? nil : candidate })
    result = brief.prepare(sources: sources,
      models: ["unavailable:model", "pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)

    assert result[:success], result[:error]
    assert_equal "pi:zai/glm-5.3-flash", @executor.calls.first[:model]
  end

  def test_reuses_fallback_cache_before_generating_with_recovered_preferred_model
    preferred_available = false
    brief = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: @executor,
      model_resolver: ->(candidate) { (candidate == "preferred:model" && !preferred_available) ? nil : candidate })
    first = brief.prepare(sources: sources, models: ["preferred:model", "pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    assert first[:success], first[:error]
    preferred_available = true
    second = brief.prepare(sources: sources, models: ["preferred:model", "pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    assert second[:success], second[:error]
    assert second[:cache_hit]
    assert_equal "pi:zai/glm-5.3-flash", second.dig(:metadata, "resolved_model")
    assert_equal 1, @executor.calls.size
  end

  def test_missing_preferred_brief_field_uses_fallback_model
    valid_executor = @executor
    calls = []
    executor = Object.new
    executor.define_singleton_method(:execute) do |**args|
      calls << args[:model]
      if calls.size == 1
        {success: true, response: {objective: {text: "Incomplete"}}.to_json,
         execution: {provider: "pi", model: "zai/glm-5.3"}}
      else
        valid_executor.execute(**args)
      end
    end
    brief = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: executor, model_resolver: ->(candidate) { candidate })
    result = brief.prepare(sources: sources,
      models: ["pi:zai/glm-5.3", "pi:zai/glm-5.3-flash"], session_dir: @session_dir, generate: true)
    assert result[:success], result[:error]
    assert_equal ["pi:zai/glm-5.3", "pi:zai/glm-5.3-flash"], calls
    assert_equal "pi:zai/glm-5.3-flash", result.dig(:metadata, "resolved_model")
  end

  def test_rejects_proposed_requirement_promoted_to_accepted
    executor = Object.new
    def executor.execute(**_args)
      {success: true, response: {objective: {text: "Goal", status: "proposed", sources: ["head:.ace-tasks/task.s.md"]}, accepted_requirements: [
                                                                                                                          {text: "Head says so", sources: ["head:.ace-tasks/task.s.md"]}
                                                                                                                        ],
                                 constraints: [], proposed_constraints: [], proposed_changes: [], deferred: []}.to_json,
       execution: {provider: "pi", model: "zai/glm-5.3-flash"}}
    end
    brief = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: executor, model_resolver: ->(candidate) { candidate })
    result = brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)

    refute result[:success]
    refute File.exist?(File.join(@test_dir, ".ace-local", "compressor", "goals"))
  end

  def test_rejects_head_only_constraint_as_accepted
    executor = Object.new
    def executor.execute(**_args)
      {success: true, response: {objective: {text: "Goal", status: "accepted", sources: ["base:docs/contract.md"]},
                                 accepted_requirements: [],
                                 constraints: [{text: "Head-only rule", sources: ["head:.ace-tasks/task.s.md"]}],
                                 proposed_constraints: [], proposed_changes: [], deferred: []}.to_json,
       execution: {provider: "pi", model: "zai/glm-5.3-flash"}}
    end
    brief = Ace::Review::Molecules::GoalsBrief.new(project_root: @test_dir,
      llm_executor: executor, model_resolver: ->(candidate) { candidate })
    result = brief.prepare(sources: sources, models: ["pi:zai/glm-5.3-flash"],
      session_dir: @session_dir, generate: true)
    refute result[:success]
    assert_match(/accepted authority/, result[:error])
  end
end
