# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/organisms/code_quality/validation_workflow_manager"

RSpec.describe CodingAgentTools::Organisms::CodeQuality::ValidationWorkflowManager do
  let(:config) { { validation_threshold: 100 } }
  let(:manager) { described_class.new(config: config) }
  let(:temp_dir) { Dir.mktmpdir("validation_workflow_test") }
  let(:test_file_path) { File.join(temp_dir, "test_file.rb") }

  before do
    FileUtils.mkdir_p(temp_dir)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "initializes with provided config" do
      expect(manager.config).to eq(config)
    end

    it "stores config as instance variable" do
      expect(manager.instance_variable_get(:@config)).to eq(config)
    end
  end

  describe "#orchestrate_validation" do
    let(:linting_results) do
      {
        ruby: {
          total_issues: 5,
          linters: {
            rubocop: {
              findings: [
                {
                  file: test_file_path,
                  line: 10,
                  message: "Style issue",
                  correctable: true
                }
              ]
            }
          }
        },
        markdown: {
          total_issues: 2,
          linters: {
            markdownlint: {
              findings: [
                {
                  file: "#{temp_dir}/test.md",
                  line: 5,
                  message: "MD001: Missing header",
                  correctable: false
                }
              ]
            }
          }
        }
      }
    end

    before do
      File.write(test_file_path, "# Test Ruby file\nclass TestClass\nend\n")
      File.write("#{temp_dir}/test.md", "# Test Markdown\nContent here")
    end

    context "without autofix applied" do
      it "returns workflow with validation results" do
        result = manager.orchestrate_validation(linting_results)

        expect(result).to have_key(:validations_run)
        expect(result).to have_key(:validations_passed)
        expect(result).to have_key(:validations_failed)
        expect(result).to have_key(:recommendations)
        expect(result).to be_a(Hash)
      end

      it "runs cross-validations" do
        expect(manager).to receive(:run_cross_validations).with(linting_results, anything)
        manager.orchestrate_validation(linting_results)
      end

      it "generates recommendations" do
        expect(manager).to receive(:generate_recommendations).with(linting_results, anything)
        manager.orchestrate_validation(linting_results)
      end

      it "does not check autofix regressions when autofix not applied" do
        expect(manager).not_to receive(:check_autofix_regressions)
        manager.orchestrate_validation(linting_results, autofix_applied: false)
      end
    end

    context "with autofix applied" do
      it "checks for autofix regressions" do
        expect(manager).to receive(:check_autofix_regressions).with(linting_results, anything)
        manager.orchestrate_validation(linting_results, autofix_applied: true)
      end

      it "includes regression check in workflow" do
        result = manager.orchestrate_validation(linting_results, autofix_applied: true)
        
        # Should have regression validation result
        regression_validations = result[:validations_passed] + result[:validations_failed]
        regression_found = regression_validations.any? { |v| v[:type] == "autofix_regression" }
        expect(regression_found).to be(true)
      end
    end
  end

  describe "#has_conflicting_fixes?" do
    context "with conflicting fixes on same line" do
      let(:results_with_conflicts) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  {
                    file: test_file_path,
                    line: 10,
                    message: "Add space",
                    correctable: true
                  }
                ]
              },
              standardrb: {
                findings: [
                  {
                    file: test_file_path,
                    line: 10,
                    message: "Remove space",
                    fixed: true
                  }
                ]
              }
            }
          }
        }
      end

      it "detects conflicting fixes" do
        expect(manager.send(:has_conflicting_fixes?, results_with_conflicts)).to be(true)
      end
    end

    context "with fixes on different lines" do
      let(:results_no_conflicts) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  {
                    file: test_file_path,
                    line: 10,
                    message: "Style issue",
                    correctable: true
                  }
                ]
              },
              standardrb: {
                findings: [
                  {
                    file: test_file_path,
                    line: 20,
                    message: "Another issue",
                    fixed: true
                  }
                ]
              }
            }
          }
        }
      end

      it "does not detect conflicts" do
        expect(manager.send(:has_conflicting_fixes?, results_no_conflicts)).to be(false)
      end
    end

    context "with no correctable findings" do
      let(:results_no_fixes) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  {
                    file: test_file_path,
                    line: 10,
                    message: "Style issue",
                    correctable: false
                  }
                ]
              }
            }
          }
        }
      end

      it "does not detect conflicts" do
        expect(manager.send(:has_conflicting_fixes?, results_no_fixes)).to be(false)
      end
    end

    context "with empty results" do
      let(:empty_results) { {} }

      it "handles empty results gracefully" do
        expect(manager.send(:has_conflicting_fixes?, empty_results)).to be(false)
      end
    end

    context "with missing linters key" do
      let(:results_missing_linters) do
        {
          ruby: {},
          markdown: {}
        }
      end

      it "raises error when linters key is missing" do
        expect { manager.send(:has_conflicting_fixes?, results_missing_linters) }.to raise_error(NoMethodError)
      end
    end
  end

  describe "#validate_file_integrity" do
    let(:workflow) { { validations_passed: [], validations_failed: [] } }

    context "with readable files" do
      let(:results_with_files) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: test_file_path, line: 1, message: "Issue" }
                ]
              }
            }
          }
        }
      end

      before do
        File.write(test_file_path, "# Test content")
      end

      it "passes integrity check for readable files" do
        manager.send(:validate_file_integrity, results_with_files, workflow)
        
        expect(workflow[:validations_passed]).to include(
          hash_including(type: "file_integrity", message: "All files passed integrity checks")
        )
        expect(workflow[:validations_failed]).to be_empty
      end
    end

    context "with empty files" do
      let(:results_with_empty_file) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: test_file_path, line: 1, message: "Issue" }
                ]
              }
            }
          }
        }
      end

      before do
        File.write(test_file_path, "")  # Create empty file
      end

      it "detects empty files as integrity issues" do
        manager.send(:validate_file_integrity, results_with_empty_file, workflow)
        
        expect(workflow[:validations_failed]).to include(
          hash_including(
            type: "file_integrity",
            message: "File integrity issues detected",
            details: include("#{test_file_path} is empty")
          )
        )
      end
    end

    context "with non-existent files" do
      let(:non_existent_file) { File.join(temp_dir, "non_existent.rb") }
      let(:results_with_missing_file) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: non_existent_file, line: 1, message: "Issue" }
                ]
              }
            }
          }
        }
      end

      it "skips non-existent files gracefully" do
        manager.send(:validate_file_integrity, results_with_missing_file, workflow)
        
        expect(workflow[:validations_passed]).to include(
          hash_including(type: "file_integrity", message: "All files passed integrity checks")
        )
      end
    end

    context "with unreadable files" do
      let(:results_with_unreadable_file) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: test_file_path, line: 1, message: "Issue" }
                ]
              }
            }
          }
        }
      end

      before do
        File.write(test_file_path, "content")
        File.chmod(0000, test_file_path) # Make unreadable
      end

      after do
        File.chmod(0644, test_file_path) # Restore permissions for cleanup
      end

      it "detects unreadable files as integrity issues" do
        manager.send(:validate_file_integrity, results_with_unreadable_file, workflow)
        
        expect(workflow[:validations_failed]).to include(
          hash_including(
            type: "file_integrity",
            message: "File integrity issues detected",
            details: include("#{test_file_path} is not readable")
          )
        )
      end
    end
  end

  describe "#check_linter_consistency" do
    let(:workflow) { { validations_passed: [], validations_failed: [] } }

    context "with consistent linter results" do
      let(:consistent_results) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: test_file_path, line: 10, message: "Style issue" }
                ]
              },
              standardrb: {
                findings: [
                  { file: test_file_path, line: 20, message: "Different issue" }
                ]
              }
            }
          }
        }
      end

      it "passes consistency check" do
        manager.send(:check_linter_consistency, consistent_results, workflow)
        
        expect(workflow[:validations_passed]).to include(
          hash_including(type: "linter_consistency", message: "Linters are consistent")
        )
      end
    end

    context "with contradictory linter results" do
      let(:contradictory_results) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: test_file_path, line: 10, message: "Add space" }
                ]
              },
              standardrb: {
                findings: [
                  { file: test_file_path, line: 10, message: "Remove space" }
                ]
              }
            }
          }
        }
      end

      before do
        allow(manager).to receive(:has_contradictory_issues?).and_return(true)
      end

      it "detects inconsistencies" do
        manager.send(:check_linter_consistency, contradictory_results, workflow)
        
        expect(workflow[:validations_failed]).to include(
          hash_including(
            type: "linter_consistency",
            message: "Inconsistent linter results",
            files: [test_file_path]
          )
        )
      end
    end

    context "with empty results" do
      let(:empty_results) { {} }

      it "handles empty results gracefully" do
        manager.send(:check_linter_consistency, empty_results, workflow)
        
        expect(workflow[:validations_passed]).to include(
          hash_including(type: "linter_consistency", message: "Linters are consistent")
        )
      end
    end
  end

  describe "#has_contradictory_issues?" do
    context "with different messages on same line" do
      let(:contradictory_issues) do
        [
          { linter: :rubocop, issue: { line: 10, message: "Add space" } },
          { linter: :standardrb, issue: { line: 10, message: "Remove space" } }
        ]
      end

      it "detects contradictions" do
        expect(manager.send(:has_contradictory_issues?, contradictory_issues)).to be(true)
      end
    end

    context "with same messages on same line" do
      let(:same_issues) do
        [
          { linter: :rubocop, issue: { line: 10, message: "Style issue" } },
          { linter: :standardrb, issue: { line: 10, message: "Style issue" } }
        ]
      end

      it "does not detect contradictions" do
        expect(manager.send(:has_contradictory_issues?, same_issues)).to be(false)
      end
    end

    context "with single issue" do
      let(:single_issue) do
        [{ linter: :rubocop, issue: { line: 10, message: "Style issue" } }]
      end

      it "does not detect contradictions" do
        expect(manager.send(:has_contradictory_issues?, single_issue)).to be(false)
      end
    end

    context "with empty issues" do
      let(:empty_issues) { [] }

      it "handles empty issues gracefully" do
        expect(manager.send(:has_contradictory_issues?, empty_issues)).to be(false)
      end
    end
  end

  describe "#check_autofix_regressions" do
    let(:workflow) { { validations_passed: [], validations_failed: [] } }

    context "with no new issues after autofix" do
      let(:results_no_issues) do
        { ruby: { total_issues: 0 }, markdown: { total_issues: 0 } }
      end

      it "passes regression check" do
        manager.send(:check_autofix_regressions, results_no_issues, workflow)
        
        expect(workflow[:validations_passed]).to include(
          hash_including(
            type: "autofix_regression",
            message: "No regressions detected from autofix"
          )
        )
      end
    end

    context "with new issues after autofix" do
      let(:results_with_issues) do
        { ruby: { total_issues: 5 }, markdown: { total_issues: 3 } }
      end

      it "detects regressions" do
        manager.send(:check_autofix_regressions, results_with_issues, workflow)
        
        expect(workflow[:validations_failed]).to include(
          hash_including(
            type: "autofix_regression",
            message: "Autofix may have introduced new issues",
            count: 8
          )
        )
      end
    end

    context "with missing total_issues" do
      let(:results_missing_totals) do
        { ruby: {}, markdown: {} }
      end

      it "handles missing totals gracefully" do
        manager.send(:check_autofix_regressions, results_missing_totals, workflow)
        
        expect(workflow[:validations_passed]).to include(
          hash_including(
            type: "autofix_regression",
            message: "No regressions detected from autofix"
          )
        )
      end
    end
  end

  describe "#generate_recommendations" do
    let(:workflow) { { recommendations: [] } }

    context "with high issue count" do
      let(:high_issue_results) do
        { ruby: { total_issues: 150 }, markdown: { total_issues: 50 } }
      end

      it "recommends incremental fixing" do
        manager.send(:generate_recommendations, high_issue_results, workflow)
        
        expect(workflow[:recommendations]).to include(
          hash_including(
            priority: "high",
            message: "Consider fixing issues incrementally due to high count"
          )
        )
      end
    end

    context "with security issues" do
      let(:security_results) do
        {
          ruby: {
            total_issues: 10,
            linters: {
              security: {
                findings: [
                  { file: test_file_path, message: "SQL injection vulnerability" }
                ]
              }
            }
          }
        }
      end

      it "recommends fixing security issues first" do
        manager.send(:generate_recommendations, security_results, workflow)
        
        expect(workflow[:recommendations]).to include(
          hash_including(
            priority: "critical",
            message: "Security issues detected - fix these first"
          )
        )
      end
    end

    context "with broken links" do
      let(:broken_link_results) do
        {
          markdown: {
            total_issues: 5,
            linters: {
              link_validation: {
                findings: [
                  { file: "#{temp_dir}/test.md", message: "Broken link" }
                ]
              }
            }
          }
        }
      end

      it "recommends fixing broken links" do
        manager.send(:generate_recommendations, broken_link_results, workflow)
        
        expect(workflow[:recommendations]).to include(
          hash_including(
            priority: "medium",
            message: "Broken links detected - may impact documentation quality"
          )
        )
      end
    end

    context "with low issue count and no special issues" do
      let(:low_issue_results) do
        { ruby: { total_issues: 5 }, markdown: { total_issues: 2 } }
      end

      it "generates no recommendations" do
        manager.send(:generate_recommendations, low_issue_results, workflow)
        
        expect(workflow[:recommendations]).to be_empty
      end
    end

    context "with exactly 100 issues" do
      let(:boundary_results) do
        { ruby: { total_issues: 100 }, markdown: { total_issues: 0 } }
      end

      it "does not recommend incremental fixing at boundary" do
        manager.send(:generate_recommendations, boundary_results, workflow)
        
        incremental_rec = workflow[:recommendations].find do |rec|
          rec[:message].include?("incremental")
        end
        expect(incremental_rec).to be_nil
      end
    end

    context "with 101 issues" do
      let(:over_boundary_results) do
        { ruby: { total_issues: 101 }, markdown: { total_issues: 0 } }
      end

      it "recommends incremental fixing just over boundary" do
        manager.send(:generate_recommendations, over_boundary_results, workflow)
        
        expect(workflow[:recommendations]).to include(
          hash_including(
            priority: "high",
            message: "Consider fixing issues incrementally due to high count"
          )
        )
      end
    end
  end

  describe "#extract_all_files" do
    let(:results_with_files) do
      {
        ruby: {
          linters: {
            rubocop: {
              findings: [
                { file: test_file_path, line: 1, message: "Issue 1" },
                { file: test_file_path, line: 2, message: "Issue 2" }
              ]
            },
            standardrb: {
              findings: [
                { file: "#{temp_dir}/other.rb", line: 1, message: "Issue 3" }
              ]
            }
          }
        },
        markdown: {
          linters: {
            markdownlint: {
              findings: [
                { file: "#{temp_dir}/test.md", line: 1, message: "Issue 4" }
              ]
            }
          }
        }
      }
    end

    it "extracts unique files from all linter results" do
      files = manager.send(:extract_all_files, results_with_files)
      
      expect(files).to contain_exactly(
        test_file_path,
        "#{temp_dir}/other.rb",
        "#{temp_dir}/test.md"
      )
    end

    context "with duplicate files" do
      let(:results_with_duplicates) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { file: test_file_path, line: 1, message: "Issue 1" },
                  { file: test_file_path, line: 2, message: "Issue 2" }
                ]
              }
            }
          }
        }
      end

      it "returns unique files only" do
        files = manager.send(:extract_all_files, results_with_duplicates)
        
        expect(files).to eq([test_file_path])
        expect(files.size).to eq(1)
      end
    end

    context "with missing file key" do
      let(:results_missing_files) do
        {
          ruby: {
            linters: {
              rubocop: {
                findings: [
                  { line: 1, message: "Issue without file" }
                ]
              }
            }
          }
        }
      end

      it "handles missing file keys gracefully" do
        files = manager.send(:extract_all_files, results_missing_files)
        
        expect(files).to be_empty
      end
    end

    context "with empty results" do
      let(:empty_results) { {} }

      it "handles empty results gracefully" do
        files = manager.send(:extract_all_files, empty_results)
        
        expect(files).to be_empty
      end
    end
  end

  describe "#count_total_issues" do
    let(:results_with_totals) do
      { ruby: { total_issues: 25 }, markdown: { total_issues: 15 } }
    end

    it "sums total issues across all languages" do
      count = manager.send(:count_total_issues, results_with_totals)
      
      expect(count).to eq(40)
    end

    context "with missing total_issues" do
      let(:results_missing_totals) do
        { ruby: {}, markdown: {} }
      end

      it "handles missing totals gracefully" do
        count = manager.send(:count_total_issues, results_missing_totals)
        
        expect(count).to eq(0)
      end
    end

    context "with partial missing totals" do
      let(:results_partial_totals) do
        { ruby: { total_issues: 10 }, markdown: {} }
      end

      it "handles partial missing totals" do
        count = manager.send(:count_total_issues, results_partial_totals)
        
        expect(count).to eq(10)
      end
    end

    context "with missing language sections" do
      let(:results_missing_sections) { {} }

      it "handles missing language sections" do
        count = manager.send(:count_total_issues, results_missing_sections)
        
        expect(count).to eq(0)
      end
    end
  end

  describe "#has_security_issues?" do
    context "with security findings" do
      let(:results_with_security) do
        {
          ruby: {
            linters: {
              security: {
                findings: [
                  { file: test_file_path, message: "SQL injection" }
                ]
              }
            }
          }
        }
      end

      it "detects security issues" do
        expect(manager.send(:has_security_issues?, results_with_security)).to be(true)
      end
    end

    context "with empty security findings" do
      let(:results_no_security) do
        {
          ruby: {
            linters: {
              security: { findings: [] }
            }
          }
        }
      end

      it "returns false for empty findings" do
        expect(manager.send(:has_security_issues?, results_no_security)).to be(false)
      end
    end

    context "with missing security linter" do
      let(:results_no_security_linter) do
        {
          ruby: {
            linters: {
              rubocop: { findings: [] }
            }
          }
        }
      end

      it "returns false when security linter missing" do
        expect(manager.send(:has_security_issues?, results_no_security_linter)).to be_falsy
      end
    end

    context "with missing ruby section" do
      let(:results_no_ruby) { { markdown: {} } }

      it "returns false when ruby section missing" do
        expect(manager.send(:has_security_issues?, results_no_ruby)).to be_falsy
      end
    end
  end

  describe "#has_broken_links?" do
    context "with broken link findings" do
      let(:results_with_broken_links) do
        {
          markdown: {
            linters: {
              link_validation: {
                findings: [
                  { file: "#{temp_dir}/test.md", message: "Broken link to example.com" }
                ]
              }
            }
          }
        }
      end

      it "detects broken links" do
        expect(manager.send(:has_broken_links?, results_with_broken_links)).to be(true)
      end
    end

    context "with empty link validation findings" do
      let(:results_no_broken_links) do
        {
          markdown: {
            linters: {
              link_validation: { findings: [] }
            }
          }
        }
      end

      it "returns false for empty findings" do
        expect(manager.send(:has_broken_links?, results_no_broken_links)).to be(false)
      end
    end

    context "with missing link validation linter" do
      let(:results_no_link_linter) do
        {
          markdown: {
            linters: {
              markdownlint: { findings: [] }
            }
          }
        }
      end

      it "returns false when link validation linter missing" do
        expect(manager.send(:has_broken_links?, results_no_link_linter)).to be_falsy
      end
    end

    context "with missing markdown section" do
      let(:results_no_markdown) { { ruby: {} } }

      it "returns false when markdown section missing" do
        expect(manager.send(:has_broken_links?, results_no_markdown)).to be_falsy
      end
    end
  end

  # Integration test for full workflow
  describe "integration scenarios" do
    let(:complex_results) do
      {
        ruby: {
          total_issues: 150,
          linters: {
            rubocop: {
              findings: [
                {
                  file: test_file_path,
                  line: 10,
                  message: "Add space after comma",
                  correctable: true
                }
              ]
            },
            security: {
              findings: [
                {
                  file: test_file_path,
                  line: 20,
                  message: "Potential SQL injection",
                  correctable: false
                }
              ]
            }
          }
        },
        markdown: {
          total_issues: 25,
          linters: {
            link_validation: {
              findings: [
                {
                  file: "#{temp_dir}/docs.md",
                  line: 5,
                  message: "Broken link to http://example.com/missing"
                }
              ]
            }
          }
        }
      }
    end

    before do
      File.write(test_file_path, "# Test Ruby file\nclass TestClass\nend\n")
      File.write("#{temp_dir}/docs.md", "# Documentation\n[Link](http://example.com/missing)")
    end

    it "orchestrates complete validation workflow with complex results" do
      result = manager.orchestrate_validation(complex_results, autofix_applied: true)

      # Should have all workflow components
      expect(result).to have_key(:validations_run)
      expect(result).to have_key(:validations_passed)
      expect(result).to have_key(:validations_failed)
      expect(result).to have_key(:recommendations)

      # Should have file integrity validation
      integrity_validations = (result[:validations_passed] + result[:validations_failed])
                               .select { |v| v[:type] == "file_integrity" }
      expect(integrity_validations).not_to be_empty

      # Should have autofix regression check (since autofix_applied: true)
      regression_validations = (result[:validations_passed] + result[:validations_failed])
                                .select { |v| v[:type] == "autofix_regression" }
      expect(regression_validations).not_to be_empty

      # Should have recommendations due to high issue count, security issues, and broken links
      expect(result[:recommendations]).to include(
        hash_including(
          priority: "high",
          message: "Consider fixing issues incrementally due to high count"
        )
      )
      expect(result[:recommendations]).to include(
        hash_including(
          priority: "critical",
          message: "Security issues detected - fix these first"
        )
      )
      expect(result[:recommendations]).to include(
        hash_including(
          priority: "medium",
          message: "Broken links detected - may impact documentation quality"
        )
      )
    end
  end
end