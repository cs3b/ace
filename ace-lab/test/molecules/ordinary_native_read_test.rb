# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/ordinary_owner_fixture"
require "ace/lab/molecules/ordinary_native_read"

module Ace
  module Lab
    module Molecules
      class OrdinaryNativeReadTest < Minitest::Test
        include OrdinaryOwnerFixture
        WIRE = Ace::Runtime::Molecules::ProtectedSocket

        def test_existing_native_protocol_uses_exact_kernel_peer_and_matching_pid_cwd
          with_native do |reader, config|
            assert reader.preflight!
            assert_equal "/misleading-pane-cwd", reader.pane_get("w1:p1").parsed_json.dig("result", "pane", "cwd")
            reader.pane_process_info("w1:p1")
            assert_equal "/actual-worker", reader.process_cwd(123)
            assert_equal "/foreign-worker", reader.process_cwd(456)
            assert_equal %w[ping pane.get pane.process_info], @requests.map { |request| request.fetch("method") }
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.process_cwd(789) }
            @processes << @processes.first.dup
            reader.pane_process_info("w1:p1")
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.process_cwd(123) }
          end
        end

        def test_changed_endpoint_peer_policy_or_response_never_supplies_native_evidence
          with_native do |reader, config|
            @wrong_id = true
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.preflight! }
            @wrong_id = false
            before = @requests.size
            changed = ordinary_owner_document(peer: config.native.fetch("server_identity").merge("started_at" => "foreign"),
              socket_path: config.native.fetch("socket_path"), socket_identity: config.native.fetch("socket_identity"))
            selected = OrdinaryOwnerConfig.new(changed, project: "atlas", source: OrdinaryOwnerConfig::PATH)
            @selected_config = selected
            begin
              assert_raises(InvalidConfigurationError) { reader.preflight! }
              foreign = OrdinaryNativeRead.new(config: selected, deadline: WIRE.deadline(2))
              assert_raises(Ace::Runtime::RuntimeUnavailableError) { foreign.preflight! }
            ensure
              @selected_config = config
            end
            assert_equal before, @requests.size
            File.unlink(config.native.fetch("socket_path"))
            replacement = UNIXServer.new(config.native.fetch("socket_path"))
            File.chmod(0600, config.native.fetch("socket_path"))
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.preflight! }
            assert_equal before, @requests.size
          ensure
            replacement&.close
          end
        end

        def test_requester_owned_ancestor_is_refused_before_connecting
          with_native(trusted_parent_fixture: false) do |reader, _|
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.preflight! }
            assert_empty @requests
          end
        end

        def test_native_result_tags_and_process_inventory_cannot_cross_panes_or_reuse_stale_cwd
          with_native do |reader, _|
            reader.pane_process_info("w1:p1")
            assert_equal "/actual-worker", reader.process_cwd(123)
            @inventory_pane = "w2:p1"
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.pane_process_info("w1:p1") }
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.process_cwd(123) }
            @inventory_pane = "w1:p1"
            @wrong_type = true
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.preflight! }
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.pane_get("w1:p1") }
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.pane_process_info("w1:p1") }
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.process_cwd(123) }
          end
        end

        def test_silent_native_peer_hits_original_deadline
          with_native(timeout: 0.15) do |reader, _|
            @silent = true
            before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.preflight! }
            assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - before, :<, 1
          end
        end

        private

        def with_native(trusted_parent_fixture: true, timeout: 3)
          Dir.mktmpdir("ordinary-native-", Etc.getpwuid(Process.uid).dir) do |root|
            File.chmod(0700, root)
            path = File.join(root, "native.sock")
            server = UNIXServer.new(path); File.chmod(0600, path)
            identity = Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid).merge("gid" => Process.gid)
            config = OrdinaryOwnerConfig.new(ordinary_owner_document(peer: identity,
              socket_path: path, socket_identity: WIRE.socket_identity(path)), project: "atlas", source: OrdinaryOwnerConfig::PATH)
            @requests, @wrong_id, @silent = [], false, false
            @inventory_pane, @wrong_type = "w1:p1", false
            @processes = [{"pid" => 123, "cwd" => "/actual-worker"}, {"pid" => 456, "cwd" => "/foreign-worker"}]
            stopped = false
            thread = Thread.new do
              until stopped
                ready = IO.select([server], nil, nil, 0.05)
                next unless ready
                socket = server.accept
                begin
                  request = WIRE.read(socket, deadline: WIRE.deadline(1))
                  @requests << request
                  if @silent
                    sleep 0.2
                    next
                  end
                  data = case request.fetch("method")
                  when "ping" then {"type" => "pong", "version" => "0.9.1", "protocol" => 22}
                  when "pane.get" then {"type" => "pane_info", "pane" => {"pane_id" => "w1:p1", "cwd" => "/misleading-pane-cwd"}}
                  when "pane.process_info" then {"type" => "pane_process_info", "process_info" => {"pane_id" => @inventory_pane, "foreground_processes" => @processes}}
                  else raise "unexpected native mutation"
                  end
                  data["type"] = "foreign" if @wrong_type
                  WIRE.write(socket, {"id" => @wrong_id ? "foreign" : request.fetch("id"), "result" => data}, deadline: WIRE.deadline(1))
                rescue Ace::Runtime::RuntimeUnavailableError
                  # A refused kernel peer closes before sending a native request.
                ensure
                  socket.close
                end
              end
            end
            reader = OrdinaryNativeRead.new(config: config, deadline: WIRE.deadline(timeout))
            @selected_config = config
            OrdinaryOwnerConfig.stub(:load, ->(**_) { @selected_config }) do
              if trusted_parent_fixture
                # Only the filesystem installation boundary is controlled;
                # UNIX credentials, live birth, inode and protocol are real.
                WIRE.stub(:root_path!, ->(selected, directory:) { raise "wrong endpoint parent" unless selected == root && directory }) do
                  yield reader, config
                end
              else
                yield reader, config
              end
            end
          ensure
            stopped = true
            assert thread.join(2), "native reader test must drain"
            server&.close
          end
        end
      end
    end
  end
end
