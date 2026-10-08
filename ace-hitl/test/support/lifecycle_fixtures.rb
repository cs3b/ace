# frozen_string_literal: true

require "test_helper"

module LifecycleFixtures
  # The identity fixture: the unprivileged developer run keeps real
  # uid/gid arithmetic (chown targets map onto the current identity, so
  # the real ownership calls run without EPERM), while username/euid are
  # pinned exactly as production requests are pinned in the ported
  # Python suite. Named foreign identities get distinct, real-looking
  # ids so ownership transitions are observable.
  class TestIdentity
    def initialize(username: "lab-admin", root: false, euid: Process.euid,
      foreign_ids: {"mo" => [1234, 1234]}, group_ids: {"lab-control" => 966})
      @username = username
      @root = root
      @euid = euid
      @foreign_ids = foreign_ids
      @group_ids = group_ids
    end

    attr_reader :username, :euid

    def pid
      Process.pid
    end

    def root?
      @root
    end

    def uid
      Process.uid
    end

    def gid
      Process.gid
    end

    def user_ids(name)
      @foreign_ids.fetch(name, [Process.uid, Process.gid])
    end

    def group_id(name)
      @group_ids.fetch(name, Process.gid)
    end
  end

  # The binding seam fixture: records every query and fails on demand,
  # exactly like the ported suite's binding scenarios. Subclasses the
  # real seam so transition scoping (with_active) behaves like
  # production.
  class TestBinding < Ace::Hitl::Lifecycle::Binding
    attr_reader :validations, :activations

    def initialize(on_validate: nil, on_active: nil, reverse: nil)
      @on_validate = on_validate
      @on_active = on_active
      @validations = []
      @activations = []
      @reverse = reverse
    end

    def validate_request(assignment:, attempt:, project:, requester:, caller_pid: nil)
      @validations << {assignment: assignment, attempt: attempt, project: project, requester: requester}
      callback(**binding_kwargs(assignment, attempt, project, requester), &@on_validate) if @on_validate
      @reverse
    end

    def with_active(assignment:, attempt:, project: nil, requester: nil)
      @activations << {assignment: assignment, attempt: attempt}
      callback(**binding_kwargs(assignment, attempt, project, requester).slice(:assignment, :attempt), &@on_active) if @on_active
      yield
    end

    def reverse_address(assignment:, attempt:, project:, caller_pid:)
      @reverse
    end

    private

    # Callback fixtures observe only the authority fields they declare.
    def callback(**kwargs, &block)
      arity_safe = block.parameters.map { |_kind, name| name }
      block.call(**kwargs.slice(*arity_safe))
    end

    def binding_kwargs(assignment, attempt, project, requester)
      {assignment: assignment, attempt: attempt, project: project, requester: requester}
    end
  end

  # The ownership strategy fixture: real chmod/rename behavior with the
  # chown(2) transitions recorded for exact assertions.
  class RecordingOwnership
    attr_reader :transitions

    def initialize
      @transitions = []
    end

    def chown(path, ownership)
      @transitions << [path.to_s, ownership&.uid, ownership&.gid] if ownership
      nil
    end
  end

  # The boundary access-policy fixture: the configured transport is
  # allowed for broker-side scenarios; requester operations never
  # consult it.
  class AllowTransportPolicy
    def transport?(_peer, project: nil)
      true
    end

    def service_uid; end
  end


  # The boundary access-policy fixture that grants nothing: proves the
  # transport operations fail closed without configured authority.
  class DenyTransportPolicy
    def transport?(_peer, project: nil)
      false
    end

    def service_uid; end
  end

  def unprivileged_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: false)
  end

  def root_identity(name = "lab-admin")
    LifecycleFixtures::TestIdentity.new(username: name, root: true)
  end

  def make_store(root:, identity: nil, binding: nil, ownership: nil, poll_seconds: 1, policy: nil,
    vault: :file)
    Ace::Hitl::Lifecycle::Store.new(
      root: root,
      binding: binding || LifecycleFixtures::TestBinding.new,
      identity: identity || LifecycleFixtures::TestIdentity.new,
      # Like the ported suite's global chown fixture: real chmod/rename
      # behavior, ownership transitions recorded instead of executed, so
      # named foreign identities never hit EPERM in an unprivileged run.
      ownership: ownership || LifecycleFixtures::RecordingOwnership.new,
      policy: policy || LifecycleFixtures::AllowTransportPolicy.new,
      poll_seconds: poll_seconds,
      vault: vault
    )
  end

  def request_args(id: "hitl001", assignment: "assign500", attempt: "attempt500", kind: "decision",
    project: "ace", harness: "agy", plan: "configure CI", question: "approve the exact change?",
    options: [], ace_hitl_id: "ace-hitl-1", effect: nil, otp: nil)
    {
      id: id, assignment: assignment, attempt: attempt, kind: kind, project: project,
      harness: harness, plan: plan, question: question, options: options,
      ace_hitl_id: ace_hitl_id, effect: effect, otp: otp
    }.compact
  end

  # A structurally valid, non-secret OTP challenge: the OTP-required
  # publisher result evidence bound to one authorized operation.
  def otp_context(operation: "gem-push", expires_in: 3600, result_ref: "publisher-result-otp-required",
    input_digest: "b" * 64)
    {
      operation: operation,
      result_ref: result_ref,
      input_digest: input_digest,
      expires_at: Time.now.to_i + expires_in
    }
  end

  def stdin_reader(answer)
    ->(limit) { answer[0, limit] }
  end

  def with_lifecycle_root
    Dir.mktmpdir("ace-hitl-lifecycle") do |tmp|
      %w[requests secrets answers public effects].each do |dir|
        FileUtils.mkdir_p(File.join(tmp, dir))
      end
      FileUtils.mkdir_p(File.join(tmp, "outbox"))
      yield tmp
    end
  end
end
