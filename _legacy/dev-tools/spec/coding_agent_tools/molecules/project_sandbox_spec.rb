# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::ProjectSandbox do
  let(:temp_dir) { Dir.mktmpdir }
  let(:project_root) { temp_dir }

  before do
    # Create a basic project structure
    FileUtils.mkdir_p(File.join(temp_dir, ".git"))
    FileUtils.mkdir_p(File.join(temp_dir, "dev-tools", "lib"))
    FileUtils.mkdir_p(File.join(temp_dir, "dev-taskflow", "current"))
    FileUtils.mkdir_p(File.join(temp_dir, "bin"))
    FileUtils.mkdir_p(File.join(temp_dir, ".coding-agent"))

    # Create some test files
    FileUtils.touch(File.join(temp_dir, "README.md"))
    FileUtils.touch(File.join(temp_dir, "dev-tools", "lib", "test.rb"))
    FileUtils.touch(File.join(temp_dir, "bin", "script"))
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "uses provided project root" do
      sandbox = described_class.new(project_root)
      # Handle macOS symlink resolution (/var -> /private/var)
      expected_root = File.exist?(project_root) ? File.realpath(project_root) : project_root
      expect(sandbox.project_root).to eq(expected_root)
    end

    it "detects project root when not provided" do
      # Use block form to ensure directory is restored even if test fails
      original_dir = Dir.pwd
      begin
        Dir.chdir(temp_dir)
        sandbox = described_class.new
        expect(File.realpath(sandbox.project_root)).to eq(File.realpath(temp_dir))
      ensure
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      end
    end

    it "accepts custom allowed and forbidden patterns" do
      allowed = ["**/*.txt"]
      forbidden = ["**/secret/**"]

      sandbox = described_class.new(project_root, allowed, forbidden)

      # Should reject .rb files (not in allowed patterns)
      result = sandbox.validate_path(File.join(temp_dir, "test.rb"))
      expect(result[:success]).to be false
    end
  end

  describe "#validate_path", :security do
    let(:sandbox) { described_class.new(project_root) }

    context "with valid paths" do
      it "accepts paths within project root" do
        path = File.join(temp_dir, "README.md")
        result = sandbox.validate_path(path)

        expect(result[:success]).to be true
        expect(result[:path]).to eq(File.realpath(path))
      end

      it "accepts relative paths" do
        original_dir = Dir.pwd
        begin
          Dir.chdir(temp_dir)
          result = sandbox.validate_path("README.md")
          expect(result[:success]).to be true
        ensure
          Dir.chdir(original_dir) if Dir.exist?(original_dir)
        end
      end

      it "accepts ruby files in dev-tools" do
        path = File.join(temp_dir, "dev-tools", "lib", "test.rb")
        result = sandbox.validate_path(path)
        expect(result[:success]).to be true
      end

      it "accepts scripts in bin directory" do
        path = File.join(temp_dir, "bin", "script")
        result = sandbox.validate_path(path)
        expect(result[:success]).to be true
      end
    end

    context "with invalid paths", :security do
      it "rejects nil paths" do
        result = sandbox.validate_path(nil)
        expect(result[:success]).to be false
        expect(result[:error]).to include("cannot be nil")
      end

      it "rejects empty paths" do
        result = sandbox.validate_path("")
        expect(result[:success]).to be false
        expect(result[:error]).to include("cannot be empty")
      end

      it "rejects paths outside project root" do
        outside_path = File.join(File.dirname(temp_dir), "outside.md")
        result = sandbox.validate_path(outside_path)

        expect(result[:success]).to be false
        expect(result[:error]).to include("outside project root")
      end

      it "rejects path traversal attempts" do
        traversal_path = File.join(temp_dir, "..", "..", "etc", "passwd")
        result = sandbox.validate_path(traversal_path)

        expect(result[:success]).to be false
        expect(result[:error]).to include("outside project root")
      end

      it "rejects paths in .git directory" do
        git_path = File.join(temp_dir, ".git", "config")
        FileUtils.touch(git_path)  # Create the file so it passes project root check
        result = sandbox.validate_path(git_path)

        expect(result[:success]).to be false
        expect(result[:error]).to include("forbidden pattern")
      end

      it "allows all files when no allowed patterns specified (permissive mode)" do
        exe_path = File.join(temp_dir, "test.exe")
        FileUtils.touch(exe_path)  # Create the file so it passes project root check
        result = sandbox.validate_path(exe_path)

        expect(result[:success]).to be true
        expect(result[:path]).to eq(File.realpath(exe_path))
      end
    end
  end

  describe "#safe_path", :security do
    let(:sandbox) { described_class.new(project_root) }

    it "returns normalized path for valid paths" do
      path = File.join(temp_dir, "README.md")
      result = sandbox.safe_path(path)
      expect(result).to eq(File.realpath(path))
    end

    it "raises error for invalid paths" do
      outside_path = File.join(File.dirname(temp_dir), "outside.md")
      expect { sandbox.safe_path(outside_path) }.to raise_error(CodingAgentTools::Error, /outside project root/)
    end
  end

  describe "#within_sandbox?" do
    let(:sandbox) { described_class.new(project_root) }

    it "returns true for valid paths" do
      path = File.join(temp_dir, "README.md")
      expect(sandbox.within_sandbox?(path)).to be true
    end

    it "returns false for invalid paths" do
      outside_path = File.join(File.dirname(temp_dir), "outside.md")
      expect(sandbox.within_sandbox?(outside_path)).to be false
    end
  end

  describe "#relative_to_project" do
    let(:sandbox) { described_class.new(project_root) }

    it "returns relative path from project root" do
      path = File.join(temp_dir, "dev-tools", "lib", "test.rb")
      relative = sandbox.relative_to_project(path)
      expect(relative).to eq("dev-tools/lib/test.rb")
    end

    it "raises error for paths outside sandbox" do
      outside_path = File.join(File.dirname(temp_dir), "outside.md")
      expect { sandbox.relative_to_project(outside_path) }.to raise_error(CodingAgentTools::Error)
    end
  end

  describe "#absolute_path" do
    let(:sandbox) { described_class.new(project_root) }

    it "returns absolute path for relative input" do
      original_dir = Dir.pwd
      begin
        Dir.chdir(temp_dir)
        result = sandbox.absolute_path("README.md")
        # Handle macOS symlink resolution (/var -> /private/var)
        expected_path = File.realpath(File.join(temp_dir, "README.md"))
        expect(result).to eq(expected_path)
      ensure
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      end
    end

    it "validates absolute path input" do
      path = File.join(temp_dir, "README.md")
      result = sandbox.absolute_path(path)
      expect(result).to eq(File.realpath(path))
    end

    it "raises error for invalid relative paths" do
      expect { sandbox.absolute_path("../outside.md") }.to raise_error(CodingAgentTools::Error)
    end
  end

  describe "pattern matching" do
    let(:sandbox) { described_class.new(project_root) }

    context "forbidden patterns" do
      it "blocks .git directory access" do
        git_config = File.join(temp_dir, ".git", "config")
        expect(sandbox.within_sandbox?(git_config)).to be false
      end

      it "blocks node_modules directory" do
        FileUtils.mkdir_p(File.join(temp_dir, "node_modules", "package"))
        npm_path = File.join(temp_dir, "node_modules", "package", "index.js")
        expect(sandbox.within_sandbox?(npm_path)).to be false
      end

      it "blocks coverage directory" do
        FileUtils.mkdir_p(File.join(temp_dir, "coverage"))
        coverage_path = File.join(temp_dir, "coverage", "index.html")
        expect(sandbox.within_sandbox?(coverage_path)).to be false
      end

      it "blocks tmp directory" do
        FileUtils.mkdir_p(File.join(temp_dir, "tmp"))
        tmp_path = File.join(temp_dir, "tmp", "tempfile")
        expect(sandbox.within_sandbox?(tmp_path)).to be false
      end

      it "blocks log files" do
        log_path = File.join(temp_dir, "application.log")
        expect(sandbox.within_sandbox?(log_path)).to be false
      end
    end

    context "allowed patterns" do
      it "allows markdown files" do
        md_path = File.join(temp_dir, "docs", "guide.md")
        FileUtils.mkdir_p(File.dirname(md_path))
        FileUtils.touch(md_path)
        expect(sandbox.within_sandbox?(md_path)).to be true
      end

      it "allows ruby files" do
        rb_path = File.join(temp_dir, "lib", "module.rb")
        FileUtils.mkdir_p(File.dirname(rb_path))
        FileUtils.touch(rb_path)
        expect(sandbox.within_sandbox?(rb_path)).to be true
      end

      it "allows yaml files" do
        yml_path = File.join(temp_dir, "config.yml")
        FileUtils.touch(yml_path)
        expect(sandbox.within_sandbox?(yml_path)).to be true
      end

      it "allows shell scripts" do
        sh_path = File.join(temp_dir, "scripts", "deploy.sh")
        FileUtils.mkdir_p(File.dirname(sh_path))
        FileUtils.touch(sh_path)
        expect(sandbox.within_sandbox?(sh_path)).to be true
      end

      it "allows files in bin directory" do
        bin_path = File.join(temp_dir, "bin", "tool")
        # Create the directory structure to ensure path resolution works
        FileUtils.mkdir_p(File.dirname(bin_path))
        FileUtils.touch(bin_path)
        expect(sandbox.within_sandbox?(bin_path)).to be true
      end

      it "allows dev-tools directory structure" do
        dev_path = File.join(temp_dir, "dev-tools", "spec", "test_spec.rb")
        FileUtils.mkdir_p(File.dirname(dev_path))
        FileUtils.touch(dev_path)
        expect(sandbox.within_sandbox?(dev_path)).to be true
      end
    end
  end

  describe "symlink handling", :security do
    let(:sandbox) { described_class.new(project_root) }

    it "resolves symlinks within project" do
      target = File.join(temp_dir, "target.md")
      link = File.join(temp_dir, "link.md")

      FileUtils.touch(target)
      File.symlink(target, link)

      result = sandbox.validate_path(link)
      expect(result[:success]).to be true
      expect(result[:path]).to eq(File.realpath(target))
    end

    it "rejects symlinks pointing outside project" do
      outside_target = File.join(File.dirname(temp_dir), "outside.md")
      inside_link = File.join(temp_dir, "link.md")

      FileUtils.touch(outside_target)
      File.symlink(outside_target, inside_link)

      result = sandbox.validate_path(inside_link)
      expect(result[:success]).to be false
      expect(result[:error]).to include("outside project root")
    end
  end

  describe "project root detection" do
    it "finds project root with .coding-agent marker" do
      nested_dir = File.join(temp_dir, "nested", "deep")
      FileUtils.mkdir_p(nested_dir)

      original_dir = Dir.pwd
      begin
        Dir.chdir(nested_dir)
        sandbox = described_class.new
        expect(File.realpath(sandbox.project_root)).to eq(File.realpath(temp_dir))
      ensure
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      end
    end

    it "finds project root with .git marker" do
      # .git already created in before block
      nested_dir = File.join(temp_dir, "nested")
      FileUtils.mkdir_p(nested_dir)

      original_dir = Dir.pwd
      begin
        Dir.chdir(nested_dir)
        sandbox = described_class.new
        expect(File.realpath(sandbox.project_root)).to eq(File.realpath(temp_dir))
      ensure
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      end
    end

    it "finds project root with CLAUDE.md marker" do
      claude_file = File.join(temp_dir, "CLAUDE.md")
      nested_dir = File.join(temp_dir, "nested")
      FileUtils.mkdir_p(nested_dir)
      FileUtils.touch(claude_file)

      original_dir = Dir.pwd
      begin
        Dir.chdir(nested_dir)
        sandbox = described_class.new
        expect(File.realpath(sandbox.project_root)).to eq(File.realpath(temp_dir))
      ensure
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      end
    end
  end
end
