---
name: overseer-bootstrap-delegation
description: Delegate project startup to lab workers and accept their observed results
allowed-tools: Bash, Read
doc-type: workflow
title: Delegated Project Bootstrap
purpose: Complete one lab-owned startup commission without the overseer doing the repair.
---
# Delegated project bootstrap or configuration repair

Read the known symptom, canonical target and existing commission. Do not diagnose
implementation before dispatch. Reuse the same task and manager after interruption.
The lab can commission a worker before the target's Overseer is running.

1. Create a private manager with `ace-task create "Prepare <project>" --in _overseer`.
   Create a separate ordinary executable task in the commissioning coordinator's
   repository. Its operational scope explicitly names the target project, allowed
   configuration paths, selected installed runtime and observable acceptance checks.
   Select `bootstrap-worker` then `bootstrap-verifier`. Product code changes require
   another implementation commission. Do not require host deployment privileges,
   private task access or running the project Overseer in the worker's checks.
2. Confirm active healthy eyes. Run `ace-overseer work-on --task <commission>
   --manager <private-manager> --runtime herdr`. It creates/reuses direct role children,
   assignments and the confirm-start condition, then starts the actual worker.
   Do not copy identities into task fields. End the turn.
3. Use `ace_eyes` action `process-reports` on report wake. The product accepts the
   outcome, retires the worker, starts the separate verifier and acknowledges the
   completed exact report revision. The verifier checks actual configuration and
   runtime; it does not repair, run code-review rounds, open a PR or integrate.
4. After independent verification, run standard `ace-overseer start --reconcile`
   from the lab, or project start for the commissioned target. Start owns standard
   eyes.json and passes it to the session; workers do not generate that file.
   Accept confirm-start only when the returned target session has its first turn
   and all required observation sources healthy. An active process alone is not proof.
5. If readiness is pending, preserve the session and let its meaningful changes
   wake you. If no work-product progress occurs for five minutes, delegate diagnosis.
   Never repeat an uncertain prompt or create a duplicate session. Once the proof is
   accepted through ace-task, process the existing report to close the manager.

Failures stay open. Missing authority or a decision outside the mandate becomes
one HITL case through the existing Second Captain procedure. End the turn while
waiting; no sleep-poll. Keep all prior work and evidence, without reset or reinstall
when the target is already ready. Ordinary same-user sessions are not an OS sandbox.
