# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "time"
require "coding_agent_tools/organisms/code/session_manager"

RSpec.describe CodingAgentTools::Organisms::Code::SessionManager do
  let(:session_manager) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir("session_manager_test") }
  let(:base_path) { File.join(temp_dir, "sessions") }

  # Mock dependencies
  let(:mock_session_builder) { instance_double(CodingAgentTools::Molecules::Code::SessionDirectoryBuilder) }
  let(:mock_file_handler) { instance_double(CodingAgentTools::Molecules::FileIoHandler) }
  let(:mock_file_reader) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }

  # Sample session data
  let(:sample_session) do
    CodingAgentTools::Models::Code::ReviewSession.new(
      session_id: "review-20240101-120000",
      session_name: "code-HEAD~1..HEAD-20240101-120000",
      timestamp: "2024-01-01T12:00:00Z",
      directory_path: File.join(base_path, "code-HEAD~1..HEAD-20240101-120000"),
      focus: "code",
      target: "HEAD~1..HEAD",
      context_mode: "auto",
      metadata: { created_at: Time.parse("2024-01-01T12:00:00Z") }
    )
  end

  let(:session_params) do
    {
      focus: "code",
      target: "HEAD~1..HEAD",
      context_mode: "auto",
      base_path: base_path
    }
  end

  before do
    # Mock dependency instantiation
    allow(CodingAgentTools::Molecules::Code::SessionDirectoryBuilder).to receive(:new).and_return(mock_session_builder)
    allow(CodingAgentTools::Molecules::FileIoHandler).to receive(:new).and_return(mock_file_handler)
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(mock_file_reader)

    # Create base directory for tests
    FileUtils.mkdir_p(base_path)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "initializes all required dependencies" do
      # Create a new instance to trigger the initialization
      described_class.new
      
      expect(CodingAgentTools::Molecules::Code::SessionDirectoryBuilder).to have_received(:new)
      expect(CodingAgentTools::Molecules::FileIoHandler).to have_received(:new)
      expect(CodingAgentTools::Atoms::Code::FileContentReader).to have_received(:new)
    end
  end

  describe "#create_session" do
    context "when all required parameters are provided" do
      before do
        allow(mock_session_builder).to receive(:build_full_session).and_return(sample_session)
        allow(session_manager).to receive(:create_session_files)
      end

      it "creates a session successfully" do
        result = session_manager.create_session(session_params)

        expect(result).to eq(sample_session)
        expect(mock_session_builder).to have_received(:build_full_session).with(
          "code",
          "HEAD~1..HEAD", 
          "auto",
          base_path
        )
      end

      it "creates additional session files" do
        expect(session_manager).to receive(:create_session_files).with(sample_session)
        
        session_manager.create_session(session_params)
      end
    end

    context "when required parameters are missing" do
      it "raises error when focus is missing" do
        params = session_params.dup
        params.delete(:focus)

        expect { session_manager.create_session(params) }.to raise_error(ArgumentError, "focus is required")
      end

      it "raises error when target is missing" do
        params = session_params.dup
        params.delete(:target)

        expect { session_manager.create_session(params) }.to raise_error(ArgumentError, "target is required")
      end

      it "raises error when focus is nil" do
        params = session_params.merge(focus: nil)

        expect { session_manager.create_session(params) }.to raise_error(ArgumentError, "focus is required")
      end

      it "raises error when target is nil" do
        params = session_params.merge(target: nil)

        expect { session_manager.create_session(params) }.to raise_error(ArgumentError, "target is required")
      end
    end

    context "when optional parameters have defaults" do
      let(:minimal_params) { { focus: "code", target: "HEAD~1..HEAD" } }

      before do
        allow(mock_session_builder).to receive(:build_full_session).and_return(sample_session)
        allow(session_manager).to receive(:create_session_files)
        allow(session_manager).to receive(:default_base_path).and_return("/default/path")
      end

      it "uses default context_mode when not provided" do
        session_manager.create_session(minimal_params)

        expect(mock_session_builder).to have_received(:build_full_session).with(
          "code",
          "HEAD~1..HEAD",
          "auto",
          "/default/path"
        )
      end

      it "uses default base_path when not provided" do
        expect(session_manager).to receive(:default_base_path).and_return("/default/path")
        
        session_manager.create_session(minimal_params)

        expect(mock_session_builder).to have_received(:build_full_session).with(
          "code",
          "HEAD~1..HEAD",
          "auto", 
          "/default/path"
        )
      end
    end

    context "when context_mode is explicitly provided" do
      let(:custom_params) { session_params.merge(context_mode: "none") }

      before do
        allow(mock_session_builder).to receive(:build_full_session).and_return(sample_session)
        allow(session_manager).to receive(:create_session_files)
      end

      it "uses the provided context_mode" do
        session_manager.create_session(custom_params)

        expect(mock_session_builder).to have_received(:build_full_session).with(
          "code",
          "HEAD~1..HEAD",
          "none",
          base_path
        )
      end
    end
  end

  describe "#load_session" do
    let(:session_id) { "review-20240101-120000" }
    let(:session_dir) { File.join(base_path, "code-HEAD~1..HEAD-20240101-120000") }
    let(:metadata_path) { File.join(session_dir, "session.meta") }
    let(:metadata_content) do
      <<~METADATA
        command: @review-code code HEAD~1..HEAD auto
        timestamp: 2024-01-01T12:00:00Z
        target: HEAD~1..HEAD
        focus: code
        context: auto
      METADATA
    end

    context "when session exists and is valid" do
      before do
        FileUtils.mkdir_p(session_dir)
        File.write(metadata_path, metadata_content)
        allow(session_manager).to receive(:find_session_directory).and_return(session_dir)
      end

      it "loads session successfully" do
        result = session_manager.load_session(session_id, base_path)

        expect(result).to be_a(CodingAgentTools::Models::Code::ReviewSession)
        expect(result.session_id).to eq(session_id)
        expect(result.session_name).to eq("code-HEAD~1..HEAD-20240101-120000")
        expect(result.timestamp).to eq("2024-01-01T12:00:00Z")
        expect(result.directory_path).to eq(session_dir)
        expect(result.focus).to eq("code")
        expect(result.target).to eq("HEAD~1..HEAD")
        expect(result.context_mode).to eq("auto")
      end

      it "parses metadata correctly" do
        result = session_manager.load_session(session_id, base_path)

        expect(result.metadata[:timestamp]).to eq("2024-01-01T12:00:00Z")
        expect(result.metadata[:focus]).to eq("code")
        expect(result.metadata[:target]).to eq("HEAD~1..HEAD")
        expect(result.metadata[:context]).to eq("auto")
      end
    end

    context "when session directory does not exist" do
      before do
        allow(session_manager).to receive(:find_session_directory).and_return(nil)
      end

      it "returns nil" do
        result = session_manager.load_session(session_id, base_path)

        expect(result).to be_nil
      end
    end

    context "when metadata file does not exist" do
      before do
        FileUtils.mkdir_p(session_dir)
        allow(session_manager).to receive(:find_session_directory).and_return(session_dir)
      end

      it "returns nil" do
        result = session_manager.load_session(session_id, base_path)

        expect(result).to be_nil
      end
    end

    context "when metadata is invalid" do
      let(:invalid_metadata) { "invalid metadata content" }

      before do
        FileUtils.mkdir_p(session_dir)
        File.write(metadata_path, invalid_metadata)
        allow(session_manager).to receive(:find_session_directory).and_return(session_dir)
      end

      it "returns nil for invalid metadata" do
        result = session_manager.load_session(session_id, base_path)

        expect(result).to be_nil
      end
    end

    context "when base_path is not provided" do
      before do
        allow(session_manager).to receive(:default_base_path).and_return(base_path)
        FileUtils.mkdir_p(session_dir)
        File.write(metadata_path, metadata_content)
        allow(session_manager).to receive(:find_session_directory).and_return(session_dir)
      end

      it "uses default base path" do
        expect(session_manager).to receive(:default_base_path)
        
        session_manager.load_session(session_id)
      end
    end
  end

  describe "#list_sessions" do
    let(:session1_dir) { File.join(base_path, "code-feature-20240101-120000") }
    let(:session2_dir) { File.join(base_path, "tests-bugfix-20240102-140000") }
    let(:session3_dir) { File.join(base_path, "docs-update-20240103-160000") }

    let(:metadata1) do
      <<~METADATA
        timestamp: 2024-01-01T12:00:00Z
        focus: code
        target: feature-branch
      METADATA
    end

    let(:metadata2) do
      <<~METADATA
        timestamp: 2024-01-02T14:00:00Z
        focus: tests
        target: bugfix-branch
      METADATA
    end

    let(:metadata3) do
      <<~METADATA
        timestamp: 2024-01-03T16:00:00Z
        focus: docs
        target: update-branch
      METADATA
    end

    before do
      # Create session directories and metadata
      [session1_dir, session2_dir, session3_dir].each { |dir| FileUtils.mkdir_p(dir) }
      
      File.write(File.join(session1_dir, "session.meta"), metadata1)
      File.write(File.join(session2_dir, "session.meta"), metadata2)
      File.write(File.join(session3_dir, "session.meta"), metadata3)
    end

    context "when sessions exist" do
      it "returns all sessions" do
        sessions = session_manager.list_sessions(base_path)

        expect(sessions.size).to eq(3)
        expect(sessions.map { |s| s[:focus] }).to contain_exactly("code", "tests", "docs")
      end

      it "sorts sessions by timestamp descending" do
        sessions = session_manager.list_sessions(base_path)

        expect(sessions[0][:timestamp]).to eq("2024-01-03T16:00:00Z")
        expect(sessions[1][:timestamp]).to eq("2024-01-02T14:00:00Z")
        expect(sessions[2][:timestamp]).to eq("2024-01-01T12:00:00Z")
      end

      it "includes all required session information" do
        sessions = session_manager.list_sessions(base_path)
        session = sessions.first

        expect(session).to include(:session_name, :timestamp, :focus, :target, :path)
        expect(session[:session_name]).to eq("docs-update-20240103-160000")
        expect(session[:focus]).to eq("docs")
        expect(session[:target]).to eq("update-branch")
        expect(session[:path]).to eq(session3_dir)
      end
    end

    context "when no sessions exist" do
      let(:empty_base_path) { File.join(temp_dir, "empty_sessions") }

      before do
        FileUtils.mkdir_p(empty_base_path)
      end

      it "returns empty array" do
        sessions = session_manager.list_sessions(empty_base_path)

        expect(sessions).to be_empty
      end
    end

    context "when some directories lack metadata" do
      let(:invalid_session_dir) { File.join(base_path, "invalid-session-20240104-180000") }

      before do
        FileUtils.mkdir_p(invalid_session_dir)
        # No metadata file created
      end

      it "skips directories without metadata" do
        sessions = session_manager.list_sessions(base_path)

        expect(sessions.size).to eq(3)
        expect(sessions.map { |s| s[:session_name] }).not_to include("invalid-session-20240104-180000")
      end
    end

    context "when base_path is not provided" do
      before do
        allow(session_manager).to receive(:default_base_path).and_return(base_path)
      end

      it "uses default base path" do
        expect(session_manager).to receive(:default_base_path)
        
        session_manager.list_sessions
      end
    end
  end

  describe "#cleanup_old_sessions" do
    let(:old_session_dir) { File.join(base_path, "old-session-20240101-120000") }
    let(:recent_session_dir) { File.join(base_path, "recent-session-20240114-120000") }

    let(:old_metadata) do
      <<~METADATA
        timestamp: 2024-01-01T12:00:00Z
        focus: code
        target: old-feature
      METADATA
    end

    let(:recent_metadata) do
      <<~METADATA
        timestamp: 2024-01-14T12:00:00Z
        focus: code
        target: recent-feature
      METADATA
    end

    before do
      # Create session directories
      FileUtils.mkdir_p(old_session_dir)
      FileUtils.mkdir_p(recent_session_dir)
      
      # Create metadata files
      File.write(File.join(old_session_dir, "session.meta"), old_metadata)
      File.write(File.join(recent_session_dir, "session.meta"), recent_metadata)

      # Mock current time to be after both sessions
      allow(Time).to receive(:now).and_return(Time.parse("2024-01-15T12:00:00Z"))
    end

    context "when cleaning up sessions older than specified days" do
      it "removes sessions older than cutoff" do
        # Clean sessions older than 7 days (from 2024-01-15, cutoff is 2024-01-08)
        removed = session_manager.cleanup_old_sessions(7, base_path)

        expect(removed).to include(old_session_dir)
        expect(removed).not_to include(recent_session_dir)
        expect(File.exist?(old_session_dir)).to be false
        expect(File.exist?(recent_session_dir)).to be true
      end

      it "does not remove recent sessions" do
        # Clean sessions older than 3 days (from 2024-01-15, cutoff is 2024-01-12)
        # recent_session_dir has timestamp 2024-01-14, so it should NOT be removed
        removed = session_manager.cleanup_old_sessions(3, base_path)

        expect(removed).to include(old_session_dir)
        expect(removed).not_to include(recent_session_dir)
        expect(File.exist?(recent_session_dir)).to be true
      end

      it "returns list of removed session paths" do
        removed = session_manager.cleanup_old_sessions(7, base_path)

        expect(removed).to be_an(Array)
        expect(removed).to include(old_session_dir)
      end
    end

    context "when no sessions are old enough" do
      it "returns empty array" do
        # Clean sessions older than 20 days (both sessions are recent)
        removed = session_manager.cleanup_old_sessions(20, base_path)

        expect(removed).to be_empty
        expect(File.exist?(old_session_dir)).to be true
        expect(File.exist?(recent_session_dir)).to be true
      end
    end

    context "when base_path is not provided" do
      before do
        allow(session_manager).to receive(:default_base_path).and_return(base_path)
      end

      it "uses default base path" do
        expect(session_manager).to receive(:default_base_path)
        
        session_manager.cleanup_old_sessions(7)
      end
    end
  end

  describe "private methods" do
    describe "#default_base_path" do
      context "when current release directory exists" do
        let(:release_dir) { File.join(temp_dir, "dev-taskflow", "current", "v.0.3.0-workflows") }

        before do
          FileUtils.mkdir_p(release_dir)
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with("dev-taskflow/current").and_return(true)
          allow(File).to receive(:directory?).and_call_original
          allow(File).to receive(:directory?).with("dev-taskflow/current").and_return(true)
          allow(Dir).to receive(:glob).with(File.join("dev-taskflow/current", "v.*")).and_return([release_dir])
        end

        it "returns code_review path within current release" do
          result = session_manager.send(:default_base_path)

          expect(result).to eq(File.join(release_dir, "code_review"))
        end
      end

      context "when current release directory does not exist" do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with("dev-taskflow/current").and_return(false)
        end

        it "returns system temp directory with code_review suffix" do
          result = session_manager.send(:default_base_path)

          expect(result).to eq(File.join(Dir.tmpdir, "code_review"))
        end
      end
    end

    describe "#find_session_directory" do
      let(:session_id) { "review-20240101-120000" }
      let(:matching_dir) { File.join(base_path, "code-HEAD-#{session_id}") }

      before do
        FileUtils.mkdir_p(matching_dir)
      end

      it "finds directory containing session ID" do
        result = session_manager.send(:find_session_directory, session_id, base_path)

        expect(result).to eq(matching_dir)
      end

      it "returns nil when no matching directory exists" do
        result = session_manager.send(:find_session_directory, "nonexistent", base_path)

        expect(result).to be_nil
      end
    end

    describe "#parse_session_metadata" do
      let(:metadata_file) { File.join(temp_dir, "test.meta") }

      context "when metadata is valid" do
        let(:valid_content) do
          <<~METADATA
            timestamp: 2024-01-01T12:00:00Z
            focus: code
            target: HEAD~1..HEAD
            context: auto
          METADATA
        end

        before do
          File.write(metadata_file, valid_content)
        end

        it "parses metadata correctly" do
          result = session_manager.send(:parse_session_metadata, metadata_file)

          expect(result).to eq({
            timestamp: "2024-01-01T12:00:00Z",
            focus: "code",
            target: "HEAD~1..HEAD",
            context: "auto"
          })
        end
      end

      context "when metadata is malformed" do
        let(:invalid_content) { "invalid content without proper format" }

        before do
          File.write(metadata_file, invalid_content)
        end

        it "returns nil for malformed metadata" do
          result = session_manager.send(:parse_session_metadata, metadata_file)

          expect(result).to be_nil
        end
      end

      context "when file does not exist" do
        it "returns nil for missing file" do
          result = session_manager.send(:parse_session_metadata, "/nonexistent/file")

          expect(result).to be_nil
        end
      end

      context "when file cannot be read" do
        before do
          File.write(metadata_file, "content")
          allow(File).to receive(:read).with(metadata_file).and_raise(StandardError, "Read error")
        end

        it "returns nil on read error" do
          result = session_manager.send(:parse_session_metadata, metadata_file)

          expect(result).to be_nil
        end
      end
    end

    describe "#create_session_files" do
      let(:session_dir) { File.join(temp_dir, "test_session") }
      let(:test_session) do
        CodingAgentTools::Models::Code::ReviewSession.new(
          session_id: "review-20240101-120000",
          session_name: "code-HEAD~1..HEAD-20240101-120000",
          timestamp: "2024-01-01T12:00:00Z",
          directory_path: session_dir,
          focus: "code",
          target: "HEAD~1..HEAD",
          context_mode: "auto"
        )
      end

      before do
        FileUtils.mkdir_p(session_dir)
      end

      it "creates README file with session information" do
        session_manager.send(:create_session_files, test_session)

        readme_path = File.join(session_dir, "README.md")
        expect(File.exist?(readme_path)).to be true

        content = File.read(readme_path)
        expect(content).to include("# Code Review Session: code-HEAD~1..HEAD-20240101-120000")
        expect(content).to include("**Generated**: 2024-01-01T12:00:00Z")
        expect(content).to include("**Target**: HEAD~1..HEAD")
        expect(content).to include("**Focus**: code")
        expect(content).to include("**Context**: auto")
      end

      it "includes session files documentation" do
        session_manager.send(:create_session_files, test_session)

        readme_path = File.join(session_dir, "README.md")
        content = File.read(readme_path)

        expect(content).to include("## Session Files")
        expect(content).to include("session.meta")
        expect(content).to include("input.diff")
        expect(content).to include("prompt.md")
        expect(content).to include("cr-report-*.md")
      end

      it "includes next steps information" do
        session_manager.send(:create_session_files, test_session)

        readme_path = File.join(session_dir, "README.md")
        content = File.read(readme_path)

        expect(content).to include("## Next Steps")
        expect(content).to include("code-review command")
      end
    end
  end

  describe "integration scenarios" do
    context "complete session lifecycle" do
      let(:focus) { "code tests" }
      let(:target) { "HEAD~2..HEAD" }
      let(:context_mode) { "auto" }

      before do
        # Mock session builder to return a realistic session
        allow(mock_session_builder).to receive(:build_full_session) do |f, t, c, bp|
          session_dir = File.join(bp, "#{f.gsub(' ', '-')}-#{t.gsub('~', 'tilde').gsub('..', '-to-')}-20240101-120000")
          # Create the directory since create_session_files expects it to exist
          FileUtils.mkdir_p(session_dir)
          
          CodingAgentTools::Models::Code::ReviewSession.new(
            session_id: "review-20240101-120000",
            session_name: "#{f.gsub(' ', '-')}-#{t.gsub('~', 'tilde').gsub('..', '-to-')}-20240101-120000",
            timestamp: "2024-01-01T12:00:00Z",
            directory_path: session_dir,
            focus: f,
            target: t,
            context_mode: c,
            metadata: { created_at: Time.now }
          )
        end
      end

      it "can create, list, and load sessions" do
        # Create session
        session = session_manager.create_session({
          focus: focus,
          target: target,
          context_mode: context_mode,
          base_path: base_path
        })

        expect(session.focus).to eq(focus)
        expect(session.target).to eq(target)

        # Create the actual directory and metadata for listing test
        FileUtils.mkdir_p(session.directory_path)
        metadata_content = <<~METADATA
          timestamp: #{session.timestamp}
          focus: #{session.focus}
          target: #{session.target}
          context: #{session.context_mode}
        METADATA
        File.write(File.join(session.directory_path, "session.meta"), metadata_content)

        # List sessions should include our created session
        sessions = session_manager.list_sessions(base_path)
        expect(sessions.size).to eq(1)
        expect(sessions.first[:focus]).to eq(focus)

        # Load session should work
        # Need to mock the find_session_directory method to return the correct path
        allow(session_manager).to receive(:find_session_directory).with(session.session_id, base_path).and_return(session.directory_path)
        
        loaded_session = session_manager.load_session(session.session_id, base_path)
        expect(loaded_session).not_to be_nil
        expect(loaded_session.focus).to eq(focus)
        expect(loaded_session.target).to eq(target)
      end
    end

    context "error handling throughout lifecycle" do
      it "handles session builder errors gracefully" do
        allow(mock_session_builder).to receive(:build_full_session).and_raise(StandardError, "Builder failed")

        expect {
          session_manager.create_session(session_params)
        }.to raise_error(StandardError, "Builder failed")
      end

      it "handles file system errors in listing" do
        # Create a session directory but make it unreadable
        session_dir = File.join(base_path, "unreadable-session-20240101-120000")
        FileUtils.mkdir_p(session_dir)
        
        # Create metadata file
        metadata_path = File.join(session_dir, "session.meta")
        File.write(metadata_path, "timestamp: 2024-01-01T12:00:00Z\nfocus: code\ntarget: HEAD")

        # Mock File.read to raise an error
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(metadata_path).and_raise(StandardError, "Permission denied")

        # Should handle the error gracefully and skip the problematic session
        sessions = session_manager.list_sessions(base_path)
        expect(sessions).to be_empty
      end
    end
  end
end