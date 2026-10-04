#!/usr/bin/env ruby
# frozen_string_literal: true

# Child driver for the multi-UID boundary fixture (spec 8wq.t.34i).
# The root parent forks this script after dropping the child to the
# target identity; the child performs ONE boundary operation and prints
# one JSON result line. Kept dependency-free on purpose: it requires
# only the ace-hitl load path handed in via -I.

require "socket"
require "json"
require "ace/hitl"

class OpenBinding < Ace::Hitl::Lifecycle::Binding
  def validate_request(**); end

  def require_active(**); end

  def with_active(**)
    yield
  end
end

class OpenPolicy
  def transport?(_peer, project: nil)
    true
  end

  def service_uid; end
end

socket_path = ENV.fetch("ACE_HITL_SOCKET")
service_uid = Integer(ENV.fetch("ACE_HITL_SERVICE_UID"))
op = ARGV[0]
client = Ace::Hitl::Lifecycle::Client.new(socket_path: socket_path, service_uid: service_uid)

# Classified denials are REPORTED outcomes, not crashes: the envelope
# carries the error class and message (review 8x333sqq).
begin
  result = run_op(client, op)
  puts JSON.generate({ok: true, op: op, result: result})
rescue Ace::Hitl::Lifecycle::Error => e
  puts JSON.generate({ok: false, op: op, error: e.message, error_class: e.class.name})
end

def run_op(client, op)
  case op
  when "create"
    client.create(id: ARGV[1], assignment: ARGV[2], attempt: ARGV[3], kind: "decision",
      project: "ace", harness: "agy", plan: "configure CI", question: "approve the exact change?",
      ace_hitl_id: "ace-hitl-1")
  when "forge"
    # The forged-identity probe: a payload `requester` field is not a
    # boundary parameter and must never become authority.
    client.create(id: ARGV[1], assignment: ARGV[2], attempt: ARGV[3], kind: "decision",
      project: "ace", harness: "agy", plan: "configure CI", question: "approve the exact change?",
      ace_hitl_id: "ace-hitl-1", requester: ARGV[4])
  when "deliver"
    client.deliver(ARGV[1], ARGV[2])
  when "consume"
    client.consume(ARGV[1], timeout: Integer(ARGV[2]))
  when "cancel"
    client.cancel(ARGV[1], reason: "fixture cancel")
  when "read"
    client.read(ARGV[1])
  when "pending"
    client.pending
  when "states"
    client.states
  when "directread"
    # A raw filesystem probe OUTSIDE the boundary: proves the store's
    # OS-level isolation from a foreign identity. A DENIAL is the
    # expected, reported outcome — same top-level envelope as the
    # boundary operations (review 8x32r9ay).
    begin
      {content: File.read(ARGV[1])}
    rescue SystemCallError => e
      raise Ace::Hitl::Lifecycle::TransportError, "fs-denied:#{e.class.name}:#{e.errno}"
    end
  when "peekmode"
    begin
      stat = File.lstat(ARGV[1])
      {ok: true, mode: (stat.mode & 0o777), uid: stat.uid}
    rescue SystemCallError => e
      {ok: false, error: e.class.name}
    end
  else
    raise "unknown child op: #{op}"
  end
end
