# Isolated installed protected launch proof

Status: author expanded uninstrumented run 71539 passed; independent clean rerun pending. Actual Lab/gad.2 acceptance has not occurred. The retained prior proof does not include the two final additional assertions: DAC_OVERRIDE bounding refusal and guest-only root SUID executable with NNP preserving effective UID 13001. The prepared clean image includes those assertions for independent verification.

The tested artifacts were built from exact source e2d3dad3e3c93247e0d741ddaef3cf07cddaa46f. Subsequent c3bdc29c0 changes only a termination diagnostic string; parent independently approved that text delta. Full Assign 8x45dm passed 888/3961 with two existing skips. Runtime all 8x463l passed175/485 and Herdr all 8x463y passed463/1521 on code-equivalent final source.

This fixture uses a separate Debian ARM64 kernel (linux-image-6.1.0-53-arm64 6.1.187-1), guest-only Yama2, distinct UID13001 worker/native server,13002 launcher,13003 authority,13004 recovery supervisor; all five capability sets empty and NoNewPrivs1. Root-installed immutable map/bootstrap/payload/native server, protected directories and exact socket/kernel births are used. No network device, shared host filesystem, host credentials or Docker socket is attached to the guest. The worker-writable payload marker is observation only: canonical phase/binding and independently observed exact kernel process identity prove launch ownership. Child exit after issuance remains uncertain and never proves all attributable writers gone.

QEMU11.1.2 Homebrew ARM64 bottle uses HVF. TCG on the owned Docker kernel booted the same separate guest, but emulation consumed the unchanged product deadline. No timeout or security policy was weakened. Diagnostic instrumentation was removed before completed expanded run71539. Fixture startup PATH/GEM_PATH, run-directory mode and journal-reader ordering corrections are fixture repairs, not product changes.

## Independent prepared-image run

The complete offline artifacts remain in `/Users/mc/Ps/ace/.ace-wt/codex-wave5-protected-launch-final/.ace-local/09j-vm`. Run from that directory, sequentially:

```
python3 verify-artifacts.py artifact-manifest.json
sh boot-hvf.sh
python3 verify-proof.py guest-console-hvf.log independent-expanded-proof.json
```

The manifest binds the clean preboot disk, kernel/initrd, exact 22 built ACE gem files, actual Herdr binary, and fixture scripts. Boot mutates the disk; verification must occur before boot. QEMU exit0 alone does not indicate success: the verifier requires exactly one completed proof, no failure, all declared cases and the expected source/kernel distinction. Retain the serial log and verifier JSON. The scripts do not alter source or grant protocol permission outside the actual installed authority.

## Build inputs

At an isolated checkout of exact e2d, run `bundle exec ruby .ace-local/09j-vm/build-gems.rb` to build the actual source gem dependency closure; this is artifact construction, not a package-test invocation. Copy the retained fixture files into its `.ace-local/09j-vm` directory, with the actual Herdr0.9.3 binary matching `artifact-manifest.json`. Upstream native source identity:7b116c05bfda646af39d2524c54e70c751f57ee8. Build the toolchain, installed and guest images using the three Dockerfiles, in that order. The image names are `ace-09j-vm-toolchain:local`, `ace-09j-installed-final:local`, `ace-09j-guest-final:local`. Actual cached images used: toolchain26a0079ee739ce9d03e6856ffc42f0eee7ae57b602a7f17caa8c9575aa656c1e, installed4af4f1c1518879d3a35fcba24224e2ae02e329ec1e365a4f882b78e2e3cc459e. Ruby3.4.8-slim-bookworm base digest1af92319c7301866eddd99a7d43750d64afa1f2b96d9a4cb45167d759e865a85. DebianGCC12.2, json-c0.16-2/libjson-c5, libc2.36 and libffi-dev build the shipped native source as UID65534 with empty capabilities/NNP before root installation0755. The final ELF SHA56680e55674cb72c8e6b685e116e4d2f1dfe91bf31564c37247dcfdc40edf612 matches the product artifact used in every protected guest run.

Export the owned guest Docker image to a tar, extract into an owned temporary directory, overlay current guest-init/guest-probe.py/phase-client.rb, create a2GiB ext4 image with `mkfs.ext4 -F -d`, and copy the packaged vmlinuz/initrd. This needs no privileged Docker/loopmount. Record fresh offline hashes before running if rebuilding; filesystem creation timestamps/UUIDs legitimately change the disk hash. The retained prepared-image manifest is an exact acceptance input, not an assertion that arbitrary later package downloads are identical.

## Case coverage

Public CLI happy path observes only one fresh native child and unchanged baseline shell; canonical registration/reservation/record/bind/issuance match the exact root-installed payload after exec. Worker ptrace/process_vm_readv and protected file/UID escalation attempts are denied. Actual worker native API spawns a same-ticket direct bootstrap mimic; its different exact child identity cannot receive permission. Worker release mutation is denied. New launcher retry never creates another pane. Bound launcher loss causes gate EOF and exact retained child exit; public supervisor abort produces failed plus protected not-issued observation. Release reply loss retains issued/potentially-executed and exact original-client replay. Lost native creation reply leaves one gate/reservation, no adopted binding or second creation. Issued child exit stays uncertain. Authority crash destroys the gate stream; verified installer restart cannot fabricate lost pidfd evidence or release ownership. Endpoint replacement and closed configured container refuse without fallback. Final additional checks reject DAC_OVERRIDE/SETUID bounding sets and missing NNP, and show NNP prevents root SUID exec escalation.
