# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::Git::PathDispatcher do
  let(:temp_dir) { Dir.mktmpdir }
  let(:main_repo_path) { temp_dir }
  let(:submodule_path) { File.join(temp_dir, "submodule") }

  let(:mock_repositories) do
    [
      {
        name: "main",
        path: temp_dir,
        full_path: temp_dir,
        exists: true,
        is_git_repo: true
      },
      {
        name: "submodule",
        path: submodule_path,
        full_path: submodule_path,
        exists: true,
        is_git_repo: true
      }
    ]
  end

  before do
    # Stub the dependencies
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(main_repo_path)
    allow(CodingAgentTools::Atoms::Git::RepositoryScanner).to receive(:discover_repositories).and_return(mock_repositories)
    
    # Create test directories
    FileUtils.mkdir_p(submodule_path)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#dispatch_paths" do
    let(:dispatcher) { described_class.new(main_repo_path) }

    context "with main repository files" do
      let(:main_file) { File.join(main_repo_path, "main_file.rb") }
      let(:mock_path_resolver) { instance_double(CodingAgentTools::Atoms::Git::PathResolver) }

      before do
        FileUtils.touch(main_file)
        allow(CodingAgentTools::Atoms::Git::PathResolver).to receive(:new).and_return(mock_path_resolver)
        allow(mock_path_resolver).to receive(:group_paths_by_repository).and_return(
          "main" => [main_file]
        )
      end

      it "uses git -C with full path for main repository" do
        result = dispatcher.dispatch_paths([main_file])

        expect(result).to have_key("main")
        
        main_dispatch = result["main"]
        expect(main_dispatch[:command_context][:git_command_prefix]).to eq("git -C #{main_repo_path.shellescape}")
        expect(main_dispatch[:command_context][:prefix]).to eq("-C #{main_repo_path.shellescape}")
        expect(main_dispatch[:command_context][:description]).to eq("main repository")
      end
    end

    context "with submodule files" do
      let(:submodule_file) { File.join(submodule_path, "sub_file.rb") }
      let(:mock_path_resolver) { instance_double(CodingAgentTools::Atoms::Git::PathResolver) }

      before do
        FileUtils.touch(submodule_file)
        allow(CodingAgentTools::Atoms::Git::PathResolver).to receive(:new).and_return(mock_path_resolver)
        allow(mock_path_resolver).to receive(:group_paths_by_repository).and_return(
          "submodule" => [submodule_file]
        )
      end

      it "uses git -C with full path for submodule" do
        result = dispatcher.dispatch_paths([submodule_file])

        expect(result).to have_key("submodule")
        
        submodule_dispatch = result["submodule"]
        expect(submodule_dispatch[:command_context][:git_command_prefix]).to eq("git -C #{submodule_path.shellescape}")
        expect(submodule_dispatch[:command_context][:prefix]).to eq("-C #{submodule_path.shellescape}")
        expect(submodule_dispatch[:command_context][:description]).to eq("submodule repository")
      end
    end

    context "with mixed repository files" do
      let(:main_file) { File.join(main_repo_path, "main_file.rb") }
      let(:submodule_file) { File.join(submodule_path, "sub_file.rb") }
      let(:mock_path_resolver) { instance_double(CodingAgentTools::Atoms::Git::PathResolver) }

      before do
        FileUtils.touch(main_file)
        FileUtils.touch(submodule_file)
        allow(CodingAgentTools::Atoms::Git::PathResolver).to receive(:new).and_return(mock_path_resolver)
        allow(mock_path_resolver).to receive(:group_paths_by_repository).and_return(
          "main" => [main_file],
          "submodule" => [submodule_file]
        )
      end

      it "provides consistent command context for all repositories" do
        result = dispatcher.dispatch_paths([main_file, submodule_file])

        expect(result).to have_key("main")
        expect(result).to have_key("submodule")

        # Both should use git -C format
        main_dispatch = result["main"]
        submodule_dispatch = result["submodule"]

        expect(main_dispatch[:command_context][:git_command_prefix]).to start_with("git -C")
        expect(submodule_dispatch[:command_context][:git_command_prefix]).to start_with("git -C")

        expect(main_dispatch[:command_context][:prefix]).to start_with("-C")
        expect(submodule_dispatch[:command_context][:prefix]).to start_with("-C")
      end
    end

    context "with paths containing spaces or special characters" do
      let(:spaced_dir) { File.join(main_repo_path, "dir with spaces") }
      let(:spaced_file) { File.join(spaced_dir, "file with spaces.rb") }
      let(:mock_path_resolver) { instance_double(CodingAgentTools::Atoms::Git::PathResolver) }

      before do
        FileUtils.mkdir_p(spaced_dir)
        FileUtils.touch(spaced_file)
        allow(CodingAgentTools::Atoms::Git::PathResolver).to receive(:new).and_return(mock_path_resolver)
        allow(mock_path_resolver).to receive(:group_paths_by_repository).and_return(
          "main" => [spaced_file]
        )
      end

      it "properly escapes paths in command context" do
        result = dispatcher.dispatch_paths([spaced_file])

        main_dispatch = result["main"]
        
        # Path should be properly escaped
        expect(main_dispatch[:command_context][:git_command_prefix]).to include(main_repo_path.shellescape)
        expect(main_dispatch[:command_context][:prefix]).to include(main_repo_path.shellescape)
        
        # Should not contain unescaped spaces
        expect(main_dispatch[:command_context][:git_command_prefix]).not_to match(/git -C [^'"].*\s.*[^'"]/)
      end
    end
  end

  describe "#build_command_context" do
    let(:dispatcher) { described_class.new(main_repo_path) }

    context "for main repository" do
      let(:main_repository) do
        {
          name: "main",
          path: main_repo_path,
          full_path: main_repo_path
        }
      end

      it "returns unified command context with -C flag" do
        result = dispatcher.send(:build_command_context, main_repository)

        expect(result[:git_command_prefix]).to eq("git -C #{main_repo_path.shellescape}")
        expect(result[:prefix]).to eq("-C #{main_repo_path.shellescape}")
        expect(result[:description]).to eq("main repository")
      end
    end

    context "for submodule repository" do
      let(:submodule_repository) do
        {
          name: "submodule", 
          path: submodule_path,
          full_path: submodule_path
        }
      end

      it "returns unified command context with -C flag" do
        result = dispatcher.send(:build_command_context, submodule_repository)

        expect(result[:git_command_prefix]).to eq("git -C #{submodule_path.shellescape}")
        expect(result[:prefix]).to eq("-C #{submodule_path.shellescape}")
        expect(result[:description]).to eq("submodule repository")
      end
    end

    context "consistency across repository types" do
      let(:main_repository) do
        {
          name: "main",
          path: main_repo_path,
          full_path: main_repo_path
        }
      end

      let(:submodule_repository) do
        {
          name: "test-submodule",
          path: submodule_path,
          full_path: submodule_path
        }
      end

      it "provides consistent command format for all repository types" do
        main_context = dispatcher.send(:build_command_context, main_repository)
        submodule_context = dispatcher.send(:build_command_context, submodule_repository)

        # Both should follow the same pattern
        expect(main_context[:git_command_prefix]).to match(/^git -C .+/)
        expect(submodule_context[:git_command_prefix]).to match(/^git -C .+/)

        expect(main_context[:prefix]).to match(/^-C .+/)
        expect(submodule_context[:prefix]).to match(/^-C .+/)

        # Both should have description
        expect(main_context[:description]).to include("repository")
        expect(submodule_context[:description]).to include("repository")
      end
    end
  end

  describe "working directory independence" do
    let(:dispatcher) { described_class.new(main_repo_path) }
    let(:main_file) { File.join(main_repo_path, "test_file.rb") }
    let(:mock_path_resolver) { instance_double(CodingAgentTools::Atoms::Git::PathResolver) }

    before do
      FileUtils.touch(main_file)
      allow(CodingAgentTools::Atoms::Git::PathResolver).to receive(:new).and_return(mock_path_resolver)
      allow(mock_path_resolver).to receive(:group_paths_by_repository).and_return(
        "main" => [main_file]
      )
    end

    it "produces consistent command context regardless of current working directory" do
      original_dir = Dir.pwd

      begin
        # Test from project root
        Dir.chdir(main_repo_path)
        result_from_root = dispatcher.dispatch_paths([main_file])

        # Test from submodule directory  
        Dir.chdir(submodule_path)
        result_from_submodule = dispatcher.dispatch_paths([main_file])

        # Test from completely different directory
        Dir.chdir("/tmp")
        result_from_tmp = dispatcher.dispatch_paths([main_file])

        # All results should be identical
        expect(result_from_root["main"][:command_context]).to eq(result_from_submodule["main"][:command_context])
        expect(result_from_root["main"][:command_context]).to eq(result_from_tmp["main"][:command_context])
        
        # All should use absolute paths with -C
        result_from_root["main"][:command_context][:git_command_prefix].tap do |prefix|
          expect(prefix).to start_with("git -C")
          expect(prefix).to include(main_repo_path)
        end
      ensure
        Dir.chdir(original_dir)
      end
    end
  end
end