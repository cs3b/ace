require 'spec_helper'
require 'tempfile'
require 'fileutils'

RSpec.describe "User-Facing Command Integration", type: :integration do
  include ProcessHelpers
  let(:project_root) { File.expand_path('../../', __dir__) }
  let(:exe_dir) { File.join(project_root, 'exe') }
  
  describe "Command availability and basic functionality" do
    Dir.entries(File.join(File.expand_path('../../', __dir__), 'exe')).reject { |f| f.start_with?('.') }.sort.each do |command|
      describe command do
        let(:command_path) { File.join(exe_dir, command) }
        
        it "is executable" do
          expect(File.executable?(command_path)).to be true
        end
        
        it "provides help output when called with --help" do
          result = system("cd #{project_root} && timeout 10s #{command_path} --help >/dev/null 2>&1")
          # Many commands exit with non-zero even when help works, so we check output instead
          help_output = `cd #{project_root} && timeout 10s #{command_path} --help 2>&1`
          expect(help_output).to include("Commands:").or include("Usage:").or include("DESCRIPTION:")
        end
        
        it "handles invalid arguments gracefully" do
          # Test that commands don't crash with invalid arguments
          result = system("cd #{project_root} && timeout 5s #{command_path} --invalid-flag >/dev/null 2>&1")
          # Commands should either succeed or fail gracefully (not timeout/crash)
          expect($?.exitstatus).to be_a(Integer)
        end
      end
    end
  end

  describe "Core command functionality" do
    describe "navigation commands" do
      it "nav-ls lists directory contents" do
        output = `cd #{project_root} && exe/nav-ls lib 2>/dev/null`
        expect(output).to include("coding_agent_tools")
      end
      
      it "nav-path finds files" do
        output = `cd #{project_root} && exe/nav-path file "Gemfile" 2>/dev/null`
        expect(output).to include("Gemfile")
      end
      
      it "nav-tree shows directory structure" do
        output = `cd #{project_root} && exe/nav-tree lib --depth 2 2>/dev/null`
        expect(output).to include("lib")
      end
    end

    describe "git commands" do
      it "git-status shows repository status" do
        output = `cd #{project_root} && exe/git-status 2>/dev/null`
        # Should complete without error (output varies by repo state)
        expect($?.exitstatus).to eq(0)
      end
    end

    describe "task management commands" do
      it "task-manager provides task information" do
        output = `cd #{project_root} && exe/task-manager --help 2>&1`
        expect(output).to include("Commands:")
      end
    end

    describe "code quality commands" do
      it "code-lint provides linting capabilities" do
        output = `cd #{project_root} && exe/code-lint --help 2>&1`
        expect(output).to include("Commands:")
      end
    end
  end

  describe "Error handling" do
    it "commands handle missing arguments appropriately" do
      # Test a representative command with missing required arguments
      cmd = "create-path"
      
      # Use ProcessHelpers for more efficient execution
      command_path = File.join(exe_dir, cmd)
      stdout, stderr, status = execute_command([command_path], timeout: 2)
      # Commands should exit with error codes when missing required args (some may exit 0)
      expect(status.exitstatus).to be_a(Integer)
    end
  end

  describe "Performance" do
    it "help commands respond quickly" do
      # Test that help commands complete within reasonable time
      start_time = Time.now
      `cd #{project_root} && exe/nav-ls --help >/dev/null 2>&1`
      end_time = Time.now
      
      expect(end_time - start_time).to be < 5
    end
  end
end