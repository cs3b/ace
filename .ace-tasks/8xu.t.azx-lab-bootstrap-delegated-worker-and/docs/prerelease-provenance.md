# Preserved prerelease payload provenance

Read-only inspection on Omarchy of `/home/mo/Projects/ace-bootstrap-slice`.
Python tarfile read the outer gem archive and nested `data.tar.gz` in memory;
every regular packaged file was compared byte-for-byte against `git show
<full-sha>:ace-overseer/<path>`. No payload was executed, installed or extracted
onto the checkout. No source checkout or live actor was changed.

| Artifact under `.ace-local/candidates/` | SHA-256 | Unique payload match among six preserved commits |
|---|---|---|
| `pre2/ace-overseer-0.28.0.pre.2.gem` | `c6e83d2e8ea87397687223c9fe7c3aa5e4d8cb58562b860e03302a538074a640` | `799c71b02e603f4ab0c286b13ff5cc45d498f3f2` |
| `pre3/ace-overseer-0.28.0.pre.3.gem` | `c493fee37aca75ccdae62bb1c132c5fe25aa3cb70de95cc041dfc5a1a93cd3ae` | `c4703dfdcf8925a1e191aed6a69c710af600bdae` |

Each archive contains 68 regular payload files. At its matching commit,
all 68 match exactly: zero differing files, zero missing source paths.
The packaged version.rb values are respectively 0.28.0.pre.2 and 0.28.0.pre.3.

Compared full source commits, newest first:

- c4703dfdcf8925a1e191aed6a69c710af600bdae
- 799c71b02e603f4ab0c286b13ff5cc45d498f3f2
- db6667ffbc2aa68052f3ba577c9fa1dfd20c9e4c
- 8f0c0bbb9b11f09433785ea701ea9466408708f1
- fce6d7db308642afe974c8ebabc155022966ef10
- fc72f8fea9c637cf526bfbd0cee2c2908deb1d75

For the two matching commits, their package payload differences are exactly:
CHANGELOG.md, docs/usage.md,
handbook/workflow-instructions/overseer/lab-start.wf.md,
lib/ace/overseer/molecules/project_bundle.rb,
lib/ace/overseer/version.rb. All earlier candidates also differ; the oldest
lacks molecules/project_bundle.rb entirely.

## Limits of the evidence

This establishes exact packaged source-content matches, unique within the
six-commit comparison set. It does not establish the build invocation,
build environment, checkout cleanliness, commit checked out at build time,
or authorship of the build. An equivalent source tree can produce the same
payload. Gem metadata and packaging timestamps are not treated as an attested
source/build identity. Do not describe this as independently proven build
origin; build origin remains unproven beyond payload-content equivalence.
