# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/models/code/review_session"

RSpec.describe CodingAgentTools::Models::Code::ReviewSession do
  let(:valid_attributes) do
    {
      session_id: "session-123",
      session_name: "code-HEAD~1..HEAD-20240106-143052",
      timestamp: Time.parse("2024-01-06T14:30:52Z"),
      directory_path: "/path/to/session/dir",
      focus: "code",
      target: "HEAD~1..HEAD",
      context_mode: "auto",
      metadata: {created_by: "user", version: "1.0"}
    }
  end

  describe "#initialize" do
    it "creates a new review session with valid attributes" do
      session = described_class.new(valid_attributes)

      expect(session.session_id).to eq("session-123")
      expect(session.session_name).to eq("code-HEAD~1..HEAD-20240106-143052")
      expect(session.timestamp).to eq(Time.parse("2024-01-06T14:30:52Z"))
      expect(session.directory_path).to eq("/path/to/session/dir")
      expect(session.focus).to eq("code")
      expect(session.target).to eq("HEAD~1..HEAD")
      expect(session.context_mode).to eq("auto")
      expect(session.metadata).to eq({created_by: "user", version: "1.0"})
    end

    it "accepts minimal required attributes" do
      minimal_attrs = valid_attributes.except(:context_mode, :metadata)
      session = described_class.new(minimal_attrs)

      expect(session.session_id).to eq("session-123")
      expect(session.context_mode).to be_nil
      expect(session.metadata).to be_nil
    end
  end

  describe "#validate!" do
    it "validates successfully with all required fields" do
      session = described_class.new(valid_attributes)
      expect { session.validate! }.not_to raise_error
    end

    it "raises error when session_id is nil" do
      session = described_class.new(valid_attributes.merge(session_id: nil))
      expect { session.validate! }.to raise_error(ArgumentError, "session_id is required")
    end

    it "raises error when session_id is empty" do
      session = described_class.new(valid_attributes.merge(session_id: ""))
      expect { session.validate! }.to raise_error(ArgumentError, "session_id is required")
    end

    it "raises error when session_name is nil" do
      session = described_class.new(valid_attributes.merge(session_name: nil))
      expect { session.validate! }.to raise_error(ArgumentError, "session_name is required")
    end

    it "raises error when session_name is empty" do
      session = described_class.new(valid_attributes.merge(session_name: ""))
      expect { session.validate! }.to raise_error(ArgumentError, "session_name is required")
    end

    it "raises error when timestamp is nil" do
      session = described_class.new(valid_attributes.merge(timestamp: nil))
      expect { session.validate! }.to raise_error(ArgumentError, "timestamp is required")
    end

    it "raises error when directory_path is nil" do
      session = described_class.new(valid_attributes.merge(directory_path: nil))
      expect { session.validate! }.to raise_error(ArgumentError, "directory_path is required")
    end

    it "raises error when directory_path is empty" do
      session = described_class.new(valid_attributes.merge(directory_path: ""))
      expect { session.validate! }.to raise_error(ArgumentError, "directory_path is required")
    end

    it "raises error when focus is nil" do
      session = described_class.new(valid_attributes.merge(focus: nil))
      expect { session.validate! }.to raise_error(ArgumentError, "focus is required")
    end

    it "raises error when focus is empty" do
      session = described_class.new(valid_attributes.merge(focus: ""))
      expect { session.validate! }.to raise_error(ArgumentError, "focus is required")
    end

    it "raises error when target is nil" do
      session = described_class.new(valid_attributes.merge(target: nil))
      expect { session.validate! }.to raise_error(ArgumentError, "target is required")
    end

    it "raises error when target is empty" do
      session = described_class.new(valid_attributes.merge(target: ""))
      expect { session.validate! }.to raise_error(ArgumentError, "target is required")
    end
  end

  describe "#multi_focus?" do
    it "returns true when focus contains spaces" do
      multi_focus_session = described_class.new(valid_attributes.merge(focus: "code tests"))
      expect(multi_focus_session.multi_focus?).to be(true)
    end

    it "returns true when focus contains multiple spaces" do
      multi_focus_session = described_class.new(valid_attributes.merge(focus: "code tests docs"))
      expect(multi_focus_session.multi_focus?).to be(true)
    end

    it "returns false when focus is single word" do
      single_focus_session = described_class.new(valid_attributes.merge(focus: "code"))
      expect(single_focus_session.multi_focus?).to be(false)
    end

    it "returns false when focus has no spaces" do
      single_focus_session = described_class.new(valid_attributes.merge(focus: "documentation"))
      expect(single_focus_session.multi_focus?).to be(false)
    end
  end

  describe "#focus_areas" do
    it "returns single focus area as array" do
      session = described_class.new(valid_attributes.merge(focus: "code"))
      expect(session.focus_areas).to eq(["code"])
    end

    it "returns multiple focus areas as array" do
      session = described_class.new(valid_attributes.merge(focus: "code tests"))
      expect(session.focus_areas).to eq(["code", "tests"])
    end

    it "returns multiple focus areas with extra spaces handled" do
      session = described_class.new(valid_attributes.merge(focus: "code  tests   docs"))
      expect(session.focus_areas).to eq(["code", "tests", "docs"])
    end

    it "handles single character focus areas" do
      session = described_class.new(valid_attributes.merge(focus: "a b c"))
      expect(session.focus_areas).to eq(["a", "b", "c"])
    end
  end

  describe "#context_mode_with_default" do
    it "returns context_mode when set" do
      session = described_class.new(valid_attributes.merge(context_mode: "custom"))
      expect(session.context_mode_with_default).to eq("custom")
    end

    it "returns 'auto' when context_mode is nil" do
      session = described_class.new(valid_attributes.merge(context_mode: nil))
      expect(session.context_mode_with_default).to eq("auto")
    end

    it "returns 'auto' when context_mode is not provided" do
      attrs = valid_attributes.dup
      attrs.delete(:context_mode)
      session = described_class.new(attrs)
      expect(session.context_mode_with_default).to eq("auto")
    end

    it "returns empty string when context_mode is empty string" do
      session = described_class.new(valid_attributes.merge(context_mode: ""))
      expect(session.context_mode_with_default).to eq("")
    end
  end

  describe "session naming patterns" do
    it "handles typical git-based session names" do
      git_name = "code-HEAD~3..HEAD-20240201-120000"
      session = described_class.new(valid_attributes.merge(session_name: git_name))
      expect(session.session_name).to eq(git_name)
    end

    it "handles file-based session names" do
      file_name = "tests-src/models/**/*.rb-20240201-120000"
      session = described_class.new(valid_attributes.merge(session_name: file_name))
      expect(session.session_name).to eq(file_name)
    end

    it "handles custom session names" do
      custom_name = "custom-review-feature-authentication"
      session = described_class.new(valid_attributes.merge(session_name: custom_name))
      expect(session.session_name).to eq(custom_name)
    end
  end

  describe "focus patterns" do
    it "handles standard single focus areas" do
      ["code", "tests", "docs"].each do |focus|
        session = described_class.new(valid_attributes.merge(focus: focus))
        expect(session.focus).to eq(focus)
        expect(session.multi_focus?).to be(false)
      end
    end

    it "handles standard multi-focus combinations" do
      multi_focuses = ["code tests", "tests docs", "code tests docs"]
      multi_focuses.each do |focus|
        session = described_class.new(valid_attributes.merge(focus: focus))
        expect(session.focus).to eq(focus)
        expect(session.multi_focus?).to be(true)
      end
    end
  end

  describe "target patterns" do
    it "handles git diff targets" do
      git_targets = ["HEAD~1..HEAD", "main..feature-branch", "abc123..def456"]
      git_targets.each do |target|
        session = described_class.new(valid_attributes.merge(target: target))
        expect(session.target).to eq(target)
      end
    end

    it "handles file pattern targets" do
      file_targets = ["src/**/*.rb", "lib/models/*.rb", "*.md"]
      file_targets.each do |target|
        session = described_class.new(valid_attributes.merge(target: target))
        expect(session.target).to eq(target)
      end
    end

    it "handles special keyword targets" do
      special_targets = ["staged", "unstaged", "working"]
      special_targets.each do |target|
        session = described_class.new(valid_attributes.merge(target: target))
        expect(session.target).to eq(target)
      end
    end
  end

  describe "edge cases", :edge_cases do
    it "handles very long session IDs" do
      long_id = "session-" + ("x" * 1000)
      session = described_class.new(valid_attributes.merge(session_id: long_id))
      expect(session.session_id).to eq(long_id)
    end

    it "handles special characters in session names" do
      special_name = "session-with-special-chars_@\#$%^&*()[]{}|"
      session = described_class.new(valid_attributes.merge(session_name: special_name))
      expect(session.session_name).to eq(special_name)
    end

    it "handles unicode characters in paths" do
      unicode_path = "/path/with/émojis/🚀/and/ñéẅ/chars"
      session = described_class.new(valid_attributes.merge(directory_path: unicode_path))
      expect(session.directory_path).to eq(unicode_path)
    end

    it "handles complex metadata structures" do
      complex_metadata = {
        nested: {key: "value", array: [1, 2, 3]},
        symbols: :symbol_value,
        numbers: 42,
        boolean: true
      }
      session = described_class.new(valid_attributes.merge(metadata: complex_metadata))
      expect(session.metadata).to eq(complex_metadata)
    end

    it "handles very old and future timestamps" do
      old_time = Time.parse("1970-01-01T00:00:00Z")
      future_time = Time.parse("2100-12-31T23:59:59Z")

      old_session = described_class.new(valid_attributes.merge(timestamp: old_time))
      expect(old_session.timestamp).to eq(old_time)

      future_session = described_class.new(valid_attributes.merge(timestamp: future_time))
      expect(future_session.timestamp).to eq(future_time)
    end

    it "handles empty focus with spaces only" do
      space_focus = "   "
      session = described_class.new(valid_attributes.merge(focus: space_focus))
      expect(session.focus_areas).to eq([])
      expect(session.multi_focus?).to be(true)
    end
  end
end
