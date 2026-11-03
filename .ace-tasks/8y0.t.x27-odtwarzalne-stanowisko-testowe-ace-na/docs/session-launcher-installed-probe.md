# Installed session launcher probe

Executed on the existing diagnostic UTM VM
`FA8EFE78-E054-408F-AFF7-6A151C043435`, Linux ARM64/systemd 257.

Artifact: ace-lab 0.14.2.pre.utm58, built by lab-vm-build-gem from
`15786dbb66c036dcb72955d32f0573e024b01850`.
SHA-256: `4d74edb2f93e0ee9898f251cd74542f2a024560544508f69d91d6c387cd4eaef`.
Verified in the guest before installation into `/opt/ace/diagnostic/utm58/gems`.
Dependencies resolved from `/opt/ace/runtime/gems`; the operational gem home
and release manifest were unchanged. Ruby was
`/opt/ace/toolchains/ruby-3.4.8/bin/ruby`, with ACE_TOOLCHAIN=installed.

The packaged SessionLauncher started a configured worker SessionUnit with
`/usr/bin/sleep 30` on a Ruby PTY, then identified it through systemd and a
kernel-held pidfd. Observation:

- unit: `ace-auth-session-worker-e644b21dd8dbad3e.service`
- invocation: `93a34d5619ca4bc294e6fb6a93290d26`
- session PID: 20145; dynamic UID: 63759
- transport PID: 20142

The probe closed its pidfd, stopped the unit and reaped the transport. Exit 0.
This verifies the packaged launch/identity boundary against real systemd. It
does not prove project mounts, native Herdr handoff, Pi readiness, leases or
the autonomous E2E cycle. Those acceptance criteria remain open.
