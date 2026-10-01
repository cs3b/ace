# frozen_string_literal: true
require "test_helper"
require "ace/review/molecules/campaign_store"

class CampaignStoreTest < AceReviewTest
  Store = Ace::Review::Molecules::CampaignStore

  def record
    {"id" => "abcdef", "subject" => {}, "contract_identity" => "digest", "contract" => "requirements",
      "policy" => {}, "inherited_findings" => [], "assessments" => [], "attempts" => [], "rounds" => [],
      "head_transitions" => []}
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
          value["attempts"] << i
          store.write(value)
        end
      end
    end
    threads.each(&:value)
    assert_equal (0..7).to_a, store.read("abcdef")["attempts"].sort
  end
end
