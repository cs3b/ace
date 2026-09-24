# frozen_string_literal: true

# The generic HITL request lifecycle (spec 8wm.t.y21): provider-agnostic
# request store, kinds/secrets gates, public projection, effect layer,
# duty projection, and the Overseer reverse-address surface. Lab coupling
# lives only in the provider=lab seams (binding policy, store factory).
require_relative "lifecycle/errors"
require_relative "lifecycle/identity"
require_relative "lifecycle/atomic_json"
require_relative "lifecycle/kinds"
require_relative "lifecycle/binding"
require_relative "lifecycle/effects"
require_relative "lifecycle/store"
require_relative "lifecycle/duty"
require_relative "lifecycle/overseer"
