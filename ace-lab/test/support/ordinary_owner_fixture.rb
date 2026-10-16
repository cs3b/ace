# frozen_string_literal: true

module OrdinaryOwnerFixture
  def ordinary_owner_document(peer:, socket_path: "/run/ace/atlas/native.sock", socket_identity: [1, 2, 0])
    {"version" => 1, "projects" => {"atlas" => {
      "service" => {"uid" => 41000, "gid" => 41000, "socket_path" => "/run/ace/atlas/assign.sock", "state_root" => "/var/lib/ace/state"},
      "journal" => {"repository" => "/var/lib/ace/journal", "ref" => "refs/ace/execution", "checkout_root" => "/var/lib/ace/state/checkout"},
      "assignment_root" => "/var/lib/ace/state/assignments", "lifecycle_root" => "/var/lib/ace/state/lifecycle",
      "runtime_binary" => "/usr/local/bin/herdr", "participants" => {"41001" => {"gid" => 41001, "actor" => "atlas-worker",
        "supervisor_panes" => ["w1:pS"], "runtime" => "herdr", "workspace" => "w1"}},
      "worktrees" => {"root" => "/lab/projects/atlas/.ace-wt", "common_dir" => "/lab/projects/atlas/.git"},
      "native" => {"socket_path" => socket_path, "socket_identity" => socket_identity,
        "server_identity" => peer, "version" => "0.9.1", "protocol" => 22}
    }}}
  end
end
