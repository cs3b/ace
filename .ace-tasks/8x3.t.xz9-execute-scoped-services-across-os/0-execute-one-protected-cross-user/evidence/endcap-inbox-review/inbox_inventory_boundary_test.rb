require_relative "../../ace-assign/test/feat/endcap_inboxes_test"
class InboxInventoryBoundaryTest < Ace::Assign::EndcapInboxesTest
  def test_corrupt_archive_cannot_hide_behind_live_record
    fixture do
      reconcile
      dir = Ace::Herdr::Molecules::DeliveryRecordStore.archive_dir(@context.fetch("deliveries_dir"))
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "event.json"), "corrupt")
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { settlement }
    end
  end
end
