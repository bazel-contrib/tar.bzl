load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "tar",
    srcs = ["tar.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "@aspect_bazel_lib//lib:paths",
        "@bazel_skylib//rules:common_settings",
    ],
)
