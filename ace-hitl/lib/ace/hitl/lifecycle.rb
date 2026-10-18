# frozen_string_literal: true

# The generic HITL request lifecycle (spec 8wm.t.y21, scoped by
# 8wq.t.34i): provider-agnostic request store behind an authenticated
# scoped boundary (peer-credential service, bounded protocol, transport
# policy), kinds/secrets gates with transient OTP, public projection,
# effect layer, and duty projection. Lab coupling lives only in the
# provider=lab seams (binding policy, store factory, grants deployment).
require_relative "lifecycle/errors"
require_relative "lifecycle/identity"
require_relative "lifecycle/peer"
require_relative "lifecycle/policy"
require_relative "lifecycle/atomic_json"
require_relative "lifecycle/kinds"
require_relative "lifecycle/binding"
require_relative "lifecycle/effects"
require_relative "lifecycle/otp_vault"
require_relative "lifecycle/store"
require_relative "lifecycle/protocol"
require_relative "lifecycle/tls_credentials"
require_relative "lifecycle/credential_path_policy"
require_relative "lifecycle/tls_material"
require_relative "lifecycle/remote_peer"
require_relative "lifecycle/tls_access_policy"
require_relative "lifecycle/frame_serving"
require_relative "lifecycle/tls_project_scope"
require_relative "lifecycle/frame_exchange"
require_relative "lifecycle/lifecycle_requests"
require_relative "lifecycle/client"
require_relative "lifecycle/service"
require_relative "lifecycle/tls_service"
require_relative "lifecycle/tls_authority"
require_relative "lifecycle/duty"
