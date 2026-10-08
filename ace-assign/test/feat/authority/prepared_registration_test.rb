# frozen_string_literal: true
require_relative "../../support/protected_control_fixture"
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/transfer_codec"
require "ace/assign/authority/server"
require "open3"
require "tempfile"

module Ace
  module Assign
    class PreparedRegistrationTest < AceAssignTestCase
      def git(directory, *args)
        stdout, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
        assert status.success?, error
        stdout
      end

      def with_registration(review_campaign: false)
        Dir.mktmpdir("prepared-registration-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          source = File.join(root, "source"); journal_root = File.join(root, "journal"); quarantine = File.join(root, "quarantine")
          FileUtils.mkdir_p([source, journal_root, quarantine], mode: 0700)
          [source, journal_root].each { |directory| git(directory, "init", "-b", "main") }
          definition = {"session_id" => "batch", "name" => "prepared", "created_at" => "2026-10-07T00:00:00Z", "source_config" => "job.yaml", "task_id" => "8wr.t.qk0.3", "project_id" => "ace"}
          campaign_root = File.join(root, "campaign-repository")
          campaign_store = File.join(root, "campaign-store")
          if review_campaign
            FileUtils.mkdir_p([campaign_root, campaign_store], mode: 0700)
            manager = Ace::Review::Organisms::CampaignManager.new(repo_root: campaign_root,
              store: Ace::Review::Molecules::CampaignStore.new(root: campaign_store), revisions: ->(*) { "a" * 40 })
            campaign = manager.start(subject: {"repository" => "local:#{campaign_root}", "local_candidate_id" => "candidate"},
              contract: "Reviewed requirements", policy: {"revision" => "v1", "minimum_rounds" => 3,
                "clean_rounds" => 2, "required_scopes" => ["full"], "required_checks" => ["tests"]})
            definition["review_campaign"] = {"version" => 1, "campaign_id" => campaign.fetch("campaign_id"),
              "subject" => campaign.fetch("subject"), "contract_identity" => campaign.fetch("contract_identity"),
              "policy" => campaign.fetch("effective_policy")}
          end
          files = {"definition.json" => JSON.generate(definition), "job.yaml" => "steps:\n- number: '010.01'\n  context: fork\n  taskref: 8wr.t.qk0.3\n",
            "steps/010.01-execute.st.md" => "---\nname: execute\nstatus: pending\ncontext: fork\ntaskref: 8wr.t.qk0.3\n---\nDo prepared work.\n",
            "context/8wr.t.qk0.3/spec.md" => "---\nid: 8wr.t.qk0.3\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nReviewed work.\n", "context/8wr.t.qk0.3/bundle.txt" => "Captured exact instructions.\n"}
          record = ->(path) { {"filename" => path, "bytes" => files.fetch(path).bytesize, "sha256" => Digest::SHA256.hexdigest(files.fetch(path))} }
          manifest = {"version" => 1, "assignment_id" => "batch", "project_id" => "ace", "task_id" => "8wr.t.qk0.3", "scope" => "010.01", "job" => record.call("job.yaml"),
            "steps" => [record.call("steps/010.01-execute.st.md").merge("filename" => "010.01-execute.st.md", "number" => "010.01")],
            "context" => [{"uri" => "task://8wr.t.qk0.3", "task_id" => "8wr.t.qk0.3", "spec" => record.call("context/8wr.t.qk0.3/spec.md"), "text" => record.call("context/8wr.t.qk0.3/bundle.txt"), "reports" => []}]}
          files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
          files.each { |path, bytes| destination = File.join(source, path); FileUtils.mkdir_p(File.dirname(destination)); File.binwrite(destination, bytes) }
          git(source, "add", "."); git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "prepared")
          git(journal_root, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "journal")
          head = git(source, "rev-parse", "HEAD").strip; tree = git(source, "rev-parse", "HEAD^{tree}").strip
          path = File.join(root, "input.bundle"); git(source, "bundle", "create", path, "--all"); bundle = File.binread(path)
          work = Authority::PreparedWork.new(files: files)
          bytes = work.definition_bytes(head: head, tree: tree)
          descriptor = Authority::TransferCodec.new.descriptor([bundle], purpose: :candidate)
          params = {"mapping_id" => "mapping", "assignment_id" => "batch", "definition_digest" => Digest::SHA256.hexdigest(bytes), "prepared_head" => head,
            "prepared_tree" => tree, "manifest_sha256" => work.manifest_sha256, "expected_generation" => 0, "transfer" => descriptor}
          peer = {"pid" => 123, "uid" => 1001, "gid" => 1001, "groups" => [1001]}
          kernel = Object.new; kernel.define_singleton_method(:live!) { |_identity| true }
          mapping = {"task_context_entry" => {"manifest" => {"path" => "/fixture/assign-entry.json", "bytes" => 100, "sha256" => "1" * 64}, "wrapper" => {"path" => "/fixture/assign-entry.py", "bytes" => 200, "sha256" => "2" * 64}}, "project_id" => "ace", "authority_id" => "authority", "launcher_uid" => 1001, "launcher_gid" => 1001, "launcher_groups" => [1001], "execution_scope" => {"slot_id" => "slot"}}
          deployment = Object.new; deployment.define_singleton_method(:artifact_reference) { {"sha256" => "d" * 64} }; deployment.define_singleton_method(:mapping) { |_id| mapping }
          deployment.define_singleton_method(:project) { |_id| {"candidate_root" => quarantine, "assignment_root" => File.join(root, "definitions")} }
          deployment.define_singleton_method(:authority) { |_id| {"uid" => 13000, "gid" => 13000, "state_root" => File.join(root, "authority-state")} }
          journal = Molecules::EvidenceJournal.new(repo_root: journal_root, checkout_root: File.join(root, "checkout"))
          deployment.define_singleton_method(:project) { |_id| {"candidate_root" => quarantine, "assignment_root" => File.join(root, "definitions"), "journal_repository" => journal.repo_root, "evidence_git_ref" => journal.ref, "evidence_checkout_root" => journal.checkout_root, "campaign_repository" => campaign_root, "campaign_store_root" => campaign_store} }
          ProtectedControlFixture.prepare!(authority: deployment.authority("authority"), project_id: "ace")
          authority = Authority::LaunchLifecycle.new(deployment: deployment, control_exclusion_factory: ProtectedControlFixture.factory, kernel: kernel, journals: {"ace" => journal})
          Tempfile.create("prepared-input", root, binmode: true) do |file|
            file.write(bundle); file.flush; file.rewind
            input = Authority::TransferCodec::Input.new(file, descriptor)
            yield authority, journal, params, peer, input, bundle, bytes, deployment, kernel, root
          end
        end
      end

      def dispatch(authority, params, peer, input, mutation: "register")
        authority.dispatch(request: {"version" => 1, "operation" => "register_assignment", "mutation_id" => mutation, "project_id" => "ace", "params" => params}, peer: peer, role: :launcher, transfer: input)
      end

      def test_parent_campaign_is_retained_in_actual_registered_definition
        with_registration(review_campaign: true) do |authority, journal, params, peer, input, _bundle, definition|
          checked = []
          protection = lambda do |path, directory:, owner:|
            assert directory
            assert_equal 13000, owner
            assert_equal 0, File.stat(path).mode & 0o077
            checked << path
          end
          Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, protection) do
            accepted = dispatch(authority, params, peer, input)
            data = accepted.fetch(:data)
            stored = JSON.parse(journal.blob(data.fetch("definition_ref"), commit: data.fetch("journal_commit")))
            assert_equal JSON.parse(definition).fetch("review_campaign"), stored.fetch("review_campaign")
            assert dispatch(authority, params, peer, input).fetch(:replayed)
          end
          assert_equal 2, checked.uniq.size
        end
      end

      def test_superseded_campaign_cannot_register_or_reuse_parent_as_current
        with_registration(review_campaign: true) do |authority, journal, params, peer, input, _bundle, definition, deployment|
          protection = ->(path, directory:, owner:) { raise "not private" unless File.directory?(path) && (File.stat(path).mode & 0o077).zero? }
          Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, protection) do
            accepted = dispatch(authority, params, peer, input)
            commit = accepted.fetch(:data).fetch("journal_commit")
            project = deployment.project("ace")
            selected = JSON.parse(definition).fetch("review_campaign")
            manager = Ace::Review::Organisms::CampaignManager.new(repo_root: project.fetch("campaign_repository"),
              store: Ace::Review::Molecules::CampaignStore.new(root: project.fetch("campaign_store_root")), revisions: ->(*) { "a" * 40 })
            manager.start(subject: selected.fetch("subject"), contract: "Changed requirements", policy: selected.fetch("policy"), reason: "Revised contract")
            assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch(authority, params, peer, input, mutation: "new-registration") }
            assert_equal commit, journal.ref_value
            replay = dispatch(authority, params, peer, input)
            assert replay.fetch(:replayed)
            assert_equal accepted.fetch(:data), replay.fetch(:data)
            assert_equal commit, journal.ref_value
          end
        end
      end

      def test_campaign_registration_keeps_original_store_after_descriptor_rotation
        with_registration(review_campaign: true) do |authority, journal, params, peer, input, _bundle, _definition, original|
          protection = ->(path, directory:, owner:) { raise "not private" unless File.directory?(path) && (File.stat(path).mode & 0o077).zero? }
          Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, protection) do
            accepted = dispatch(authority, params, peer, input)
            replacement = original.clone
            replacement.define_singleton_method(:artifact_reference) { {"sha256" => "e" * 64} }
            replacement.define_singleton_method(:project) do |id|
              original.project(id).merge("campaign_repository" => "/unavailable/replacement-repository",
                "campaign_store_root" => "/unavailable/replacement-store")
            end
            history = Object.new
            history.define_singleton_method(:descriptor!) do |sha256:|
              raise "unexpected original descriptor" unless sha256 == "d" * 64
              original
            end
            authority.instance_variable_set(:@deployment, replacement)
            authority.instance_variable_set(:@deployment_history, history)
            result = dispatch(authority, params.merge("expected_generation" => 1), peer, input, mutation: "after-rotation")
            refute result.fetch(:replayed)
            assert_equal accepted.fetch(:data).fetch("lifecycle_control"), result.fetch(:data).fetch("lifecycle_control")
            assert_equal 2, result.fetch(:data).fetch("generation")
            assert_equal result.fetch(:data).fetch("journal_commit"), journal.ref_value
          end
        end
      end

      def test_exact_received_bundle_and_derived_definition_share_original_commit_and_replay
        with_registration do |authority, journal, params, peer, input, bundle, definition|
          accepted = dispatch(authority, params, peer, input)
          data = accepted.fetch(:data); commit = data.fetch("journal_commit")
          assert_equal bundle, journal.blob(data.fetch("prepared_bundle_ref"), commit: commit)
          assert_equal definition, journal.blob(data.fetch("definition_ref"), commit: commit)
          assert_equal Digest::SHA256.hexdigest(bundle), data.fetch("prepared_bundle_sha256")
          assert_equal params.fetch("definition_digest"), data.fetch("definition_digest")
          assert_equal "010.01", data.dig("prepared_work", "scope")
          assert dispatch(authority, params, peer, input).fetch(:replayed)
          assert_equal commit, journal.ref_value
          changed_bundle = bundle.sub("\n\n".b, "\n#{params.fetch('prepared_head')} refs/heads/alias\n\n".b)
          refute_equal bundle, changed_bundle
          descriptor = Authority::TransferCodec.new.descriptor([changed_bundle], purpose: :candidate)
          Tempfile.create("changed-prepared-input", binmode: true) do |file|
            file.write(changed_bundle); file.flush; file.rewind
            changed_input = Authority::TransferCodec::Input.new(file, descriptor)
            assert_raises(AttemptErrors::Conflict) do
              dispatch(authority, params.merge("transfer" => descriptor), peer, changed_input, mutation: "replace-original-bundle")
            end
          end
          assert_equal commit, journal.ref_value
          changed = params.merge("manifest_sha256" => "0" * 64)
          assert_raises(ArgumentError) { dispatch(authority, changed, peer, input) }
          assert_equal commit, journal.ref_value
        end
      end

      def test_no_input_or_unmapped_launcher_cannot_create_registration
        with_registration do |authority, journal, params, peer, input, _bundle, _definition|
          original = journal.ref_value
          assert_raises(AttemptErrors::MalformedTransfer) { dispatch(authority, params, peer, nil) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { dispatch(authority, params, peer.merge("uid" => 2002), input) }
          assert_equal original, journal.ref_value
        end
      end

      def test_original_entry_pin_cannot_change_on_replay_or_same_definition_registration
        with_registration do |authority, journal, params, peer, input, _bundle, _definition, deployment|
          mapping = deployment.mapping("mapping")
          original_pin = Marshal.load(Marshal.dump(mapping.fetch("task_context_entry")))
          accepted = dispatch(authority, params, peer, input)
          assert_equal original_pin, accepted.fetch(:data).fetch("task_context_entry")
          commit = journal.ref_value
          mapping.fetch("task_context_entry").fetch("wrapper")["sha256"] = "3" * 64
          assert_raises(AttemptErrors::Conflict) { dispatch(authority, params, peer, input) }
          assert_raises(AttemptErrors::Conflict) do
            dispatch(authority, params.merge("expected_generation" => accepted.fetch(:data).fetch("generation")), peer, input, mutation: "different-entry")
          end
          assert_equal commit, journal.ref_value
          mapping.delete("task_context_entry")
          assert_raises(KeyError) { dispatch(authority, params, peer, input, mutation: "missing-entry") }
          assert_equal commit, journal.ref_value
        end
      end

      def test_actual_public_server_requires_exact_candidate_body_before_atomic_registration
        with_registration do |authority, journal, params, peer, _input, bundle, definition, deployment, kernel, root|
          wire = Ace::Runtime::Molecules::ProtectedSocket
          service = {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort,
            "socket_path" => File.join(root, "authority.sock"), "state_root" => root}
          deployment.define_singleton_method(:authority) { |_| service }
          ProtectedControlFixture.prepare!(authority: service, project_id: "ace")
          deployment.define_singleton_method(:verify_composition!) { |*_, **_| true }
          deployment.define_singleton_method(:verify_receiver_paths!) { |_| true }
          mapping = deployment.mapping("mapping")
          deployment.define_singleton_method(:verify!) { |*_, **_| mapping }
          kernel.define_singleton_method(:supported!) { true }
          kernel.define_singleton_method(:capture) { |_| service }
          kernel.define_singleton_method(:peer) { |_| peer }
          server = Authority::Server.new(authority_id: "authority", lifecycle: authority, deployment: deployment, kernel: kernel)
          controlled_wire = Object.new
          controlled_wire.define_singleton_method(:root_path!) { |*_, **_| true }
          %i[socket_identity read write deadline].each do |name|
            controlled_wire.define_singleton_method(name) { |*args, **options| wire.public_send(name, *args, **options) }
          end
          server.define_singleton_method(:wire) { controlled_wire }
          listener = Thread.new { server.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(service.fetch("socket_path")) }
          original = journal.ref_value
          [bundle.byteslice(0, bundle.bytesize - 1), bundle + "extra"].each_with_index do |body, index|
            UNIXSocket.open(service.fetch("socket_path")) do |socket|
              wire.write(socket, {"version" => 1, "operation" => "register_assignment", "mutation_id" => "bad-#{index}", "project_id" => "ace", "params" => params}, deadline: wire.deadline(2))
              socket.write(body); socket.shutdown(Socket::SHUT_WR)
              assert_equal "error", wire.read(socket, deadline: wire.deadline(3)).fetch("status")
            end
            assert_equal original, journal.ref_value
          end
          UNIXSocket.open(service.fetch("socket_path")) do |socket|
            wire.write(socket, {"version" => 1, "operation" => "register_assignment", "mutation_id" => "public-register", "project_id" => "ace", "params" => params}, deadline: wire.deadline(2))
            socket.write(bundle); socket.shutdown(Socket::SHUT_WR)
            reply = wire.read(socket, deadline: wire.deadline(5))
            assert_equal "ok", reply.fetch("status"), reply.inspect
            data = reply.fetch("data"); commit = data.fetch("journal_commit")
            assert_equal bundle, journal.blob(data.fetch("prepared_bundle_ref"), commit: commit)
            assert_equal definition, journal.blob(data.fetch("definition_ref"), commit: commit)
          end
          assert_empty Dir.children(File.join(root, "transfers"))
        ensure
          server&.request_stop
          server&.stop
          assert listener.join(3), "controlled public registration handlers must drain" if listener
        end
      end
    end
  end
end
