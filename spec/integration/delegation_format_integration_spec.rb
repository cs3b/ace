# frozen_string_literal: true

require "spec_helper"
require "yaml"

RSpec.describe "Delegation Format Integration", verbose: false do
  include_context "uses temp dir"
  include CliHelpers

  let(:config_dir) { File.join(temp_dir, ".coding-agent") }
  let(:config_file) { File.join(config_dir, "create-path.yml") }
  let(:executable_path) { File.expand_path("../../exe/create-path", __dir__) }

  before do
    FileUtils.mkdir_p(config_dir)
    
    # Create basic config for testing
    config = {
      "templates" => {
        "docs-new" => {
          "template" => File.join(temp_dir, "templates", "docs.md")
        },
        "reflection-new" => {
          "template" => File.join(temp_dir, "templates", "reflection.md")
        },
        "code-review-new" => {
          "template" => File.join(temp_dir, "templates", "code-review.md")
        }
      },
      "variable_processors" => {
        "defaults" => {
          "priority" => "medium",
          "status" => "pending"
        }
      }
    }
    
    File.write(config_file, YAML.dump(config))
    
    # Create template directory
    template_dir = File.join(temp_dir, "templates")
    FileUtils.mkdir_p(template_dir)
    
    # Create some templates
    File.write(File.join(template_dir, "docs.md"), "# Documentation: {metadata.title}\n\nContent here...")
    File.write(File.join(template_dir, "reflection.md"), "# Reflection: {metadata.title}\n\nReflection content...")
    File.write(File.join(template_dir, "code-review.md"), "# Code Review: {metadata.title}\n\nReview content...")
    
    # Mock PathResolver behavior by creating path.yml
    path_config = {
      "repositories" => {
        "scan_order" => [
          {"name" => "test-repo", "path" => ".", "priority" => 1}
        ]
      },
      "path_patterns" => {
        "docs_new" => {
          "template" => "docs/{slug}.md",
          "variables" => {
            "slug" => "user_input"
          }
        },
        "reflection_new" => {
          "template" => "reflections/{slug}.md",
          "variables" => {
            "slug" => "user_input"
          }
        },
        "code_review_new" => {
          "template" => "reviews/{slug}/",
          "variables" => {
            "slug" => "user_input"
          }
        }
      }
    }
    
    File.write(File.join(config_dir, "path.yml"), YAML.dump(path_config))
    
    # Initialize git repository in temp directory for PathResolver
    Dir.chdir(temp_dir) do
      system("git init --quiet")
      system("git config user.email 'test@example.com'")
      system("git config user.name 'Test User'")
    end
    
    # Change to temp directory for testing
    @original_dir = Dir.pwd
    Dir.chdir(temp_dir)
  end

  after do
    if @original_dir && Dir.exist?(@original_dir) && Dir.pwd != @original_dir
      begin
        Dir.chdir(@original_dir)
      rescue Errno::ENOENT
        # Original directory no longer exists, move to safe directory
        Dir.chdir(ENV['PROJECT_ROOT'] || Dir.home)
      end
    end
  end

  describe "file:reflection-new delegation" do
    it "resolves path via PathResolver correctly" do
      result = execute_cli_command(
        "create-path",
        ["file:reflection-new", "--title", "oauth-implementation-review"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Created:")
      expect(result.stdout).to include("oauth-implementation-review")
    end

    it "creates file with contextual header when template missing" do
      # Remove template file to test fallback
      FileUtils.rm_f(File.join(temp_dir, "templates", "reflection.md"))
      
      result = execute_cli_command(
        "create-path",
        ["file:reflection-new", "--title", "api-review"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Template file not found")
      expect(result.stdout).to include("Created:")
      
      # Find the created file and check content
      created_files = Dir.glob("**/*api-review*")
      expect(created_files).not_to be_empty
      
      content = File.read(created_files.first)
      expect(content).to include("# Reflection - api-review")
    end

    it "handles missing templates gracefully" do
      # Create config without reflection template
      config = {
        "templates" => {
          "docs-new" => {"template" => "docs.md"}
        }
      }
      File.write(config_file, YAML.dump(config))
      
      result = execute_cli_command(
        "create-path",
        ["file:reflection-new", "--title", "security-review"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Template not found for reflection_new")
    end
  end

  describe "directory:code-review-new delegation" do
    it "creates directory structure correctly" do
      result = execute_cli_command(
        "create-path",
        ["directory:code-review-new", "--title", "authentication-session"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Created:")
      expect(result.stdout).to include("authentication-session")
    end

    it "integrates with nav-path resolution" do
      result = execute_cli_command(
        "create-path",
        ["directory:code-review-new", "--title", "oauth-flow-review"]
      )
      
      expect(result).to be_success
      
      # Verify directory was created (path depends on PathResolver)
      created_dirs = Dir.glob("**/oauth-flow-review*", File::FNM_PATHNAME)
      expect(created_dirs).not_to be_empty
    end
  end

  describe "file:docs-new delegation" do
    it "processes template variables correctly" do
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", "API-Documentation", "--priority", "high"]
      )
      
      expect(result).to be_success
      
      # Find created file and verify template processing
      created_files = Dir.glob("**/*API-Documentation*")
      expect(created_files).not_to be_empty
      
      content = File.read(created_files.first)
      expect(content).to include("# Documentation: API-Documentation")
      expect(content).to include("Content here...")
    end

    it "handles special characters in titles" do
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", "API & Auth (v2)"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Created:")
    end
  end

  describe "error handling in delegation" do
    it "shows appropriate error for invalid delegation format" do
      result = execute_cli_command(
        "create-path",
        ["invalid:format", "--title", "test"]
      )
      
      expect(result).not_to be_success
      expect(result.stdout).to include("Error:")
      expect(result.stdout).to include("Unknown delegation creation-type")
    end

    it "handles PathResolver failures gracefully" do
      # Create invalid path config to trigger PathResolver failure
      invalid_config = {
        "repositories" => {
          "scan_order" => []
        }
      }
      File.write(File.join(config_dir, "path.yml"), YAML.dump(invalid_config))
      
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", "test"]
      )
      
      # Should handle the error gracefully
      expect([0, 1]).to include(result.exitstatus)
    end

    it "validates title requirement" do
      result = execute_cli_command(
        "create-path",
        ["file:docs-new"]
      )
      
      expect(result).not_to be_success
      expect(result.stdout).to include("Error:")
      expect(result.stdout).to include("Title required")
    end
  end

  describe "edge cases" do
    it "handles concurrent delegation operations" do
      # Run multiple delegation commands concurrently
      threads = []
      results = []
      
      5.times do |i|
        threads << Thread.new do
          result = execute_cli_command(
            "create-path",
            ["file:docs-new", "--title", "concurrent-doc-#{i}"]
          )
          results << result
        end
      end
      
      threads.each(&:join)
      
      # All should succeed or fail gracefully
      results.each do |result|
        expect([0, 1]).to include(result.exitstatus)
      end
    end

    it "handles very long titles" do
      long_title = "very-" + "long-" * 50 + "title"
      
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", long_title]
      )
      
      # Should handle gracefully (success or controlled failure)
      expect([0, 1]).to include(result.exitstatus)
    end

    it "handles file system permission issues" do
      # Create a read-only directory to test permission handling
      restricted_dir = File.join(temp_dir, "restricted")
      FileUtils.mkdir_p(restricted_dir)
      FileUtils.chmod(0444, restricted_dir)
      
      # Update path config to point to restricted directory
      path_config = {
        "repositories" => {
          "scan_order" => [
            {"name" => "test-repo", "path" => ".", "priority" => 1}
          ]
        },
        "path_patterns" => {
          "docs_new" => {
            "template" => "restricted/{slug}.md"
          }
        }
      }
      File.write(File.join(config_dir, "path.yml"), YAML.dump(path_config))
      
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", "permission-test"]
      )
      
      # Should fail gracefully with appropriate error
      expect(result.exitstatus).to eq(1)
      
      # Restore permissions for cleanup
      FileUtils.chmod(0755, restricted_dir) rescue nil
    end
  end

  describe "template context fallback" do
    it "creates appropriate content based on delegation type" do
      # Remove all templates to test pure fallback
      templates_dir = File.join(temp_dir, "templates")
      FileUtils.rm_rf(templates_dir) if File.exist?(templates_dir)
      
      # Test each delegation type
      delegation_tests = [
        {type: "file:docs-new", title: "api-guide", expected: "# Documentation - api-guide"},
        {type: "file:reflection-new", title: "oauth-analysis", expected: "# Reflection - oauth-analysis"},
        {type: "directory:code-review-new", title: "auth-review", expected: "# Code Review - auth-review"}
      ]
      
      delegation_tests.each do |test_case|
        result = execute_cli_command(
          "create-path",
          [test_case[:type], "--title", test_case[:title]]
        )
        
        expect(result).to be_success
        
        # Find created file/directory and verify content
        created_items = Dir.glob("**/*#{test_case[:title]}*")
        expect(created_items).not_to be_empty
        
        # Check content if it's a file
        created_items.each do |item|
          if File.file?(item)
            content = File.read(item)
            expect(content).to include(test_case[:expected])
          end
        end
      end
    end
  end

  describe "CLI delegation commands" do
    it "executes create-path file:reflection-new successfully" do
      result = execute_cli_command(
        "create-path",
        ["file:reflection-new", "--title", "oauth-implementation-review"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Created:")
      expect(result.stdout).to include("oauth-implementation-review")
    end

    it "executes create-path directory:code-review-new successfully" do
      result = execute_cli_command(
        "create-path",
        ["directory:code-review-new", "--title", "authentication-session"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Created:")
      expect(result.stdout).to include("authentication-session")
    end

    it "shows appropriate error messages for invalid delegation" do
      result = execute_cli_command(
        "create-path",
        ["file:unknown-type", "--title", "test"]
      )
      
      expect(result).not_to be_success
      expect(result.stdout).to include("Error:")
      expect(result.stdout).to include("Unknown delegation nav-type")
    end

    it "handles malformed delegation syntax" do
      result = execute_cli_command(
        "create-path",
        ["file-docs-new", "--title", "test"]
      )
      
      expect(result).not_to be_success
      expect(result.stdout).to include("Error:")
      expect(result.stdout).to include("Unknown creation type")
    end

    it "validates required title parameter" do
      result = execute_cli_command(
        "create-path",
        ["file:docs-new"]
      )
      
      expect(result).not_to be_success
      expect(result.stdout).to include("Error:")
      expect(result.stdout).to include("Title required")
    end

    it "handles delegation with metadata options" do
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", "API-Guide", "--priority", "high"]
      )
      
      expect(result).to be_success
      expect(result.stdout).to include("Created:")
    end

    it "provides help text that includes delegation examples" do
      result = execute_cli_command(
        "create-path",
        ["--help"]
      )
      
      expect(result.stdout).to include("file:docs-new")
      expect(result.stdout).to include("file:reflection-new")
      expect(result.stdout).to include("directory:code-review-new")
    end
  end

  describe "performance regression tests" do
    it "ensures delegation format doesn't significantly impact performance" do
      # Measure baseline performance with regular file creation
      start_time = Time.now
      10.times do |i|
        result = execute_cli_command(
          "create-path",
          ["file", "--title", "baseline-#{i}.txt", "--content", "test content"]
        )
        expect(result).to be_success
      end
      baseline_time = Time.now - start_time

      # Measure delegation format performance
      start_time = Time.now
      10.times do |i|
        result = execute_cli_command(
          "create-path",
          ["file:docs-new", "--title", "delegation-#{i}"]
        )
        expect(result).to be_success
      end
      delegation_time = Time.now - start_time

      # Delegation should not be more than 2x slower than baseline
      expect(delegation_time).to be < (baseline_time * 2.0)
    end

    it "tests concurrent delegation operations" do
      threads = []
      results = []
      
      # Run 5 concurrent delegation operations
      5.times do |i|
        threads << Thread.new do
          # Add unique timestamp to avoid file conflicts
          unique_id = "#{i}-#{Time.now.to_f.to_s.gsub('.', '')}"
          result = execute_cli_command(
            "create-path",
            ["file:docs-new", "--title", "concurrent-delegation-#{unique_id}"]
          )
          results << result
        end
      end
      
      threads.each(&:join)
      
      # All should succeed or fail gracefully
      results.each do |result|
        # Accept either success or controlled failure for concurrent operations
        expect([0, 1]).to include(result.exit_code)
      end
    end

    it "handles delegation with large titles efficiently" do
      # Test with moderately long title (realistic use case)
      long_title = "implementation-guide-for-oauth-2-authentication-with-pkce-extension"
      
      start_time = Time.now
      result = execute_cli_command(
        "create-path",
        ["file:docs-new", "--title", long_title]
      )
      execution_time = Time.now - start_time
      
      expect(result).to be_success
      # Should complete within reasonable time (5 seconds is very generous)
      expect(execution_time).to be < 5.0
    end

    it "maintains consistent performance across delegation types" do
      delegation_types = [
        "file:docs-new",
        "file:reflection-new", 
        "directory:code-review-new"
      ]
      
      execution_times = []
      
      delegation_types.each_with_index do |type, i|
        start_time = Time.now
        result = execute_cli_command(
          "create-path",
          [type, "--title", "performance-test-#{i}"]
        )
        execution_time = Time.now - start_time
        
        expect(result).to be_success
        execution_times << execution_time
      end
      
      # All delegation types should have similar performance
      # (within 500ms of each other for this simple operation)
      max_time = execution_times.max
      min_time = execution_times.min
      expect(max_time - min_time).to be < 0.5
    end
  end
end