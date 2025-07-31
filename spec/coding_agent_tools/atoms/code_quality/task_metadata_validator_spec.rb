# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::TaskMetadataValidator do
  let(:temp_dir) { Dir.mktmpdir }

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "uses default task directories" do
      validator = described_class.new
      expect(validator.task_dirs).to include("dev-taskflow/current", "dev-taskflow/backlog")
    end

    it "accepts custom task directories" do
      custom_dirs = ["custom/tasks", "other/tasks"]
      validator = described_class.new(task_dirs: custom_dirs)
      expect(validator.task_dirs).to eq(custom_dirs)
    end

    it "accepts project root" do
      validator = described_class.new(project_root: "/project/root")
      expect(validator.project_root).to eq("/project/root")
    end
  end

  describe "#validate" do
    let(:validator) { described_class.new(task_dirs: [temp_dir]) }

    context "with no task files" do
      it "returns successful validation with empty results" do
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:findings]).to be_empty
      end
    end

    context "with valid task files" do
      before do
        create_task_file("valid_task.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high"
        }, "# Valid Task")
      end

      it "validates successfully" do
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "with specific paths validation" do
      let(:specific_file) { File.join(temp_dir, "specific.md") }

      before do
        create_task_file("specific.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high"
        }, "# Specific Task")
      end

      it "validates only specified paths" do
        result = validator.validate([specific_file])

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end

      it "handles directory paths" do
        result = validator.validate([temp_dir])

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end

      it "ignores non-markdown files in directories" do
        File.write(File.join(temp_dir, "readme.txt"), "not markdown")
        result = validator.validate([temp_dir])

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end

      it "handles individual markdown files" do
        result = validator.validate([specific_file])

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "with missing frontmatter" do
      before do
        File.write(File.join(temp_dir, "no_frontmatter.md"), "# Task without frontmatter")
      end

      it "reports malformed frontmatter error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Malformed frontmatter/))
      end
    end

    context "with malformed frontmatter" do
      before do
        content = <<~CONTENT
          not frontmatter
          ---
          id: v.0.1.0+task.1
          ---
          # Task
        CONTENT
        File.write(File.join(temp_dir, "malformed.md"), content)
      end

      it "reports malformed frontmatter error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Malformed frontmatter/))
      end
    end

    context "with invalid YAML" do
      before do
        content = <<~CONTENT
          ---
          id: v.0.1.0+task.1
          invalid: yaml: structure: here
          ---
          # Task
        CONTENT
        File.write(File.join(temp_dir, "invalid_yaml.md"), content)
      end

      it "reports YAML syntax error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Invalid YAML/))
      end
    end

    context "with non-hash frontmatter" do
      before do
        content = <<~CONTENT
          ---
          - this is an array
          - not a hash
          ---
          # Task
        CONTENT
        File.write(File.join(temp_dir, "array_frontmatter.md"), content)
      end

      it "reports non-hash frontmatter error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Frontmatter is not a Hash/))
      end
    end

    context "with missing required fields" do
      before do
        create_task_file("missing_fields.md", {
          "id" => "v.0.1.0+task.1"
          # Missing status and priority
        }, "# Task")
      end

      it "reports missing required fields" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Missing required field 'status'/))
        expect(result[:errors]).to include(match(/Missing required field 'priority'/))
      end
    end

    context "with invalid ID format" do
      before do
        create_task_file("invalid_id.md", {
          "id" => "invalid-id-format",
          "status" => "pending",
          "priority" => "high"
        }, "# Task")
      end

      it "reports invalid ID format" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Invalid ID format/))
      end
    end

    context "with non-string ID" do
      before do
        create_task_file("numeric_id.md", {
          "id" => 123,
          "status" => "pending",
          "priority" => "high"
        }, "# Task")
      end

      it "reports non-string ID error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/ID must be a string/))
      end

      context "in backlog directory" do
        let(:backlog_dir) { File.join(temp_dir, "backlog") }
        let(:validator) { described_class.new(task_dirs: [backlog_dir]) }

        before do
          FileUtils.mkdir_p(backlog_dir)
          create_task_file("backlog/numeric_id.md", {
            "id" => 123,
            "status" => "pending",
            "priority" => "high"
          }, "# Task")
        end

        it "allows numeric IDs in backlog" do
          result = validator.validate

          expect(result[:success]).to be true
        end
      end
    end

    context "with invalid status" do
      before do
        create_task_file("invalid_status.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "invalid-status",
          "priority" => "high"
        }, "# Task")
      end

      it "reports invalid status" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Invalid status/))
      end
    end

    context "with non-string status" do
      before do
        create_task_file("numeric_status.md", {
          "id" => "v.0.1.0+task.1",
          "status" => 1,
          "priority" => "high"
        }, "# Task")
      end

      it "reports non-string status error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Status must be a string/))
      end
    end

    context "with valid statuses" do
      described_class::VALID_STATUSES.each do |status|
        it "accepts valid status: #{status}" do
          create_task_file("status_#{status}.md", {
            "id" => "v.0.1.0+task.1",
            "status" => status,
            "priority" => "high"
          }, "# Task")

          result = validator.validate

          expect(result[:success]).to be true
        end
      end
    end

    context "with invalid priority" do
      before do
        create_task_file("invalid_priority.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "invalid-priority"
        }, "# Task")
      end

      it "reports invalid priority" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Invalid priority/))
      end
    end

    context "with non-string priority" do
      before do
        create_task_file("numeric_priority.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => 3
        }, "# Task")
      end

      it "reports non-string priority error" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Priority must be a string/))
      end
    end

    context "with valid priorities" do
      described_class::VALID_PRIORITIES.each do |priority|
        it "accepts valid priority: #{priority}" do
          create_task_file("priority_#{priority}.md", {
            "id" => "v.0.1.0+task.1",
            "status" => "pending",
            "priority" => priority
          }, "# Task")

          result = validator.validate

          expect(result[:success]).to be true
        end
      end
    end

    context "with estimate validation" do
      context "with valid estimates" do
        %w[1h 2.5h 3d 1w 5sp 10pt 2wk 1mo].each do |estimate|
          it "accepts valid estimate: #{estimate}" do
            create_task_file("estimate_#{estimate.tr(".", "_")}.md", {
              "id" => "v.0.1.0+task.1",
              "status" => "pending",
              "priority" => "high",
              "estimate" => estimate
            }, "# Task")

            result = validator.validate

            expect(result[:success]).to be true
          end
        end
      end

      context "with invalid estimates" do
        %w[1hour 2days invalid 1x].each do |estimate|
          it "rejects invalid estimate: #{estimate}" do
            create_task_file("bad_estimate_#{estimate}.md", {
              "id" => "v.0.1.0+task.1",
              "status" => "pending",
              "priority" => "high",
              "estimate" => estimate
            }, "# Task")

            result = validator.validate

            expect(result[:success]).to be false
            expect(result[:errors]).to include(match(/Invalid estimate format/))
          end
        end
      end
    end

    context "with dependencies validation" do
      it "accepts array dependencies" do
        create_task_file("with_deps.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high",
          "dependencies" => ["v.0.1.0+task.2", "v.0.1.0+task.3"]
        }, "# Task")

        result = validator.validate

        expect(result[:success]).to be true
      end

      it "accepts empty array dependencies" do
        create_task_file("empty_deps.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high",
          "dependencies" => []
        }, "# Task")

        result = validator.validate

        expect(result[:success]).to be true
      end

      it "accepts null dependencies" do
        create_task_file("null_deps.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high",
          "dependencies" => nil
        }, "# Task")

        result = validator.validate

        expect(result[:success]).to be true
      end

      it "rejects non-array dependencies" do
        create_task_file("string_deps.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high",
          "dependencies" => "v.0.1.0+task.2"
        }, "# Task")

        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Dependencies must be an array/))
      end
    end

    context "with missing H1 title" do
      before do
        create_task_file("no_h1.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high"
        }, "## H2 Title\n\nNo H1 here.")
      end

      it "reports missing H1 title" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors]).to include(match(/Missing H1 title in body/))
      end
    end

    context "with valid H1 title" do
      before do
        create_task_file("with_h1.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high"
        }, "# Valid H1 Title\n\nContent here.")
      end

      it "validates successfully" do
        result = validator.validate

        expect(result[:success]).to be true
      end
    end

    context "with path resolution" do
      let(:project_root) { temp_dir }
      let(:validator) { described_class.new(task_dirs: [temp_dir], project_root: project_root) }

      before do
        create_task_file("path_test.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "invalid-status",
          "priority" => "high"
        }, "# Task")
      end

      it "shows relative paths in error messages" do
        result = validator.validate

        expect(result[:success]).to be false
        expect(result[:errors].first).not_to include(temp_dir)
        expect(result[:errors].first).to include("path_test.md")
      end
    end

    context "with file read errors" do
      before do
        create_task_file("read_error.md", {
          "id" => "v.0.1.0+task.1",
          "status" => "pending",
          "priority" => "high"
        }, "# Task")

        allow(File).to receive(:read).with(anything).and_call_original
        allow(File).to receive(:read).with(File.join(temp_dir, "read_error.md")).and_raise(IOError, "Read failed")
      end

      it "handles file read errors gracefully" do
        expect { validator.validate }.not_to raise_error
      end
    end
  end

  describe "draft status support" do
    let(:validator) { described_class.new(task_dirs: [temp_dir]) }

    context "with draft status" do
      before do
        create_task_file("draft_task.md", {
          "id" => "v.0.4.0+task.7",
          "status" => "draft",
          "priority" => "medium"
        }, "# Add Draft Status Support")
      end

      it "accepts draft as a valid status" do
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end

      it "includes draft in VALID_STATUSES constant" do
        expect(described_class::VALID_STATUSES).to include("draft")
      end

      it "validates draft status case-insensitively" do
        create_task_file("draft_case.md", {
          "id" => "v.0.4.0+task.8",
          "status" => "DRAFT",
          "priority" => "medium"
        }, "# Draft Case Test")

        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "with mixed statuses including draft" do
      before do
        create_task_file("pending_task.md", {
          "id" => "v.0.4.0+task.1",
          "status" => "pending",
          "priority" => "high"
        }, "# Pending Task")

        create_task_file("draft_task.md", {
          "id" => "v.0.4.0+task.2",
          "status" => "draft",
          "priority" => "medium"
        }, "# Draft Task")

        create_task_file("in_progress_task.md", {
          "id" => "v.0.4.0+task.3",
          "status" => "in-progress",
          "priority" => "high"
        }, "# In Progress Task")
      end

      it "validates all tasks with different statuses including draft" do
        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "backward compatibility" do
      it "maintains all existing valid statuses" do
        expected_statuses = ["pending", "in-progress", "done", "blocked", "icebox", "on-hold", "draft"]
        expect(described_class::VALID_STATUSES).to match_array(expected_statuses)
      end

      it "does not break existing validation for non-draft statuses" do
        existing_statuses = ["pending", "in-progress", "done", "blocked", "icebox", "on-hold"]
        
        existing_statuses.each do |status|
          create_task_file("existing_#{status}.md", {
            "id" => "v.0.4.0+task.#{rand(100)}",
            "status" => status,
            "priority" => "medium"
          }, "# #{status.capitalize} Task")
        end

        result = validator.validate

        expect(result[:success]).to be true
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe "constants validation" do
    it "has valid ID regex pattern" do
      valid_ids = ["v.0.1.0+task.1", "v.10.20.30+task.999"]
      invalid_ids = ["v0.1.0+task.1", "v.0.1+task.1", "task.1", "v.0.1.0task.1"]

      valid_ids.each do |id|
        expect(id).to match(described_class::VALID_ID_REGEX)
      end

      invalid_ids.each do |id|
        expect(id).not_to match(described_class::VALID_ID_REGEX)
      end
    end

    it "has valid estimate regex pattern" do
      valid_estimates = ["1h", "2.5h", "3d", "1w", "5sp", "10pt", "2wk", "1mo", "0.1H", "15D"]
      invalid_estimates = ["1hour", "2days", "invalid", "1x", "h1", ".5h"]

      valid_estimates.each do |estimate|
        expect(estimate).to match(described_class::ESTIMATE_REGEX)
      end

      invalid_estimates.each do |estimate|
        expect(estimate).not_to match(described_class::ESTIMATE_REGEX)
      end
    end
  end

  private

  def create_task_file(filename, frontmatter, body)
    content = "---\n#{frontmatter.to_yaml.sub(/^---\n/, "")}---\n\n#{body}"
    File.write(File.join(temp_dir, filename), content)
  end
end
