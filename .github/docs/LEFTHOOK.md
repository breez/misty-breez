# Setting up Lefthook

### Pre-commit `dart format` with Lefthook

[Lefthook](https://github.com/evilmartians/lefthook) is a Git hooks manager that allows custom logic to be
executed prior to Git commit or push. Misty Breez comes with Lefthook configuration (`lefthook.yml`), but it must
be installed first.

### Installation

- Install Lefthook.
  See [installation guide](https://github.com/evilmartians/lefthook/blob/master/docs/install.md).
- Run the following command from project root folder to install hooks:

```sh
$ lefthook install
```

Before you commit your changes, Lefthook will automatically run `dart format`.

### Skipping hooks

Should the need arise to skip `pre-commit` hook, CLI users can use the standard Git option `--no-verify` to skip `pre-commit` hook:

```sh
$ git commit -m "..." --no-verify
```

There currently is no Github Desktop support to skip git-hooks. However, you can run:
```sh
$ lefthook uninstall
```
to clear hooks related to `lefthook.yml` configuration before committing your changes.

Do no forget to run `lefthook install` to re-activate `pre-commit` hook.

```sh
$ lefthook install
```