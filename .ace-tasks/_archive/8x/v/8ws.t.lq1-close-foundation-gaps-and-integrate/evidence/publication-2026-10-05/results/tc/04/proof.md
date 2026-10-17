# RubyGems install verification proof

- Verified at: 2026-10-05T15:59:07+01:00
- Ruby: ruby 3.4.8 (2025-12-17 revision 995b59f666) +PRISM [arm64-darwin25]
- ACE Gemfile declarations: 49
- Normal install exit: 0. Evidence: `results/tc/02/install.stdout`, `install.stderr`, `Gemfile.lock`, `install-receipt.json`, and consumer receipts.
- Full-index install exit: 0. Evidence: `results/tc/03/fullindex.stdout`, `fullindex.stderr`, `Gemfile.lock`, `install-receipt.json`, and consumer receipts.
- Classification: SAFE
- Exact-version acceptance: pass with 0 findings. Evidence: `results/tc/04/exact-version-acceptance.json`.

Operator guidance: Normal installation resolved the released graph at the frozen manifest versions; the operator may use the normal Bundler path.

The final machine-readable verdict is produced by `install_receipt.rb finalize` after the runner session completes, when report `metadata.yml` exists. Its inputs are the frozen manifest, both mode directories, and this acceptance JSON.
