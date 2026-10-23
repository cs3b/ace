# Formal approval protocol evidence — 2026-10-23

Read-only anonymous upstream research after independent REJECT of `9bcc26015`.
No authenticated provider API/model request or server/account change was made.
The local download directory `/tmp/ace-formal-provider-upstream/` holds the
examined bytes; their pinned upstream URLs and hashes below preserve provenance.

## Forgejo v11.0.0 and deployed-version v16.0.5

In both versions, CreatePullReview keeps an explicitly supplied `commit_id`
and passes it with the requested event to the review service. The ID-based
pending-submit router instead reads current PR head and passes that value.
The model's SubmitReview reuses the authenticated actor's current pending
review, replacing its content/type/commit and including its existing comments.
Therefore publication uses direct create with `event=APPROVED` and explicit
reviewed commit; it never uses the pending-submit route. This is commit
preservation, not an invented server-side current-head or pending-object CAS.

An observed unrelated pending review refuses before mutation. Exact known
comment-free pending can be recovered through direct create under the mandatory
exclusive-writer deployment condition. Pending with comments or unprovable
identity/content remains unchanged with a capability/refusal result. Local
flock spans all correlations/worktrees for the same OS account and normalized
provider/repository/PR, using the system temporary directory rather than
caller-controlled worktree TMPDIR. No new registry/journal is introduced.

**Mandatory deployment precondition (owner: lab-config gad.b):** a dedicated
automation reviewer identity and one writer per actor/repository/PR. Another
host or manual client using that identity can race a preflight read and direct
create; the API has no expected-pending condition to prevent replacement. Such
concurrent reuse is outside the supported deployment contract. Do not claim
server-atomic pending isolation, silently weaken this condition, or share a
worker/admin credential to satisfy it. Missing confirmed identity/ownership
mapping withholds live acceptance.

The converter emits REQUEST_REVIEW entries with user or team; request models
do not supply a reviewed commit. The Forgejo adapter excludes these request
rows from formal-review evidence. Generic validation requires full actor/commit
for the selected approval and relevant revocations; unrelated null-actor
comments do not make an otherwise valid PR malformed.

Formal review capability has its own minimum verified source version, 11.0.0;
the unrelated lifecycle floor remains 8.0.0. The deployed target reported by
the host is 16.0.5; no live-server observation was made by this implementer.

| Version/source | Anonymous upstream URL | SHA256 of examined bytes |
| --- | --- | --- |
| v11.0.0/api | https://codeberg.org/forgejo/forgejo/src/tag/v11.0.0/routers/api/v1/repo/pull_review.go | `35ed86f06585e11244bdc7400a102cd7130ede49fa221f8c0565b21ec5264c3f` |
| v11.0.0/model | https://codeberg.org/forgejo/forgejo/src/tag/v11.0.0/models/issues/review.go | `5bfad186c8b6752dfc1fcde0f6d43cdfb942ae538acd43369455640a9971ffdb` |
| v11.0.0/service | https://codeberg.org/forgejo/forgejo/src/tag/v11.0.0/services/pull/review.go | `f108d18b730993ced78ade1b77565305e7f987f13933db342ba491d77467971e` |
| v11.0.0/struct | https://codeberg.org/forgejo/forgejo/src/tag/v11.0.0/modules/structs/pull_review.go | `0165e7f53e4417248f095531aaea6dd2d38f841aa0a94e9ac5d984d667c25ef9` |
| v11.0.0/convert | https://codeberg.org/forgejo/forgejo/src/tag/v11.0.0/services/convert/pull_review.go | `b4c93497c0d56caf733bb0a53a4edeefcd8a7d96985df5b011c30ef7878b96e9` |
| v16.0.5/api | https://codeberg.org/forgejo/forgejo/src/tag/v16.0.5/routers/api/v1/repo/pull_review.go | `429f8ebcae4416beb81bd23fc80ceacdff79f4ff6282bf2f5de89c3d1b62a00e` |
| v16.0.5/model | https://codeberg.org/forgejo/forgejo/src/tag/v16.0.5/models/issues/review.go | `f22ea2616c1bb0c4bd45fb1c1bd43b2e9789db05e1c44ff77127d1daadcab790` |
| v16.0.5/service | https://codeberg.org/forgejo/forgejo/src/tag/v16.0.5/services/pull/review.go | `95007aeb8c241ef5e52e85b5346daaa34ba5b924be9cb3e2aa83c43cb0f9d042` |
| v16.0.5/struct | https://codeberg.org/forgejo/forgejo/src/tag/v16.0.5/modules/structs/pull_review.go | `5745b07705d600454493213f6be1c5715dfa43bb041d9330dfdcb3af1ddb61fb` |
| v16.0.5/convert | https://codeberg.org/forgejo/forgejo/src/tag/v16.0.5/services/convert/pull_review.go | `990debd9559be1c85802f88e90d4a3cc70e649b76a0bb8162cd5b99e53bf17cd` |

## GitHub authenticated actor and credential capability

[Create-review API documentation](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request)
accepts an explicit reviewed commit SHA and APPROVE event, and lists installation
and user token support. The implementation supplies both fields in one request;
it does not create a pending review as a separate step.


[Installation authentication documentation](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation)
explicitly demonstrates an installation-token GraphQL `viewer` query.
[GraphQL authentication](https://docs.github.com/en/graphql/guides/forming-calls-with-graphql)
supports PAT, App installation, App user and OAuth user contexts.
[REST authenticated-user documentation](https://docs.github.com/en/rest/users/users#get-the-authenticated-user)
does not list installation tokens for `/user`; review-endpoint permission is
not proof that `/user` can resolve their actor.

Use the configured host/token GraphQL viewer's login and numeric databaseId,
then compare the actual review actor and repository/head on readback. Do not
guess a bot login from a configured App label or substitute credentials. A
GraphQL error, null/unverifiable viewer or integration access refusal returns
an explicit capability/authentication refusal before approval, never apparent
network unreachability or a fake successful actor. PAT/App user identities
use the same authenticated-viewer contract. Deployment App live verification
remains open until the host provides an actual bounded read-only receipt.

Both providers directly create an approval at the explicit accepted commit.
Lost responses are reconciled from submitted review evidence; no automatic POST
retry. GitHub known pending recovery is explicitly refused until a protocol
path is verified to preserve the accepted identity/content; pending is retained
and that acceptance limitation stays open. Forgejo's verified direct-create
reuse supplies safe known/comment-free pending recovery within the exclusive
actor contract. A post-send readback failure never undoes an approval, so
regression fixtures assert the commit/state actually left on the provider.
