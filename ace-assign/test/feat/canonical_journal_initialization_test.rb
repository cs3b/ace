# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"

module Ace
  module Assign
    class CanonicalJournalInitializationTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      def test_cold_journal_owner_initializes_without_warmed_authority_loader
        fixture do
          code = <<~'RUBY'
            raise "fresh child unexpectedly warmed Pathname" if defined?(Pathname)
            require "ace/assign/molecules/evidence_journal"
            journal = Ace::Assign::Molecules::EvidenceJournal.new(repo_root: ARGV.fetch(0), ref: ARGV.fetch(1), checkout_root: ARGV.fetch(2))
            commit = journal.initialize_canonical!(owner_uid: Process.uid, owner_gid: Process.gid, owner_groups: Process.groups)
            raise "fresh initializer changed canonical ref" unless commit == journal.ref_value
            STDOUT.write(commit)
          RUBY
          argv = [RbConfig.ruby, "--disable=gems,rubyopt"]
          $LOAD_PATH.each { |path| argv.concat(["-I", path]) }
          argv.concat(["-e", code, @journal.repo_root, @journal.ref, @journal.checkout_root])
          before = @journal.ref_value
          stdout, stderr, status = Open3.capture3({"RUBYOPT" => nil}, *argv)
          assert status.success?, stderr
          assert_equal before, stdout
          assert_equal before, @journal.ref_value
        end
      end

      def test_canonical_initialization_preserves_actual_registration_prepared_bundle_and_result_import
        fixture do
          before = @journal.ref_value
          assert_equal before, @journal.initialize_canonical!(owner_uid: Process.uid, owner_gid: Process.gid, owner_groups: Process.groups)
          data = submit.fetch(:data)
          completed = @journal.ref_value
          assert_equal completed, @journal.initialize_canonical!(owner_uid: Process.uid, owner_gid: Process.gid, owner_groups: Process.groups)
          assert_equal completed, @journal.ref_value
          assert_equal "first\x00\r\n".b, fetch(data).fetch(:transfer_parts).first
          assert_equal "second evidence", fetch(data, 1).fetch(:transfer_parts).first
          assert_equal completed, @journal.ref_value
        end
      end

    end
  end
end
