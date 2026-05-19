"""Test fixture: an external repository that contains a real on-disk symlink.

Used to exercise preserve_symlinks against `external/<repo>/...` content paths
when the symlink and its target both live inside the same external repo. On
Bazel 9 with the CAS-backed repo layout, `readlink -f` on these paths walks
through the content-addressed cache, so the awk classifier must still
normalise the result back to an `external/<repo>/...` form.
"""

def _impl(rctx):
    rctx.file("BUILD.bazel", content = "exports_files([\"real\", \"alias\"])\n")
    rctx.file("real", content = "real content\n")
    rctx.symlink(rctx.path("real"), "alias")

symlink_repo = repository_rule(implementation = _impl)

def _ext_impl(_mctx):
    symlink_repo(name = "tar_bzl_test_symlink_repo")

test_fixtures = module_extension(implementation = _ext_impl)
