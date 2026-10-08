# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/server_resource_observation"
require "socket"

class ServerResourceObservationTest < AceRuntimeTestCase
  Observation = Ace::Runtime::Molecules::ServerResourceObservation
  Kernel = Struct.new(:identity, :changed, :calls) do
    def live!(expected)
      raise Ace::Runtime::RuntimeUnavailableError, "incarnation changed" unless identity == expected
      true
    end
    def capture(_pid)
      self.calls += 1
      calls > 1 && changed ? changed : identity.dup
    end
    def same?(left, right) = left == right
  end
  Files = Struct.new(:result, :seen) do
    def observe(pid, entries, authority_socket:)
      self.seen = [pid, entries, authority_socket]
      result
    end
  end

  def test_same_server_incarnation_bounds_real_source_observation_owner
    server = {"pid" => 81, "uid" => 13001, "started_at" => "birth"}
    expected = {"mount_namespace_identity" => {"device" => 2, "inode" => 9}, "resource_identities" => [], "resource_topology" => []}
    files = Files.new(expected)
    kernel = Kernel.new(server, nil, 0)
    entries = [{"host_path" => "/private", "view_path" => "/scratch"}]
    assert_equal expected, Observation.new(kernel: kernel, files: files).observe!(server: server, entries: entries, authority_socket: "/authority/socket")
    assert_equal [81, entries, "/authority/socket"], files.seen
    assert_equal 2, kernel.calls
  end

  def test_credential_or_birth_change_after_collection_refuses
    server = {"pid" => 81, "uid" => 13001, "started_at" => "birth"}
    kernel = Kernel.new(server, server.merge("started_at" => "replacement"), 0)
    files = Files.new({"resource_identities" => []})
    assert_raises(Ace::Runtime::RuntimeUnavailableError) do
      Observation.new(kernel: kernel, files: files).observe!(server: server, entries: [], authority_socket: "/authority/socket")
    end
  end

  def with_contained_fixture(changed_table: false, changed_ipc: false, changed_ptmx_link: false, changed_ptmx_node: false, changed_network: false, wrong_network_type: false)
    Dir.mktmpdir("ace-server-view-") do |root|
      views = Observation::VIEW_PATHS
      (views + ["/scratch", "/authority"]).each { |path| FileUtils.mkdir_p(root + path) }
      %w[mnt ipc net replacement].each { |name| File.write(root + "/#{name}.identity", name) }
      endpoint = UNIXServer.new(root + "/authority/socket")
      File.write(root + "/dev/pts/ptmx", "controlled node")
      File.symlink(changed_ptmx_link ? "foreign" : "pts/ptmx", root + "/dev/ptmx")
      paths = ["/"] + views + ["/scratch", "/dev/pts/ptmx"]
      mount_text = paths.each_with_index.map do |path, index|
        "#{index + 1} 0 8:1 / #{path} ro - ext4 fixture ro\n"
      end.join
      real_open, real_read, real_stat = File.method(:open), File.method(:read), File.method(:stat)
      handles = {}
      native = Class.new(Observation::Files) do
        attr_accessor :inside
        def supported!; true; end
        def open_inside(root, path, flags: File::RDONLY | File::NONBLOCK | File::NOFOLLOW)
          inside.call(root, path, flags)
        end
      end.new
      seen_flags = []
      native.inside = lambda do |held_root, path, flags|
        raise "wrong pinned root" unless held_root.stat.ino == real_stat.call(root).ino
        seen_flags << [path, flags]
        if path == "/authority/socket"
          Struct.new(:stat) { def close; end }.new(real_stat.call(root + path))
        else
          handle = real_open.call(root + path, File::RDONLY)
          handles[handle.fileno] = paths.index(path) + 1
          if path == "/dev/pts/ptmx"
            original_stat = handle.stat
            typed_node = Struct.new(:dev, :ino, :rdev_major, :rdev_minor) { def chardev?; true; end }.new(original_stat.dev, original_stat.ino, 5, changed_ptmx_node ? 3 : 2)
            handle.define_singleton_method(:stat) { typed_node }
          end
          handle
        end
      end
      opens = Hash.new(0)
      opener = lambda do |path, *args, &block|
        opens[path] += 1
        mapped = case path
        when "/proc/81/root" then root
        when "/proc/81/ns/mnt" then root + "/mnt.identity"
        when "/proc/81/ns/ipc"
          root + (changed_ipc && opens[path] > 1 ? "/replacement.identity" : "/ipc.identity")
        when "/proc/81/ns/net"
          root + (changed_network && opens[path] > 1 ? "/replacement.identity" : "/net.identity")
        when "/proc/self/ns/ipc" then root + "/ipc.identity"
        else raise "undeclared observation #{path}"
        end
        handle = real_open.call(mapped, *args)
        if path == "/proc/81/ns/net"
          handle.define_singleton_method(:ioctl) do |operation|
            raise "wrong namespace ioctl" unless operation == 0xb703
            wrong_network_type ? 0x20000 : 0x40000000
          end
        end
        if block
          begin; block.call(handle); ensure; handle.close; end
        else
          handle
        end
      end
      table_reads = 0
      reader = lambda do |path, *_args|
        if path == "/proc/81/mountinfo"
          table_reads += 1
          changed_table && table_reads > 1 ? mount_text + "99 0 8:1 / /foreign rw - ext4 fixture rw\n" : mount_text
        elsif (match = /\A\/proc\/self\/fdinfo\/([0-9]+)\z/.match(path))
          "mnt_id:\t#{handles.fetch(Integer(match[1], 10))}\n"
        else
          raise "undeclared observation #{path}"
        end
      end
      File.stub(:open, opener) do
        File.stub(:read, reader) do
          File.stub(:stat, ->(path) { raise "wrong root stat" unless path == "/proc/81/root"; real_stat.call(root) }) do
            yield native, seen_flags
          end
        end
      end
    ensure
      endpoint&.close
    end
  end

  def test_complete_source_collector_pins_fixed_views_and_socket_and_repeats_table_ipc
    with_contained_fixture do |files, flags|
      result = files.observe(81, [{"host_path" => "/host/scratch", "view_path" => "/scratch"}], authority_socket: "/authority/socket")
      topology = result.fetch("kernel_view_topology")
      assert_equal %w[device inode], result.fetch("network_namespace_identity").keys.sort
      assert result.fetch("network_namespace_identity").values.all? { |value| value.is_a?(Integer) && value.positive? }
      assert_equal Observation::VIEW_PATHS.sort, topology.fetch("views").map { |view| view.fetch("path") }.sort
      assert_equal 13, topology.fetch("mounts").size
      assert_equal "pts/ptmx", topology.fetch("ptmx_link")
      assert_equal [5, 2], topology.fetch("ptmx_identity").values_at("rdev_major", "rdev_minor")
      assert_equal topology.fetch("ipc_namespace_identity"), topology.fetch("hook_ipc_namespace_identity")
      assert_equal Process.uid, topology.fetch("authority_socket_identity").last
      assert_equal 26, flags.count { |path, bits| path != "/scratch" && bits == 0x200000 | File::NOFOLLOW }
    end
    [{changed_table: true}, {changed_ipc: true}, {changed_ptmx_link: true}, {changed_ptmx_node: true}, {changed_network: true}, {wrong_network_type: true}].each do |options|
      with_contained_fixture(**options) do |files, _flags|
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { files.observe(81, [], authority_socket: "/authority/socket") }
      end
    end
  end
end
