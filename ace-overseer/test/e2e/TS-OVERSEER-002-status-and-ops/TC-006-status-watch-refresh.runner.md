# Goal 6 -- Status Watch Refresh

## Goal

Demonstrate public status refresh behavior by running `ace-overseer status --watch` in a bounded interval and capturing successive refresh output.

## Workspace

Save all output to `results/tc/06/`. Capture:

- `results/tc/06/baseline.stdout`, `.stderr`, `.exit` - baseline table status
- `results/tc/06/watch.command.txt` - exact bounded watch execution contract
- `results/tc/06/watch.stdout`, `.stderr`, `.exit` - bounded watch output, stderr, and exit code

## Constraints

- Use only public status commands.
- Keep watch execution bounded; do not leave long-running watch sessions.
- Before the watch run, create a scenario-local `.ace/overseer/config.yml` with short watch intervals so at least two refreshes are observable inside the bounded run.
- Capture at least two refresh frames or clear repeated status updates in watch output.
- Use a controlled bounded-session shutdown, not an uncontrolled kill. The retained scenario should terminate the watch command with `TERM` or `INT` and persist the resulting bounded-session exit code (`143` or `130`), rather than relying on an external `SIGKILL` path.
- The command under test remains `ace-overseer status --watch`; if you use Ruby process control to bound the session, persist that exact command in `watch.command.txt`.
- All artifacts must come from real tool execution, not fabricated.

## Steps

1. Write a scenario-local watch config with fast refresh intervals:

   ```bash
   mkdir -p .ace/overseer
   cat > .ace/overseer/config.yml <<'EOF'
   watch:
     refresh_interval: 1
     git_refresh_interval: 2
   EOF
   ```

2. Capture the baseline status:

   ```bash
   ace-overseer status --format table > results/tc/06/baseline.stdout 2> results/tc/06/baseline.stderr
   echo $? > results/tc/06/baseline.exit
   ```

3. Persist the exact watch command:

   ```bash
   printf 'ace-overseer status --watch\n' > results/tc/06/watch.command.txt
   ```

4. Run a bounded watch session with controlled `TERM` shutdown and persist the bounded exit code:

   ```bash
   ruby <<'RUBY'
   require "open3"

   stdin, stdout, stderr, wait_thr = Open3.popen3("ace-overseer", "status", "--watch")
   out_thread = Thread.new { stdout.read }
   err_thread = Thread.new { stderr.read }

   sleep 6
   begin
     Process.kill("TERM", wait_thr.pid)
   rescue Errno::ESRCH
   end

   status = wait_thr.value
   stdin.close unless stdin.closed?

   out = out_thread.value
   err = err_thread.value
   code = status.exitstatus
   code = 128 + status.termsig if code.nil? && status.signaled?

   File.write("results/tc/06/watch.stdout", out)
   File.write("results/tc/06/watch.stderr", err)
   File.write("results/tc/06/watch.exit", code.to_s)
   RUBY
   ```
