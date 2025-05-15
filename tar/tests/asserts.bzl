"Make shorter assertions"

load("@aspect_bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

def _fmt_env_line(kv):
    name, value = kv
    return "{name}={value}".format(name = name, value = value)

def _default_tar_env_impl(ctx):
    env = ctx.toolchains["@aspect_bazel_lib//lib:tar_toolchain_type"].tarinfo.default_env
    out = ctx.actions.declare_file(ctx.attr.name + ".env")

    content = ctx.actions.args()
    content.set_param_file_format("multiline")
    content.add_all(env.items(), map_each = _fmt_env_line)

    ctx.actions.write(out, content = content)
    return [DefaultInfo(files = depset([out]))]

default_tar_env = rule(
    implementation = _default_tar_env_impl,
    toolchains = ["@aspect_bazel_lib//lib:tar_toolchain_type"],
    doc = """
    Writes a .env file providing OS-specific environment variables to coerce the `tar` tool into a consistent, neutral, UTF-8 supporting locale.
    """,
)

# buildifier: disable=function-docstring
def assert_tar_listing(name, actual, expected):
    actual_listing = "{}_listing".format(name)
    expected_listing = "{}_expected".format(name)

    list_env = Label("{}_list_env".format(name))
    default_tar_env(
        name = list_env.name,
    )

    native.genrule(
        name = actual_listing,
        srcs = [
            actual,
            list_env,
        ],
        testonly = True,
        outs = ["{}.listing".format(name)],
        cmd = """
            set -a
            source $(execpath {list_env})
            $(BSDTAR_BIN) -tvf $(execpath {actual}) >$@
        """.format(
            actual = actual,
            list_env = list_env,
        ),
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
