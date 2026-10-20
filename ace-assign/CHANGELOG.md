# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.73.0] - 2026-10-20

### Changed
- Drive workflow now requires re-reading active assignment state immediately before every `finish`/`fail` report, so reports cannot land on auto-advanced child steps in long-running forked subtrees.
- Verify-test-suite workflow documents the hermetic environment rule for forked drive sessions: verification must go through `ace-test`/`ace-test-suite`, whose environment policy drops ambient `ACE_*`/`LAB_*` fork-runtime configuration; manual env scrubbing and raw rake/bundle invocation inside forked subtrees are prohibited.

0.73.0