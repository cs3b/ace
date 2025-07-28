# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::StatisticsCalculator do
  let(:calculator) { described_class.new }

  # Sample dependency data for testing
  let(:sample_dependencies) do
    {
      "docs/readme.md" => {
        refs_to: ["docs/api.md", "docs/guide.md"],
        refs_from: ["docs/index.md"]
      },
      "docs/api.md" => {
        refs_to: [],
        refs_from: ["docs/readme.md", "docs/index.md", "tasks/task1.md"]
      },
      "docs/guide.md" => {
        refs_to: ["docs/api.md"],
        refs_from: ["docs/readme.md"]
      },
      "docs/index.md" => {
        refs_to: ["docs/readme.md", "docs/api.md"],
        refs_from: []
      },
      "workflow.wf.md" => {
        refs_to: ["docs/api.md"],
        refs_from: []
      },
      "tutorial.g.md" => {
        refs_to: [],
        refs_from: []
      },
      "tasks/task1.md" => {
        refs_to: ["docs/api.md"],
        refs_from: []
      },
      "dev-taskflow/task2.md" => {
        refs_to: [],
        refs_from: []
      }
    }
  end

  let(:empty_dependencies) { {} }

  let(:minimal_dependencies) do
    {
      "single.md" => {
        refs_to: [],
        refs_from: []
      }
    }
  end

  describe "#calculate_basic_stats" do
    it "calculates basic statistics for sample dependencies" do
      result = calculator.calculate_basic_stats(sample_dependencies)

      expect(result).to eq({
        total_files: 8,
        files_with_outgoing_refs: 5,
        files_with_incoming_refs: 3,
        total_references: 7,
        average_outgoing_refs: 0.88,
        average_incoming_refs: 0.63
      })
    end

    it "handles empty dependencies" do
      result = calculator.calculate_basic_stats(empty_dependencies)

      expect(result).to eq({
        total_files: 0,
        files_with_outgoing_refs: 0,
        files_with_incoming_refs: 0,
        total_references: 0,
        average_outgoing_refs: 0.0,
        average_incoming_refs: 0.0
      })
    end

    it "handles single file with no references" do
      result = calculator.calculate_basic_stats(minimal_dependencies)

      expect(result).to eq({
        total_files: 1,
        files_with_outgoing_refs: 0,
        files_with_incoming_refs: 0,
        total_references: 0,
        average_outgoing_refs: 0.0,
        average_incoming_refs: 0.0
      })
    end

    it "calculates averages correctly with rounding" do
      dependencies = {
        "file1.md" => { refs_to: ["file2.md"], refs_from: [] },
        "file2.md" => { refs_to: [], refs_from: ["file1.md"] },
        "file3.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_basic_stats(dependencies)

      expect(result[:average_outgoing_refs]).to eq(0.33)
      expect(result[:average_incoming_refs]).to eq(0.33)
    end
  end

  describe "#most_referenced_files" do
    it "returns files sorted by incoming reference count" do
      result = calculator.most_referenced_files(sample_dependencies, 3)

      expect(result).to eq([
        { file: "docs/api.md", reference_count: 3 },
        { file: "docs/readme.md", reference_count: 1 },
        { file: "docs/guide.md", reference_count: 1 }
      ])
    end

    it "returns empty array when no files have incoming references" do
      dependencies = {
        "file1.md" => { refs_to: ["file2.md"], refs_from: [] },
        "file2.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.most_referenced_files(dependencies)
      expect(result).to eq([])
    end

    it "respects the limit parameter" do
      result = calculator.most_referenced_files(sample_dependencies, 1)

      expect(result.length).to eq(1)
      expect(result.first[:file]).to eq("docs/api.md")
    end

    it "uses default limit of 10" do
      result = calculator.most_referenced_files(sample_dependencies)
      expect(result.length).to eq(3) # Only 3 files have incoming references
    end

    it "handles empty dependencies" do
      result = calculator.most_referenced_files(empty_dependencies)
      expect(result).to eq([])
    end
  end

  describe "#most_referencing_files" do
    it "returns files sorted by outgoing reference count" do
      result = calculator.most_referencing_files(sample_dependencies, 5)

      expect(result).to eq([
        { file: "docs/readme.md", reference_count: 2 },
        { file: "docs/index.md", reference_count: 2 },
        { file: "docs/guide.md", reference_count: 1 },
        { file: "workflow.wf.md", reference_count: 1 },
        { file: "tasks/task1.md", reference_count: 1 }
      ])
    end

    it "returns empty array when no files have outgoing references" do
      dependencies = {
        "file1.md" => { refs_to: [], refs_from: ["file2.md"] },
        "file2.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.most_referencing_files(dependencies)
      expect(result).to eq([])
    end

    it "respects the limit parameter" do
      result = calculator.most_referencing_files(sample_dependencies, 2)

      expect(result.length).to eq(2)
      expect(result.map { |r| r[:file] }).to contain_exactly("docs/readme.md", "docs/index.md")
    end

    it "handles empty dependencies" do
      result = calculator.most_referencing_files(empty_dependencies)
      expect(result).to eq([])
    end
  end

  describe "#find_orphaned_files" do
    it "finds files with no incoming or outgoing references" do
      result = calculator.find_orphaned_files(sample_dependencies)

      expect(result).to contain_exactly("tutorial.g.md", "dev-taskflow/task2.md")
    end

    it "returns empty array when no orphaned files exist" do
      dependencies = {
        "file1.md" => { refs_to: ["file2.md"], refs_from: [] },
        "file2.md" => { refs_to: [], refs_from: ["file1.md"] }
      }

      result = calculator.find_orphaned_files(dependencies)
      expect(result).to eq([])
    end

    it "returns all files when all are orphaned" do
      dependencies = {
        "file1.md" => { refs_to: [], refs_from: [] },
        "file2.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.find_orphaned_files(dependencies)
      expect(result).to contain_exactly("file1.md", "file2.md")
    end

    it "returns sorted list of orphaned files" do
      dependencies = {
        "z-file.md" => { refs_to: [], refs_from: [] },
        "a-file.md" => { refs_to: [], refs_from: [] },
        "m-file.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.find_orphaned_files(dependencies)
      expect(result).to eq(["a-file.md", "m-file.md", "z-file.md"])
    end

    it "handles empty dependencies" do
      result = calculator.find_orphaned_files(empty_dependencies)
      expect(result).to eq([])
    end
  end

  describe "#find_isolated_files" do
    it "finds files with no incoming references" do
      result = calculator.find_isolated_files(sample_dependencies)

      expect(result).to contain_exactly(
        "docs/index.md", "workflow.wf.md", "tutorial.g.md", 
        "tasks/task1.md", "dev-taskflow/task2.md"
      )
    end

    it "includes files with outgoing but no incoming references" do
      dependencies = {
        "isolated.md" => { refs_to: ["other.md"], refs_from: [] },
        "other.md" => { refs_to: [], refs_from: ["isolated.md"] }
      }

      result = calculator.find_isolated_files(dependencies)
      expect(result).to contain_exactly("isolated.md")
    end

    it "returns empty array when all files have incoming references" do
      dependencies = {
        "file1.md" => { refs_to: [], refs_from: ["file2.md"] },
        "file2.md" => { refs_to: ["file1.md"], refs_from: ["file1.md"] }
      }

      result = calculator.find_isolated_files(dependencies)
      expect(result).to eq([])
    end

    it "returns sorted list of isolated files" do
      dependencies = {
        "z-isolated.md" => { refs_to: [], refs_from: [] },
        "a-isolated.md" => { refs_to: [], refs_from: [] },
        "connected.md" => { refs_to: [], refs_from: ["other.md"] }
      }

      result = calculator.find_isolated_files(dependencies)
      expect(result).to eq(["a-isolated.md", "z-isolated.md"])
    end

    it "handles empty dependencies" do
      result = calculator.find_isolated_files(empty_dependencies)
      expect(result).to eq([])
    end
  end

  describe "#find_hub_files" do
    it "finds files with high incoming and outgoing references using default thresholds" do
      hub_dependencies = {
        "major_hub.md" => { refs_to: ["a.md", "b.md", "c.md"], refs_from: ["x.md", "y.md", "z.md"] },
        "minor_hub.md" => { refs_to: ["a.md", "b.md"], refs_from: ["x.md", "y.md"] },
        "isolated.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.find_hub_files(hub_dependencies)

      expect(result).to eq([
        {
          file: "major_hub.md",
          incoming_count: 3,
          outgoing_count: 3,
          total_connections: 6
        }
      ])
    end

    it "allows custom thresholds" do
      hub_dependencies = {
        "hub.md" => { refs_to: ["a.md", "b.md"], refs_from: ["x.md", "y.md"] },
        "isolated.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.find_hub_files(hub_dependencies, 2, 2)

      expect(result).to eq([
        {
          file: "hub.md",
          incoming_count: 2,
          outgoing_count: 2,
          total_connections: 4
        }
      ])
    end

    it "sorts results by total connections descending" do
      hub_dependencies = {
        "small_hub.md" => { refs_to: ["a.md", "b.md", "c.md"], refs_from: ["x.md", "y.md", "z.md"] },
        "big_hub.md" => { refs_to: ["a.md", "b.md", "c.md", "d.md"], refs_from: ["x.md", "y.md", "z.md", "w.md"] }
      }

      result = calculator.find_hub_files(hub_dependencies)

      expect(result.first[:file]).to eq("big_hub.md")
      expect(result.first[:total_connections]).to eq(8)
      expect(result.last[:file]).to eq("small_hub.md")
      expect(result.last[:total_connections]).to eq(6)
    end

    it "returns empty array when no hubs exist" do
      result = calculator.find_hub_files(sample_dependencies)
      expect(result).to eq([])
    end

    it "handles empty dependencies" do
      result = calculator.find_hub_files(empty_dependencies)
      expect(result).to eq([])
    end
  end

  describe "#calculate_file_type_distribution" do
    it "calculates distribution of file types" do
      result = calculator.calculate_file_type_distribution(sample_dependencies)

      expect(result).to eq({
        documentation: 4, # docs/readme.md, docs/api.md, docs/guide.md, docs/index.md
        workflow: 1,      # workflow.wf.md
        guide: 1,         # tutorial.g.md
        task: 1,          # tasks/task1.md
        taskflow: 1       # dev-taskflow/task2.md
      })
    end

    it "handles empty dependencies" do
      result = calculator.calculate_file_type_distribution(empty_dependencies)
      expect(result).to eq({})
    end

    it "handles files with other types" do
      dependencies = {
        "unknown.txt" => { refs_to: [], refs_from: [] },
        "README.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_file_type_distribution(dependencies)
      expect(result).to eq({ other: 2 })
    end

    it "correctly categorizes workflow files" do
      dependencies = {
        "setup.wf.md" => { refs_to: [], refs_from: [] },
        "deploy.wf.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_file_type_distribution(dependencies)
      expect(result).to eq({ workflow: 2 })
    end

    it "correctly categorizes guide files" do
      dependencies = {
        "tutorial.g.md" => { refs_to: [], refs_from: [] },
        "howto.g.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_file_type_distribution(dependencies)
      expect(result).to eq({ guide: 2 })
    end

    it "correctly categorizes task files" do
      dependencies = {
        "tasks/feature.md" => { refs_to: [], refs_from: [] },
        "tasks/bugfix.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_file_type_distribution(dependencies)
      expect(result).to eq({ task: 2 })
    end

    it "correctly categorizes taskflow files" do
      dependencies = {
        "dev-taskflow/current.md" => { refs_to: [], refs_from: [] },
        "dev-taskflow/backlog.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_file_type_distribution(dependencies)
      expect(result).to eq({ taskflow: 2 })
    end

    it "correctly categorizes documentation files" do
      dependencies = {
        "docs/architecture.md" => { refs_to: [], refs_from: [] },
        "docs/api.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.calculate_file_type_distribution(dependencies)
      expect(result).to eq({ documentation: 2 })
    end
  end

  describe "#analyze_reference_patterns" do
    it "analyzes which file types reference which other types" do
      result = calculator.analyze_reference_patterns(sample_dependencies)

      expect(result).to eq({
        documentation: {
          documentation: 5  # docs files referencing other docs files
        },
        workflow: {
          documentation: 1  # workflow.wf.md -> docs/api.md
        },
        task: {
          documentation: 1  # tasks/task1.md -> docs/api.md
        }
      })
    end

    it "handles empty dependencies" do
      result = calculator.analyze_reference_patterns(empty_dependencies)
      expect(result).to eq({})
    end

    it "handles files with no outgoing references" do
      dependencies = {
        "isolated.md" => { refs_to: [], refs_from: [] }
      }

      result = calculator.analyze_reference_patterns(dependencies)
      expect(result).to eq({})
    end

    it "counts multiple references between same file types" do
      dependencies = {
        "docs/file1.md" => { refs_to: ["docs/file2.md", "docs/file3.md"], refs_from: [] },
        "docs/file2.md" => { refs_to: ["docs/file3.md"], refs_from: ["docs/file1.md"] },
        "docs/file3.md" => { refs_to: [], refs_from: ["docs/file1.md", "docs/file2.md"] }
      }

      result = calculator.analyze_reference_patterns(dependencies)
      expect(result).to eq({
        documentation: {
          documentation: 3  # file1->file2, file1->file3, file2->file3
        }
      })
    end

    it "handles cross-type references" do
      dependencies = {
        "workflow.wf.md" => { refs_to: ["docs/api.md", "tasks/task1.md"], refs_from: [] },
        "docs/api.md" => { refs_to: [], refs_from: ["workflow.wf.md"] },
        "tasks/task1.md" => { refs_to: [], refs_from: ["workflow.wf.md"] }
      }

      result = calculator.analyze_reference_patterns(dependencies)
      expect(result).to eq({
        workflow: {
          documentation: 1,
          task: 1
        }
      })
    end
  end

  # Testing private methods indirectly
  describe "private method behaviors" do
    describe "average calculations" do
      context "when dependencies is empty" do
        it "returns 0.0 for both averages" do
          result = calculator.calculate_basic_stats({})
          expect(result[:average_outgoing_refs]).to eq(0.0)
          expect(result[:average_incoming_refs]).to eq(0.0)
        end
      end

      context "with fractional averages" do
        it "rounds to 2 decimal places" do
          dependencies = {
            "file1.md" => { refs_to: ["file2.md"], refs_from: [] },
            "file2.md" => { refs_to: [], refs_from: ["file1.md"] },
            "file3.md" => { refs_to: [], refs_from: [] }
          }
          
          result = calculator.calculate_basic_stats(dependencies)
          expect(result[:average_outgoing_refs]).to eq(0.33)
          expect(result[:average_incoming_refs]).to eq(0.33)
        end
      end
    end

    describe "file type categorization" do
      it "categorizes workflow files correctly through distribution calculation" do
        dependencies = { "test.wf.md" => { refs_to: [], refs_from: [] } }
        result = calculator.calculate_file_type_distribution(dependencies)
        expect(result[:workflow]).to eq(1)
      end

      it "categorizes guide files correctly through distribution calculation" do
        dependencies = { "test.g.md" => { refs_to: [], refs_from: [] } }
        result = calculator.calculate_file_type_distribution(dependencies)
        expect(result[:guide]).to eq(1)
      end

      it "categorizes task files correctly through distribution calculation" do
        dependencies = { "tasks/test.md" => { refs_to: [], refs_from: [] } }
        result = calculator.calculate_file_type_distribution(dependencies)
        expect(result[:task]).to eq(1)
      end

      it "categorizes documentation files correctly through distribution calculation" do
        dependencies = { "docs/test.md" => { refs_to: [], refs_from: [] } }
        result = calculator.calculate_file_type_distribution(dependencies)
        expect(result[:documentation]).to eq(1)
      end

      it "categorizes taskflow files correctly through distribution calculation" do
        dependencies = { "dev-taskflow/test.md" => { refs_to: [], refs_from: [] } }
        result = calculator.calculate_file_type_distribution(dependencies)
        expect(result[:taskflow]).to eq(1)
      end

      it "categorizes other files correctly through distribution calculation" do
        dependencies = { "unknown.txt" => { refs_to: [], refs_from: [] } }
        result = calculator.calculate_file_type_distribution(dependencies)
        expect(result[:other]).to eq(1)
      end
    end
  end
end