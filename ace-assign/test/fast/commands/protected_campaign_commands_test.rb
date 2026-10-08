# frozen_string_literal: true
require_relative "../../test_helper"

module Ace
  module Assign
    class ProtectedCampaignCommandsTest < AceAssignTestCase
      def test_registered_round_and_export_preserve_selectors_and_exact_bytes
        Dir.mktmpdir("campaign-command-") do |root|
          artifact = File.join(root, "report")
          File.binwrite(artifact, "report bytes")
          input = File.join(root, "round.json")
          round = {"attempt_id" => "stable", "head" => "a" * 40}
          File.binwrite(input, JSON.generate("version" => 1, "round" => round,
            "artifacts" => [{"path" => "report.md", "sha256" => Digest::SHA256.hexdigest("report bytes")}]))
          output = File.join(root, "result.json")
          bytes = JSON.generate("schema" => "ace.review.accepted-result/v1")
          calls = []
          client = Object.new
          client.define_singleton_method(:call) do |operation, params, **options|
            calls << [operation, params, options]
            if operation == "campaign_export_result"
              Struct.new(:data, :parts).new(params.slice("head", "candidate_generation").merge(
                "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)), [bytes])
            else
              Struct.new(:data).new({"replayed" => false})
            end
          end
          context = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
          context.define_singleton_method(:protected_participant?) { true }
          context.define_singleton_method(:client) { |**_| client }
          common = ["--mapping", "mapping", "--assignment", "parent", "--attempt", "attempt",
            "--head", "a" * 40, "--candidate-generation", "2"]
          Authority::ProtectedAssignmentContext.stub(:load, context) do
            capture_io { assert_equal 0, CLI.start(["campaign-record-round", *common, "--mutation", "stable", "--input", input, "--artifact", artifact]) }
            assert_equal [File.binread(input), "report bytes"], calls.last.last.fetch(:upload_parts)
            assert_equal "stable", calls.last.last.fetch(:mutation_id)
            assert_equal 2, calls.last[1].fetch("candidate_generation")
            capture_io { assert_equal 0, CLI.start(["campaign-export-result", *common, "--output", output]) }
            assert_equal bytes, File.binread(output)
            assert_equal true, calls.last.last.fetch(:download)
            assert_equal :artifacts, calls.last.last.fetch(:purpose)
            capture_io { assert_equal 0, CLI.start(["campaign-export-result", *common, "--output", output]) }
            File.binwrite(output, "foreign result")
            assert_raises(Ace::Support::Cli::Error) { CLI.start(["campaign-export-result", *common, "--output", output]) }
            count = calls.length
            assert_raises(Ace::Support::Cli::Error) do
              CLI.start(["campaign-record-round", *common, "--mutation", "changed", "--input", input, "--artifact", artifact])
            end
            assert_equal count, calls.length
          end
        end
      end
    end
  end
end
