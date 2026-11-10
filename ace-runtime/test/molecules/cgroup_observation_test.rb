# frozen_string_literal: true

require_relative "../test_helper"
require "ace/runtime/molecules/cgroup_observation"

class CgroupObservationTest < AceRuntimeTestCase
  Observation = Ace::Runtime::Molecules::CgroupObservation
  Unavailable = Ace::Runtime::RuntimeUnavailableError
  PATH = "/sys/fs/cgroup/ace-slot.slice"

  class Handle
    attr_reader :inode
    def initialize(inode)
      @inode = inode
      @closed = false
    end
    def fileno = 42
    def stat
      value = Struct.new(:dev, :ino).new(27, inode)
      value.define_singleton_method(:directory?) { true }
      value
    end
    def closed? = @closed
    def close = @closed = true
  end

  class Files
    attr_accessor :inode, :mount_id, :events, :membership, :after_read, :filesystem, :mount_root
    attr_reader :handles, :reads
    def initialize
      @inode, @mount_id = 111, 12
      @filesystem, @mount_root = "cgroup2", "/"
      @events, @membership = "populated 1\nfrozen 0\n", "0::/ace-slot.slice/server.service\n"
      @handles, @reads = [], []
    end
    def open_directory(_path)
      handle = Handle.new(inode)
      @handles << handle
      handle
    end
    def mount_identity(_handle)
      {"mount_id" => mount_id, "filesystem_type" => filesystem,
       "root" => mount_root, "mountpoint" => "/sys/fs/cgroup"}
    end
    def read(path, limit:)
      @reads << [path, limit]
      value = path.end_with?("cgroup.events") ? events : membership
      after_read&.call
      value
    end
  end

  def setup
    @files = Files.new
    @observer = Observation.new(files: @files)
  end

  def teardown
    @files.handles.each(&:close)
  end

  def test_population_comes_from_pinned_parent_events_and_does_not_imply_authority_proof
    pinned = @observer.pin(PATH)
    assert_equal({"cgroup_identity" => pinned.fetch(:identity), "populated" => 1}, @observer.observe(pinned))
    @files.events = "populated 0\nfrozen 0\n"
    result = @observer.observe(pinned)
    assert_equal 0, result.fetch("populated")
    refute result.key?("proof_id")
    assert_equal "/proc/self/fd/42/cgroup.events", @files.reads.last.first
    refute pinned.fetch(:handle).closed?
    assert @files.handles.drop(1).all?(&:closed?), "every transient pathname descriptor is closed"
  end

  def test_missing_population_duplicate_and_malformed_values_never_become_empty
    ["", "frozen 0\n", "populated 2\n", "populated 0\npopulated 0\n", "populated -1\n",
     "populated 0 trailing\n", "populated\t0\n", "populated 0\n" + "x" * 4096].each do |bytes|
      assert_raises(Unavailable, bytes.inspect) { @observer.parse_events(bytes) }
    end
    assert_equal 0, @observer.parse_events("populated 0\nfrozen 1\n").fetch("populated")
  end

  def test_path_replacement_before_or_during_read_refuses_even_if_old_object_is_empty
    pinned = @observer.pin(PATH)
    @files.events = "populated 0\n"
    @files.inode = 222
    assert_raises(Unavailable) { @observer.observe(pinned) }
    @files.inode = 111
    @files.after_read = -> { @files.inode = 333 }
    assert_raises(Unavailable) { @observer.observe(pinned) }
  end

  def test_restart_reopens_only_identical_mount_and_object
    first = @observer.pin(PATH)
    expected = first.fetch(:identity)
    first.fetch(:handle).close
    reopened = @observer.pin(PATH, expected: expected)
    assert_equal expected, reopened.fetch(:identity)
    @files.mount_id = 44
    assert_raises(Unavailable) { @observer.pin(PATH, expected: expected) }
    assert @files.handles.last.closed?
  end

  def test_nonunified_and_namespace_relative_mounts_refuse
    @files.filesystem = "cgroup"
    assert_raises(Unavailable) { @observer.pin(PATH) }
    assert @files.handles.last.closed?
    @files.filesystem = "cgroup2"
    @files.mount_root = "/ace-slot.slice"
    assert_raises(Unavailable) { @observer.pin(PATH) }
  end

  def test_paths_cannot_select_root_foreign_mount_or_traversal
    ["/sys/fs/cgroup", "/tmp/cgroup", "/sys/fs/cgroup/../outside", "/sys/fs/cgroup/slot\0",
     nil, "relative"].each do |path|
      assert_raises(Unavailable) { @observer.pin(path) }
    end
    assert_empty @files.handles
  end

  def test_membership_is_exact_subtree_with_birth_rechecked
    pinned = @observer.pin(PATH)
    process = {"pid" => 99, "started_at" => "exact"}
    calls = []
    kernel = Object.new
    kernel.define_singleton_method(:live!) { |identity| calls << identity; true }
    assert @observer.member!(process, pinned: pinned, kernel: kernel)
    assert_equal [process, process], calls
    ["0::/ace-slot.slice-sibling/server.service\n", "0::/other.slice\n", "1:cpu:/ace-slot.slice\n",
     "0::/ace-slot.slice\n0::/ace-slot.slice\n"].each do |membership|
      @files.membership = membership
      assert_raises(Unavailable) { @observer.member!(process, pinned: pinned, kernel: kernel) }
    end
  end

  def test_denied_read_and_closed_descriptor_refuse
    pinned = @observer.pin(PATH)
    @files.define_singleton_method(:read) { |*, **| raise Errno::EACCES }
    assert_raises(Unavailable) { @observer.observe(pinned) }
    pinned.fetch(:handle).close
    assert_raises(Unavailable) { @observer.observe(pinned) }
  end
end
