# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/campaign_round_transfer"
require "etc"

class CampaignRoundTransferTest < AceAssignTestCase
  Transfer = Ace::Assign::Authority::CampaignRoundTransfer
  Input = Struct.new(:parts) do
    def count = parts.length
    def bytes(index:) = parts.fetch(index)
  end

  def envelope(path: "session/metadata.yml")
    {"version" => 1, "round" => {"attempt_id" => "round-request", "head" => "a" * 40},
      "artifacts" => [{"path" => path, "sha256" => Digest::SHA256.hexdigest("canonical bytes")}]}
  end

  def decode(value)
    bytes = JSON.generate(value)
    Transfer.decode(input: Input.new([bytes, "canonical bytes"]), sha256: Digest::SHA256.hexdigest(bytes))
  end

  def test_closed_bounded_frame_and_private_materialization_exact_replay
    admitted = decode(envelope)
    Dir.mktmpdir("campaign-round-", File.realpath(Etc.getpwuid(Process.uid).dir)) do |repository|
      paths = Transfer.materialize(admitted: admitted, repository: repository, request_id: "stable")
      assert paths.frozen?
      path = paths.fetch("session/metadata.yml")
      assert_equal "canonical bytes", File.binread(path)
      assert_equal 0o600, File.stat(path).mode & 0o777
      assert_equal paths, Transfer.materialize(admitted: admitted, repository: repository, request_id: "stable")
      File.binwrite(path, "replacement")
      assert_raises(Ace::Assign::AttemptErrors::Conflict) {
        Transfer.materialize(admitted: admitted, repository: repository, request_id: "stable")
      }
    end
  end

  def test_unknown_duplicate_and_unsafe_materialization_names_refuse
    [envelope.merge("extra" => true), envelope.merge("version" => 1.0),
      envelope(path: "/authority/path"), envelope(path: "../outside"), envelope(path: "session//file")].each do |value|
      assert_raises(ArgumentError) { decode(value) }
    end
    bytes = '{"version":1,"version":1,"round":{},"artifacts":[]}'
    assert_raises(ArgumentError) { Transfer.decode(input: Input.new([bytes]), sha256: Digest::SHA256.hexdigest(bytes)) }
    bytes = JSON.generate(envelope)
    assert_raises(Ace::Assign::AttemptErrors::ReceiptRejected) {
      Transfer.decode(input: Input.new([bytes, "different bytes"]), sha256: Digest::SHA256.hexdigest(bytes))
    }
  end
end
