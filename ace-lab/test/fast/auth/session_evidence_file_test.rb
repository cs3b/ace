# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_evidence_file"

module Ace::Lab::Auth
  class SessionEvidenceFileTest < Minitest::Test
    def setup
      @root = Dir.mktmpdir
      @sessions = File.join(@root, "pi", "sessions")
      FileUtils.mkdir_p(@sessions)
      @path = File.join(@sessions, "session.jsonl")
      File.write(@path, "evidence\n")
      @identity = SessionPeer::Identity.new(runtime_dir: @root, uid: Process.uid, gid: Process.gid)
    end

    def teardown = FileUtils.remove_entry(@root)

    def test_refuses_nonroot_and_paths_outside_private_sessions_before_fork
      assert_raises(Error) { SessionEvidenceFile.new(privileged: -> { false }).open(@path, identity: @identity) }
      reader = SessionEvidenceFile.new(privileged: -> { true })
      ["/etc/passwd", @sessions + "/../auth.jsonl", @sessions + "/not-json.txt", @path + "\n"].each do |path|
        assert_raises(Error) { reader.open(path, identity: @identity) }
      end
    end

    def test_linux_descriptor_transfer_is_read_only_and_owned
      skip "Linux descriptor reader" unless RUBY_PLATFORM.include?("linux")
      file = reader.open(@path, identity: @identity)
      assert_kind_of File, file
      assert_equal "evidence\n", file.read
      assert_equal Process.uid, file.stat.uid
      assert_equal File::RDONLY, file.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE
      assert file.close_on_exec?
    ensure
      file&.close
    end

    def test_linux_reader_rejects_symlink_ancestors_leaf_and_nonregular_files
      skip "Linux descriptor reader" unless RUBY_PLATFORM.include?("linux")
      File.symlink(@sessions, File.join(@sessions, "linked"))
      assert_raises(Error) { reader.open(File.join(@sessions, "linked", "session.jsonl"), identity: @identity) }
      File.symlink(@path, File.join(@sessions, "link.jsonl"))
      assert_raises(Error) { reader.open(File.join(@sessions, "link.jsonl"), identity: @identity) }
      File.mkfifo(File.join(@sessions, "fifo.jsonl"))
      assert_raises(Error) { reader.open(File.join(@sessions, "fifo.jsonl"), identity: @identity) }
    end

    def test_linux_root_reader_drops_to_target_uid_before_open
      skip "root Linux privilege drop" unless RUBY_PLATFORM.include?("linux") && Process.euid.zero?
      uid = 62_123
      FileUtils.chown_R(uid, uid, @root)
      File.chown(0, 0, @root)
      File.chmod(0o711, @root)
      @identity.uid = @identity.gid = uid
      file = SessionEvidenceFile.new.open(@path, identity: @identity)
      assert_equal "evidence\n", file.read
      file.close
      File.chown(0, 0, @path)
      File.chmod(0o600, @path)
      assert_raises(Error) { SessionEvidenceFile.new.open(@path, identity: @identity) }
    ensure
      file&.close unless file&.closed?
    end

    private

    # This seam covers FD transfer/anchoring on nonroot Linux runners. The
    # separate root test exercises real credential and capability changes.
    def reader
      SessionEvidenceFile.new(privileged: -> { true }, drop: ->(*) {}, parent_guard: ->(*) {})
    end
  end
end
