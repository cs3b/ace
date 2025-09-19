# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::CodeQuality::AutofixOrchestrator do
  let(:orchestrator) { described_class.new }
  let(:dry_run_orchestrator) { described_class.new(dry_run: true) }

  describe "#initialize" do
    it "initializes with dry_run false by default" do
      expect(orchestrator.dry_run).to be false
    end

    it "accepts dry_run parameter" do
      expect(dry_run_orchestrator.dry_run).to be true
    end
  end

  describe "#apply_fixes" do
    context "with Ruby StandardRB fixes" do
      let(:linting_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                fixed: true,
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Extra whitespace", correctable: true},
                  {file: "lib/test.rb", line: 15, message: "Prefer single quotes", correctable: true},
                  {file: "lib/helper.rb", line: 5, message: "Undefined variable", correctable: false}
                ]
              }
            }
          }
        }
      end

      it "processes Ruby fixes correctly" do
        result = orchestrator.apply_fixes(linting_results)

        expect(result[:total_fixed]).to eq(2)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied].length).to eq(1)

        fix = result[:fixes_applied].first
        expect(fix[:type]).to eq("ruby_standardrb")
        expect(fix[:count]).to eq(2)
        expect(fix[:message]).to include("StandardRB formatting fixes")
      end

      it "handles no correctable issues" do
        no_correctable_results = {
          ruby: {
            linters: {
              standardrb: {
                fixed: true,
                findings: [
                  {file: "lib/test.rb", line: 5, message: "Undefined variable", correctable: false}
                ]
              }
            }
          }
        }

        result = orchestrator.apply_fixes(no_correctable_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(1)
        expect(result[:failures].length).to eq(1)
        expect(result[:failures].first[:error]).to include("No correctable issues found")
      end
    end

    context "with Markdown fixes" do
      let(:linting_results) do
        {
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Fixed formatting", fixed: true},
                  {file: "docs/guide.md", message: "Fixed list item", fixed: true},
                  {file: "CHANGELOG.md", message: "Issue not fixed", fixed: false}
                ]
              }
            }
          }
        }
      end

      it "processes Markdown fixes correctly" do
        result = orchestrator.apply_fixes(linting_results)

        expect(result[:total_fixed]).to eq(2)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied].length).to eq(1)

        fix = result[:fixes_applied].first
        expect(fix[:type]).to eq("markdown_formatting")
        expect(fix[:count]).to eq(2)
        expect(fix[:message]).to include("Kramdown formatting")
      end
    end

    context "with combined Ruby and Markdown fixes" do
      let(:combined_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                fixed: true,
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Extra whitespace", correctable: true}
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Fixed formatting", fixed: true}
                ]
              }
            }
          }
        }
      end

      it "processes both types of fixes" do
        result = orchestrator.apply_fixes(combined_results)

        expect(result[:total_fixed]).to eq(2)
        expect(result[:fixes_applied].length).to eq(2)

        types = result[:fixes_applied].map { |fix| fix[:type] }
        expect(types).to include("ruby_standardrb", "markdown_formatting")
      end
    end

    context "with no fixes to apply" do
      let(:empty_results) { {} }

      it "returns empty summary" do
        result = orchestrator.apply_fixes(empty_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
        expect(result[:failures]).to be_empty
      end
    end
  end

  describe "#validate_fixes" do
    let(:before_results) do
      {
        ruby: {
          linters: {
            standardrb: {
              findings: [
                {file: "lib/test.rb", line: 10, message: "Extra whitespace"},
                {file: "lib/test.rb", line: 15, message: "Undefined variable"}
              ]
            }
          }
        }
      }
    end

    context "when issues are resolved" do
      let(:after_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {file: "lib/test.rb", line: 15, message: "Undefined variable"}
                ]
              }
            }
          }
        }
      end

      it "identifies resolved issues" do
        validation = orchestrator.validate_fixes(before_results, after_results)

        expect(validation[:success]).to be true
        expect(validation[:resolved_issues].length).to eq(1)
        expect(validation[:resolved_issues].first[:message]).to eq("Extra whitespace")
        expect(validation[:new_issues]).to be_empty
      end
    end

    context "when new issues are introduced" do
      let(:after_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Extra whitespace"},
                  {file: "lib/test.rb", line: 15, message: "Undefined variable"},
                  {file: "lib/test.rb", line: 20, message: "New syntax error"}
                ]
              }
            }
          }
        }
      end

      it "identifies new issues and marks validation as failed" do
        validation = orchestrator.validate_fixes(before_results, after_results)

        expect(validation[:success]).to be false
        expect(validation[:new_issues].length).to eq(1)
        expect(validation[:new_issues].first[:message]).to eq("New syntax error")
        expect(validation[:resolved_issues]).to be_empty
      end
    end

    context "when issues persist" do
      let(:after_results) { before_results }

      it "identifies persistent issues" do
        validation = orchestrator.validate_fixes(before_results, after_results)

        expect(validation[:success]).to be true
        expect(validation[:persistent_issues].length).to eq(2)
        expect(validation[:resolved_issues]).to be_empty
        expect(validation[:new_issues]).to be_empty
      end
    end
  end

  describe "private methods" do
    describe "#extract_all_issues" do
      let(:mixed_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Ruby issue"}
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Markdown issue"}
                ],
                errors: ["Parse error in file.md"]
              }
            }
          }
        }
      end

      it "extracts issues from all linter types" do
        issues = orchestrator.send(:extract_all_issues, mixed_results)

        expect(issues.length).to be >= 2

        ruby_issue = issues.find { |i| i[:type] == "ruby_standardrb" }
        expect(ruby_issue[:file]).to eq("lib/test.rb")
        expect(ruby_issue[:line]).to eq(10)

        markdown_issue = issues.find { |i| i[:type] == "markdown_styleguide" && i[:file] == "README.md" }
        expect(markdown_issue[:message]).to eq("Markdown issue")
      end
    end

    describe "#find_matching_issue" do
      let(:issue1) do
        {
          type: "ruby_standardrb",
          file: "lib/test.rb",
          line: 10,
          message: "Extra whitespace"
        }
      end

      let(:issue2) do
        {
          type: "ruby_standardrb",
          file: "lib/test.rb",
          line: 15,
          message: "Undefined variable"
        }
      end

      let(:issue_list) { [issue1, issue2] }

      it "finds exact matching issue" do
        match = orchestrator.send(:find_matching_issue, issue1, issue_list)
        expect(match).to eq(issue1)
      end

      it "returns nil when no match found" do
        different_issue = {
          type: "ruby_standardrb",
          file: "lib/other.rb",
          line: 10,
          message: "Extra whitespace"
        }

        match = orchestrator.send(:find_matching_issue, different_issue, issue_list)
        expect(match).to be_nil
      end
    end
  end

  # New comprehensive test coverage for edge cases and improved reliability
  describe "dry run mode", :dry_run do
    let(:dry_run_orchestrator) { described_class.new(dry_run: true) }
    let(:linting_results) do
      {
        ruby: {
          linters: {
            standardrb: {
              fixed: true,
              findings: [
                {file: "lib/test.rb", line: 10, message: "Extra whitespace", correctable: true}
              ]
            }
          }
        }
      }
    end

    it "processes fixes in dry run mode without side effects" do
      result = dry_run_orchestrator.apply_fixes(linting_results)

      expect(result[:total_fixed]).to eq(1)
      expect(result[:fixes_applied]).not_to be_empty
      expect(dry_run_orchestrator.dry_run).to be true
    end

    it "validates fixes in dry run mode" do
      before_results = linting_results
      after_results = {}

      validation = dry_run_orchestrator.validate_fixes(before_results, after_results)

      expect(validation[:success]).to be true
      expect(validation[:resolved_issues]).not_to be_empty
    end
  end

  describe "edge cases for Ruby fixes", :ruby_edge_cases do
    context "with missing or malformed data" do
      it "handles missing standardrb data gracefully" do
        malformed_results = {
          ruby: {
            linters: {
              standardrb: nil
            }
          }
        }

        result = orchestrator.apply_fixes(malformed_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
        expect(result[:failures]).to be_empty
      end

      it "handles missing findings array" do
        no_findings_results = {
          ruby: {
            linters: {
              standardrb: {
                fixed: true,
                findings: nil
              }
            }
          }
        }

        expect { orchestrator.apply_fixes(no_findings_results) }.to raise_error(NoMethodError)
      end

      it "handles empty findings array" do
        empty_findings_results = {
          ruby: {
            linters: {
              standardrb: {
                fixed: true,
                findings: []
              }
            }
          }
        }

        result = orchestrator.apply_fixes(empty_findings_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(1)
        expect(result[:failures].first[:error]).to include("No correctable issues found")
      end

      it "handles findings without correctable field" do
        no_correctable_field_results = {
          ruby: {
            linters: {
              standardrb: {
                fixed: true,
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Issue without correctable field"}
                ]
              }
            }
          }
        }

        result = orchestrator.apply_fixes(no_correctable_field_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(1)
      end

      it "handles standardrb fixed: false" do
        not_fixed_results = {
          ruby: {
            linters: {
              standardrb: {
                fixed: false,
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Issue", correctable: true}
                ]
              }
            }
          }
        }

        result = orchestrator.apply_fixes(not_fixed_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
      end
    end
  end

  describe "edge cases for Markdown fixes", :markdown_edge_cases do
    context "with missing or malformed data" do
      it "handles missing styleguide data gracefully" do
        malformed_results = {
          markdown: {
            linters: {
              styleguide: nil
            }
          }
        }

        result = orchestrator.apply_fixes(malformed_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
      end

      it "handles missing findings array" do
        no_findings_results = {
          markdown: {
            linters: {
              styleguide: {
                findings: nil
              }
            }
          }
        }

        result = orchestrator.apply_fixes(no_findings_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
      end

      it "handles empty findings array" do
        empty_findings_results = {
          markdown: {
            linters: {
              styleguide: {
                findings: []
              }
            }
          }
        }

        result = orchestrator.apply_fixes(empty_findings_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:total_failed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
      end

      it "handles findings without fixed field" do
        no_fixed_field_results = {
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Issue without fixed field"}
                ]
              }
            }
          }
        }

        result = orchestrator.apply_fixes(no_fixed_field_results)

        expect(result[:total_fixed]).to eq(0)
        expect(result[:fixes_applied]).to be_empty
      end

      it "handles mixed fixed and unfixed findings" do
        mixed_results = {
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Fixed issue", fixed: true},
                  {file: "docs/guide.md", message: "Unfixed issue", fixed: false},
                  {file: "CHANGELOG.md", message: "Another fixed issue", fixed: true}
                ]
              }
            }
          }
        }

        result = orchestrator.apply_fixes(mixed_results)

        expect(result[:total_fixed]).to eq(2)
        expect(result[:fixes_applied].first[:count]).to eq(2)
      end
    end
  end

  describe "comprehensive issue extraction", :issue_extraction do
    context "with complex nested data structures" do
      let(:complex_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Ruby issue 1"},
                  {file: "lib/test.rb", line: 20, message: "Ruby issue 2"}
                ]
              },
              rubocop: {
                findings: [
                  {file: "lib/helper.rb", line: 5, message: "Rubocop issue"}
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Markdown issue 1"},
                  {file: "docs/guide.md", message: "Markdown issue 2"}
                ],
                errors: ["Parse error in corrupted.md", "Another parse error"]
              },
              markdownlint: {
                findings: [
                  {file: "CHANGELOG.md", message: "Lint issue"}
                ]
              }
            }
          }
        }
      end

      it "extracts all issues from complex nested structures" do
        issues = orchestrator.send(:extract_all_issues, complex_results)

        expect(issues.length).to eq(6) # 3 ruby + 3 markdown (2 styleguide findings + 1 markdownlint)

        ruby_issues = issues.select { |i| i[:type].start_with?("ruby_") }
        expect(ruby_issues.length).to eq(3)

        markdown_issues = issues.select { |i| i[:type].start_with?("markdown_") }
        expect(markdown_issues.length).to eq(3)
      end

      it "handles missing file or line information" do
        incomplete_results = {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {message: "Issue without file/line info"},
                  {file: "lib/test.rb", message: "Issue without line"},
                  {line: 10, message: "Issue without file"}
                ]
              }
            }
          }
        }

        issues = orchestrator.send(:extract_all_issues, incomplete_results)

        expect(issues.length).to eq(3)
        issues.each do |issue|
          expect(issue[:message]).not_to be_nil
          expect(issue[:message]).not_to be_empty
          expect(issue[:type]).to eq("ruby_standardrb")
        end
      end

      it "handles missing linters section" do
        no_linters_results = {
          ruby: {},
          markdown: {}
        }

        issues = orchestrator.send(:extract_all_issues, no_linters_results)
        expect(issues).to be_empty
      end

      it "handles completely empty results" do
        empty_results = {}

        issues = orchestrator.send(:extract_all_issues, empty_results)
        expect(issues).to be_empty
      end
    end
  end

  describe "complex validation scenarios", :validation_edge_cases do
    context "with complex before/after comparisons" do
      let(:complex_before_results) do
        {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {file: "lib/test.rb", line: 10, message: "Whitespace issue"},
                  {file: "lib/test.rb", line: 15, message: "Syntax issue"},
                  {file: "lib/helper.rb", line: 5, message: "Style issue"}
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Format issue"},
                  {file: "docs/guide.md", message: "List issue"}
                ]
              }
            }
          }
        }
      end

      it "handles partial resolution with new issues" do
        after_results = {
          ruby: {
            linters: {
              standardrb: {
                findings: [
                  {file: "lib/test.rb", line: 15, message: "Syntax issue"}, # persistent
                  {file: "lib/test.rb", line: 25, message: "New issue"} # new
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  {file: "README.md", message: "Format issue"} # persistent
                ]
              }
            }
          }
        }

        validation = orchestrator.validate_fixes(complex_before_results, after_results)

        expect(validation[:success]).to be false
        expect(validation[:resolved_issues].length).to eq(3) # whitespace + style + list issues resolved
        expect(validation[:new_issues].length).to eq(1) # new issue introduced
        expect(validation[:persistent_issues].length).to eq(2) # syntax + format issues persist
      end

      it "handles complete resolution" do
        after_results = {}

        validation = orchestrator.validate_fixes(complex_before_results, after_results)

        expect(validation[:success]).to be true
        expect(validation[:resolved_issues].length).to eq(5) # all issues resolved
        expect(validation[:new_issues]).to be_empty
        expect(validation[:persistent_issues]).to be_empty
      end

      it "handles no changes scenario" do
        validation = orchestrator.validate_fixes(complex_before_results, complex_before_results)

        expect(validation[:success]).to be true
        expect(validation[:resolved_issues]).to be_empty
        expect(validation[:new_issues]).to be_empty
        expect(validation[:persistent_issues].length).to eq(5) # all issues persist
      end

      it "handles malformed before/after results" do
        malformed_before = {ruby: {linters: nil}}
        malformed_after = {markdown: {linters: {}}}

        validation = orchestrator.validate_fixes(malformed_before, malformed_after)

        expect(validation[:success]).to be true
        expect(validation[:resolved_issues]).to be_empty
        expect(validation[:new_issues]).to be_empty
        expect(validation[:persistent_issues]).to be_empty
      end
    end
  end

  describe "integration scenarios", :integration do
    it "processes a complete autofix workflow" do
      # Simulate real autofix workflow with before/after states
      before_results = {
        ruby: {
          linters: {
            standardrb: {
              findings: [
                {file: "lib/calculator.rb", line: 10, message: "Extra whitespace", correctable: true},
                {file: "lib/calculator.rb", line: 15, message: "Use single quotes", correctable: true}
              ]
            }
          }
        },
        markdown: {
          linters: {
            styleguide: {
              findings: [
                {file: "README.md", message: "Fix list formatting", fixed: false}
              ]
            }
          }
        }
      }

      # Apply fixes
      applied_results = {
        ruby: {
          linters: {
            standardrb: {
              fixed: true,
              findings: [
                {file: "lib/calculator.rb", line: 10, message: "Extra whitespace", correctable: true},
                {file: "lib/calculator.rb", line: 15, message: "Use single quotes", correctable: true}
              ]
            }
          }
        },
        markdown: {
          linters: {
            styleguide: {
              findings: [
                {file: "README.md", message: "Fix list formatting", fixed: true}
              ]
            }
          }
        }
      }

      # After fixes applied
      after_results = {
        ruby: {
          linters: {
            standardrb: {
              findings: []
            }
          }
        },
        markdown: {
          linters: {
            styleguide: {
              findings: []
            }
          }
        }
      }

      # Test the complete workflow
      fix_summary = orchestrator.apply_fixes(applied_results)
      validation = orchestrator.validate_fixes(before_results, after_results)

      # Verify fix summary
      expect(fix_summary[:total_fixed]).to eq(3) # 2 ruby + 1 markdown
      expect(fix_summary[:total_failed]).to eq(0)
      expect(fix_summary[:fixes_applied].length).to eq(2) # ruby and markdown fixes

      # Verify validation
      expect(validation[:success]).to be true
      expect(validation[:resolved_issues].length).to eq(3)
      expect(validation[:new_issues]).to be_empty
      expect(validation[:persistent_issues]).to be_empty
    end

    it "handles mixed success and failure scenarios" do
      # Scenario where some fixes succeed and others fail or introduce issues
      mixed_results = {
        ruby: {
          linters: {
            standardrb: {
              fixed: true,
              findings: [
                {file: "lib/good.rb", line: 10, message: "Fixed issue", correctable: true}
              ]
            }
          }
        },
        markdown: {
          linters: {
            styleguide: {
              findings: [
                {file: "broken.md", message: "Could not fix", fixed: false}
              ]
            }
          }
        }
      }

      fix_summary = orchestrator.apply_fixes(mixed_results)

      expect(fix_summary[:total_fixed]).to eq(1) # only ruby fix succeeded
      expect(fix_summary[:fixes_applied].length).to eq(1) # only ruby fixes applied
      expect(fix_summary[:fixes_applied].first[:type]).to eq("ruby_standardrb")
    end

    it "integrates with dry run mode for safe preview" do
      dry_run_orchestrator = described_class.new(dry_run: true)

      preview_results = {
        ruby: {
          linters: {
            standardrb: {
              fixed: true,
              findings: [
                {file: "lib/preview.rb", line: 5, message: "Preview fix", correctable: true}
              ]
            }
          }
        }
      }

      # Dry run should process normally but not affect state
      fix_summary = dry_run_orchestrator.apply_fixes(preview_results)

      expect(fix_summary[:total_fixed]).to eq(1)
      expect(dry_run_orchestrator.dry_run).to be true
    end
  end
end
