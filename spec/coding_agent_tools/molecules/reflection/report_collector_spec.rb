# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::Reflection::ReportCollector do
  let(:collector) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#collect_reports" do
    context "when no reflection paths provided" do
      it "returns failure with no paths" do
        result = collector.collect_reports([])
        
        expect(result).to be_failure
        expect(result.error).to include("No valid reflection files found")
      end
    end

    context "when handling glob patterns" do
      let(:reflection1) { File.join(temp_dir, "20250101-123000-reflection.md") }
      let(:reflection2) { File.join(temp_dir, "20250102-143000-reflection.md") }
      let(:non_reflection) { File.join(temp_dir, "regular-doc.md") }

      before do
        File.write(reflection1, <<~CONTENT)
          # Daily Reflection

          **Date**: 2025-01-01
          **Context**: First reflection

          ## What Went Well
          - Completed major features
          - Good team collaboration

          ## What Could Be Improved
          - Better time estimation
          - More thorough testing

          ## Key Learnings
          - New framework patterns
          - Team dynamics

          ## Action Items
          - [ ] Improve testing process
          - [ ] Update documentation
        CONTENT

        File.write(reflection2, <<~CONTENT)
          # Project Reflection Notes

          **Date**: 2025-01-02

          ## What Went Well
          - Successful deployment
          - No critical bugs

          ## What Could Be Improved
          - Communication could be better
          - Need more automated tests

          ## Key Learnings
          - Deployment process works well
          - Monitoring is effective
        CONTENT

        File.write(non_reflection, "# Regular Documentation\n\nThis is not a reflection.")
      end

      context "when glob pattern matches reflection files" do
        it "expands glob and collects valid reflections" do
          glob_pattern = File.join(temp_dir, "*reflection*.md")
          result = collector.collect_reports([glob_pattern])

          expect(result).to be_success
          expect(result.data[:reports]).to contain_exactly(reflection1, reflection2)
        end

        it "sorts the results" do
          glob_pattern = File.join(temp_dir, "*reflection*.md")
          result = collector.collect_reports([glob_pattern])

          expect(result.data[:reports]).to eq([reflection1, reflection2])
        end
      end

      context "when glob pattern matches no files" do
        it "handles empty glob results" do
          no_match_pattern = File.join(temp_dir, "nonexistent-*.md")
          result = collector.collect_reports([no_match_pattern])

          expect(result).to be_failure
          expect(result.error).to include("No valid reflection files found")
        end
      end

      context "when mixing direct paths and glob patterns" do
        it "combines results from both" do
          direct_path = reflection1
          glob_pattern = File.join(temp_dir, "*reflection2*.md")
          
          # Rename reflection2 to match glob
          reflection2_renamed = File.join(temp_dir, "test-reflection2.md")
          File.rename(reflection2, reflection2_renamed)
          
          result = collector.collect_reports([direct_path, glob_pattern])

          expect(result).to be_success
          expect(result.data[:reports]).to contain_exactly(reflection1, reflection2_renamed)
        end

        it "removes duplicates" do
          glob_pattern = File.join(temp_dir, "*reflection*.md")
          direct_path = reflection1
          
          result = collector.collect_reports([glob_pattern, direct_path])

          expect(result).to be_success
          expect(result.data[:reports]).to contain_exactly(reflection1, reflection2)
        end
      end
    end

    context "when handling direct file paths" do
      let(:reflection_file) { File.join(temp_dir, "team-reflection.md") }

      before do
        File.write(reflection_file, <<~CONTENT)
          # Team Reflection

          **Context**: Sprint retrospective

          ## What Went Well
          - Great team collaboration
          - All features completed

          ## What Could Be Improved
          - Better planning
          - More communication

          ## Action Items
          - Weekly check-ins
          - Improved documentation
        CONTENT
      end

      it "collects valid reflection files" do
        result = collector.collect_reports([reflection_file])

        expect(result).to be_success
        expect(result.data[:reports]).to eq([reflection_file])
      end
    end

    context "when files don't exist" do
      it "returns failure for non-existent files" do
        non_existent = File.join(temp_dir, "missing.md")
        result = collector.collect_reports([non_existent])

        expect(result).to be_failure
        expect(result.error).to include("File not found: #{non_existent}")
      end
    end

    context "when files are not readable" do
      let(:unreadable_file) { File.join(temp_dir, "unreadable.md") }

      before do
        File.write(unreadable_file, <<~CONTENT)
          # Reflection
          ## What Went Well
          Something good
        CONTENT
        File.chmod(0000, unreadable_file)
      end

      after do
        File.chmod(0644, unreadable_file) # Restore permissions for cleanup
      end

      it "skips unreadable files" do
        result = collector.collect_reports([unreadable_file])

        expect(result).to be_failure
        expect(result.error).to include("Invalid reflection file")
      end
    end

    context "when files are empty" do
      let(:empty_file) { File.join(temp_dir, "empty.md") }

      before do
        File.write(empty_file, "")
      end

      it "skips empty files" do
        result = collector.collect_reports([empty_file])

        expect(result).to be_failure
        expect(result.error).to include("Invalid reflection file")
      end
    end

    context "when files are not markdown" do
      let(:txt_file) { File.join(temp_dir, "reflection.txt") }

      before do
        File.write(txt_file, <<~CONTENT)
          # Reflection
          ## What Went Well
          Something good
        CONTENT
      end

      it "skips non-markdown files" do
        result = collector.collect_reports([txt_file])

        expect(result).to be_failure
        expect(result.error).to include("Invalid reflection file")
      end
    end

    context "when files don't have reflection content" do
      let(:regular_file) { File.join(temp_dir, "regular.md") }

      before do
        File.write(regular_file, <<~CONTENT)
          # Regular Documentation

          This is just regular documentation without reflection markers.
          No reflection patterns here.
        CONTENT
      end

      it "skips files without reflection markers" do
        result = collector.collect_reports([regular_file])

        expect(result).to be_failure
        expect(result.error).to include("Invalid reflection file")
      end
    end

    context "with valid reflection files" do
      let(:reflection1) { File.join(temp_dir, "reflection-alpha.md") }
      let(:reflection2) { File.join(temp_dir, "reflection-beta.md") }

      before do
        File.write(reflection1, <<~CONTENT)
          # Sprint Reflection

          **Date**: 2025-01-01

          ## What Went Well
          - Good progress on features
          - Team worked well together

          ## What Could Be Improved
          - Better time management
          - More testing coverage

          ## Key Learnings
          - New patterns are effective
          - Team communication improved

          ## Action Items
          - [ ] Update process documentation
          - [ ] Schedule training session
        CONTENT

        File.write(reflection2, <<~CONTENT)
          # Project Reflection

          **Context**: End of quarter review

          ## What Went Well
          - All deliverables completed
          - Quality remained high

          ## What Could Be Improved
          - Faster feedback cycles
          - Better requirement clarity
        CONTENT
      end

      it "returns successful result with sorted reports" do
        result = collector.collect_reports([reflection1, reflection2])

        expect(result).to be_success
        expect(result.data[:reports]).to eq([reflection1, reflection2])
      end
    end

    context "with mixed valid and invalid files" do
      let(:valid_reflection) { File.join(temp_dir, "valid-reflection.md") }
      let(:invalid_file) { File.join(temp_dir, "invalid.md") }
      let(:missing_file) { File.join(temp_dir, "missing.md") }

      before do
        File.write(valid_reflection, <<~CONTENT)
          # Valid Reflection

          ## What Went Well
          - Good progress

          ## What Could Be Improved
          - Better communication

          ## Action Items
          - Follow up meeting
        CONTENT

        File.write(invalid_file, "# Regular Doc\n\nNot a reflection.")
      end

      it "returns error when any file is invalid" do
        result = collector.collect_reports([valid_reflection, invalid_file, missing_file])

        expect(result).to be_failure
        expect(result.error).to include("File not found: #{missing_file}")
      end
    end
  end

  describe "private methods" do
    describe "#valid_reflection_file?" do
      let(:test_file) { File.join(temp_dir, "test.md") }

      context "with valid extensions" do
        it "accepts .md files" do
          File.write(test_file, <<~CONTENT)
            # Reflection
            ## What Went Well
            Good stuff
          CONTENT

          expect(collector.send(:valid_reflection_file?, test_file)).to be true
        end

        it "accepts .markdown files" do
          markdown_file = File.join(temp_dir, "test.markdown")
          File.write(markdown_file, <<~CONTENT)
            # Reflection
            ## What Went Well
            Good stuff
          CONTENT

          expect(collector.send(:valid_reflection_file?, markdown_file)).to be true
        end

        it "rejects other extensions" do
          txt_file = File.join(temp_dir, "test.txt")
          File.write(txt_file, "# Reflection\n## What Went Well\nGood stuff")

          expect(collector.send(:valid_reflection_file?, txt_file)).to be false
        end
      end

      context "with reflection content patterns" do
        it "identifies files with 'What Went Well' pattern" do
          File.write(test_file, <<~CONTENT)
            # Sprint Review
            ## What Went Well
            Great progress
            ## Action Items
            Follow up
          CONTENT

          expect(collector.send(:valid_reflection_file?, test_file)).to be true
        end

        it "identifies files with 'What Could Be Improved' pattern" do
          File.write(test_file, <<~CONTENT)
            # Review
            ## What Could Be Improved
            Better communication
            ## Key Learnings
            New patterns
          CONTENT

          expect(collector.send(:valid_reflection_file?, test_file)).to be true
        end

        it "identifies files with reflection title" do
          File.write(test_file, <<~CONTENT)
            # Daily Reflection
            **Date**: Today
            Good day overall
          CONTENT

          expect(collector.send(:valid_reflection_file?, test_file)).to be true
        end

        it "identifies files with context metadata" do
          File.write(test_file, <<~CONTENT)
            # Review
            **Context**: Sprint retrospective
            ## What Went Well
            Good session
          CONTENT
          expect(collector.send(:valid_reflection_file?, test_file)).to be true
        end

        it "requires at least 2 reflection markers" do
          File.write(test_file, <<~CONTENT)
            # Some Review
            ## What Went Well
            Only one marker here
          CONTENT

          expect(collector.send(:valid_reflection_file?, test_file)).to be false
        end

        it "rejects files with no reflection patterns" do
          File.write(test_file, <<~CONTENT)
            # Regular Documentation
            This is just regular documentation.
            No reflection patterns here.
          CONTENT

          expect(collector.send(:valid_reflection_file?, test_file)).to be false
        end
      end
    end

    describe "#has_reflection_markers?" do
      it "counts reflection patterns correctly" do
        content = <<~CONTENT
          # Daily Reflection
          **Date**: Today
          ## What Went Well
          Good progress
          ## What Could Be Improved
          Better planning
          ## Key Learnings
          New insights
        CONTENT

        expect(collector.send(:has_reflection_markers?, content)).to be true
      end

      it "returns false for insufficient markers" do
        content = <<~CONTENT
          # Some Document
          ## What Went Well
          Only one reflection marker
        CONTENT

        expect(collector.send(:has_reflection_markers?, content)).to be false
      end
    end
  end
end
