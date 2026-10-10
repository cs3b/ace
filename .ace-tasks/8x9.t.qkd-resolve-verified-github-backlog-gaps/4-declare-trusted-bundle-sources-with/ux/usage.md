# Proposed usage contract

These are acceptance scenarios for the draft, not claims of current functionality. Commands use the installed executable spelling; inside ACE use `bin/ace-*`.

## Project source

Input: `Load a project-root source in review-safe mode`

Expected: Source accepted with canonical path and project-root policy provenance.

## Installed source

Input: `Load an installed protocol source explicitly admitted by trusted caller policy`

Expected: Source accepted with installed-owner and policy identity.

## Untrusted override

Input: `Resolve the same protocol through an unapproved user-tier override`

Expected: Fail closed with actionable source/policy diagnostic.

