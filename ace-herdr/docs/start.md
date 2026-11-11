# Start from configuration

`ace-herdr start` starts or attaches to the native persistent Herdr terminal.
It replaces the invoking process, retaining the terminal and native exit status.
Native Herdr owns its server lifecycle and terminal state.

Configure the existing `herdr` namespace, for example in `~/.ace/herdr/config.yml`:

```yaml
binary: /opt/ace/runtime/bin/herdr
socket: /home/mo/.config/herdr/herdr.sock
toolchain: installed
```

`native_config` optionally selects the native TOML configuration file. Omit it
to use Herdr's normal configuration path. `binary` defaults to `herdr` on PATH.
The same configuration is applied by ACE's native executor, including commands
issued by the overseer. An inherited `ACE_TOOLCHAIN=installed` cannot be downgraded
by configuration. Installed Linux starts check the declared managed Pi extension
paths before launching; a missing extension is an error, not a source fallback.

```sh
ace-herdr start
```

No shell profile needs to be sourced manually. In the terminal, run the configured
overseer. For a lab coordinator started from a separate operator terminal:

```sh
cd /lab
ace-overseer start --scope lab --format json
```

Overseer configuration should declare `toolchain: installed`; its existing
`start`, `profiles` and instruction configuration still select the role/model.
Session credentials and child runtime paths come from the lab's existing role
configuration. The configured session-runtime socket must match Herdr's socket.
