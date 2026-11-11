# Installed lab runtime

The lab's operational ACE bundle is separate from every project checkout and its
Gemfile. RubyGems/Bundler owns dependency resolution. `ace-lab install` performs
one `bundle install` for the declared gem set; success does not trigger a second
installation audit. `ace-lab verify` is an explicit diagnostic command.

Example for Ruby 3.4:

```yaml
gemset:
  gem_home: /opt/ace/runtime/bundle/ruby/3.4.0
  bin_dir: /usr/local/bin
  gems:
    - name: ace-lab
      version: 0.16.0
    - name: ace-herdr
      version: 0.11.0
    - name: ace-overseer
      version: 0.30.0
```

`gem_home` is Bundler's standard `<bundle-root>/<ruby-engine>/<ruby-ABI>`
installation directory. The installer writes one Gemfile and Bundler configuration
at `<bundle-root>`, retaining the lockfile across updates. Bundler generates
binstubs with the installing Ruby's absolute shebang. Optional `bin_dir` exposes
those binstubs through normal executable links. Unrelated executable paths are
not overwritten.

A failed update restores the previous Gemfile, lockfile and bundle configuration.
Already installed sibling versions remain on disk; the lockfile selects the
runtime. Diagnostics of a bundled runtime use frozen, read-only `bundle check`.

For updates, change the manifest pins and run `ace-lab install` once. To rerun
installation of an unchanged runtime directly:

```sh
cd /opt/ace/runtime/bundle
bundle install
```

No project Gemfile is changed. Native Herdr, Node, Pi and Forgejo are provisioned
separately; a gem update does not reinstall the VM or recreate its repositories.
