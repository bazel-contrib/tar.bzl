load("@bazel_skylib//lib:partial.bzl", "partial")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@tar.bzl", "mtree_mutate", "tar")
load("//:defs.bzl", "assert_tars_match")

filegroup(
    name = "static",
    srcs = ["index.html"],
)

pkg_tar(
    name = "old",
    srcs = [":static"],
    mode = "0755",
)

tar(
    name = "new",
    srcs = [":static"],
    mutations = partial.make(
        mtree_mutate,
        mtime = 946684740,
        strip_prefix = package_name(),
    ),
)

assert_tars_match(
    name = "test",
    actual = "new",
    expected = "old",
)
