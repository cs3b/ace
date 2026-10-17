# Project-scoped interactive execution — draft usage

API surface: CLI and trusted per-project configuration.

## Project default
Goal: run the reviewed publication command using the ACE project's permitted default.

```sh
ace-lab run --project ace -- .ace-bin/ace-rubygems-publish --interactive
```

Expected: caller needs no sudo; the permitted executor runs in the configured
project context, using only configured default services. Native no-echo prompt,
signals and exit status remain usable. Missing default or grant refuses before start.
The command still owns its publication authorization and exact release checks.

## Explicit service set and executor

```sh
ace-lab run --project ace --as lab-admin --service rubygems-publish --service forgejo -- .ace-bin/ace-rubygems-publish --interactive
```

Expected: explicit services replace the default set; both services and their
combination must be permitted under the selected executor. lab-admin is a selector,
not a permission. No secrets appear in ACE output or command argv. No change of
executor or omission of a denied service occurs to make the command run.

## Refused selection

```sh
ace-lab run --project ace --service rubygems-publish --service forbidden-service -- .ace-bin/ace-rubygems-publish --interactive
```

Expected: classified nonzero denial before publisher start, prompt, secret exposure
or other command effect. No subset executes. Unknown project, ambiguous defaults
and ungranted --as have the same no-effect guarantee. Lost completion after a valid
launch returns an attributable uncertain outcome for reconciliation, never a retry.

These examples specify future behavior; they do not assert ace-lab run exists.
Complete final usage documentation during implementation via wfi://docs/update-usage.
