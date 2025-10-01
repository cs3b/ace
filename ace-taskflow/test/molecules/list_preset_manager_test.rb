# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/molecules/list_preset_manager"

describe Ace::Taskflow::Molecules::ListPresetManager do
  before do
    @manager = Ace::Taskflow::Molecules::ListPresetManager.new
  end

  describe "default presets" do
    it "loads default presets" do
      presets = @manager.list_presets
      preset_names = presets.map { |p| p[:name] }

      assert_includes preset_names, "next"
      assert_includes preset_names, "recent"
      assert_includes preset_names, "all"
      assert_includes preset_names, "pending"
      assert_includes preset_names, "in-progress"
      assert_includes preset_names, "done"
    end

    it "returns next preset configuration" do
      preset = @manager.get_preset("next")

      assert_equal "next", preset[:name]
      assert_equal "Next actionable tasks (pending + in-progress)", preset[:description]
      assert_equal "current", preset[:context]
      assert_equal ["pending", "in-progress"], preset[:filters][:status]
      assert_equal :sort, preset[:sort][:by]
      assert_equal true, preset[:sort][:ascending]
    end

    it "returns recent preset configuration" do
      preset = @manager.get_preset("recent")

      assert_equal "recent", preset[:name]
      assert_equal "Recently modified items (last 7 days)", preset[:description]
      assert_equal "current", preset[:context]
      assert_equal({}, preset[:filters])
      assert_equal "modified", preset[:sort]["by"]
      assert_equal false, preset[:sort]["ascending"]
    end

    it "returns all preset configuration" do
      preset = @manager.get_preset("all")

      assert_equal "all", preset[:name]
      assert_equal "All tasks in current release (all statuses)", preset[:description]
      assert_equal "current", preset[:context]
      assert_equal({}, preset[:display])
    end
  end

  describe "preset filtering by type" do
    it "filters presets by tasks type" do
      tasks_presets = @manager.list_presets(:tasks)
      tasks_preset_names = tasks_presets.map { |p| p[:name] }

      # next is tasks-specific
      assert_includes tasks_preset_names, "next"
      # universal presets should also appear
      assert_includes tasks_preset_names, "recent"
      assert_includes tasks_preset_names, "all"
    end

    it "filters presets by ideas type" do
      ideas_presets = @manager.list_presets(:ideas)
      ideas_preset_names = ideas_presets.map { |p| p[:name] }

      # next is tasks-specific, should not appear for ideas
      refute_includes ideas_preset_names, "next"
      # universal presets should appear
      assert_includes ideas_preset_names, "recent"
      assert_includes ideas_preset_names, "all"
    end
  end

  describe "preset existence checks" do
    it "checks preset existence for tasks" do
      assert @manager.preset_exists?("next", :tasks)
      assert @manager.preset_exists?("recent", :tasks)
      refute @manager.preset_exists?("nonexistent", :tasks)
    end

    it "checks preset existence for ideas" do
      refute @manager.preset_exists?("next", :ideas)
      assert @manager.preset_exists?("recent", :ideas)
      assert @manager.preset_exists?("all", :ideas)
      refute @manager.preset_exists?("nonexistent", :ideas)
    end
  end

  describe "preset application" do
    it "applies preset with additional filters" do
      result = @manager.apply_preset("next", { priority: ["high"] })

      assert_equal "next", result[:name]
      assert_equal "current", result[:context]
      assert_equal ["pending", "in-progress"], result[:filters]["status"]
      assert_equal ["high"], result[:filters][:priority]
    end

    it "merges array filters correctly" do
      result = @manager.apply_preset("pending", { status: ["blocked"] })

      # Should merge pending + blocked
      assert_includes result[:filters][:status], "pending"
      assert_includes result[:filters][:status], "blocked"
    end

    it "overwrites non-array filters" do
      result = @manager.apply_preset("next", { days: 14 })

      assert_equal "current", result[:context]
      assert_equal 14, result[:filters][:days]
    end
  end

  describe "type compatibility" do
    it "returns nil for incompatible preset-type combinations" do
      # next preset is tasks-only
      assert_nil @manager.get_preset("next", :ideas)
      assert_nil @manager.get_preset("next", :releases)
    end

    it "returns preset for compatible type combinations" do
      # recent is universal
      refute_nil @manager.get_preset("recent", :tasks)
      refute_nil @manager.get_preset("recent", :ideas)
      refute_nil @manager.get_preset("recent", :releases)
    end
  end
end