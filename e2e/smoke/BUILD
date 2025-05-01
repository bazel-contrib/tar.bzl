load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@tar.bzl", "tar")

tar(
    name = "archive",
    srcs = [],
)

build_test(
    name = "smoke_test",
    targets = [
        ":archive",
    ],
)
