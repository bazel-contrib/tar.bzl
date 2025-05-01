load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "tar",
    srcs = ["tar.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//tar/private:mtree",
        "//tar/private:tar",
    ],
)
