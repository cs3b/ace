# Control callback and maintained fixture adoption successor

Scope: successor to d7c87f190, joined with main d1c31da9a in 21018e256. ControlExclusion preserves the original exception object from owner callbacks while still classifying its own filesystem/protection failures and unwinding all held guards. Maintained positive LaunchLifecycle fixtures explicitly provision the selected original control root and use controlled installed identity/ACL/namespace observations. Production admission is not relaxed.

The constructor audit covers EndcapResultOwnerFixture, deployment, parent-cap, historical rotation, protected attempt consumers, native admission, prepared registration and launch lifecycle fixtures. Pure history readers and non-dispatch Object fixtures need no control adoption. The lifecycle test class was consolidated from three identical reopened scopes into one static scope, preserving all methods, so exact source selectors are valid.

Executed final gates:

- Control/workspace primitives: 21 tests / 116 assertions PASS, cf19a602-94b8-4295-92c5-950ff6320bb5.
- Canonical registration full file: 4/34 PASS, 18.9s, 629bab67-6153-49d2-b179-4249d806ea04.
- Maintained production parent-cap fixture: 1/21 PASS, 17.09s, 5a577d7e-5c5d-4fae-a39a-78a4446dc7b2.
- Prepared registration full file: 4/63 PASS, 10.92s, d7b22050-ed79-4eb5-8575-e04fadba23e6.
- Native admission winner: 1/13 PASS, 4a05b817-539d-489b-97c9-b3142744077c.
- Lifecycle SH/EX/mutex: 1/11 PASS, 50dda2ef-3afe-4a39-8153-ea834c0d3d0d.
- Lifecycle original record callback failure: 1/11 PASS, d4410fc4-4142-451c-b397-b9e650ce7f07.

Retained failures: 2ba9657f initially lacked operator preparation after the public server fixture replaced authority.state_root; explicit selected-root provisioning fixed it. 00368834 exposed callback RuntimeUnavailableError incorrectly wrapped as EvidenceUnavailable; the production fix preserves it. Intermediate a794e1dc and 042fa176 exposed an uninitialized callback local; fixed before final gates. Whole lifecycle aggregate afc7028a timed out at the existing 180s limit with no reported completed cases; it is not positive evidence. cfb2fa44 selected zero files because --filter filters filenames, not methods, and is excluded. Earlier reopened-class exact selection was correctly rejected by runner policy, motivating the static class consolidation.

No native, installed, root, process identity or systemd probes. No complete task acceptance: native creator host SH lifetime, remaining creator adoption and actual Installer physical composition remain required. Frozen source awaits independent review.
