# YAML Demo Spike Concept Inventory

## Survives (kept as-is)
- `Ace::Demo::Molecules::VhsExecutor` remains the runtime backend for tape execution.
- `Ace::Demo::Atoms::VhsCommandBuilder` still builds the VHS command argv.
- Existing `.tape` and inline recording paths in `ace-demo record` remain unchanged.

## Changes (existing behavior extended)
- `ace-demo record` now routes `.tape.yml` inputs to a dedicated YAML recorder.
- `VhsExecutor#run` now accepts optional `chdir:` to run recordings in an isolated sandbox.
- `ace-demo` usage docs now include YAML recording flow.

## New Components
- `Ace::Demo::Atoms::YamlTapeParser`
- `Ace::Demo::Atoms::YamlTapeContentGenerator`
- `Ace::Demo::Molecules::DemoSetupExecutor`
- `Ace::Demo::Organisms::YamlDemoRecorder`
- Demo source file: `ace-task/docs/demo/ace-task-getting-started.tape.yml`
- Demo fixture seed: `ace-task/docs/demo/fixtures/.ace/task/config.yml`

## Removed
- Nothing removed in this spike.
