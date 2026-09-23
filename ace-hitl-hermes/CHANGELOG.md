# Changelog

All notable changes to `ace-hitl-hermes` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Folder-as-interface plugin + registry (spec 8wm.t.vs1)**: new package owning the channel registry, notification texts, and message formats for the shared lab <-> hermes folder. Folder contract `ace.hitl.hermes.folder/v1` + message schema `ace.hitl.hermes.message/v1` (JSON Schema asset shipped at `lib/ace/hitl/hermes/schemas/message.v1.schema.json`): a message is a file named `<id>.json`, the address is `<machine>/<folder>/<id>`, the Captain's answer file carries `answer` / `sender` / `received_at`. Fail-closed filename validation, UTF-8 + 64 KiB bounds, id/filename cross-check, ownership/permissions (files 0640, tmp 0600, quarantine 0750; running as root is refused), atomic same-directory tmp+rename writes, quarantine for invalid files with reason sidecars, bounded collision and undeleted-file retry policies, and the write -> validate -> deliver -> ACK deletion state machine. Canonical shared-contract file location/ownership is settled by A4 (8wm.t.vs2); the lab-config consumer side is 8wm.t.vp9 (separate repo).
