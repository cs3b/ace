# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"

class ProtectedControlRegistrationTest < AceAssignTestCase
  include Ace::Assign::EndcapResultOwnerFixture

  def register(id:, generation:, task: "task")
    bytes = JSON.generate("session_id" => "assignment", "name" => "control fixture",
      "created_at" => "2026-10-05T00:00:00Z", "source_config" => "job.yaml",
      "task_id" => task, "project_id" => "project")
    call("register_assignment", {"definition_bytes" => bytes,
      "definition_digest" => Digest::SHA256.hexdigest(bytes), "expected_generation" => generation},
      id: id, peer: @launcher, role: :launcher).fetch(:data)
  end

  def test_first_control_selection_survives_new_registration_and_changed_task
    fixture(prepare_attempt: false) do
      first = register(id: "first", generation: 0)
      original = first.fetch("lifecycle_control")
      root = File.join(@root, "lifecycle-exclusion", "project", "control")
      lock = File.join(root, "#{Digest::SHA256.hexdigest('assignment:assignment')}.lock")
      inode = File.stat(lock).ino
      second = register(id: "second", generation: first.fetch("generation"))
      assert_equal original, second.fetch("lifecycle_control")
      changed = register(id: "changed", generation: second.fetch("generation"), task: "next-task")
      assert_equal original, changed.fetch("lifecycle_control")
      assert_equal inode, File.stat(lock).ino
      assert File.file?(File.join(root, "#{Digest::SHA256.hexdigest('task:task')}.lock"))
      assert File.file?(File.join(root, "#{Digest::SHA256.hexdigest('task:next-task')}.lock"))
      registrations = @journal.read_events("assignment").select { |event| event.dig("payload", "operation") == "register_assignment" }
      assert_equal 3, registrations.size
      assert registrations.all? { |event| event.dig("payload", "data", "lifecycle_control") == original }
    end
  end
  # Descriptor retention is an injected installed-artifact boundary here; the
  # registration/introduction journal and all selected-root IO remain actual.
  class History < Ace::Assign::Authority::DeploymentHistory
    def self.build(original, successor)
      allocate.tap { |value| value.instance_variable_set(:@selected, successor); value.instance_variable_set(:@retained, original) }
    end
    def selects?(deployment) = deployment.equal?(@selected)
    def descriptor!(sha256:)
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "unknown original" unless sha256 == "d" * 64
      @retained
    end
  end

  def rotate_descriptor(original, map: @map, authority: @service)
    project = @project
    successor = Object.new
    successor.define_singleton_method(:artifact_reference) { {"sha256" => "e" * 64} }
    successor.define_singleton_method(:mapping) { |_id| map }
    successor.define_singleton_method(:project) { |_id| project }
    successor.define_singleton_method(:authority) { |_id| authority }
    successor.define_singleton_method(:verify!) { |*_, **_| map }
    @history = History.build(original, successor)
    @deployment = successor
    restart
  end

  def test_descriptor_rotation_retains_original_selection_and_missing_history_refuses
    fixture(prepare_attempt: false) do
      first = register(id: "first", generation: 0)
      original = @deployment
      rotate_descriptor(original)
      second = register(id: "rotated", generation: first.fetch("generation"))
      assert_equal first.fetch("lifecycle_control"), second.fetch("lifecycle_control")
      assert_equal "d" * 64, second.dig("lifecycle_control", "descriptor_sha256")
      before = @journal.ref_value
      @history = nil
      restart
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        register(id: "missing-original", generation: second.fetch("generation"))
      end
      assert_equal before, @journal.ref_value
    end
  end

  def test_owner_or_slot_migration_requires_fresh_assignment_before_key_creation
    fixture(prepare_attempt: false) do
      first = register(id: "first", generation: 0)
      original = @deployment
      before = @journal.ref_value
      root = File.join(@root, "lifecycle-exclusion", "project", "control")
      entries = Dir.children(root).sort
      migrated = @map.merge("execution_scope" => @map.fetch("execution_scope").merge("slot_id" => "replacement"))
      rotate_descriptor(original, map: migrated)
      assert_raises(Ace::Assign::AttemptErrors::Conflict) do
        register(id: "slot-migration", generation: first.fetch("generation"), task: "different-task")
      end
      assert_equal before, @journal.ref_value
      assert_equal entries, Dir.children(root).sort
      rotate_descriptor(original, authority: @service.merge("state_root" => File.join(@root, "replacement")))
      assert_raises(Ace::Assign::AttemptErrors::Conflict) do
        register(id: "root-migration", generation: first.fetch("generation"))
      end
      assert_equal before, @journal.ref_value
      refute File.exist?(File.join(@root, "replacement"))
    end
  end

  def test_changed_task_holds_both_keys_and_revalidates_them_before_canonical_cas
    fixture(prepare_attempt: false) do
      first = register(id: "first", generation: 0)
      root = File.join(@root, "lifecycle-exclusion", "project", "control")
      keys = %w[task:task task:next-task assignment:assignment]
      original_mutate = @journal.method(:mutate)
      observed = false
      @journal.define_singleton_method(:mutate) do |**options, &planner|
        if options[:mutation_id] == "changed"
          observed = true
          keys.each do |key|
            File.open(File.join(root, "#{Digest::SHA256.hexdigest(key)}.lock"), File::RDONLY) do |file|
              raise "registration did not hold original ordered key" if file.flock(File::LOCK_EX | File::LOCK_NB)
            end
          end
        end
        original_mutate.call(**options, &planner)
      end
      changed = register(id: "changed", generation: first.fetch("generation"), task: "next-task")
      assert observed
      assert_equal first.fetch("lifecycle_control"), changed.fetch("lifecycle_control")
      before = @journal.ref_value
      marker = File.join(root, "#{Digest::SHA256.hexdigest('assignment:assignment')}.state.json")
      @journal.define_singleton_method(:mutate) do |**options, &planner|
        File.write(marker, "corrupt") if options[:mutation_id] == "corrupt-before-cas"
        original_mutate.call(**options, &planner)
      end
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        register(id: "corrupt-before-cas", generation: changed.fetch("generation"), task: "third-task")
      end
      assert_equal before, @journal.ref_value
      assert_equal "corrupt", File.read(marker)
    end
  end

end
