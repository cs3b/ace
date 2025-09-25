# frozen_string_literal: true

require "spec_helper"
require "ace/taskflow/organisms/task_scheduler"
require "ace/taskflow/organisms/task_manager"
require "tempfile"
require "fileutils"

RSpec.describe Ace::Taskflow::Organisms::TaskScheduler do
  let(:temp_dir) { Dir.mktmpdir }
  let(:task_manager) { Ace::Taskflow::Organisms::TaskManager.new }
  let(:scheduler) { described_class.new(task_manager) }

  before do
    allow(task_manager).to receive(:instance_variable_get).with(:@root_path).and_return(temp_dir)
    allow_any_instance_of(Ace::Taskflow::Molecules::ConfigLoader).to receive(:find_root).and_return(temp_dir)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#reschedule" do
    context "with add_next strategy" do
      it "places tasks before existing pending tasks" do
        # Create mock tasks
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md"), sort: 100 },
          { id: "v.0.9.0+task.026", status: "pending", path: File.join(temp_dir, "026.md"), sort: 200 },
          { id: "v.0.9.0+task.027", status: "done", path: File.join(temp_dir, "027.md") }
        ]

        # Create task files
        tasks.each do |task|
          File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n#{"sort: #{task[:sort]}\n" if task[:sort]}---\n# Task")
        end

        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        # Reschedule task 027 to add_next
        scheduler.reschedule(["027"], strategy: :add_next)

        # Read the updated file to verify sort value
        content = File.read(File.join(temp_dir, "027.md"))
        expect(content).to match(/sort: \d+/)

        # The sort value should be less than 100 (the minimum of pending tasks)
        sort_match = content.match(/sort: (\d+)/)
        expect(sort_match).not_to be_nil
        expect(sort_match[1].to_i).to be < 100
      end
    end

    context "with add_at_end strategy" do
      it "places tasks after highest task" do
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md"), sort: 100 },
          { id: "v.0.9.0+task.026", status: "done", path: File.join(temp_dir, "026.md") }
        ]

        tasks.each do |task|
          File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n#{"sort: #{task[:sort]}\n" if task[:sort]}---\n# Task")
        end

        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        scheduler.reschedule(["026"], strategy: :add_at_end)

        content = File.read(File.join(temp_dir, "026.md"))
        sort_match = content.match(/sort: (\d+)/)
        expect(sort_match).not_to be_nil
        expect(sort_match[1].to_i).to be > 100
      end
    end

    context "with after strategy" do
      it "places tasks after the reference task" do
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md"), sort: 100 },
          { id: "v.0.9.0+task.026", status: "pending", path: File.join(temp_dir, "026.md"), sort: 200 },
          { id: "v.0.9.0+task.027", status: "done", path: File.join(temp_dir, "027.md") }
        ]

        tasks.each do |task|
          File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n#{"sort: #{task[:sort]}\n" if task[:sort]}---\n# Task")
        end

        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        scheduler.reschedule(["027"], strategy: :after, reference_task: "025")

        content = File.read(File.join(temp_dir, "027.md"))
        sort_match = content.match(/sort: (\d+)/)
        expect(sort_match).not_to be_nil
        sort_value = sort_match[1].to_i
        expect(sort_value).to be > 100
        expect(sort_value).to be < 200
      end
    end

    context "with before strategy" do
      it "places tasks before the reference task" do
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md"), sort: 100 },
          { id: "v.0.9.0+task.026", status: "pending", path: File.join(temp_dir, "026.md"), sort: 200 },
          { id: "v.0.9.0+task.027", status: "done", path: File.join(temp_dir, "027.md") }
        ]

        tasks.each do |task|
          File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n#{"sort: #{task[:sort]}\n" if task[:sort]}---\n# Task")
        end

        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        scheduler.reschedule(["027"], strategy: :before, reference_task: "026")

        content = File.read(File.join(temp_dir, "027.md"))
        sort_match = content.match(/sort: (\d+)/)
        expect(sort_match).not_to be_nil
        sort_value = sort_match[1].to_i
        expect(sort_value).to be > 100
        expect(sort_value).to be < 200
      end
    end

    context "with task identifier resolution" do
      it "resolves task by number only" do
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md") }
        ]

        tasks.each do |task|
          File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n---\n# Task")
        end

        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        expect { scheduler.reschedule(["025"], strategy: :add_at_end) }.not_to raise_error

        content = File.read(File.join(temp_dir, "025.md"))
        expect(content).to match(/sort: \d+/)
      end

      it "resolves task by partial ID" do
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md") }
        ]

        tasks.each do |task|
          File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n---\n# Task")
        end

        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        expect { scheduler.reschedule(["task.025"], strategy: :add_at_end) }.not_to raise_error

        content = File.read(File.join(temp_dir, "025.md"))
        expect(content).to match(/sort: \d+/)
      end
    end

    context "error handling" do
      it "raises error when no valid tasks found" do
        allow(task_manager).to receive(:list_tasks).and_return([])

        expect { scheduler.reschedule(["999"], strategy: :add_next) }.to raise_error(/No valid tasks found/)
      end

      it "raises error when reference task not found" do
        tasks = [
          { id: "v.0.9.0+task.025", status: "pending", path: File.join(temp_dir, "025.md") }
        ]

        File.write(tasks[0][:path], "---\nid: #{tasks[0][:id]}\nstatus: #{tasks[0][:status]}\n---\n# Task")
        allow(task_manager).to receive(:list_tasks).and_return(tasks)

        expect { scheduler.reschedule(["025"], strategy: :after, reference_task: "999") }.to raise_error(/Could not find reference task/)
      end
    end
  end
end