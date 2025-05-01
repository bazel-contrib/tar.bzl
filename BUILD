load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(["tar.bzl"])

bzl_library(
    name = "tar",
    srcs = ["tar.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//tar/private:tar",
        "@aspect_bazel_lib//lib:expand_template",
        "@aspect_bazel_lib//lib:utils",
        "@bazel_skylib//lib:types",
    ],
)
