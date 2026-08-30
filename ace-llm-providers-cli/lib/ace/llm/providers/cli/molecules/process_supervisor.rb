# frozen_string_literal: true

# Linux normally reparents orphaned grandchildren to PID 1. Container
# entrypoints do not always reap them, leaving killed descendants as observable
# zombies. This supervisor becomes a child subreaper before spawning the provider
# command, so it owns and reaps the complete isolated command group before exit.
module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          module ProcessSupervisor
            PR_SET_CHILD_SUBREAPER = 36

            module_function

            def run(command)
              enable_child_subreaper
              ready_fd = Integer(ENV.delete("ACE_SAFE_CAPTURE_READY_FD"))
              command_pid = Process.spawn(*command, pgroup: true, ready_fd => :close)
              command_pgid = command_pid
              IO.for_fd(ready_fd).tap { |io| io.write("1"); io.close }

              Signal.trap("TERM") { terminate_group(command_pgid) }

              _pid, status = Process.wait2(command_pid)
              terminate_group(command_pgid)
              reap_group(command_pgid)

              exit(status.exitstatus || 128 + status.termsig)
            end

            def enable_child_subreaper
              previous_deprecated = Warning[:deprecated]
              Warning[:deprecated] = false
              require "fiddle"
              Warning[:deprecated] = previous_deprecated

              prctl = Fiddle::Function.new(
                Fiddle::Handle::DEFAULT["prctl"],
                [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG],
                Fiddle::TYPE_INT
              )
              raise "unable to become a child subreaper" unless prctl.call(PR_SET_CHILD_SUBREAPER, 1, 0, 0, 0).zero?
            ensure
              Warning[:deprecated] = previous_deprecated unless previous_deprecated.nil?
            end

            def terminate_group(pgid)
              Process.kill("TERM", -pgid)
              Process.kill("KILL", -pgid)
            rescue Errno::ESRCH, Errno::EPERM
              nil
            end

            def reap_group(pgid)
              loop { Process.waitpid(-pgid) }
            rescue Errno::ECHILD
              nil
            end
          end
        end
      end
    end
  end
end

Ace::LLM::Providers::CLI::Molecules::ProcessSupervisor.run(ARGV) if $PROGRAM_NAME == __FILE__
