# frozen_string_literal: true

require "fileutils"

# Builds a temporary project with a coworker config, a task folder, and an
# assignment metadata file. Used by molecule/organism/command tests with
# injectable probes; the integration fixture layers a real ace-assign
# assignment on top.
module CoworkerFixture
  module_function

  def build_task(dir, id:, title: "Fixture task")
    folder = File.join(dir, ".ace-tasks", "#{id}-fixture-task")
    FileUtils.mkdir_p(folder)
    File.write(File.join(folder, "#{id}-fixture-task.s.md"), <<~SPEC)
      ---
      id: #{id}
      status: pending
      priority: medium
      created_at: "2026-10-18 00:00:00"
      title: "#{title}"
      ---

      # #{title}

      Fixture body.
    SPEC
    folder
  end

  def build_assignment(dir, id:, task_id:)
    folder = File.join(dir, ".ace-local", "assign", id)
    FileUtils.mkdir_p(folder)
    File.write(File.join(folder, "assignment.yaml"), <<~YAML)
      session_id: #{id}
      name: fixture-work
      task_id: #{task_id}
    YAML
    folder
  end

  def build_config(dir, assignment:, task:, instructions: "roles/worker.md", role: "worker", overseer: "overseer@lab")
    FileUtils.mkdir_p(File.join(dir, ".ace-local", "coworker"))
    instructions_file = File.join(dir, instructions)
    FileUtils.mkdir_p(File.dirname(instructions_file))
    File.write(instructions_file, "# Worker role\nDo the work.\n")
    config_path = File.join(dir, ".ace-local", "coworker", "config.yml")
    File.write(config_path, <<~YAML)
      role: #{role}
      instructions: #{instructions}
      start_prompt: "Drive assignment #{assignment} for task #{task} as #{role}."
      task: #{task}
      assignment: #{assignment}
      overseer: #{overseer}
    YAML
    config_path
  end

  def status_json(state:, steps:, id: "fix001", name: "fixture-work")
    require "json"
    steps_payload = steps.map do |s|
      {"number" => s.fetch(:number), "name" => s.fetch(:name), "status" => s.fetch(:status)}
    end
    done = steps_payload.count { |s| s["status"] == "done" }
    JSON.generate({
      assignment: {id: id, name: name, state: state},
      steps: steps_payload,
      active_steps: steps_payload.select { |s| s["status"] == "active" },
      progress: "#{done}/#{steps_payload.size} done"
    })
  end

  SuccessStatus = Struct.new(:success?) do
    def self.ok
      new(true)
    end
  end

  def fake_probe_runner(json)
    ->(_argv, _cwd) { [json, "", SuccessStatus.ok] }
  end
end
