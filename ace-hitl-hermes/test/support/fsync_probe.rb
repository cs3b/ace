# frozen_string_literal: true

# Observe real filesystem barriers without replacing their implementation.
# Thread-local scope prevents probes from leaking into another test or service.
module HermesFsyncProbe
  KEY = :ace_hermes_fsync_probe
  module Instrumentation
    def fsync
      probe = Thread.current[HermesFsyncProbe::KEY]
      if probe
        probe.fetch(:calls) << {path: path, directory: stat.directory?}
        raise Errno::EIO, "injected directory fsync failure" if path == probe[:failure_path]
      end
      super
    end
  end
  File.prepend(Instrumentation)

  def self.observe(calls:, failure_path: nil)
    previous = Thread.current[KEY]
    Thread.current[KEY] = {calls: calls, failure_path: failure_path}
    yield
  ensure
    Thread.current[KEY] = previous
  end
end
