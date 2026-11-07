# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/hitl/molecules/event_observation"

class EventObservationTest < AceHitlTestCase
  def test_observation_distinguishes_uncreated_and_unavailable_roots
    with_hitl_dir do |parent|
      root = File.join(parent, "events")
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      observer = Ace::Hitl::Molecules::EventObservation.new(manager: manager)

      assert_empty observer.call.fetch("events")
      File.write(root, "not a directory")
      assert_raises(Errno::ENOTDIR) { observer.call }
      File.unlink(root)

      File.symlink(File.join(parent, "unavailable"), root)
      assert_raises(Errno::ENOENT) { observer.call }
      File.unlink(root)

      target = File.join(parent, "target")
      Dir.mkdir(target)
      File.symlink(target, root)
      assert_empty observer.call.fetch("events")

      Dir.rmdir(target)
      File.write(target, "not a directory")
      assert_raises(Errno::ENOTDIR) { observer.call }
    end
  end

  def test_observation_refuses_an_unreadable_store
    skip "root bypasses store permissions" if Process.euid.zero?

    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      observer = Ace::Hitl::Molecules::EventObservation.new(manager: manager)
      original_mode = File.stat(root).mode & 0o777
      File.chmod(0, root)
      assert_raises(Errno::EACCES) { observer.call }
    ensure
      File.chmod(original_mode, root) if original_mode
    end
  end

  def test_semantic_changes_ignore_poll_delivery_metadata_and_mtime_but_keep_answer
    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      event = manager.create("Decision", questions: ["Proceed?"])
      observer = Ace::Hitl::Molecules::EventObservation.new(manager: manager)
      first = observer.call
      File.utime(Time.now + 60, Time.now + 60, event.file_path)
      manager.update(event.id, set: {"delivery.captain.attempted_at" => Time.now.utc.iso8601, "waiter_last_seen_at" => "later"})
      assert_equal first, observer.call
      manager.accept_answer(event.id, answer: "private-test-answer")
      changed = observer.call
      refute_equal first["events"][0]["revision"], changed["events"][0]["revision"]
      refute_includes JSON.generate(changed), "private-test-answer"
      assert_equal changed, observer.call
      manager.create("New report", type: "report", result: "success")
      assert_raises(ArgumentError) { observer.call(limit: 1) }
      assert_equal 2, observer.call["events"].size
    end
  end
  def test_nested_same_size_content_change_with_preserved_mtime_and_report_step_revision
    with_hitl_dir do |root|
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: {"hitl" => {"root_dir" => root}})
      event = manager.create("Before", type: "report", result: "success")
      nested = File.join(root, "group", "nested", File.basename(event.path))
      FileUtils.mkdir_p(File.dirname(nested))
      FileUtils.mv(event.path, nested)
      file = Dir.glob(File.join(nested, "*.md")).first
      observer = Ace::Hitl::Molecules::EventObservation.new(manager: manager)
      first = observer.call
      timestamp = File.mtime(file)
      File.write(file, File.read(file).gsub("Before", "After!"))
      File.utime(timestamp, timestamp, file)
      second = observer.call
      assert_equal first["events"][0]["key"], second["events"][0]["key"]
      refute_equal first["events"][0]["revision"], second["events"][0]["revision"]
      manager.update(event.id, set: {"step" => "review"})
      refute_equal second["events"][0]["revision"], observer.call["events"][0]["revision"]
    end
  end

  def test_owner_filter_excludes_outbound_and_other_recipients_but_keeps_actual_answers_and_instructions
    with_hitl_dir do |root|
      config = {"hitl" => {"root_dir" => root, "machine" => "lab", "recipients" => {
        "self" => {"machine" => "lab", "panel" => "w7:p1"},
        "captain" => {"machine" => "hermes", "panel" => "captain"},
        "other" => {"machine" => "lab", "panel" => "w9:p1"}}}}
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: config)
      question = manager.create("Outbound question", to: "captain", questions: ["Proceed?"])
      report = manager.create("Outbound completion", to: "captain", type: "report", result: "success")
      manager.create("Other owner's report", to: "other", type: "report", result: "success")
      observer = Ace::Hitl::Molecules::EventObservation.new(manager: manager)
      assert_empty observer.call(owner: "self")["events"]
      Dir.mktmpdir do |foreign_root|
        foreign = Ace::Hitl::Organisms::HitlManager.new(root_dir: foreign_root,
          config: {"hitl" => config["hitl"].merge("root_dir" => foreign_root)})
        foreign.create("Other project", to: "self", type: "report", result: "success")
        assert_empty observer.call(owner: "self")["events"], "unrelated project is outside current scope"
      end
      manager.update(report.id, set: {"delivery.captain.status" => "delivered"})
      assert_empty observer.call(owner: "self")["events"]
      manager.accept_answer(question.id, answer: "Yes")
      incoming = manager.create("Worker result", to: "self", type: "report", result: "success")
      instruction = manager.create("Instruction", type: "report", result: "success", tags: ["hermes-instruction"])
      assert_equal [question.id, incoming.id, instruction.id].sort, observer.call(owner: "self")["events"].map { |e| e["id"] }.sort
      assert_raises(Ace::Hitl::Molecules::HitlAddressResolver::UnknownRecipientError) { observer.call(owner: "missing") }
    end
  end

  def test_archived_publication_can_be_verified_without_reentering_live_observation
    with_hitl_dir do |root|
      config = {"hitl" => {"root_dir" => root, "machine" => "lab", "recipients" => {
        "owner" => {"machine" => "lab", "folder" => "/lab/.ace-local/hitl"},
        "other" => {"machine" => "lab", "folder" => "/lab/other/.ace-local/hitl"}}}}
      manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: root, config: config)
      event = manager.create("Completed worker", to: "owner", type: "report", result: "success",
        task: "8xh.t.aaa", assignment: "abc123", move_to: "archive")
      observer = Ace::Hitl::Molecules::EventObservation.new(manager: manager)
      assert_empty observer.call(owner: "owner")["events"]
      rows = observer.call(owner: "owner", in_folder: "all")["events"]
      assert_equal [event.id], rows.map { |row| row["id"] }
      assert_equal "8xh.t.aaa", rows.first["task"]
      assert_equal "abc123", rows.first["assignment"]
      assert_empty observer.call(owner: "other", in_folder: "all")["events"]
      with_cli_root(root, config: config) do
        response = run_cli(["observe", "--owner", "owner", "--in", "all"])
        assert_equal 0, response[:exit_code], response[:stderr]
        assert_equal [event.id], JSON.parse(response[:stdout])["events"].map { |row| row["id"] }
      end
      assert_raises(ArgumentError) { observer.call(in_folder: "invalid") }
    end
  end

end
