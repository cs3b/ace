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
      "#{version}/t/001/task.md" => sample_task_content(id: "#{version}+task.001"),
      "#{version}/t/002/task.md" => sample_task_content(id: "#{version}+task.002", status: "in-progress"),
      "#{version}/t/003/task.md" => sample_task_content(id: "#{version}+task.003", status: "done"),
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

    # Create standard structure
    %w[v.0.9.0 v.0.8.0 backlog done].each do |dir|
      FileUtils.mkdir_p(File.join(base_dir, dir))
    end

    # Create sample tasks
    create_task_structure(base_dir, "v.0.9.0", 5)
    create_task_structure(base_dir, "v.0.8.0", 3)
    create_task_structure(base_dir, "backlog", 10)

    # Create sample ideas
    create_idea_structure(base_dir, "v.0.9.0", 3)
    create_idea_structure(base_dir, "backlog", 5)
  end

  def self.create_task_structure(base_dir, release, count)
    count.times do |i|
      task_num = sprintf("%03d", i + 1)
      task_dir = File.join(base_dir, release, "t", task_num)
      FileUtils.mkdir_p(task_dir)

      status = case i
               when 0 then "done"
               when 1 then "in-progress"
               else "pending"
               end

      File.write(
        File.join(task_dir, "task.md"),
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
      create_test_filesystem(dir)
      yield dir
    end
  end
end