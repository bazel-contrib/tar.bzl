load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@tar.bzl", "mutate", "tar")

tar(
    name = "archive",
    srcs = ["README.md"],
)

tar(
    name = "new2",
    srcs = ["README.md"],
    mutate = mutate(
        mtime = 946699200,
        package_dir = "/usr/share/nginx/html",
        strip_prefix = package_name(),
    ),
)

build_test(
    name = "smoke_test",
    targets = [
        ":archive",
    ],
)
