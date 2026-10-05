# frozen_string_literal: true
require "test_helper"
require "support/lifecycle_fixtures"
require "timeout"
require "etc"

class PendingPaginationTest < AceHitlTestCase
  include LifecycleFixtures

  def test_pending_retained_native_claims_fit_boundary_frame
    with_lifecycle_root do |root|
      reverse = {"schema" => "ace.hitl.ref/v1", "session" => "workspace1", "pane" => "pane1"}
      store = make_store(root: root, binding: TestBinding.new(reverse: reverse))
      120.times do |i|
        id = "native#{i.to_s.rjust(3, '0')}"
        store.create(**request_args(id: id))
        store.deliver(id, stdin_reader("approved"))
        store.consume(id, native_delivery: true)
      end
      store.create(**request_args(id: "newask1"))
      facts = store.pending(project: "ace")
      assert_equal "created", facts.find { |v| v["id"] == "newask1" }["state"]
      bytes = JSON.generate({"ok" => true, "result" => facts}).bytesize
      socket = File.join(root, "hitl.sock")
      service = Ace::Hitl::Lifecycle::Service.new(root: root, binding: TestBinding.new(reverse: reverse),
        policy: AllowTransportPolicy.new, socket_path: socket, group: Etc.getgrgid(Process.gid).name)
      thread = Thread.new { service.run }
      begin
        Timeout.timeout(5) { sleep 0.01 until File.socket?(socket) || !thread.alive? }
        thread.value unless thread.alive?
        boundary = Ace::Hitl::Lifecycle::Client.new(socket_path: socket, service_uid: Process.uid)
        begin
          all = boundary.pending(project: "ace")
          assert_equal facts.map { |v| v["id"] }.sort, all.map { |v| v["id"] }.sort
          assert_equal 120, all.count { |v| v["native_delivery"] == true }
          page = boundary.pending_page(project: "ace")
          refute_nil page["next"]
          assert_operator Ace::Hitl::Lifecycle::Protocol.encode_result(page).bytesize, :<=, Ace::Hitl::Lifecycle::Protocol::MAX_FRAME_BYTES
          next_page = boundary.pending_page(project: "ace", after: page["next"])
          assert_empty page["items"].map { |v| v["id"] } & next_page["items"].map { |v| v["id"] }
          assert_equal [], boundary.pending(project: "other")
          assert_raises(Ace::Hitl::Lifecycle::StateError) { boundary.pending_page(after: "../bad") }
          assert_equal "consumed", boundary.read("native000")["state"]
        rescue Ace::Hitl::Lifecycle::TransportError => e
          flunk "#{facts.size} retained requests make the pending IPC response #{bytes} bytes: #{e.class}: #{e.message}"
        end
      ensure
        service.stop
        thread.join(5)
        thread.kill if thread.alive?
      end
    end
  end
end
