# frozen_string_literal: true

module TestFactory
  def self.sample_task_metadata(overrides = {})
    {
      id: "v.0.9.0+task.001",
      status: "pending",
      priority: "medium",
      estimate: "4h",
      dependencies: [],
      sort: 100
    }.merge(overrides)
  end

  def self.sample_task_content(metadata = {})
    meta = sample_task_metadata(metadata)
    <<~CONTENT
      ---
      id: #{meta[:id]}
      status: #{meta[:status]}
      priority: #{meta[:priority]}
      estimate: #{meta[:estimate]}
      dependencies: #{meta[:dependencies].to_yaml.lines[1..-1].join.strip}
      sort: #{meta[:sort]}
      ---

      # Sample Task

      ## Description
      This is a sample task for testing.

      ## Planning Steps
      * [ ] Research step
      * [ ] Design step

      ## Execution Steps
      - [ ] Implementation step
      - [ ] Testing step

      ## Acceptance Criteria
      - [ ] All tests pass
      - [ ] Documentation updated
    CONTENT
  end

  def self.sample_release_metadata(overrides = {})
    {
      version: "v.0.9.0",
      name: "Test Release",
      status: "active",
      created_at: Time.now.strftime("%Y-%m-%d")
    }.merge(overrides)
  end

  def self.sample_release_structure(version = "v.0.9.0")
    {
      "#{version}/release.md" => release_content(version),
      "#{version}/tasks/001/task.md" => sample_task_content(id: "#{version}+task.001"),
      "#{version}/tasks/002/task.md" => sample_task_content(id: "#{version}+task.002", status: "in-progress"),
      "#{version}/tasks/003/task.md" => sample_task_content(id: "#{version}+task.003", status: "done"),
      "#{version}/i/001.md" => sample_idea_content
    }
  end

  def self.release_content(version)
    <<~CONTENT
      # Release #{version}

      ## Overview
      Test release for #{version}

      ## Goals
      - Complete test tasks
      - Validate functionality

      ## Status
      Active
    CONTENT
  end

  def self.sample_idea_content(title = "Sample Idea")
    <<~CONTENT
      # #{title}

      This is a sample idea for testing purposes.
      It contains multiple lines and can be used to test idea processing.

      ---
      Captured: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}
    CONTENT
  end

  def self.create_test_filesystem(base_dir)
    FileUtils.mkdir_p(base_dir)

    # Create .ace-taskflow root directory
    taskflow_root = File.join(base_dir, ".ace-taskflow")
    FileUtils.mkdir_p(taskflow_root)

    # Create .ace/taskflow/config.yml for config discovery
    config_dir = File.join(base_dir, ".ace", "taskflow")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), <<~CONFIG)
      taskflow:
        root: .ace-taskflow
        directories:
          tasks: tasks
    CONFIG

    # Create standard structure in .ace-taskflow
    %w[v.0.9.0 backlog done].each do |dir|
      FileUtils.mkdir_p(File.join(taskflow_root, dir))
    end
    # Create v.0.8.0 in done directory since it's completed
    FileUtils.mkdir_p(File.join(taskflow_root, "done", "v.0.8.0"))

    # Create release files
    File.write(File.join(taskflow_root, "v.0.9.0", "release.md"), <<~RELEASE)
      ---
      version: v.0.9.0
      status: active
      created_at: #{Time.now.strftime("%Y-%m-%d")}
      ---

      # Release v.0.9.0
      Test release
    RELEASE

    File.write(File.join(taskflow_root, "done", "v.0.8.0", "release.md"), <<~RELEASE)
      ---
      version: v.0.8.0
      status: completed
      created_at: #{(Time.now - 30 * 24 * 60 * 60).strftime("%Y-%m-%d")}
      ---

      # Release v.0.8.0
      Previous release
    RELEASE

    # Create sample tasks
    create_task_structure(taskflow_root, "v.0.9.0", 5)
    create_task_structure(File.join(taskflow_root, "done"), "v.0.8.0", 3)
    create_task_structure(taskflow_root, "backlog", 10)

    # Create sample ideas
    create_idea_structure(taskflow_root, "v.0.9.0", 3)
    create_idea_structure(taskflow_root, "backlog", 5)
  end

  def self.create_task_structure(base_dir, release, count)
    count.times do |i|
      task_num = sprintf("%03d", i + 1)
      task_dir = File.join(base_dir, release, "tasks", task_num)
      FileUtils.mkdir_p(task_dir)

      status = case i
               when 0 then "done"
               when 1 then "in-progress"
               else "pending"
               end

      File.write(
        File.join(task_dir, "task.#{task_num}.md"),
        sample_task_content(
          id: "#{release}+task.#{task_num}",
          status: status,
          sort: (i + 1) * 100
        )
      )
    end
  end

  def self.create_idea_structure(base_dir, release, count)
    ideas_dir = File.join(base_dir, release, "i")
    FileUtils.mkdir_p(ideas_dir)

    count.times do |i|
      idea_num = sprintf("%03d", i + 1)
      File.write(
        File.join(ideas_dir, "#{idea_num}.md"),
        sample_idea_content("Idea #{idea_num}")
      )
    end
  end

  def self.with_test_directory
    Dir.mktmpdir do |dir|
      # Stub Ace::Core::ConfigDiscovery to return temp dir as project root
      # This prevents tests from finding the real project via PWD environment variable
      with_stubbed_project_root(dir) do
        create_test_filesystem(dir)
        yield dir
      end
    end
  end

  # Create a clean test project with minimal setup (no default fixtures)
  def self.with_clean_project
    Dir.mktmpdir do |dir|
      # Stub Ace::Core::ConfigDiscovery to return temp dir as project root
      # This prevents tests from finding the real project via PWD environment variable
      with_stubbed_project_root(dir) do
        # Create .ace-taskflow root directory
        taskflow_root = File.join(dir, ".ace-taskflow")
        FileUtils.mkdir_p(taskflow_root)

        # Create .ace/taskflow/config.yml for config discovery
        config_dir = File.join(dir, ".ace", "taskflow")
        FileUtils.mkdir_p(config_dir)
        File.write(File.join(config_dir, "config.yml"), "taskflow:\n  root: .ace-taskflow\n")

        # Create standard directories but no content
        %w[backlog done].each do |subdir|
          FileUtils.mkdir_p(File.join(taskflow_root, subdir))
        end

        yield dir
      end
    end
  end

  # Create a specific release with optional tasks
  # @param base_dir [String] Base directory
  # @param version [String] Release version (e.g., "v.0.9.0")
  # @param status [String] Release status: "active", "backlog", or "done"
  # @param tasks [Array<Hash>] Optional array of task specs: [{num: "001", status: "pending", ...}]
  def self.create_release(base_dir, version, status: "active", tasks: [])
    taskflow_root = File.join(base_dir, ".ace-taskflow")

    # Determine release location based on status
    release_path = case status
                   when "active"
                     File.join(taskflow_root, version)
                   when "backlog"
                     File.join(taskflow_root, "backlog", version)
                   when "done"
                     File.join(taskflow_root, "done", version)
                   else
                     File.join(taskflow_root, version)
                   end

    FileUtils.mkdir_p(release_path)
    FileUtils.mkdir_p(File.join(release_path, "tasks"))
    FileUtils.mkdir_p(File.join(release_path, "ideas"))
    FileUtils.mkdir_p(File.join(release_path, "docs"))

    # Create .active marker for active releases
    File.write(File.join(release_path, ".active"), "") if status == "active"

    # Create release.md
    File.write(File.join(release_path, "release.md"), <<~RELEASE)
      ---
      version: #{version}
      status: #{status}
      created_at: #{Time.now.strftime("%Y-%m-%d")}
      ---

      # Release #{version}
      Test release
    RELEASE

    # Create tasks if provided
    tasks.each do |task_spec|
      create_task(release_path, version, task_spec)
    end

    release_path
  end

  # Create a specific task in a release
  # @param release_path [String] Path to release directory
  # @param version [String] Release version
  # @param spec [Hash] Task specification: {num: "001", status: "pending", priority: "medium", ...}
  def self.create_task(release_path, version, spec)
    task_num = spec[:num] || spec[:number] || "001"
    task_dir = File.join(release_path, "tasks", task_num)
    FileUtils.mkdir_p(task_dir)

    task_metadata = {
      id: "#{version}+task.#{task_num}",
      status: spec[:status] || "pending",
      priority: spec[:priority] || "medium",
      estimate: spec[:estimate] || "4h",
      dependencies: spec[:dependencies] || [],
      sort: spec[:sort] || (task_num.to_i * 100)
    }

    File.write(
      File.join(task_dir, "task.#{task_num}.md"),
      sample_task_content(task_metadata)
    )
  end

  # Create multiple tasks with known IDs for predictable testing
  # @param base_dir [String] Base directory
  # @param release [String] Release version
  # @param task_ids [Array<String>] Task numbers (e.g., ["001", "002", "003"])
  # @param statuses [Hash] Optional status overrides: {"001" => "done", "002" => "pending"}
  def self.create_known_tasks(base_dir, release, task_ids, statuses: {})
    taskflow_root = File.join(base_dir, ".ace-taskflow")
    release_path = File.join(taskflow_root, release)

    FileUtils.mkdir_p(File.join(release_path, "t"))

    task_ids.each do |task_num|
      status = statuses[task_num] || "pending"
      create_task(release_path, release, { num: task_num, status: status })
    end
  end

  # Create ideas with known IDs
  # @param base_dir [String] Base directory
  # @param release [String] Release version
  # @param count [Integer] Number of ideas to create
  def self.create_known_ideas(base_dir, release, count)
    taskflow_root = File.join(base_dir, ".ace-taskflow")
    ideas_dir = File.join(taskflow_root, release, "i")
    FileUtils.mkdir_p(ideas_dir)

    count.times do |i|
      idea_num = sprintf("%03d", i + 1)
      File.write(
        File.join(ideas_dir, "#{idea_num}.md"),
        sample_idea_content("Idea #{idea_num}")
      )
    end
  end

  # Stub Ace::Core::ConfigDiscovery.project_root to return a specific directory
  # This is essential for test isolation when running under bundle exec
  # @param project_root_path [String] Path to use as project root
  # @yield Block to execute with stubbed project root
  def self.with_stubbed_project_root(project_root_path)
    require "ace/core/config_discovery"

    # Save original method
    original_method = Ace::Core::ConfigDiscovery.singleton_method(:project_root)

    # Stub to return test directory
    Ace::Core::ConfigDiscovery.define_singleton_method(:project_root) do
      project_root_path
    end

    begin
      yield
    ensure
      # Restore original method
      Ace::Core::ConfigDiscovery.define_singleton_method(:project_root, original_method)
    end
  end
end