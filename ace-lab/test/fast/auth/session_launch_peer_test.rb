# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/session_launch_peer"

module Ace
  module Lab
    module Auth
      class SessionLaunchPeerTest < Minitest::Test
        Account = Struct.new(:uid, :gid, :name)

        def setup
          @lifetime, @alive = IO.pipe
          @selection = Object.new
          @requests = []
          @configuration = Object.new
          selection, requests = @selection, @requests
          @configuration.define_singleton_method(:resolve) { |**args| requests << args; selection }
        end

        def teardown
          [@lifetime, @alive].each { |io| io.close unless io.closed? }
        end

        def socket(uid: 1001, gid: uid)
          lifetime = @lifetime
          Object.new.tap do |socket|
            socket.define_singleton_method(:getsockopt) do |_level, option|
              case option
              when SessionPeer::SO_PEERPIDFD
                handle = lifetime.dup
                handle.autoclose = false
                Struct.new(:int).new(handle.fileno)
              when SessionLaunchPeer::SO_PEERCRED
                Struct.new(:data).new([123, uid, gid].pack("i!3"))
              else raise "unexpected socket option"
              end
            end
          end
        end

        def test_host_principal_comes_from_peer_account_and_lifetime_is_closed
          peer = SessionLaunchPeer.new(configuration: @configuration, account: ->(uid) { Account.new(uid, uid, "mo") })
          yielded_handle = nil
          peer.with_selection(socket, project: "ace", role: "worker", terminal_id: "term_abcdef") do |selection, handle|
            assert_same @selection, selection
            refute handle.closed?
            yielded_handle = handle
          end
          assert yielded_handle.closed?
          assert_equal [{project: "ace", role: "worker", principal: "mo"}], @requests
        end

        def test_dynamic_caller_cannot_be_reinterpreted_as_host_principal
          sessions = Object.new
          sessions.define_singleton_method(:authenticate) { |_| raise Error, "invalid session" }
          peer = SessionLaunchPeer.new(configuration: @configuration, sessions: sessions,
            account: ->(*) { raise "dynamic identity reached host lookup" })
          assert_raises(Error) { peer.with_selection(socket(uid: 62_000), project: "ace", role: "worker") { flunk } }
          assert_empty @requests
        end

        def test_dynamic_session_cannot_supply_a_native_terminal_binding
          peer = SessionLaunchPeer.new(configuration: @configuration,
            account: ->(*) { flunk "host account lookup" })
          assert_raises(Error) do
            peer.with_selection(socket(uid: 62_000), project: "ace", role: "worker", terminal_id: "term_abcdef") { flunk }
          end
          assert_empty @requests
        end

        def test_session_authority_is_passed_and_closed
          sessions = Object.new
          identity = Object.new
          closed = false
          identity.define_singleton_method(:close) { closed = true }
          sessions.define_singleton_method(:authenticate) { |_| identity }
          peer = SessionLaunchPeer.new(configuration: @configuration, sessions: sessions)
          peer.with_selection(socket(uid: 62_000), project: "ace", role: "worker") { |selection, _| assert_same @selection, selection }
          assert_equal [{project: "ace", role: "worker", session: identity}], @requests
          assert closed
        end

        def test_dead_peer_and_mismatched_host_group_refuse_before_selection
          peer = SessionLaunchPeer.new(configuration: @configuration, account: ->(uid) { Account.new(uid, uid, "mo") })
          assert_raises(Error) { peer.with_selection(socket(gid: 1002), project: "ace", role: "worker") { flunk } }
          @alive.close
          assert_raises(Error) { peer.with_selection(socket, project: "ace", role: "worker") { flunk } }
          assert_empty @requests
        end
      end
    end
  end
end
