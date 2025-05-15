"""Make shorter assertions"""

load("@aspect_bazel_lib//lib:diff_test.bzl", "diff_test")

def assert_tars_match(name, actual, expected):
    """Assert that two tars match.

    Args:
        name: name of the target
        actual: actual tar file
        expected: expected tar file
    """
    actual_listing = "{}_listing".format(name)
    expected_listing = "{}_expected".format(name)
    extract = "$(BSDTAR_BIN) -tvf $(execpath {}) >$@"
    native.genrule(
        name = actual_listing,
        srcs = [actual],
        testonly = True,
        outs = ["{}.actual".format(name)],
        cmd = extract.format(actual),
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
    )

    native.genrule(
        name = expected_listing,
        srcs = [expected],
        testonly = True,
        outs = ["{}.expected".format(name)],
        cmd = extract.format(expected),
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
    )

    diff_test(
        name = name,
        file1 = actual_listing,
        file2 = expected_listing,
        timeout = "short",
    )
