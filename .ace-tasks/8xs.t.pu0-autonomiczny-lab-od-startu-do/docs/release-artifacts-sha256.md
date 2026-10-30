# Release artifact digests — PR #398

Built from code HEAD `e45dbbc05` (2026-10-30, after re-review R1–R8 fixes
and two clean review rounds; supersedes the earlier set built from
`dbfd58a89`/`f92a4b691` which did NOT contain the review-round fixes).
Artifacts in `/tmp/pu0-gem-build-r4/`; install rehearsal GREEN (fresh
GEM_HOME, 48 gems incl. published deps; installed-smoke verified every
executable and --version; ACE_TOOLCHAIN=installed).

2581a2dd4b017c1811d12546525b0f22b409c56b006658be65dd110941ea3a38  ace-coworker-0.7.0.gem
665ca7ca4e1b20ee3267a53d4433217e893744ec77b8315e017cf13f46309282  ace-git-0.32.0.gem
8e82cb4a7a7aaa37ff5a2047f0e9522a1c3770e561b0a22d1fd458c353c914b2  ace-handbook-0.37.0.gem
e5028dc023eef7e2a488c32e324ddf7ca3a0fc2232bfd574481884e4cbcf0e66  ace-handbook-integration-pi-0.8.0.gem
c4badf26f19542895a474c9c62bdb81aa6014d0018a3935f0124687a70ad769e  ace-herdr-0.9.0.gem
a7b135537cbe43b19f9043d052c7ad598bc973d3a8ae957bdbe3d7e3c97c6713  ace-hitl-0.25.0.gem
c228ec5c938acd8046fff8417dd87d945314ec4cf516ae580ca404d61938cb0a  ace-lab-0.14.0.gem
cfa5d4a33d5323dc5289faab97da23fc8616063baa275358239ce40e27cc741e  ace-overseer-0.27.0.gem
7c4cc0f0c77b4769396fe11171805a1f72f4ba5439498d20faeae07be5fca719  ace-wake-0.1.0.gem

ace-wake and ace-handbook-integration-pi ship no executables by design
(library + packaged JS extension / integration lib) — verified loadable at
their versions from the installed gemhome. Publication NOT performed.
