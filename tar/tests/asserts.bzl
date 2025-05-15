"Make shorter assertions"

load("@aspect_bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

# buildifier: disable=function-docstring
def assert_tar_listing(name, actual, expected):
    actual_listing = "{}_listing".format(name)
    expected_listing = "{}_expected".format(name)

    native.genrule(
        name = actual_listing,
        srcs = [actual],
        testonly = True,
        outs = ["{}.listing".format(name)],
        cmd = "$(BSDTAR_BIN) -tvf $(execpath {}) >$@".format(actual),
        toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
    )

    write_file(
        name = expected_listing,
        testonly = True,
        out = "{}.expected".format(name),
        content = expected + [""],
        newline = "unix",
    )

    diff_test(
        name = name,
        file1 = actual_listing,
        file2 = expected_listing,
        timeout = "short",
    )

# buildifier: disable=function-docstring
def assert_unused_listing(name, actual, expected):
    actual_listing = native.package_relative_label("{}_actual_listing".format(name))
    actual_shortnames = native.package_relative_label("{}_actual_shortnames".format(name))
    actual_shortnames_file = native.package_relative_label("{}.actual_shortnames".format(name))
    expected_listing = native.package_relative_label("{}_expected".format(name))
    expected_listing_file = native.package_relative_label("{}.expected".format(name))

    native.filegroup(
        name = actual_listing.name,
        output_group = "_unused_inputs_file",
        srcs = [actual],
        testonly = True,
    )

    # Trim platform-specific bindir prefix from unused inputs listing. E.g.
    #     bazel-out/darwin_arm64-fastbuild/bin/tar/tests/unused/info
    #     ->
    #     tar/tests/unused/info
    native.genrule(
        name = actual_shortnames.name,
        srcs = [actual_listing],
        cmd = "sed 's!^bazel-out/[^/]*/bin/!!' $< >$@",
        testonly = True,
        outs = [actual_shortnames_file],
    )

    write_file(
        name = expected_listing.name,
        testonly = True,
        out = expected_listing_file,
        content = expected + [""],
        newline = "unix",
    )

    diff_test(
        name = name,
        file1 = actual_shortnames,
        file2 = expected_listing,
        timeout = "short",
    )

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
