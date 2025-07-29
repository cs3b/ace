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

      it "detects various reflection patterns case-insensitively" do
        content = <<~CONTENT
          # Team reflection
          ## what went well
          Great progress
          ## What Could be improved
          Better communication
        CONTENT

        expect(collector.send(:has_reflection_markers?, content)).to be true
      end

      it "handles action items pattern" do
        content = <<~CONTENT
          # Review
          ## Action Items
          - Follow up tasks
          **Context**: Sprint review
        CONTENT

        expect(collector.send(:has_reflection_markers?, content)).to be true
      end

      it "detects key learnings pattern" do
        content = <<~CONTENT
          # Session Review
          ## Key Learnings
          New insights gained
          **Date**: 2025-01-01
        CONTENT

        expect(collector.send(:has_reflection_markers?, content)).to be true
      end
    end

    describe "#expand_glob_patterns" do
      let(:pattern_file1) { File.join(temp_dir, "reflection-001.md") }
      let(:pattern_file2) { File.join(temp_dir, "reflection-002.md") }
      let(:direct_file) { File.join(temp_dir, "direct.md") }

      before do
        File.write(pattern_file1, "# Reflection\n## What Went Well\nGood")
        File.write(pattern_file2, "# Reflection\n## Key Learnings\nLearned")
        File.write(direct_file, "# Direct\n## What Went Well\nContent")
      end

      it "expands glob patterns correctly" do
        pattern = File.join(temp_dir, "reflection-*.md")
        result = collector.send(:expand_glob_patterns, [pattern, direct_file])
        
        expect(result).to contain_exactly(pattern_file1, pattern_file2, direct_file)
      end

      it "handles non-glob patterns as-is" do
        result = collector.send(:expand_glob_patterns, [direct_file])
        
        expect(result).to eq([direct_file])
      end

      it "removes duplicates from expanded patterns" do
        pattern = File.join(temp_dir, "reflection-001.md")
        result = collector.send(:expand_glob_patterns, [pattern, pattern_file1])
        
        expect(result).to eq([pattern_file1])
      end

      it "handles empty glob results" do
        empty_pattern = File.join(temp_dir, "nonexistent-*.md")
        result = collector.send(:expand_glob_patterns, [empty_pattern])
        
        expect(result).to eq([])
      end
    end
  end

  describe "edge cases and advanced scenarios" do
    context "with complex glob patterns" do
      let(:nested_dir) { File.join(temp_dir, "nested") }
      let(:nested_reflection) { File.join(nested_dir, "deep-reflection.md") }
      
      before do
        Dir.mkdir(nested_dir)
        File.write(nested_reflection, <<~CONTENT)
          # Project Reflection
          **Context**: Deep nested reflection
          ## What Went Well
          Found good patterns
          ## What Could Be Improved
          Better organization
        CONTENT
      end

      it "handles recursive glob patterns" do
        recursive_pattern = File.join(temp_dir, "**", "*reflection*.md")
        result = collector.collect_reports([recursive_pattern])
        
        expect(result).to be_success
        expect(result.data[:reports]).to include(nested_reflection)
      end
    end

    context "with file encoding and special characters" do
      let(:unicode_file) { File.join(temp_dir, "unicode-reflection.md") }
      
      before do
        # Create file with unicode characters
        File.write(unicode_file, <<~CONTENT, encoding: "utf-8")
          # Daily Reflection 📝
          **Date**: 2025-01-01
          ## What Went Well ✅
          Unicode content with émojis and àccents
          ## What Could Be Improved 🔧
          Better handling of special characters
        CONTENT
      end

      it "handles unicode content correctly" do
        result = collector.collect_reports([unicode_file])
        
        expect(result).to be_success
        expect(result.data[:reports]).to include(unicode_file)
      end
    end

    context "with borderline reflection marker counts" do
      let(:borderline_file) { File.join(temp_dir, "borderline.md") }

      it "accepts files with exactly 2 markers" do
        File.write(borderline_file, <<~CONTENT)
          # Sprint Reflection
          ## What Went Well
          Exactly two markers here
        CONTENT
        
        result = collector.collect_reports([borderline_file])
        expect(result).to be_success
      end

      it "rejects files with only 1 marker" do
        File.write(borderline_file, <<~CONTENT)
          # Some Document
          ## What Went Well
          Only one marker
        CONTENT
        
        result = collector.collect_reports([borderline_file])
        expect(result).to be_failure
      end

      it "accepts files with many markers" do
        File.write(borderline_file, <<~CONTENT)
          # Comprehensive Reflection
          **Date**: Today
          **Context**: Full review
          ## What Went Well
          Multiple items
          ## What Could Be Improved
          Several areas
          ## Key Learnings
          Many insights
          ## Action Items
          Next steps
        CONTENT
        
        result = collector.collect_reports([borderline_file])
        expect(result).to be_success
      end
    end

    context "with file system edge cases" do
      it "handles files with unusual extensions correctly" do
        weird_extension = File.join(temp_dir, "reflection.MD") # Uppercase
        File.write(weird_extension, <<~CONTENT)
          # Reflection
          ## What Went Well
          Content here
        CONTENT
        
        result = collector.collect_reports([weird_extension])
        expect(result).to be_success
      end

      it "rejects symlinks to non-existent files" do
        if File.respond_to?(:symlink) # Skip on systems without symlink support
          broken_link = File.join(temp_dir, "broken-link.md")
          non_existent = File.join(temp_dir, "does-not-exist.md")
          
          begin
            File.symlink(non_existent, broken_link)
            result = collector.collect_reports([broken_link])
            expect(result).to be_failure
          rescue NotImplementedError
            skip "Symlinks not supported on this system"
          end
        else
          skip "Symlinks not available"
        end
      end
    end

    context "with content validation edge cases" do
      let(:edge_case_file) { File.join(temp_dir, "edge.md") }

      it "handles files with reflection patterns in code blocks" do
        File.write(edge_case_file, <<~CONTENT)
          # Documentation
          
          ```markdown
          ## What Went Well
          This is in a code block
          ```
          
          ## What Could Be Improved
          Real reflection content here
          **Date**: Today
        CONTENT
        
        # Should still detect the real patterns outside code blocks
        result = collector.collect_reports([edge_case_file])
        expect(result).to be_success
      end

      it "handles files with malformed reflection patterns" do
        File.write(edge_case_file, <<~CONTENT)
          # Review
          ##What Went Well (no space after ##)
          Content
          ## What Could Be improved (lowercase 'i')
          More content
        CONTENT
        
        # Should still detect case-insensitive patterns
        result = collector.collect_reports([edge_case_file])
        expect(result).to be_success
      end

      it "handles very long lines in reflection files" do
        long_line = "A" * 5000  # Very long line
        File.write(edge_case_file, <<~CONTENT)
          # Reflection
          ## What Went Well
          #{long_line}
          ## Action Items
          Regular content
        CONTENT
        
        result = collector.collect_reports([edge_case_file])
        expect(result).to be_success
      end
    end

    context "with error handling scenarios" do
      it "propagates file read errors" do
        error_file = File.join(temp_dir, "error.md")
        File.write(error_file, "Content")
        
        # Mock file read to raise an error
        allow(File).to receive(:read).with(error_file, encoding: "utf-8").and_raise(StandardError, "Read error")
        
        # The current implementation doesn't handle read errors, so it should raise
        expect { collector.collect_reports([error_file]) }.to raise_error(StandardError, "Read error")
      end
    end

    context "additional edge cases for coverage improvement" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:valid_reflection) { File.join(temp_dir, "valid.md") }
      let(:invalid_reflection) { File.join(temp_dir, "invalid.md") }
      let(:missing_file) { File.join(temp_dir, "missing.md") }

      after do
        FileUtils.rm_rf(temp_dir)
      end

      before do
        # Create a valid reflection file
        File.write(valid_reflection, <<~CONTENT)
          # Sprint Reflection
          **Date**: 2025-01-01
          ## What Went Well
          Everything worked great
          ## What Could Be Improved
          Better communication
        CONTENT

        # Create an invalid reflection file (regular markdown)
        File.write(invalid_reflection, <<~CONTENT)
          # Regular Documentation
          This is just regular documentation.
          No reflection patterns here.
        CONTENT
      end

      it "handles combination of valid files, invalid files, and missing files with proper error accumulation" do
        result = collector.collect_reports([valid_reflection, invalid_reflection, missing_file])

        expect(result).to be_failure
        expect(result.error).to include("Invalid reflection file: #{invalid_reflection}")
        expect(result.error).to include("File not found: #{missing_file}")
        # Should not include the valid file in error
        expect(result.error).not_to include(valid_reflection)
      end

      it "returns success when all files are valid reflections" do
        valid_reflection2 = File.join(temp_dir, "valid2.md")
        File.write(valid_reflection2, <<~CONTENT)
          # Team Reflection
          **Context**: Sprint review
          ## What Went Well
          Great teamwork
          ## Key Learnings
          New insights
        CONTENT

        result = collector.collect_reports([valid_reflection, valid_reflection2])

        expect(result).to be_success
        expect(result.data[:reports]).to contain_exactly(valid_reflection, valid_reflection2)
        expect(result.data[:reports]).to eq(result.data[:reports].sort)
      end

      it "handles empty glob expansion gracefully" do
        empty_glob = File.join(temp_dir, "nonexistent-pattern-*.md")
        result = collector.collect_reports([empty_glob])

        expect(result).to be_failure
        expect(result.error).to eq("No valid reflection files found")
      end

      it "handles mixed valid files and empty glob patterns" do
        empty_glob = File.join(temp_dir, "nonexistent-*.md")
        result = collector.collect_reports([valid_reflection, empty_glob])

        expect(result).to be_success
        expect(result.data[:reports]).to eq([valid_reflection])
      end

      it "accumulates multiple different error types in a single call" do
        unreadable_file = File.join(temp_dir, "unreadable.md")
        empty_file = File.join(temp_dir, "empty.md")
        
        # Create unreadable file
        File.write(unreadable_file, <<~CONTENT)
          # Reflection
          ## What Went Well
          Good content
        CONTENT
        File.chmod(0000, unreadable_file)

        # Create empty file
        File.write(empty_file, "")

        begin
          result = collector.collect_reports([invalid_reflection, missing_file, unreadable_file, empty_file])

          expect(result).to be_failure
          # Should contain multiple error messages
          error_msg = result.error
          expect(error_msg).to include("Invalid reflection file")
          expect(error_msg).to include("File not found")
        ensure
          File.chmod(0644, unreadable_file) # Restore permissions for cleanup
        end
      end

      it "processes files in deterministic order despite mixed file types" do
        # Test that sorting works correctly with mixed valid/invalid scenarios
        reflection_a = File.join(temp_dir, "a-reflection.md")
        reflection_z = File.join(temp_dir, "z-reflection.md")
        
        File.write(reflection_a, <<~CONTENT)
          # Reflection A
          **Date**: Today
          ## What Went Well
          A went well
          ## What Could Be Improved
          A improvements
        CONTENT

        File.write(reflection_z, <<~CONTENT)
          # Reflection Z
          **Context**: Final
          ## What Went Well
          Z went well
          ## Key Learnings
          Z learnings
        CONTENT

        result = collector.collect_reports([reflection_z, valid_reflection, reflection_a])

        expect(result).to be_success
        # Should be sorted alphabetically
        expect(result.data[:reports]).to eq([reflection_a, valid_reflection, reflection_z])
      end

      it "exercises all code paths in collect_reports method" do
        # This test specifically targets the exact flow through collect_reports
        # to ensure all lines 15-38 are covered
        
        # Setup files that will exercise different code paths
        valid_file1 = File.join(temp_dir, "reflection1.md")
        valid_file2 = File.join(temp_dir, "reflection2.md")
        
        File.write(valid_file1, <<~CONTENT)
          # Daily Reflection
          **Date**: 2025-01-01
          ## What Went Well
          Great progress today
          ## Action Items
          Continue tomorrow
        CONTENT

        File.write(valid_file2, <<~CONTENT)
          # Weekly Reflection
          **Context**: Sprint review
          ## What Could Be Improved
          Better planning
          ## Key Learnings
          Good insights
        CONTENT

        # Test successful path with multiple valid files
        result = collector.collect_reports([valid_file1, valid_file2])
        
        expect(result).to be_success
        expect(result.data[:reports]).to contain_exactly(valid_file1, valid_file2)
        expect(result.data[:reports]).to eq(result.data[:reports].sort)
      end

      it "exercises error accumulation and result failure paths" do
        # This specifically tests the error accumulation logic in lines 19-29
        # and the failure result creation in lines 31-34
        
        invalid_file = File.join(temp_dir, "not-reflection.md")
        missing_file1 = File.join(temp_dir, "missing1.md")
        missing_file2 = File.join(temp_dir, "missing2.md")
        
        File.write(invalid_file, "# Regular Doc\nNot a reflection at all.")
        
        result = collector.collect_reports([invalid_file, missing_file1, missing_file2])
        
        expect(result).to be_failure
        expect(result.error).to include("Invalid reflection file: #{invalid_file}")
        expect(result.error).to include("File not found: #{missing_file1}")
        expect(result.error).to include("File not found: #{missing_file2}")
      end
    end
  end
end
