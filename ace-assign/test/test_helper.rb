# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/assign"

require "minitest/autorun"
require "ace/test_support"
require "fileutils"
require "tmpdir"

class AceAssignTestCase < AceTestCase
  def setup
    super
    # Clean class-level tmpdir contents before each test (skip if not yet created)
    tmp = self.class.instance_variable_get(:@class_temp_dir)
    if tmp && Dir.exist?(tmp)
      Dir.children(tmp).each do |child|
        FileUtils.rm_rf(File.join(tmp, child))
      end
    end
  end

  # Reuse a single tmpdir per test class instead of creating/destroying per test
  def with_temp_cache
    yield self.class.class_temp_dir
  end

  class << self
    def class_temp_dir
      @class_temp_dir ||= Dir.mktmpdir("ace-assign-test")
    end
  end

  class InertSkillAssignSourceResolver
    def assign_step_catalog
      []
    end

    def assign_capable_skill_names
      []
    end

    def resolve_step_rendering(_step_name)
      nil
    end

    def resolve_skill_rendering(_skill_name)
      nil
    end

    def resolve_workflow_rendering(*)
      nil
    end

    def resolve_workflow_assign_config(*)
      nil
    end

    def resolve_assign_config(_skill_name)
      nil
    end

    def cache_signature
      "inert-test-skill-source-resolver"
    end
  end

  def build_fast_executor(cache_base:)
    Ace::Assign::Organisms::AssignmentExecutor.new(
      cache_base: cache_base,
      skill_source_resolver: InertSkillAssignSourceResolver.new,
      step_catalog: []
    )
  end

  def build_fast_command_executor(cache_base:, target: nil)
    executor = build_fast_executor(cache_base: cache_base)
    return executor if target.nil? || target.assignment_id.to_s.strip.empty?

    assignment_id = target.assignment_id
    manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_base)
    assignment = manager.load(assignment_id)
    raise Ace::Assign::AssignmentErrors::NotFound, "Assignment '#{assignment_id}' not found" unless assignment

    executor.assignment_manager.define_singleton_method(:find_active) { assignment }
    executor
  end

  def with_fast_command_executor(command, cache_base:, &block)
    command.stub(:build_executor_for_target, ->(target) do
      build_fast_command_executor(cache_base: cache_base, target: target)
    end) do
      yield
    end
  end

  Minitest.after_run do
    AceAssignTestCase.subclasses.each do |klass|
      next unless klass.instance_variable_get(:@class_temp_dir)
      FileUtils.rm_rf(klass.instance_variable_get(:@class_temp_dir))
    end
  end

  # Create a test assignment config
  def create_test_config(dir, steps: nil, name: "test-session")
    steps ||= [
      {"name" => "init", "instructions" => "Initialize project"},
      {"name" => "build", "instructions" => "Build the project"},
      {"name" => "test", "instructions" => "Run tests"}
    ]

    config = {
      "assignment" => {
        "name" => name,
        "description" => "Test workflow"
      },
      "steps" => steps
    }

    config_path = File.join(dir, "job-#{name}.yaml")
    File.write(config_path, config.to_yaml)
    config_path
  end

  # Create a test report file
  def create_report(dir, content = "Test report")
    report_path = File.join(dir, "report.md")
    File.write(report_path, content)
    report_path
  end
end
