# frozen_string_literal: true
require_relative "deployment_test"

module Ace
  module Assign
    class ProtectedPosixAclTest < AceAssignTestCase
      Stat = Struct.new(:uid, :gid, :mode)

      def search(rows, uid: 13005, groups: [13005], owner: 0, gid: 13003, mode: 0o750)
        acl = Authority::PosixAcl.new
        acl.define_singleton_method(:entries) { |_path| rows }
        acl.searchable?("/fixture", stat: Stat.new(owner, gid, mode), uid: uid, groups: groups)
      end

      def base
        [[1, 7, 0xffffffff], [4, 5, 0xffffffff], [32, 0, 0xffffffff]]
      end

      def test_mode_only_executor_cannot_use_authority_group_access
        refute search(nil)
        assert search(nil, groups: [13003])
        assert search(nil, owner: 13005, mode: 0o700)
        refute search(nil, owner: 13005, mode: 0o071)
      end

      def test_named_uid_precedes_group_and_other_and_is_masked
        rows = base + [[2, 0, 13005], [16, 7, 0xffffffff]]
        refute search(rows, groups: [13003])
        rows[3][1] = 1
        assert search(rows)
        rows[4][1] = 6
        refute search(rows)
        assert search(rows, owner: 13005) # Owner entry is not masked.
      end

      def test_matching_groups_are_masked_and_do_not_fall_through_to_other
        rows = base + [[8, 1, 13006], [16, 7, 0xffffffff]]
        assert search(rows, groups: [13005, 13006])
        rows[4][1] = 6
        refute search(rows, groups: [13005, 13006])
        rows[2][1] = 1
        refute search(rows, groups: [13003])
        assert search(rows, groups: [13005])
      end

      def test_malformed_access_acl_refuses_instead_of_mode_fallback
        acl = Authority::PosixAcl.new
        [[], base + [[2, 1, 13005]], base + [[1, 7, 0xffffffff]],
         base + [[16, 8, 0xffffffff]], base + [[2, 1, 13005], [2, 1, 13005], [16, 7, 0xffffffff]]].each do |rows|
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { acl.send(:validate!, rows) }
        end
      end
    end
  end
end
