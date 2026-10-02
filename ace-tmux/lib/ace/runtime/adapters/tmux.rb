# frozen_string_literal: true

require "ace/tmux"

Ace::Runtime.register(:tmux, -> { Ace::Tmux::RuntimeAdapter.new })
