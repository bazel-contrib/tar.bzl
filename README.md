# Bazel tar rule

General-purpose rule to create tar archives.

Unlike [pkg_tar from rules_pkg](https://github.com/bazelbuild/rules_pkg/blob/main/docs/latest.md#pkg_tar):

- It does not depend on any Python interpreter setup
- The "manifest" specification is a mature public API and uses a compact tabular format, fixing
  https://github.com/bazelbuild/rules_pkg/pull/238
- It doesn't rely custom program to produce the output, instead
  we rely on the well-known C++ program `tar(1)`.
  Specifically, we use the BSD variant of tar since it provides a means
  of controlling mtimes, uid, symlinks, etc.

We also provide full control for tar'ring binaries including their runfiles.

The `tar` binary is hermetic and fully statically-linked. See Design Notes below.

This rule was originally developed within bazel-lib.
Thanks to all the contributors who made it possible!

## Examples

- Migrate from `pkg_tar`: https://github.com/bazel-contrib/tar.bzl/blob/main/examples/migrate-rules_pkg/BUILD
- Look through our test suite: https://github.com/bazel-contrib/tar.bzl/blob/main/tar/tests/BUILD

Note; this repository doesn't yet allow modes other than `create`, such as "append", "list", "update", "extract".
See https://registry.bazel.build/modules/rules_tar for this.

## API docs

- [tar](https://registry.bazel.build/docs/tar.bzl#tar-tar-bzl) Run BSD `tar(1)` to produce archives
- [mtree](https://registry.bazel.build/docs/tar.bzl#tar-mtree-bzl) The intermediate manifest format `mtree(8)` describing a tar operation

## Design notes

1. We start from libarchive, which is on the BCR: https://registry.bazel.build/modules/libarchive
1. You could choose to register a toolchain that builds from source, but most users want a pre-built tar binary: https://github.com/aspect-build/bsdtar-prebuilt
1. bazel-lib defines the toolchain type, and registers a sensible default toolchain: https://github.com/bazel-contrib/bazel-lib/blob/main/lib/private/tar_toolchain.bzl
1. This repo then contains just the starlark rule code for invoking `tar` within Bazel actions (aka. build steps)
