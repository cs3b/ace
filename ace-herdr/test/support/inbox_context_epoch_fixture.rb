# frozen_string_literal: true

module InboxContextEpochFixture
  # Controlled service lifetime only, never canonical no-writer evidence.
  def context_owner_epoch
    boot = "00000000-0000-0000-0000-000000000001"
    {"schema" => "ace.herdr.inbox-owner-epoch/v1", "installation_sha256" => "a" * 64, "boot_id" => boot,
      "service_unit" => "ace-context.service", "service_invocation_id" => "b" * 32,
      "cgroup_identity" => {"path" => "/sys/fs/cgroup/ace-context.service", "mount_id" => 1, "filesystem_type" => "cgroup2", "device" => 2, "inode" => 3},
      "process_identity" => {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort.uniq,
        "pid" => Process.pid, "parent_pid" => Process.ppid, "host" => "controlled", "started_at" => "linux:#{boot}:42"}}
  end
end
