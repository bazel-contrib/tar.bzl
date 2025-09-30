load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@tar.bzl", "mutate", "tar")
load("@tar.bzl//tar/tests:asserts.bzl", "assert_tars_match")

filegroup(
    name = "static",
    srcs = [
        "index.html",
        "subdir/a",
    ],
)

DEFAULT_MUTATIONS = mutate(
    # rules_pkg defaults to Jan 1 2000
    mtime = 946699200,
    # rules_pkg strips the current package by default
    strip_prefix = package_name(),
)

######### strip_prefix, mode, and mtime ##################
pkg_tar(
    name = "old1",
    srcs = [":static"],
    mode = "0755",
    strip_prefix = ".",
)

# -> change to ->
tar(
    name = "new1",
    srcs = [":static"],
    mutate = DEFAULT_MUTATIONS,
)

########### package_dir ################
pkg_tar(
    name = "old2",
    srcs = [":static"],
    mode = "0755",
    package_dir = "/usr/share/nginx/html",
    strip_prefix = ".",
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

########### compression options ################
pkg_tar(
    name = "old3",
    srcs = [":static"],
    compressor = "@pigz",
    compressor_args = "-n",
    mode = "0755",
    strip_prefix = ".",
)

# -> change to ->
tar(
    name = "new3",
    srcs = [":static"],
    compressor = "@pigz",
    compressor_args = "-n",
    mutate = DEFAULT_MUTATIONS,
)

########### remap_paths ################
pkg_tar(
    name = "old4",
    srcs = [":static"],
    mode = "0755",
    remap_paths = {"/subdir": "/var/www"},
    strip_prefix = ".",
)

# -> change to ->
tar(
    name = "new4",
    srcs = [":static"],
    mutate = mutate(
        mtime = 946699200,
        remap_paths = {"/subdir": "/var/www"},
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
    for i in range(1, 5)
]
