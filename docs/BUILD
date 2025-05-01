# This load statement must be in the docs/ package rather than anything users depend on
# so that the dependency on stardoc doesn't leak to them.
load("@aspect_bazel_lib//lib:docs.bzl", "stardoc_with_diff_test", "update_docs")

stardoc_with_diff_test(
    name = "mtree",
    bzl_library_target = "@tar.bzl//tar:mtree",
    renderer = "//tools:stardoc_renderer",
)

stardoc_with_diff_test(
    name = "tar",
    bzl_library_target = "@tar.bzl//tar:tar",
    renderer = "//tools:stardoc_renderer",
)

update_docs(name = "update")
