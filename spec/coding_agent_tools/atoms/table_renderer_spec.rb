# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/table_renderer"

RSpec.describe CodingAgentTools::Atoms::TableRenderer do
  describe "#render" do
    context "with basic table" do
      let(:columns) do
        [
          {name: "Name", width: 10, align: :left},
          {name: "Type", width: 8, align: :left},
          {name: "Status", width: 6, align: :center}
        ]
      end

      let(:renderer) { described_class.new(columns) }

      before do
        renderer.add_row(["commit", "custom", "✓"])
        renderer.add_row(["draft-task", "generated", "✓"])
      end

      it "renders a formatted table" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines[0]).to eq("Name       | Type     | Status")
        expect(lines[1]).to eq("-----------|----------|-------")
        expect(lines[2]).to eq("commit     | custom   |   ✓   ")
        expect(lines[3]).to eq("draft-task | generat… |   ✓   ")
      end
    end

    context "with long values" do
      let(:columns) do
        [
          {name: "Command", width: 8, align: :left}
        ]
      end

      let(:renderer) { described_class.new(columns) }

      before do
        renderer.add_row(["very-long-command-name"])
      end

      it "truncates long values with ellipsis" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines[2]).to eq("very-lo…")
      end
    end

    context "with different alignments" do
      let(:columns) do
        [
          {name: "Left", width: 10, align: :left},
          {name: "Center", width: 10, align: :center},
          {name: "Right", width: 10, align: :right}
        ]
      end

      let(:renderer) { described_class.new(columns) }

      before do
        renderer.add_row(["L", "C", "R"])
      end

      it "aligns text correctly" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines[2]).to eq("L          |     C      |          R")
      end
    end

    context "with empty table" do
      let(:columns) do
        [
          {name: "Name", width: 10},
          {name: "Type", width: 10}
        ]
      end

      let(:renderer) { described_class.new(columns) }

      it "renders header and separator only" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines.length).to eq(2)
        expect(lines[0]).to eq("Name       | Type      ")
        expect(lines[1]).to eq("-----------|-----------")
      end
    end

    context "with nil values" do
      let(:columns) do
        [
          {name: "A", width: 5},
          {name: "B", width: 5}
        ]
      end

      let(:renderer) { described_class.new(columns) }

      before do
        renderer.add_row(["test", nil])
        renderer.add_row([nil, "test"])
      end

      it "handles nil values gracefully" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines[2]).to eq("test  |      ")
        expect(lines[3]).to eq("      | test ")
      end
    end

    context "with auto-width columns" do
      let(:columns) do
        [
          {name: "Name", align: :left},
          {name: "Description", align: :left}
        ]
      end

      let(:renderer) { described_class.new(columns) }

      before do
        renderer.add_row(["short", "A short description"])
        renderer.add_row(["medium-name", "Another one"])
      end

      it "calculates column widths based on content" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines[0]).to eq("Name        | Description        ")
        expect(lines[1]).to eq("------------|--------------------")
        expect(lines[2]).to eq("short       | A short description")
        expect(lines[3]).to eq("medium-name | Another one        ")
      end
    end

    context "with custom options" do
      let(:columns) do
        [
          {name: "A", width: 3},
          {name: "B", width: 3}
        ]
      end

      let(:renderer) do
        described_class.new(columns, separator: " : ", header_separator: "=")
      end

      before do
        renderer.add_row(["1", "2"])
      end

      it "uses custom separators" do
        output = renderer.render
        lines = output.split("\n")

        expect(lines[0]).to eq("A   : B  ")
        expect(lines[1]).to eq("====:====")
        expect(lines[2]).to eq("1   : 2  ")
      end
    end
  end

  describe "#add_row" do
    let(:columns) { [{name: "Test", width: 10}] }
    let(:renderer) { described_class.new(columns) }

    it "accumulates rows" do
      renderer.add_row(["row1"])
      renderer.add_row(["row2"])
      renderer.add_row(["row3"])

      output = renderer.render
      lines = output.split("\n")

      expect(lines.length).to eq(5) # header + separator + 3 rows
    end
  end
end
