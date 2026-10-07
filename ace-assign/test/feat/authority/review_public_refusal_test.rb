# frozen_string_literal: true
require_relative "review_request_test"

module Ace
  module Assign
    class ReviewPublicRefusalTest < ReviewRequestTest
      ReviewRequestTest.instance_methods.grep(/^test_/).each { |name| undef_method name }

      def endpoint
        @launch.instance_variable_get(:@control_channels).each_value { |channel| channel.define_singleton_method(:close) { true } unless channel.respond_to?(:close) }
        @kernel.peer_identity = @reviewer
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        kernel = Kernel.new
        kernel.peer_identity = @service.slice("uid", "gid", "groups")
        yield Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
      end

      def public_params
        request_params.merge("assignment_id" => "assignment", "attempt_id" => @attempt)
      end

      def test_public_preflight_refusals_leave_no_request_or_delegation
        %i[missing busy stale dead_original foreign_reviewer author_reviewer sealed].each do |stage|
          fixture do
            issued_with_channel
            left, right = UNIXSocket.pair
            channel = Authority::LaunchControlChannel.new(socket: left, codec: Object.new,
              outcome: ->(*) { flunk "preflight cannot invoke native outcome" })
            original_dispatch = channel.method(:dispatch_review)
            test = self
            channel.define_singleton_method(:dispatch_review) do |**arguments|
              test.instance_variable_set(:@dispatches, test.instance_variable_get(:@dispatches) + 1)
              original_dispatch.call(**arguments)
            end
            channels = @launch.instance_variable_get(:@control_channels)
            key = ["project", "mapping", "assignment", @attempt]
            channels[key] = channel
            params = public_params
            reservation = nil
            case stage
            when :missing then channels.delete(key)
            when :busy
              reservation = channel.reserve_dispatch!
              assert channel.dispatch_reserved?(reservation)
            when :stale then params["expected_generation"] = generation - 1
            when :dead_original then @kernel.dead << @launcher.fetch("pid")
            when :foreign_reviewer then @reviewer = @reviewer.merge("groups" => [999])
            when :author_reviewer then @reviewer = @worker
            when :sealed
              channel.close
              call("close_execution_scope", {"expected_generation" => generation}, id: "seal", peer: @launcher, role: :launcher)
              assert @journal.read_events("assignment").any? { |event| event["type"] == "scope_sealed" }
              params["expected_generation"] = generation
            end
            before = @journal.ref_value
            endpoint do |client|
              assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("request_review", params, mutation_id: "refused", timeout: 30) }
            end
            assert channel.dispatch_reserved?(reservation) if stage == :busy
            assert_equal before, @journal.ref_value, stage.to_s
            assert_nil @journal.mutation_result("refused")
            assert_equal 0, @dispatches
          ensure
            channel&.close
            left&.close
            right&.close
          end
        end
      end

      def test_concurrent_public_requests_cannot_replace_original_assignment_or_hold_observation_lock
        fixture do
          issued_with_channel
          left, right = UNIXSocket.pair
          channel = Authority::LaunchControlChannel.new(socket: left, codec: Object.new, outcome: ->(*) { flunk "no native effect" })
          @launch.instance_variable_get(:@control_channels)[["project", "mapping", "assignment", @attempt]] = channel
          arrived, proceed = Queue.new, Queue.new
          owner = self
          channel.define_singleton_method(:dispatch_review) do |frame:, **_|
            owner.instance_variable_set(:@dispatches, owner.instance_variable_get(:@dispatches) + 1)
            arrived << frame
            proceed.pop
            owner.delegate(frame, :assigned)
          end
          params = public_params
          endpoint do |client|
            first = Thread.new { client.call("request_review", params, mutation_id: "request", timeout: 30) }
            frame = Timeout.timeout(5) { arrived.pop }
            assert_equal "request", frame.fetch("mutation_id")
            pending = @journal.ref_value
            assert_raises(AttemptErrors::EvidenceUnavailable) { client.call("request_review", params, mutation_id: "competitor", timeout: 30) }
            assert_equal pending, @journal.ref_value
            assert_nil @journal.mutation_result("competitor")
            observed = client.call("review_status", params.slice("assignment_id", "attempt_id").merge("mutation_id" => "request"), timeout: 30).data
            assert_equal "requested", observed.fetch("state"), "observation must work while delegation waits"
            proceed << true
            assert first.join(10)
            accepted = first.value
            assert_equal "assigned", accepted.data.fetch("state")
            assert_equal 1, @dispatches
          ensure
            proceed << true
            first&.join(3)
          end
        ensure
          channel&.close
          left&.close
          right&.close
        end
      end

      def test_public_bodyless_malformed_frames_refuse_without_canonical_writes
        fixture do
          issued_with_channel
          before = @journal.ref_value
          endpoint do |_client|
            params = public_params.merge("mapping_id" => "mapping")
            request = {"version" => 1, "project_id" => "project", "operation" => "request_review", "mutation_id" => "malformed", "params" => params}
            status = request.merge("operation" => "review_status", "mutation_id" => nil,
              "params" => params.slice("assignment_id", "attempt_id", "mapping_id").merge("mutation_id" => "unknown"))
            [request, status].each do |frame|
              valid = JSON.generate(frame)
              typed_params = frame.fetch("operation") == "request_review" ?
                frame.fetch("params").merge("expected_generation" => params.fetch("expected_generation").to_f) :
                frame.fetch("params").merge("mutation_id" => 1)
              cases = {trailing: valid + "\nextra", duplicate: valid.sub('{', '{"version":1,'),
                oversized: JSON.generate(frame.merge("params" => frame.fetch("params").merge("hidden" => "x" * 17_000))),
                typed: JSON.generate(frame.merge("params" => typed_params))}
              cases.each do |name, body|
                UNIXSocket.open(@service.fetch("socket_path")) do |socket|
                  socket.write(body + (name == :trailing ? "" : "\n"))
                  socket.shutdown(Socket::SHUT_WR)
                  response = WIRE.read(socket, deadline: WIRE.deadline(5))
                  assert_equal "error", response.fetch("status"), "#{frame.fetch('operation')}/#{name}"
                end
                assert_equal before, @journal.ref_value, name.to_s
                assert_nil @journal.mutation_result("malformed")
                assert_equal 0, @dispatches
              end
            end
          end
        end
      end
    end
  end
end
