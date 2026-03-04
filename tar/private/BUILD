load("@bazel_lib//:bzl_library.bzl", "bzl_library")

exports_files(
    [
        "default.awk",
        "modify_mtree.awk",
        "preserve_symlinks.awk",
    ],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "tar",
    srcs = ["tar.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "@bazel_lib//lib:paths",
        "@bazel_skylib//rules:common_settings",
    ],
)
