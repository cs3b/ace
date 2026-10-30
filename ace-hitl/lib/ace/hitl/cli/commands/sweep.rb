# frozen_string_literal: true

require "json"

module Ace
  module Hitl
    module CLI
      module Commands
        # `ace-hitl sweep [--apply]` (task 8xs.t.pu0.6): qualify transport
        # leftovers against the CANONICAL case files, list-first. The
        # only deletion candidates are ask-wake request files whose case
        # is terminally closed or cancelled; active cases (pending /
        # received / applied), unknown ids, unparseable requests and the
        # canonical decision history are always preserved. Without
        # --apply nothing is deleted.
        class Sweep < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "List (and with --apply, remove) transport leftovers of terminally closed cases"

          option :apply, type: :boolean, default: false,
            desc: "Remove the qualified leftovers (default: list only)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(apply: false, **)
            report = Ace::Hitl::Organisms::HitlManager.new.sweep(apply: apply)
            puts JSON.pretty_generate(report)
          rescue Ace::Hitl::Organisms::HitlManager::Error => e
            raise Ace::Support::Cli::Error.new(e.message)
          end
        end
      end
    end
  end
end
