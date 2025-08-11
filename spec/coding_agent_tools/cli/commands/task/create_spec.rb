# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/task/create"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Task::Create do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:project_root) { temp_dir }
  let(:release_manager) { instance_double(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager) }
  let(:task_manager) { instance_double(CodingAgentTools::Organisms::TaskflowManagement::TaskManager) }
  let(:file_handler) { instance_double(CodingAgentTools::Molecules::FileIoHandler) }

  before do
    # Create project structure
    FileUtils.mkdir_p(File.join(temp_dir, "dev-taskflow/current/v.0.4.0-replanning/tasks"))

    # Stub project root detection
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)

    # Stub component initialization
    allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(release_manager)
    allow(CodingAgentTools::Organisms::TaskflowManagement::TaskManager).to receive(:new).and_return(task_manager)
    allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(file_handler)

    # Default stubs
    manager_result = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager::ManagerResult
    allow(release_manager).to receive(:generate_id).and_return(
      manager_result.new("v.0.4.0+task.123", true, nil)
    )
    allow(release_manager).to receive(:resolve_path).with("tasks", create_if_missing: true).and_return(
      File.join(temp_dir, "dev-taskflow/current/v.0.4.0-replanning/tasks")
    )
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#call" do
    context "with valid basic options" do
      it "creates a task with required title" do
        expect(file_handler).to receive(:write_content) do |content, path, _options|
          expect(path).to end_with("v.0.4.0+task.123-implement-feature-x.md")
          expect(content).to include("# Implement feature X")
          expect(content).to include("id: v.0.4.0+task.123")
          expect(content).to include("status: draft")
          expect(content).to include("priority: medium")
          expect(content).to include("estimate: TBD")
        end

        expect(command).to receive(:puts).with("File created successfully")
        expect(command).to receive(:puts).with(/Created:.*v\.0\.4\.0\+task\.123-implement-feature-x\.md/)

        result = command.call(title: "Implement feature X")
        expect(result).to eq(0)
      end
    end

    context "with all standard options" do
      it "creates a task with all metadata" do
        expect(file_handler).to receive(:write_content) do |content, _path, _options|
          expect(content).to include("id: v.0.4.0+task.123")
          expect(content).to include("status: pending")
          expect(content).to include("priority: high")
          expect(content).to include("estimate: 4h")
        end

        expect(command).to receive(:puts).with("File created successfully")
        expect(command).to receive(:puts).with(/Created:/)

        result = command.call(
          title: "Fix critical bug",
          priority: "high",
          estimate: "4h",
          status: "pending"
        )
        expect(result).to eq(0)
      end
    end

    context "with dynamic flags" do
      it "adds dynamic metadata to frontmatter" do
        # Simulate ARGV with dynamic flags
        stub_const("ARGV", ["create", "--title", "Research task", "--custom-field", "test-value", "--another-flag", "dynamic"])

        expect(file_handler).to receive(:write_content) do |content, _path, _options|
          expect(content).to include("custom-field: test-value")
          expect(content).to include("another-flag: dynamic")
        end

        expect(command).to receive(:puts).with("File created successfully")
        expect(command).to receive(:puts).with(/Created:/)
        expect(command).to receive(:puts).with("Added metadata: custom_field=test-value, another_flag=dynamic")

        result = command.call(title: "Research task")
        expect(result).to eq(0)
      end
    end

    context "when title is missing" do
      it "is handled by dry-cli" do
        # Dry::CLI handles missing required options before call method is invoked
        # This test verifies that title is properly marked as required
        expect(described_class.arguments).to be_empty
        expect(described_class.options.map(&:name)).to include(:title)

        title_option = described_class.options.find { |opt| opt.name == :title }
        expect(title_option).to be_required
      end
    end

    context "when release manager fails to generate ID" do
      it "returns error" do
        manager_result = CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager::ManagerResult
        allow(release_manager).to receive(:generate_id).and_return(
          manager_result.new(nil, false, "Failed to generate ID")
        )

        expect(command).to receive(:puts).with("Error: Failed to generate ID")

        result = command.call(title: "Test task")
        expect(result).to eq(1)
      end
    end

    context "when release manager fails to resolve path" do
      it "returns error" do
        allow(release_manager).to receive(:resolve_path).and_raise(
          StandardError.new("No current release found")
        )

        expect(command).to receive(:puts).with("Error: No current release found")

        result = command.call(title: "Test task")
        expect(result).to eq(1)
      end
    end

    context "when file write fails" do
      it "returns error" do
        allow(file_handler).to receive(:write_content).and_raise(
          CodingAgentTools::Error.new("File already exists")
        )

        expect(command).to receive(:puts).with("Error: File already exists")

        result = command.call(title: "Test task")
        expect(result).to eq(1)
      end
    end

    context "with custom template" do
      it "uses template content when available" do
        # Create config directory and template
        config_dir = File.join(temp_dir, ".coding-agent")
        FileUtils.mkdir_p(config_dir)

        template_content = <<~TEMPLATE
          ---
          id: {id}
          title: {title}
          priority: {priority}
          custom: template
          ---
          
          # {title}
          
          Created on {date}
        TEMPLATE

        config_content = {
          "templates" => {
            "task" => {
              "path" => File.join(config_dir, "task-template.md")
            }
          }
        }.to_yaml

        File.write(File.join(config_dir, "task-manager.yml"), config_content)
        File.write(File.join(config_dir, "task-template.md"), template_content)

        expect(file_handler).to receive(:write_content) do |content, _path, _options|
          expect(content).to include("custom: template")
          expect(content).to include("Created on #{Time.now.strftime("%Y-%m-%d")}")
        end

        result = command.call(title: "Templated task")
        expect(result).to eq(0)
      end
    end

    context "filename generation" do
      it "creates valid filename from title" do
        test_cases = {
          "Simple Task" => "v.0.4.0+task.123-simple-task.md",
          "Task with Special Characters!@#" => "v.0.4.0+task.123-task-with-special-characters.md",
          "Task   with   multiple   spaces" => "v.0.4.0+task.123-task-with-multiple-spaces.md",
          "A" * 100 => "v.0.4.0+task.123-#{"a" * 60}.md"  # Should truncate
        }

        test_cases.each do |title, expected_filename|
          expect(file_handler).to receive(:write_content) do |_content, path, _options|
            expect(File.basename(path)).to eq(expected_filename)
          end

          command.call(title: title)
        end
      end
    end
  end
end
