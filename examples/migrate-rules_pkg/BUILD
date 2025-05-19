load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@tar.bzl", "mutate", "tar")
load("@tar.bzl//tar/tests:asserts.bzl", "assert_tars_match")

filegroup(
    name = "static",
    srcs = ["index.html"],
)

######### strip_prefix, mode, and mtime ##################
pkg_tar(
    name = "old1",
    srcs = [":static"],
    mode = "0755",
)

# -> change to ->
tar(
    name = "new1",
    srcs = [":static"],
    mutate = mutate(
        mtime = 946699200,
        strip_prefix = package_name(),
    ),
)

########### package_dir ################
pkg_tar(
    name = "old2",
    srcs = [":static"],
    package_dir = "/usr/share/nginx/html",
)

# -> change to ->
tar(
    name = "new2",
    srcs = [":static"],
    mutate = mutate(
        mtime = 946699200,
        package_dir = "/usr/share/nginx/html",
        strip_prefix = package_name(),
    ),
)

########## TEST #################
[
    assert_tars_match(
        name = "test%s" % i,
        actual = "new%s" % i,
        expected = "old%s" % i,
    )
    for i in range(1, 3)
]
