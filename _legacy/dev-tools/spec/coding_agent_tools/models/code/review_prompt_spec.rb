# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/code/review_prompt"

RSpec.describe CodingAgentTools::Models::Code::ReviewPrompt do
  let(:valid_attributes) do
    {
      session_id: "session-123",
      focus_areas: ["Code quality, architecture, security, performance"],
      system_prompt_path: "/path/to/system_prompt.md",
      combined_content: "System prompt content\n\nUser content here",
      metadata: {generated_at: Time.now.iso8601}
    }
  end

  let(:frontmatter_content) do
    "---\ntitle: Test Review\ntype: code_review\n---\n\nActual content here"
  end

  describe "#initialize" do
    it "creates a new review prompt with valid attributes" do
      prompt = described_class.new(valid_attributes)

      expect(prompt.session_id).to eq("session-123")
      expect(prompt.focus_areas).to eq(["Code quality, architecture, security, performance"])
      expect(prompt.system_prompt_path).to eq("/path/to/system_prompt.md")
      expect(prompt.combined_content).to eq("System prompt content\n\nUser content here")
      expect(prompt.metadata).to include(:generated_at)
    end

    it "accepts minimal required attributes" do
      minimal_attrs = valid_attributes.except(:metadata)
      prompt = described_class.new(minimal_attrs)

      expect(prompt.session_id).to eq("session-123")
      expect(prompt.metadata).to be_nil
    end
  end

  describe "#validate!" do
    it "validates successfully with all required fields" do
      prompt = described_class.new(valid_attributes)
      expect { prompt.validate! }.not_to raise_error
    end

    it "raises error when session_id is nil" do
      prompt = described_class.new(valid_attributes.merge(session_id: nil))
      expect { prompt.validate! }.to raise_error(ArgumentError, "session_id is required")
    end

    it "raises error when session_id is empty" do
      prompt = described_class.new(valid_attributes.merge(session_id: ""))
      expect { prompt.validate! }.to raise_error(ArgumentError, "session_id is required")
    end

    it "raises error when focus_areas is nil" do
      prompt = described_class.new(valid_attributes.merge(focus_areas: nil))
      expect { prompt.validate! }.to raise_error(ArgumentError, "focus_areas is required")
    end

    it "raises error when focus_areas is empty" do
      prompt = described_class.new(valid_attributes.merge(focus_areas: []))
      expect { prompt.validate! }.to raise_error(ArgumentError, "focus_areas is required")
    end

    it "raises error when system_prompt_path is nil" do
      prompt = described_class.new(valid_attributes.merge(system_prompt_path: nil))
      expect { prompt.validate! }.to raise_error(ArgumentError, "system_prompt_path is required")
    end

    it "raises error when system_prompt_path is empty" do
      prompt = described_class.new(valid_attributes.merge(system_prompt_path: ""))
      expect { prompt.validate! }.to raise_error(ArgumentError, "system_prompt_path is required")
    end

    it "raises error when combined_content is nil" do
      prompt = described_class.new(valid_attributes.merge(combined_content: nil))
      expect { prompt.validate! }.to raise_error(ArgumentError, "combined_content is required")
    end

    it "raises error when combined_content is empty" do
      prompt = described_class.new(valid_attributes.merge(combined_content: ""))
      expect { prompt.validate! }.to raise_error(ArgumentError, "combined_content is required")
    end
  end

  describe "#content_size" do
    it "returns correct content size" do
      prompt = described_class.new(valid_attributes)
      expected_size = "System prompt content\n\nUser content here".size
      expect(prompt.content_size).to eq(expected_size)
    end

    it "returns 0 when content is nil" do
      prompt = described_class.new(valid_attributes.merge(combined_content: nil))
      expect(prompt.content_size).to eq(0)
    end

    it "returns 0 when content is empty" do
      prompt = described_class.new(valid_attributes.merge(combined_content: ""))
      expect(prompt.content_size).to eq(0)
    end
  end

  describe "#word_count" do
    it "counts words correctly" do
      prompt = described_class.new(valid_attributes)
      expected_words = "System prompt content\n\nUser content here".split(/\s+/).size
      expect(prompt.word_count).to eq(expected_words)
    end

    it "returns 0 when content is nil" do
      prompt = described_class.new(valid_attributes.merge(combined_content: nil))
      expect(prompt.word_count).to eq(0)
    end

    it "handles multiple whitespace correctly" do
      content_with_spaces = "word1   word2\n\n\tword3\r\nword4"
      prompt = described_class.new(valid_attributes.merge(combined_content: content_with_spaces))
      expect(prompt.word_count).to eq(4)
    end
  end

  describe "#multi_focus?" do
    it "returns true when multiple focus areas" do
      multi_focus_attrs = valid_attributes.merge(
        focus_areas: ["Code quality", "Test coverage", "Documentation"]
      )
      prompt = described_class.new(multi_focus_attrs)
      expect(prompt.multi_focus?).to be(true)
    end

    it "returns false when single focus area" do
      single_focus_attrs = valid_attributes.merge(
        focus_areas: ["Code quality only"]
      )
      prompt = described_class.new(single_focus_attrs)
      expect(prompt.multi_focus?).to be(false)
    end
  end

  describe "#primary_focus" do
    it "returns first focus area" do
      prompt = described_class.new(valid_attributes)
      expect(prompt.primary_focus).to eq("Code quality, architecture, security, performance")
    end

    it "returns first of multiple focus areas" do
      multi_focus_attrs = valid_attributes.merge(
        focus_areas: ["Primary focus", "Secondary focus", "Tertiary focus"]
      )
      prompt = described_class.new(multi_focus_attrs)
      expect(prompt.primary_focus).to eq("Primary focus")
    end
  end

  describe ".focus_area_descriptions" do
    it "returns standard focus area mappings" do
      descriptions = described_class.focus_area_descriptions
      expect(descriptions).to be_a(Hash)
      expect(descriptions.keys).to include("code", "tests", "docs")
    end

    it "has correct structure for code focus" do
      code_focus = described_class.focus_area_descriptions["code"]
      expect(code_focus).to be_an(Array)
      expect(code_focus).to include("Code quality, architecture, security, performance")
    end

    it "has correct structure for tests focus" do
      tests_focus = described_class.focus_area_descriptions["tests"]
      expect(tests_focus).to include("Test coverage, quality, maintainability")
    end

    it "has correct structure for docs focus" do
      docs_focus = described_class.focus_area_descriptions["docs"]
      expect(docs_focus).to include("Documentation gaps, updates, cross-references")
    end
  end

  describe ".get_focus_descriptions" do
    it "returns descriptions for valid focus type" do
      descriptions = described_class.get_focus_descriptions("code")
      expect(descriptions).to be_an(Array)
      expect(descriptions).not_to be_empty
    end

    it "returns empty array for invalid focus type" do
      descriptions = described_class.get_focus_descriptions("invalid")
      expect(descriptions).to eq([])
    end
  end

  describe "#using_standard_focus_areas?" do
    it "returns true when using standard focus areas" do
      standard_focus = described_class.focus_area_descriptions["code"]
      standard_attrs = valid_attributes.merge(focus_areas: standard_focus)
      prompt = described_class.new(standard_attrs)
      expect(prompt.using_standard_focus_areas?).to be(true)
    end

    it "returns false when using custom focus areas" do
      custom_attrs = valid_attributes.merge(focus_areas: ["Custom focus area"])
      prompt = described_class.new(custom_attrs)
      expect(prompt.using_standard_focus_areas?).to be(false)
    end

    it "returns false when focus_areas is nil" do
      prompt = described_class.new(valid_attributes.merge(focus_areas: nil))
      expect(prompt.using_standard_focus_areas?).to be(false)
    end
  end

  describe "#frontmatter" do
    it "extracts YAML frontmatter correctly" do
      prompt = described_class.new(valid_attributes.merge(combined_content: frontmatter_content))
      frontmatter = prompt.frontmatter

      expect(frontmatter).to be_a(Hash)
      expect(frontmatter["title"]).to eq("Test Review")
      expect(frontmatter["type"]).to eq("code_review")
    end

    it "returns empty hash when no frontmatter" do
      prompt = described_class.new(valid_attributes)
      expect(prompt.frontmatter).to eq({})
    end

    it "returns empty hash when malformed YAML" do
      malformed_content = "---\nmalformed: yaml: content\n---\nContent"
      prompt = described_class.new(valid_attributes.merge(combined_content: malformed_content))
      expect(prompt.frontmatter).to eq({})
    end

    it "returns empty hash when content is nil" do
      prompt = described_class.new(valid_attributes.merge(combined_content: nil))
      expect(prompt.frontmatter).to eq({})
    end
  end

  describe "edge cases", :edge_cases do
    it "handles very large content" do
      large_content = "x" * 100_000
      prompt = described_class.new(valid_attributes.merge(combined_content: large_content))
      expect(prompt.content_size).to eq(100_000)
      expect(prompt.word_count).to eq(1)
    end

    it "handles special characters in session_id" do
      special_id = "session-123_with-special.chars@domain.com"
      prompt = described_class.new(valid_attributes.merge(session_id: special_id))
      expect(prompt.session_id).to eq(special_id)
    end

    it "handles unicode content" do
      unicode_content = "Content with émojis 🚀 and ñéẅlíñés\n\t"
      prompt = described_class.new(valid_attributes.merge(combined_content: unicode_content))
      expect(prompt.content_size).to be > 0
      expect(prompt.combined_content).to include("🚀")
    end

    it "handles very long focus areas array" do
      long_focus_areas = Array.new(100) { |i| "Focus area #{i}" }
      prompt = described_class.new(valid_attributes.merge(focus_areas: long_focus_areas))
      expect(prompt.focus_areas.size).to eq(100)
      expect(prompt.multi_focus?).to be(true)
    end

    it "handles empty strings in focus areas" do
      focus_with_empty = ["Valid focus", "", "Another valid focus"]
      prompt = described_class.new(valid_attributes.merge(focus_areas: focus_with_empty))
      expect(prompt.focus_areas).to include("")
      expect(prompt.multi_focus?).to be(true)
    end
  end
end
