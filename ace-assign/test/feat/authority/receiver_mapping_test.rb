# frozen_string_literal: true
require_relative "deployment_test"
require "tmpdir"

module Ace
  module Assign
    class ProtectedReceiverMappingTest < AceAssignTestCase
      def receiver_data(uid: 13005)
        value = ProtectedDeploymentTest.new("fixture").data
        value["authorities"]["authority"]["composition"] = "services"
        project = value["projects"]["project"]
        project["service_executor_uids"] = [uid]
        project["peer_credentials"][uid.to_s] = {"gid" => uid, "groups" => [uid], "scratch_root" => "/var/lib/ace-executor"}
        project["service_receivers"] = {"publish" => {"executor_uid" => uid, "socket_path" => "/run/ace-service/control.sock", "staging_root" => "/var/lib/ace-service-staging"}}
        value
      end

      def test_launch_optional_but_services_requires_fixed_nonempty_receivers
        assert Authority::Deployment.new(ProtectedDeploymentTest.new("fixture").data)
        valid = receiver_data
        assert Authority::Deployment.new(valid).verify_composition!("authority", composition: "services")
        [nil, {}].each do |receivers|
          value = receiver_data
          value["projects"]["project"]["service_receivers"] = receivers
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        absent = receiver_data
        absent["projects"]["project"].delete("service_receivers")
        assert_raises(ArgumentError) { Authority::Deployment.new(absent) }
      end

      def test_receiver_identity_fields_and_paths_refuse_before_listener
        changes = [->(row) { row["executor_uid"] = 0 }, ->(row) { row["executor_uid"] = 13001 },
          ->(row) { row["executor_uid"] = 13006 }, ->(row) { row["executor_uid"] = "13005" },
          ->(row) { row["argv"] = ["/usr/bin/true"] }, ->(row) { row["socket_path"] = "/run/../control.sock" },
          ->(row) { row["staging_root"] = "relative" }]
        changes.each do |change|
          value = receiver_data
          change.call(value["projects"]["project"]["service_receivers"]["publish"])
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        %w[launcher_uids reviewer_uids worker_uids supervisor_uids].each do |role|
          value = receiver_data
          value["projects"]["project"][role] = (value["projects"]["project"][role] + [13005]).sort
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        authority = receiver_data(uid: 13003)
        assert_raises(ArgumentError) { Authority::Deployment.new(authority) }
        foreign = receiver_data
        foreign["authorities"]["other"] = foreign["authorities"]["authority"].merge("uid" => 13005,
          "gid" => 13005, "groups" => [13005], "socket_path" => "/run/other-authority/control.sock", "state_root" => "/var/lib/other-authority")
        assert_raises(ArgumentError) { Authority::Deployment.new(foreign) }
      end

      def test_receiver_endpoint_and_staging_isolation
        [->(value, row) { row["socket_path"] = value["authorities"]["authority"]["socket_path"] },
         ->(_value, row) { row["staging_root"] = "/var/lib/ace-journal/imports" }].each do |change|
          value = receiver_data
          change.call(value, value["projects"]["project"]["service_receivers"]["publish"])
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        private_endpoint = receiver_data
        row = private_endpoint["projects"]["project"]["service_receivers"]["publish"]
        row["socket_path"] = row["staging_root"] + "/control.sock"
        assert_raises(ArgumentError) { Authority::Deployment.new(private_endpoint) }
        %w[socket_path staging_root].each do |field|
          value = receiver_data
          row = value["projects"]["project"]["service_receivers"]["publish"]
          second = row.merge("socket_path" => "/run/other/control.sock", "staging_root" => "/var/lib/other-staging")
          second[field] = row[field]
          value["projects"]["project"]["service_receivers"]["other"] = second
          assert_raises(ArgumentError) { Authority::Deployment.new(value) }
        end
        nested = receiver_data
        row = nested["projects"]["project"]["service_receivers"]["publish"]
        nested["projects"]["project"]["service_receivers"]["other"] = row.merge("socket_path" => "/run/other.sock", "staging_root" => row["staging_root"] + "/child")
        assert_raises(ArgumentError) { Authority::Deployment.new(nested) }
      end

      def with_private_paths
        skip "private receiver path fixture requires nonroot account" if Process.uid.zero?
        Dir.mktmpdir("ace-receiver-", File.realpath(Etc.getpwuid(Process.uid).dir)) do |root|
          File.chmod(0o700, root)
          staging = File.join(root, "staging")
          Dir.mkdir(staging, 0o700)
          value = receiver_data(uid: Process.uid)
          row = value["projects"]["project"]["service_receivers"]["publish"]
          row.merge!("staging_root" => staging, "socket_path" => File.join(root, "service.sock"))
          value["projects"]["project"]["peer_credentials"][Process.uid.to_s]["gid"] = Process.gid
          if RUBY_PLATFORM.include?("linux")
            yield value, root, staging
          else
            # These host tests exercise filesystem placement, not Linux ACL retrieval.
            acl = Authority::PosixAcl.new
            acl.define_singleton_method(:entries) { |_path| nil }
            Authority::PosixAcl.stub(:new, acl) { yield value, root, staging }
          end
        end
      end

      def test_authority_access_does_not_admit_executor_inaccessible_ancestor
        with_private_paths do |value, root, _staging|
          deployment = Authority::Deployment.new(value)
          original = File.method(:lstat)
          observed = original.call(root)
          modeled = Struct.new(:uid, :gid, :mode) do
            def directory? = true
            def symlink? = false
          end.new(0, 13003, 0o40750)
          acl = Authority::PosixAcl.new
          acl.define_singleton_method(:entries) { |_path| nil }
          deployment.define_singleton_method(:receiver_acl) { acl }
          File.stub(:lstat, ->(path) { path == root ? modeled : original.call(path) }) do
            # Host authority can traverse this actual directory; installed executor
            # lacks the modeled root-owned ancestor's authority-only group.
            assert File.executable?(root)
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.verify_receiver_paths!("authority") }
          end
          assert observed.directory?
        end
      end

      def test_real_private_directory_and_absent_receiver_socket_are_admitted
        with_private_paths do |value, root, staging|
          assert Authority::Deployment.new(value).verify_receiver_paths!("authority")
          socket = UNIXServer.new(File.join(root, "service.sock"))
          File.chmod(0o600, socket.path)
          assert Authority::Deployment.new(value).verify_receiver_paths!("authority")
        ensure
          socket&.close
        end
      end

      def test_writable_or_substituted_receiver_roots_refuse_before_listener_creation
        with_private_paths do |value, root, staging|
          deployment = Authority::Deployment.new(value)
          File.chmod(0o720, staging)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.verify_receiver_paths!("authority") }
          File.chmod(0o700, staging)
          File.rename(staging, staging + "-original")
          File.symlink(staging + "-original", staging)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { deployment.verify_receiver_paths!("authority") }
          File.unlink(staging)
          File.rename(staging + "-original", staging)
          File.chmod(0o722, root)
          value["authorities"]["authority"]["socket_path"] = File.join(root, "authority.sock")
          deployment = Authority::Deployment.new(value)
          kernel = Object.new
          kernel.define_singleton_method(:supported!) { true }
          kernel.define_singleton_method(:capture) { |_pid| {"uid" => 13003, "gid" => 13003, "groups" => [13003]} }
          server = Authority::Server.new(authority_id: "authority", deployment: deployment, lifecycle: Object.new,
            kernel: kernel, composition: "services")
          # Isolate receiver admission from the unrelated authority-directory
          # ownership check. The actual receiver filesystem remains unstubbed.
          actual = Ace::Runtime::Molecules::ProtectedSocket
          wire = Object.new
          wire.define_singleton_method(:root_path!) { |*args, **options| true }
          %i[socket_identity deadline read write].each do |name|
            wire.define_singleton_method(name) { |*args, **options| actual.public_send(name, *args, **options) }
          end
          server.define_singleton_method(:wire) { wire }
          errors = Queue.new
          owner = Thread.new { begin; server.serve; rescue StandardError => error; errors << error; end }
          error = Timeout.timeout(1) { errors.pop }
          assert_instance_of Ace::Runtime::RuntimeUnavailableError, error
          refute File.exist?(File.join(root, "listener.lock"))
          refute File.socket?(File.join(root, "authority.sock"))
        ensure
          server&.request_stop
          owner&.join(2)
          File.chmod(0o700, root)
        end
      end

      def test_existing_receiver_endpoint_must_be_owned_socket_and_inspectable
        with_private_paths do |value, root, staging|
          path = value["projects"]["project"]["service_receivers"]["publish"]["socket_path"]
          File.write(path, "replacement")
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { Authority::Deployment.new(value).verify_receiver_paths!("authority") }
          File.unlink(path)
          File.symlink(staging, path)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { Authority::Deployment.new(value).verify_receiver_paths!("authority") }
          File.unlink(path)
          File.chmod(0o600, root)
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { Authority::Deployment.new(value).verify_receiver_paths!("authority") }
        ensure
          File.chmod(0o700, root)
        end
      end
    end
  end
end
