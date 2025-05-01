# Bazel tar rule

This rule was originally developed within bazel-lib.
Thanks to all the contributors who made it possible!

## Examples

Simplest possible usage:

```
load("@tar.bzl", "tar")

# build this target to produce archive.tar
tar(
    name = "archive",
    srcs = ["my-file.txt"],
)
```

Exhaustive examples may be found in our test suite: `/tar/tests/BUILD`

Note; this repository doesn't yet allow modes other than `create`, such as "append", "list", "update", "extract".
See https://registry.bazel.build/modules/rules_tar for this.

## API docs

- [tar](docs/tar.md) Run BSD `tar(1)` to produce archives: https://man.freebsd.org/cgi/man.cgi?tar(1)
- [mtree](docs/mtree.md) The intermediate manifest format `mtree(8)` describing a tar operation: https://man.freebsd.org/cgi/man.cgi?mtree(8)

## Design notes

1. We start from libarchive, which is on the BCR: https://registry.bazel.build/modules/libarchive
1. You could choose to register a toolchain that builds from source, but most users want a pre-built tar binary: https://github.com/aspect-build/bsdtar-prebuilt
1. bazel-lib defines the toolchain type, and registers a sensible default toolchain: https://github.com/bazel-contrib/bazel-lib/blob/main/lib/private/tar_toolchain.bzl
1. This repo then contains just the starlark rule code for invoking `tar` within Bazel actions (aka. build steps)
