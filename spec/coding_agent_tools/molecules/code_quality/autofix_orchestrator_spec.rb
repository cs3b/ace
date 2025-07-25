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
                  { file: "lib/test.rb", line: 10, message: "Extra whitespace", correctable: true },
                  { file: "lib/test.rb", line: 15, message: "Prefer single quotes", correctable: true },
                  { file: "lib/helper.rb", line: 5, message: "Undefined variable", correctable: false }
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
                  { file: "lib/test.rb", line: 5, message: "Undefined variable", correctable: false }
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
                  { file: "README.md", message: "Fixed formatting", fixed: true },
                  { file: "docs/guide.md", message: "Fixed list item", fixed: true },
                  { file: "CHANGELOG.md", message: "Issue not fixed", fixed: false }
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
                  { file: "lib/test.rb", line: 10, message: "Extra whitespace", correctable: true }
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  { file: "README.md", message: "Fixed formatting", fixed: true }
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
                { file: "lib/test.rb", line: 10, message: "Extra whitespace" },
                { file: "lib/test.rb", line: 15, message: "Undefined variable" }
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
                  { file: "lib/test.rb", line: 15, message: "Undefined variable" }
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
                  { file: "lib/test.rb", line: 10, message: "Extra whitespace" },
                  { file: "lib/test.rb", line: 15, message: "Undefined variable" },
                  { file: "lib/test.rb", line: 20, message: "New syntax error" }
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
                  { file: "lib/test.rb", line: 10, message: "Ruby issue" }
                ]
              }
            }
          },
          markdown: {
            linters: {
              styleguide: {
                findings: [
                  { file: "README.md", message: "Markdown issue" }
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
end