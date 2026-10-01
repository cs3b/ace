# frozen_string_literal: true

require "ace/herdr"
require "ace/runtime"

Ace::Runtime.register(:herdr, -> { Ace::Herdr::Organisms::RuntimeAdapter.new })
