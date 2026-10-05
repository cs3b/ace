# Fixed executor traversal repair

Independent receiver-map review rejected 7f0f28eea (8x46utx7): authority
search access did not establish executor access to a root-owned 0750 ancestor.

The repair reads bounded Linux access-ACL xattrs and checks search permission
for the fixed executor on every ancestor. No ACL (`ENODATA`) uses mode bits;
unsupported/error/malformed ACL refuses. This is discretionary access evidence,
not an LSM bypass or executor readiness handshake.

Primary semantics: [acl(5), access-check algorithm](https://man7.org/linux/man-pages/man5/acl.5.html),
[getxattr(2)](https://man7.org/linux/man-pages/man2/getxattr.2.html), and
[Linux v6.1 POSIX ACL xattr wire format](https://github.com/torvalds/linux/blob/v6.1/include/uapi/linux/posix_acl_xattr.h).

Maintained focused tests: 8x46ys, 19 tests / 93 assertions, zero failures/errors.
Host filesystem-placement tests explicitly model Linux ACL retrieval on macOS;
they are not installed Linux acceptance.

Actual isolated Linux diagnostic (`probe.rb`) evaluated the same source helper
and compared `/usr/bin/test -x` under UID/GID/groups 13005 using `setpriv`:
root-owned authority-group-only ancestor denied; named executor search allowed;
masked search denied; named-user denial overrides searchable other entry.
All four matched actual kernel access on Docker Linux
7.0.11-orbstack-00360-gc9bc4d96ac70. No network, credentials or Docker socket
were mounted. Separate guest installed proof remains pending.

Reproduce: copy `posix_acl.rb` beside `probe.rb`, then run an owned Docker
fixture with `acl`, Ruby and `setpriv` installed, create groups 13003/13005,
create `/fixture/ancestor` root:13003 with `/fixture` mode0755, and execute
`ruby /probe/probe.rb`. The accepted existing installed image was
`ace-09j-installed-final:local`; only the diagnostic directory was mounted read-only.
