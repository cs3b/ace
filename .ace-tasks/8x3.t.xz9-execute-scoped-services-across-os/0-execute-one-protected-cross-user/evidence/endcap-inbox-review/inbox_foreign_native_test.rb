require_relative "../../ace-assign/test/feat/endcap_inboxes_test"
class InboxForeignNativeTest < Ace::Assign::EndcapInboxesTest
  def test_consumed_local_binding_must_match_canonical_native_workspace
    fixture do
      store = Ace::Herdr::Molecules::DeliveryRecordStore
      path = store.path_for(@context.fetch("deliveries_dir"), "event")
      record = JSON.parse(File.read(path))
      record.fetch("inbox").fetch("binding")["session"] = "foreign-workspace"
      File.write(path, JSON.generate(record))
      receipt = JSON.parse(@bytes)
      receipt.fetch("binding")["session"] = "foreign-workspace"
      @bytes = JSON.generate(receipt)
      @signature = @key.sign(OpenSSL::Digest::SHA256.new, @bytes)
      @params = @params.merge("receipt_sha256" => Digest::SHA256.hexdigest(@bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature))
      assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { reconcile }
    end
  end
end
