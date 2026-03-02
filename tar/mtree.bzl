"""Helpers for mtree(8), see https://man.freebsd.org/cgi/man.cgi?mtree(8)

### Mutating the tar contents

The `mtree_spec` rule can be used to create an mtree manifest for the tar file.
Then you can mutate that spec using `mtree_mutate` and feed the result
as the `mtree` attribute of the `tar` rule.

For example, to set the owner uid of files in the tar, you could:

```starlark
_TAR_SRCS = ["//some:files"]

mtree_spec(
    name = "mtree",
    srcs = _TAR_SRCS,
)

mtree_mutate(
    name = "change_owner",
    mtree = ":mtree",
    owner = "1000",
)

tar(
    name = "tar",
    srcs = _TAR_SRCS,
    mtree = "change_owner",
)
```
"""

load("@bazel_skylib//lib:partial.bzl", "partial")
load("@bazel_skylib//lib:types.bzl", "types")
load("//tar/private:tar.bzl", _mutate_mtree = "mtree_mutate", _tar_lib = "tar_lib")

mtree_spec = rule(
    doc = "Create an mtree specification to map a directory hierarchy. See https://man.freebsd.org/cgi/man.cgi?mtree(8)",
    implementation = _tar_lib.mtree_implementation,
    attrs = _tar_lib.mtree_attrs,
)

def mtree_mutate(
        name,
        mtree,
        srcs = None,
        preserve_symlinks = False,
        strip_prefix = None,
        package_dir = None,
        mtime = None,
        owner = None,
        ownername = None,
        pipeline = Label("@tar.bzl//tar/private:default.awk"),
        script_args = {},
        includes = None,
        awk_script = None,
        **kwargs):
    """Modify metadata in an mtree file.

    Args:
        name: name of the target, output will be `[name].mtree`.
        mtree: input mtree file, typically created by `mtree_spec`.
        srcs: list of files to resolve symlinks for.
        preserve_symlinks: `EXPERIMENTAL!` We may remove or change it at any point without further notice. Flag to determine whether to preserve symlinks in the tar.
        strip_prefix: prefix to remove from all paths in the tar. Files and directories not under this prefix are dropped.
        package_dir: directory prefix to add to all paths in the tar.
        mtime: new modification time for all entries.
        owner: new uid for all entries.
        ownername: new uname for all entries.
        pipeline: awk script for mtree mutation. Override to provide a custom pipeline; use @include "default" to compose with the built-in pipeline.
        script_args: extra key=value variables passed via --assign. Available in pipeline and any includes.
        includes: additional awk scripts appended after pipeline. A wrapper is generated that @include-s pipeline then each script here in order.
        awk_script: deprecated, use pipeline= instead.
        **kwargs: additional named parameters to genrule
    """
    if awk_script != None:
        # buildifier: disable=print
        print("awk_script is deprecated, use pipeline= instead")
        pipeline = awk_script

    if preserve_symlinks and not srcs:
        fail("preserve_symlinks requires srcs to be set in order to resolve symlinks")

    # Check if srcs is of type list
    if srcs and not types.is_list(srcs):
        srcs = [srcs]
    _mutate_mtree(
        name = name,
        mtree = mtree,
        srcs = srcs,
        preserve_symlinks = preserve_symlinks,
        strip_prefix = strip_prefix,
        package_dir = package_dir,
        mtime = str(mtime) if mtime else None,
        owner = owner,
        ownername = ownername,
        pipeline = pipeline,
        script_args = script_args,
        includes = includes or [],
        out = "{}.mtree".format(name),
        **kwargs
    )

def mutate(**kwargs):
    """Factory function to make a partially-applied `mtree_mutate` rule."""
    return partial.make(mtree_mutate, **kwargs)
