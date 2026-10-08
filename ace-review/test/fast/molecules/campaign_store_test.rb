# frozen_string_literal: true
require "test_helper"
require "ace/review/molecules/campaign_store"

class CampaignStoreTest < AceReviewTest
  Store = Ace::Review::Molecules::CampaignStore

  def record
    {"id" => "abcdef", "subject" => {"repository" => "local:/repo", "local_candidate_id" => "candidate"},
      "contract_identity" => Digest::SHA256.hexdigest("requirements"), "contract" => "requirements",
      "policy" => {"revision" => "v1", "minimum_rounds" => 3, "clean_rounds" => 2,
        "required_scopes" => ["full"], "required_checks" => ["tests"]}, "inherited_findings" => [], "assessments" => [], "attempts" => [], "rounds" => [],
      "head_transitions" => [], "profile" => "delivery",
      "bounds" => {"minimum_rounds" => 3, "clean_rounds" => 2, "maximum_rounds" => 5},
      "phases" => [{"id" => "initial", "profile" => "delivery", "round_start" => 0, "maximum_rounds" => 5}],
      "execution_attempts" => []}
  end

  def test_atomic_roundtrip_restart_and_corruption
    root = File.join(@test_dir, "campaigns")
    store = Store.new(root: root)
    store.transaction { store.write(record) }
    assert_equal record, Store.new(root: root).read("abcdef")
    content = JSON.parse(File.read(store.path("abcdef")))
    content["record"]["rounds"] << {"fabricated" => true}
    File.write(store.path("abcdef"), JSON.generate(content))
    assert_raises(ArgumentError) { store.read("abcdef") }
    assert_raises(ArgumentError) { store.read("unknown") }
    malformed = record.merge("rounds" => "corrupt")
    store.transaction { store.write(malformed) }
    assert_raises(ArgumentError) { store.read("abcdef") }
    noncanonical = record.merge("subject" => {"repository" => "https://github.com/Owner/Repo/", "pr" => "Owner/Repo#42"})
    assert_raises(ArgumentError) { store.transaction { store.write(noncanonical) } }
  end

  def test_dry_run_does_not_create_storage
    root = File.join(@test_dir, "absent")
    Store.new(root: root).transaction(dry_run: true) { assert true }
    refute File.exist?(root)
  end

  def test_concurrent_mutations_serialize_without_lost_records
    store = Store.new(root: File.join(@test_dir, "campaigns"))
    store.transaction { store.write(record) }
    threads = 8.times.map do |i|
      Thread.new do
        store.transaction do
          value = store.read("abcdef")
          value["head_transitions"] << {"head" => i.to_s.rjust(40, "0"), "base" => "b" * 40}
          store.write(value)
        end
      end
    end
    threads.each(&:value)
    assert_equal (0..7).to_a, store.read("abcdef")["head_transitions"].map { |entry| entry["head"].to_i }.sort
  end
  def test_missing_record_and_index_preserve_history_failure
    store = Store.new(root: File.join(@test_dir, "campaigns"))
    store.transaction { store.write(record) }
    File.delete(store.path("abcdef"))
    error = assert_raises(ArgumentError) { store.records(subject: record["subject"]) }
    assert_match(/indexed campaign.*unavailable/, error.message)
    store.transaction { store.write(record) }
    assert_equal [record], store.records(subject: record["subject"])
    File.delete(File.join(store.root, ".identity-index.json"))
    assert_raises(ArgumentError) { store.records(subject: record["subject"]) }
    assert_raises(ArgumentError) { store.transaction { store.write(record) } }
  end

  def test_subject_lookup_does_not_read_unrelated_corrupt_or_missing_records
    store = Store.new(root: File.join(@test_dir, "campaigns"))
    other = record.merge("id" => "bcdefg", "subject" => record["subject"].merge("local_candidate_id" => "other"))
    store.transaction { store.write(record); store.write(other) }
    File.write(store.path("abcdef"), "corrupt")
    assert_equal [other], store.records(subject: other["subject"])
    assert_raises(ArgumentError) { store.records(subject: record["subject"]) }
    File.delete(store.path("abcdef"))
    assert_equal [other], store.records(subject: other["subject"])
    assert store.registered_id?("abcdef")
  end

  def test_interrupted_first_publication_retains_identity
    store = Store.new(root: File.join(@test_dir, "campaigns"))
    original = store.method(:persist)
    store.define_singleton_method(:persist) do |destination, envelope|
      raise IOError, "interrupted record write" if destination.end_with?("/abcdef.json")
      original.call(destination, envelope)
    end
    assert_raises(IOError) { store.transaction { store.write(record) } }
    assert File.file?(File.join(store.root, ".identity-index.json"))
    restarted = Store.new(root: store.root)
    assert_raises(ArgumentError) { restarted.records(subject: record["subject"]) }
    assert restarted.registered_id?("abcdef")
  end

  def test_corrupt_index_and_unregistered_records_fail_closed
    store = Store.new(root: File.join(@test_dir, "campaigns"))
    store.transaction { store.write(record) }
    path = File.join(store.root, ".identity-index.json")
    trusted = File.read(path)
    envelope = JSON.parse(trusted)
    envelope["index"]["version"] = 2
    File.write(path, JSON.generate(envelope))
    assert_raises(ArgumentError) { store.read("abcdef") }
    envelope["sha256"] = Ace::Review::Atoms::CampaignContract.digest(envelope["index"])
    File.write(path, JSON.generate(envelope))
    assert_raises(ArgumentError) { store.read("abcdef") }
    File.write(path, trusted)
    File.write(store.path("bcdefg"), File.read(store.path("abcdef")))
    assert_raises(ArgumentError) { store.records(subject: record["subject"]) }
  end

end
