# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../../ace-assign/test/support/prepared_registration_fixture"
require "ace/overseer/molecules/launch_request"
require "etc"

class LaunchRequestTest < AceOverseerTestCase
  def setup
    super
    @root = Dir.mktmpdir("retained-launch-", Etc.getpwuid(Process.uid).dir)
    File.chmod(0700, @root)
    @owner = Ace::Overseer::Molecules::LaunchRequest.new(root: @root)
    @artifact = Ace::Assign::PreparedRegistrationFixture.build(root: @root, scope: "010", definition: {
      "session_id" => "assignment", "project_id" => "project", "task_id" => "task", "name" => "fixture",
      "created_at" => "2026-10-07T00:00:00Z", "source_config" => "job.yaml"})
    @prepared = {"bundle" => @artifact.bundle, "bytes" => @artifact.bundle.bytesize,
      "sha256" => Digest::SHA256.hexdigest(@artifact.bundle), "definition_bytes" => @artifact.definition_bytes,
      "assignment_id" => "assignment", "scope" => "010"}
  end

  def teardown
    FileUtils.rm_rf(@root)
    super
  end

  def publish(**changes)
    @owner.publish(**{project_id: "project", mapping_id: "worker", task_id: "task", base_head: "a" * 40,
      mutation_id: "invocation", prepared: @prepared}.merge(changes))
  end

  def test_exact_publication_and_exclusive_identity
    document = publish
    assert document.frozen?
    assert_equal @artifact.definition_bytes, document.fetch("definition_bytes")
    assert_equal @artifact.bundle, @owner.verify_fresh!(document)
    assert_equal "available", @owner.bundle_availability(document)
    original = File.binread(File.join(@root, "invocation.json"))
    assert_raises(Ace::Overseer::Error) { publish }
    assert_equal original, File.binread(File.join(@root, "invocation.json"))
    assert_equal @artifact.bundle, File.binread(File.join(@root, "invocation.prepared.bundle"))
  end

  def test_last_admitted_proof_is_instance_owned_and_exact_tuple_bound
    original = Ace::Assign::Authority::PreparedWork.method(:admit)
    admissions = []
    measured = ->(**args) { admissions << args; original.call(**args) }
    Ace::Assign::Authority::PreparedWork.stub(:admit, measured) do
      document = publish
      assert_equal 1, admissions.size
      2.times { assert_equal @artifact.bundle, @owner.verify_fresh!(document) }
      assert_equal 1, admissions.size
      fresh_owner = Ace::Overseer::Molecules::LaunchRequest.new(root: @root)
      assert_equal @artifact.bundle, fresh_owner.verify_fresh!(fresh_owner.load(File.join(@root, "invocation.json")))
      assert_equal 2, admissions.size
      changed = document.merge("base_head" => "b" * 40)
      assert_equal @artifact.bundle, @owner.verify_fresh!(changed)
      assert_equal 3, admissions.size
      assert_equal @artifact.bundle, @owner.verify_fresh!(document)
      assert_equal 4, admissions.size # only the last proof, never a growing cache
    end
  end

  def test_last_proof_never_bypasses_fresh_sidecar_or_bundle_admission
    document = publish
    original = Ace::Assign::Authority::PreparedWork.method(:admit)
    admissions = []
    Ace::Assign::Authority::PreparedWork.stub(:admit, ->(**args) { admissions << args; original.call(**args) }) do
      File.binwrite(@owner.definition_path(document), "changed")
      assert_raises(Ace::Overseer::Error) { @owner.verify_fresh!(document) }
      assert_empty admissions
      File.binwrite(@owner.definition_path(document), document.fetch("definition_bytes"))
      path = File.join(@root, "invocation.prepared.bundle")
      File.binwrite(path, "invalid bundle")
      assert_raises(Ace::Overseer::Error) { @owner.verify_fresh!(document) }
      assert_empty admissions
      changed = document.merge("prepared_bundle" => document.fetch("prepared_bundle").merge(
        "bytes" => 14, "sha256" => Digest::SHA256.hexdigest("invalid bundle")))
      assert_raises(Ace::Overseer::Error) { @owner.verify_fresh!(changed) }
      assert_equal 1, admissions.size
      File.binwrite(path, @artifact.bundle)
      assert_equal @artifact.bundle, @owner.verify_fresh!(document)
      assert_equal 1, admissions.size # failed admission cannot replace the proof
    end
  end

  def test_recovery_keeps_document_when_local_bundle_is_missing_or_changed
    document = publish
    path = File.join(@root, "invocation.prepared.bundle")
    File.binwrite(path, "changed")
    assert_equal "mismatch", @owner.bundle_availability(document)
    assert_raises(Ace::Overseer::Error) { @owner.verify_fresh!(document) }
    File.unlink(path)
    recovered = @owner.load(File.join(@root, "invocation.json"))
    assert_equal document, recovered
    assert_equal "unavailable", @owner.bundle_availability(recovered)
    assert_raises(Errno::ENOENT) { @owner.verify_fresh!(recovered) }
    refute File.exist?(path)
    assert_raises(Ace::Overseer::Error) { publish }
    refute File.exist?(path)
  end

  def test_association_refusal_before_any_publication
    [ {project_id: "other"}, {task_id: "other"}, {mutation_id: "x" * 117},
      {prepared: @prepared.merge("bundle" => "wrong")}, {prepared: @prepared.merge("scope" => "011")} ].each do |changes|
      assert_raises(Ace::Overseer::Error) { publish(**changes) }
      assert_empty Dir.children(@root)
    end
  end

  def test_interrupted_publication_leaves_only_unselected_orphan
    original = @owner.method(:write_exclusive)
    @owner.define_singleton_method(:write_exclusive) do |path, bytes|
      raise Errno::EIO, "injected request publication fault" if path.end_with?(".json")
      original.call(path, bytes)
    end
    assert_raises(Ace::Overseer::Error) { publish }
    assert_equal ["invocation.prepared.bundle"], Dir.children(@root)
    assert_raises(Ace::Overseer::Error) { @owner.load(File.join(@root, "invocation.json")) }
    assert_equal @artifact.bundle, File.binread(File.join(@root, "invocation.prepared.bundle"))
  end

  def test_definition_sidecar_tamper_missing_and_collision_never_rebuild
    document = publish
    path = @owner.definition_path(document)
    assert_equal @artifact.definition_bytes, File.binread(path)
    assert_equal "available", @owner.definition_availability(document)
    File.binwrite(path, "changed")
    assert_equal "mismatch", @owner.definition_availability(document)
    assert_raises(Ace::Overseer::Error) { @owner.verify_fresh!(document) }
    File.unlink(path)
    assert_equal "unavailable", @owner.definition_availability(document)
    assert_equal document, @owner.load(File.join(@root, "invocation.json"))
    assert_raises(Ace::Overseer::Error) { publish }
    refute File.exist?(path)
  end

  def test_held_private_file_and_closed_document_refusals
    document = publish
    path = File.join(@root, "invocation.json")
    File.chmod(0644, path)
    assert_raises(Ace::Overseer::Error) { @owner.load(path) }
    File.chmod(0600, path)
    File.binwrite(path, JSON.generate(document.merge("version" => 1.0)))
    assert_raises(Ace::Overseer::Error) { @owner.load(path) }
    File.binwrite(path, '{"version":1,"version":1}')
    assert_raises(Ace::Overseer::Error) { @owner.load(path) }
    File.unlink(path)
    File.symlink(File.join(@root, "invocation.prepared.bundle"), path)
    assert_raises(Ace::Overseer::Error) { @owner.load(path) }
  end
end
