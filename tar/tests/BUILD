load("@bazel_lib//lib:copy_directory.bzl", "copy_directory")
load("@bazel_lib//lib:diff_test.bzl", "diff_test")
load("@bazel_lib//lib:testing.bzl", "assert_archive_contains")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("@tar.bzl", "mtree_mutate", "mtree_spec", "tar")
load(":asserts.bzl", "assert_tar_listing", "assert_unused_listing")
load(":cross_linking_tree.bzl", "venv_binary", "venv_binary_independent", "whl_install", "whl_install_from_file")
load(":directory.bzl", "directory")
load(":node_modules_tree.bzl", "node_modules_tree")
load(":runfiles_symlinks.bzl", "runfiles_symlinks")

# The examples below work with both source files and generated files.
# Here we generate a file to use in the examples.
write_file(
    name = "fixture1",
    out = "generated.txt",
    content = ["hello a"],
)

#############
# Example 1: Show that you can run any `tar` command you like, using a genrule.
# This is advanced, atypical usage where you need such a level of control and don't want to use the `tar` rule.
genrule(
    name = "tar_genrule",
    srcs = [
        ":fixture1",
        "src_file",
    ],
    outs = ["1.tar"],
    cmd = "$(BSDTAR_BIN) --create --dereference --file $@ -s '#$(BINDIR)##' $(execpath :fixture1) $(execpath src_file)",
    target_compatible_with = select({
        # bsdtar.exe: -s is not supported by this version of bsdtar
        "@platforms//os:windows": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
)

assert_archive_contains(
    name = "test_genrule",
    archive = "1.tar",
    expected = [
        "tar/tests/generated.txt",
        "tar/tests/src_file",
    ],
)

# Test that resolved_target_toolchain works similarly to resolved_toolchain.
# This demonstrates target-platform-based toolchain resolution.
genrule(
    name = "tar_genrule_target_toolchain",
    srcs = [
        ":fixture1",
        "src_file",
    ],
    outs = ["1_target.tar"],
    cmd = "$(BSDTAR_BIN) --create --dereference --file $@ -s '#$(BINDIR)##' $(execpath :fixture1) $(execpath src_file)",
    target_compatible_with = select({
        # bsdtar.exe: -s is not supported by this version of bsdtar
        "@platforms//os:windows": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    toolchains = ["@bsd_tar_toolchains//:resolved_target_toolchain"],
)

assert_archive_contains(
    name = "test_genrule_target_toolchain",
    archive = "1_target.tar",
    expected = [
        "tar/tests/generated.txt",
        "tar/tests/src_file",
    ],
)

#############
# Example 2: exact control of the resulting tar file, using a custom specification in the "mtree" format.
# Copied from the output of `man tar`:
#    An input file in mtree(5) format can be used to create an output
#    archive with arbitrary ownership, permissions, or names that differ
#    from existing data on disk:
#      $ cat input.mtree
#      #mtree
#      usr/bin uid=0 gid=0 mode=0755 type=dir
#      usr/bin/ls	uid=0 gid=0 mode=0755 type=file	content=myls
#      $ tar -cvf	output.tar @input.mtree
tar(
    name = "tar_custom_mtree",
    srcs = ["src_file"],
    mtree = [
        "usr/bin uid=0 gid=0 mode=0755 time=1672560000 type=dir",
        "usr/bin/ls uid=0 gid=0 mode=0755 time=1672560000 type=file content={}/src_file".format(package_name()),
    ],
)

assert_tar_listing(
    name = "test_custom_mtree",
    actual = "tar_custom_mtree",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 usr/bin/",
        "-rwxr-xr-x  0 0      0          21 Jan  1  2023 usr/bin/ls",
    ],
)

#############
# Example 3: compression.
# This uses gzip, see the `compress` attribute documentation for other legal values.
tar(
    name = "tar_compress",
    srcs = ["generated.txt"],
    out = "3.tgz",
    compress = "gzip",
)

assert_archive_contains(
    name = "test_compress",
    archive = "3.tgz",
    expected = ["tar/tests/generated.txt"],
    type = "tar",
)

#############
# Example 4: you can pass arbitrary command-line flags to the bsdtar executable.
write_file(
    name = "fixture4",
    out = ".git",
    content = ["it's a folder"],
)

tar(
    name = "tar_flags",
    srcs = [
        ".git",
        "src_file",
        ":fixture1",
    ],
    out = "4.tar",
    # Due to this argument, .git should not appear in the resulting tar
    args = ["--exclude-vcs"],
)

assert_tar_listing(
    name = "test_flags",
    actual = "tar_flags",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/",
        "-rwxr-xr-x  0 0      0          21 Jan  1  2023 tar/tests/src_file",
        "-rwxr-xr-x  0 0      0           7 Jan  1  2023 tar/tests/generated.txt",
    ],
)

#############
# Example 5: features like `strip_prefix` are supported by `mtree_mutate`.
# This lets you port code that used the `pkg_tar` rule from bazelbuild/rules_pkg.
_SRCS5 = [
    ":fixture1",
    "src_file",
]

mtree_spec(
    name = "mtree5",
    srcs = _SRCS5,
)

mtree_mutate(
    name = "strip_prefix",
    mtree = "mtree5",
    strip_prefix = package_name(),
)

tar(
    name = "tar_strip_prefix",
    srcs = _SRCS5,
    out = "5.tar",
    mtree = "strip_prefix",
)

assert_tar_listing(
    name = "test_strip_prefix",
    actual = "tar_strip_prefix",
    expected = [
        "-rwxr-xr-x  0 0      0           7 Jan  1  2023 generated.txt",
        "-rwxr-xr-x  0 0      0          21 Jan  1  2023 src_file",
    ],
)

#############
# Example 6: When archiving a binary, the "runfiles" are included.
sh_binary(
    name = "cat_src_file",
    srcs = ["cat_src_file.sh"],
    data = ["src_file"],
    deps = ["@rules_shell//shell/runfiles"],
)

tar(
    name = "tar_runfiles",
    srcs = [":cat_src_file"],
    out = "6.tar",
)

genrule(
    name = "run_program_with_runfiles",
    srcs = [":tar_runfiles"],
    outs = ["cat_src_file_output"],
    cmd = """\
      export DIR=$$(mktemp -d)
      $(BSDTAR_BIN) --extract --file $(execpath :tar_runfiles) --directory $$DIR
      (
        cd $$DIR
        ./tar/tests/cat_src_file
      ) > $@
    """,
    target_compatible_with = select({
        # requires runfiles tree, otherwise get
        # ERROR: cannot find bazel_tools/tools/bash/runfiles/runfiles.bash
        "@platforms//os:windows": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    toolchains = ["@bsd_tar_toolchains//:resolved_toolchain"],
)

diff_test(
    name = "test_runfiles",
    timeout = "short",
    file1 = "src_file",
    file2 = "cat_src_file_output",
)

#############
# Example 7: You can archive directories,
# both those in the source tree and those produced by rules that understand "tree artifacts".
copy_directory(
    name = "treeartifact",
    src = "srcdir",
    out = "treeartifact",
)

tar(
    name = "dirs",
    # Note, testonly should be propagated, proven by
    # % bazel query --output=label_kind 'attr("testonly", 1, lib/tests/tar:all)'
    # mtree_spec rule //lib/tests/tar:_dirs.mtree
    # tar rule //lib/tests/tar:dirs
    testonly = True,
    srcs = glob(["srcdir/**"]) + [
        "treeartifact",
    ],
    out = "7.tar",
)

assert_tar_listing(
    name = "test_dirs",
    actual = "dirs",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/srcdir/",
        "-rwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/srcdir/info",
        "-rwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/srcdir/pkg",
        "-rwxr-xr-x  0 0      0           2 Jan  1  2023 tar/tests/srcdir/space in name.txt",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/treeartifact/",
        "-rwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/treeartifact/info",
        "-rwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/treeartifact/pkg",
        "-rwxr-xr-x  0 0      0           2 Jan  1  2023 tar/tests/treeartifact/space in name.txt",
    ],
)

#############
# Example 8: arbitrary mutations of the mtree spec can be performed.
# Typically use the `mtree_mutate` rule which supports specific mutations using a more ergonomic API,
# see Example 12 below.
_SRCS8 = [
    ":fixture1",
    "src_file",
]

mtree_spec(
    name = "mtree8",
    srcs = _SRCS8,
)

# This is a very simple way to mutate the mtree specification, just using regex.
# See docs on tar about future directions for mtree mutation
genrule(
    name = "change_owner",
    srcs = ["mtree8"],
    outs = ["mtree8.mutated"],
    # Modify uid and gid, e.g.
    # tar/tests/a uid=0 gid=0 time=1672560000 mode=0755 type=file content=bazel-out/darwin_arm64-opt/bin/tar/tests/a
    # ->
    # tar/tests/a uid=1000 gid=500 time=1672560000 mode=0755 type=file content=bazel-out/darwin_arm64-opt/bin/tar/tests/a
    cmd = "sed 's/uid=0/uid=1000/;s/gid=0/gid=500/' <$< >$@",
)

tar(
    name = "tar_change_owner",
    srcs = _SRCS8,
    out = "8.tar",
    mtree = "change_owner",
)

assert_tar_listing(
    name = "test_change_owner",
    actual = "tar_change_owner",
    expected = [
        "drwxr-xr-x  0 1000   500         0 Jan  1  2023 tar/",
        "drwxr-xr-x  0 1000   500         0 Jan  1  2023 tar/tests/",
        "-rwxr-xr-x  0 1000   500         7 Jan  1  2023 tar/tests/generated.txt",
        "-rwxr-xr-x  0 1000   500        21 Jan  1  2023 tar/tests/src_file",
    ],
)

#############
# Example 9: Files from a different repository (see #697)
# Note: This test uses an exported file from skylib, so we do not need to create
# an additional workspace just for this test.
tar(
    name = "tar_different_repo",
    srcs = ["@bazel_skylib//:LICENSE"],
    out = "9.tar",
)

assert_archive_contains(
    name = "test_different_repo",
    archive = "9.tar",
    expected = [
        "LICENSE",
    ],
)

#############
# Example 10: Similar to Example 9, you can reference generated files in the `mtree` attribute as well.
tar(
    name = "tar_location_expansion",
    srcs = ["@bazel_skylib//:LICENSE"],
    out = "10.tar",
    mtree = [
        "license uid=0 gid=0 time=1672560000 mode=0755 type=file content=$(location @bazel_skylib//:LICENSE)",
    ],
)

assert_tar_listing(
    name = "test_tar_location_expansion",
    actual = "tar_location_expansion",
    expected = [
        "-rwxr-xr-x  0 0      0       11358 Jan  1  2023 license",
    ],
)

#############
# Example 11: You can create a tar without srcs, only empty directories
tar(
    name = "create_tmp",
    mtree = ["./tmp time=1501783453.0 mode=1777 gid=0 uid=0 type=dir"],
)

assert_tar_listing(
    name = "test_create_create_tmp",
    actual = "create_tmp",
    expected = [
        "drwxrwxrwt  0 0      0           0 Aug  3  2017 ./tmp/",
    ],
)

#############
# Example 12: arbitrary mtree modifications
mtree_mutate(
    name = "modified1",
    mtree = "source-casync.mtree",
    package_dir = "test",
    strip_prefix = "xattr",
)

diff_test(
    name = "test1",
    file1 = "modified1.mtree",
    file2 = "expected1.mtree",
)

mtree_mutate(
    name = "modified2",
    group = "1000",
    groupname = "vbatts",
    mtime = 946684740,  # 1999-12-31, 23:59
    mtree = "source-casync.mtree",
    owner = "123",
    ownername = "fred",
)

diff_test(
    name = "test2",
    file1 = "modified2.mtree",
    file2 = "expected2.mtree",
)

#############
# Example 13: Ensure that multiple entries at the root directory are handled correctly (bug #851)
# NOTE: The mtree_spec part of this test is placed at the root BUILD.bazel because
#       that's the only way to ensure that the mtree_spec generates single-component
#       entries (which would trigger the bug).
exports_files(["expected13.mtree"])

#############
# Example 14: Ensure mtree_mutate correctly handles prefix stripping for top-level directories (bug #851)
write_file(
    name = "test14_main",
    out = "14project/__main__.py",
    content = ["__main__.py"],
)

write_file(
    name = "test14_bin",
    out = "14project_bin",
    content = ["project_bin"],
)

mtree_spec(
    name = "mtree14",
    srcs = [
        ":test14_bin",
        ":test14_main",
    ],
)

mtree_mutate(
    name = "strip_prefix14_unsorted",
    mtree = "mtree14",
    strip_prefix = "tar/tests",
)

# NOTE: On some systems, the mtree_spec output can have a different order.
#       To make the test less brittle, we sort the mtree output and replace the BINDIR with a constant placeholder
genrule(
    name = "strip_prefix14",
    srcs = [":strip_prefix14_unsorted"],
    outs = ["actual14.mtree"],
    cmd = "sort $< | sed 's#$(BINDIR)#{BINDIR}#' >$@",
)

diff_test(
    name = "test14",
    file1 = ":strip_prefix14",
    file2 = "expected14.mtree",
)

#############
# Example 15: mtree subsetting and unused-input pruning.

copy_directory(
    name = "unused_srcdir",
    src = "srcdir",
    out = "unused",
)

mtree_spec(
    name = "mtree15",
    srcs = [
        ":treeartifact",
    ],
)

tar(
    name = "tar15",
    srcs = [
        "treeartifact",
        ":mtree15",  # Not in output archive, but cannot be pruned.
        ":unused_srcdir",
    ],
    out = "15.tar",
    compute_unused_inputs = 1,
    mtree = ":mtree15",
)

assert_tar_listing(
    name = "test_unused_inputs_ignored",
    actual = ":tar15",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/treeartifact/",
        "-rwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/treeartifact/info",
        "-rwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/treeartifact/pkg",
        "-rwxr-xr-x  0 0      0           2 Jan  1  2023 tar/tests/treeartifact/space in name.txt",
    ],
)

assert_unused_listing(
    name = "test_unused_inputs_listed",
    actual = ":tar15",
    expected = [
        "tar/tests/unused/info",
        "tar/tests/unused/pkg",
        "tar/tests/unused/space in name.txt",
    ],
)

#############
# Example 16: Ensure that root directories are properly handled with strip_prefix (bug #978)
# Don't assume that files or directories exist after stripping the prefix. See (bug #851)

_SRCS16 = [
    "src_file",
    ":fixture1",
]

mtree_spec(
    name = "mtree16",
    srcs = _SRCS16,
)

mtree_mutate(
    name = "strip_prefix16",
    mtree = ":mtree16",
    strip_prefix = "tar",
)

tar(
    name = "tar_strip_prefix16",
    srcs = _SRCS16,
    out = "16.tar",
    mtree = "strip_prefix16",
)

assert_tar_listing(
    name = "test_strip_prefix16",
    actual = "tar_strip_prefix16",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tests/",
        "-rwxr-xr-x  0 0      0          21 Jan  1  2023 tests/src_file",
        "-rwxr-xr-x  0 0      0           7 Jan  1  2023 tests/generated.txt",
    ],
)

#############
# Example 17: mtree_mutate preserves symlinks
node_modules_tree(
    name = "e17_node_modules",
)

write_file(
    name = "executable",
    out = "executable.sh",
    content = [
        "#!/usr/bin/env bash",
    ],
    is_executable = True,
)

native_binary(
    name = "e17_binary",
    src = ":executable",
    out = "native_binary_bin",
    data = [":e17_node_modules"],
)

mtree_spec(
    name = "mtree17",
    srcs = [
        ":e17_binary",
    ],
)

assert_tar_listing(
    name = "test_17_before_processing",
    actual = ":mtree17",
    expected = [
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/node_modules/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/node_modules/a/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/node_modules/a/package.json",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/node_modules/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/node_modules/a/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/node_modules/a/package.json",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/a/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/a/package.json",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/dir/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/dir/a",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/dir/b",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/executable.sh",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/native_binary_bin",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_repo_mapping",
    ],
)

mtree_mutate(
    name = "resolve_symlinks",
    srcs = [
        ":e17_binary",
    ],
    mtree = ":mtree17",
    preserve_symlinks = True,
)

assert_tar_listing(
    name = "test_17_after_processing",
    actual = ":resolve_symlinks",
    expected = [
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/",
        "lrwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin -> ../native_binary_bin.runfiles/_main/tar/tests/executable.sh",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/node_modules/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/node_modules/a/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/a@0.0.0/node_modules/a/package.json",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/node_modules/",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/node_modules/a/",
        "lrwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/.pnpm/b@0.0.0/node_modules/a/package.json -> ../../../../a@0.0.0/node_modules/a/package.json",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/a/",
        "lrwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/node_modules/a/package.json -> ../../.pnpm/a@0.0.0/node_modules/a/package.json",
        "drwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/dir/",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/dir/a",
        "lrwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/dir/b -> ../a",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/executable.sh",
        "lrwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_main/tar/tests/native_binary_bin -> ../executable.sh",
        "-rwxr-xr-x  1 0      0           0 Jan  1  2023 tar/tests/native_binary_bin.runfiles/_repo_mapping",
    ],
)

#############
# Example 18: runfiles symlinks
directory(
    name = "symlinks_dir",
    files = [
        "nested/in/a/dir/file",
        "nested/in/a/sibling/another_file",
        "nested/in/a/sibling/file",
        "other/subtree/other/file",
        "top_level",
    ],
)

runfiles_symlinks(
    name = "runfiles_symlinks",
    symlinks = {
        ":symlinks_dir": "in/a/subdir",
        "src_file": "top_level",
        ":fixture1": "../nested/file",
    },
)

tar(
    name = "tar_runfiles_symlinks",
    srcs = [
        ":runfiles_symlinks",
    ],
)

assert_tar_listing(
    name = "test18_runfiles_symlinks",
    actual = ":tar_runfiles_symlinks",
    # This file has a different size depending on the Bazel version, so don't assert on it being in the tar
    exclude = "tar/tests/runfiles_symlinks.runfiles/_repo_mapping",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/",
        "-rwxr-xr-x  0 0      0          10 Jan  1  2023 tar/tests/runfiles_symlinks",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/tar/tests/",
        "-rwxr-xr-x  0 0      0          10 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/tar/tests/runfiles_symlinks",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/a/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/a/dir/",
        "-rwxr-xr-x  0 0      0          31 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/a/dir/file",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/a/sibling/",
        "-rwxr-xr-x  0 0      0          43 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/a/sibling/another_file",
        "-rwxr-xr-x  0 0      0          35 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/nested/in/a/sibling/file",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/other/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/other/subtree/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/other/subtree/other/",
        "-rwxr-xr-x  0 0      0          35 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/other/subtree/other/file",
        "-rwxr-xr-x  0 0      0          20 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/in/a/subdir/top_level",
        "-rwxr-xr-x  0 0      0          21 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/_main/top_level",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/nested/",
        "-rwxr-xr-x  0 0      0           7 Jan  1  2023 tar/tests/runfiles_symlinks.runfiles/nested/file",
    ],
)

#############
# Example 19: runfiles root_symlinks
directory(
    name = "root_symlinks_dir",
    files = [
        "nested/in/a/dir/file",
        "nested/in/a/sibling/another_file",
        "nested/in/a/sibling/file",
        "other/subtree/other/file",
        "top_level",
    ],
)

runfiles_symlinks(
    name = "runfiles_root_symlinks",
    root_symlinks = {
        ":symlinks_dir": "in/a/subdir",
        "src_file": "top_level",
        ":fixture1": "nested/file",
    },
)

tar(
    name = "tar_runfiles_root_symlinks",
    srcs = [
        ":runfiles_root_symlinks",
    ],
)

assert_tar_listing(
    name = "test19_runfiles_root_symlinks",
    actual = ":tar_runfiles_root_symlinks",
    exclude = "tar/tests/runfiles_root_symlinks.runfiles/_repo_mapping",
    expected = [
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/",
        "-rwxr-xr-x  0 0      0          10 Jan  1  2023 tar/tests/runfiles_root_symlinks",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/_main/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/_main/tar/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/_main/tar/tests/",
        "-rwxr-xr-x  0 0      0          10 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/_main/tar/tests/runfiles_root_symlinks",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/a/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/a/dir/",
        "-rwxr-xr-x  0 0      0          31 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/a/dir/file",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/a/sibling/",
        "-rwxr-xr-x  0 0      0          43 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/a/sibling/another_file",
        "-rwxr-xr-x  0 0      0          35 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/nested/in/a/sibling/file",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/other/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/other/subtree/",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/other/subtree/other/",
        "-rwxr-xr-x  0 0      0          35 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/other/subtree/other/file",
        "-rwxr-xr-x  0 0      0          20 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/in/a/subdir/top_level",
        "-rwxr-xr-x  0 0      0          21 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/top_level",
        "drwxr-xr-x  0 0      0           0 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/nested/",
        "-rwxr-xr-x  0 0      0           7 Jan  1  2023 tar/tests/runfiles_root_symlinks.runfiles/nested/file",
    ],
)

#############
# Example 20: Test custom compressor without compressor_args (fixes None issue)
# Create a simple mock compressor for testing
sh_binary(
    name = "mock_compressor",
    srcs = ["mock_compressor.sh"],
)

write_file(
    name = "mock_compressor_sh",
    out = "mock_compressor.sh",
    content = [
        "#!/bin/bash",
        "# Mock compressor that just passes through data",
        "cat",
    ],
)

tar(
    name = "tar_custom_compressor_no_args",
    srcs = ["generated.txt"],
    out = "20.tgz",
    compressor = ":mock_compressor",
    # Note: compressor_args is not specified, should default to None and not cause "None" in command
)

assert_archive_contains(
    name = "test20_custom_compressor_no_args",
    archive = "20.tgz",
    expected = ["tar/tests/generated.txt"],
    type = "tar",
)

#############
# Example 21: mtree_mutate with includes — zero-boilerplate extension via composable pipeline.
# change_mode.awk is @include-d after the default pipeline and uses custom_mode from script_args.
mtree_spec(
    name = "mtree21",
    srcs = ["src_file"],
)

mtree_mutate(
    name = "mutate21",
    includes = [":change_mode.awk"],
    mtree = ":mtree21",
    script_args = {"custom_mode": "0644"},
    strip_prefix = "tar/tests",
)

tar(
    name = "tar21",
    srcs = ["src_file"],
    out = "21.tar",
    mtree = ":mutate21",
)

assert_tar_listing(
    name = "test21_includes",
    actual = ":tar21",
    expected = [
        "-rw-r--r--  0 0      0          21 Jan  1  2023 src_file",
    ],
)

#############
# Example 22: compute_unused_inputs with directory-level cross-TreeArtifact symlinks.
#
# node_modules_tree produces TreeArtifacts where dep_symlink_b_to_a and node_modules_a
# are directory-level symlinks to store_a.  Both the symlink directories AND store_a
# itself are in e17_binary's runfiles, so the mtree contains content= entries for
# store_a's files directly.  The pruner therefore correctly does not prune store_a.
#
# This is a regression test: it verifies that directory-level symlink TreeArtifacts
# in runfiles are handled correctly and nothing is incorrectly pruned.

mtree_spec(
    name = "mtree22",
    srcs = [":e17_binary"],
)

tar(
    name = "tar22",
    srcs = [":e17_binary"],
    out = "22.tar",
    compute_unused_inputs = 1,
    mtree = ":mtree22",
)

# store_a backing files must NOT appear in unused_inputs; they are needed to
# resolve dep_symlink_b_to_a → store_a and node_modules_a → store_a at runtime.
assert_unused_listing(
    name = "test22_cross_dir_symlink_treeartifact_not_pruned",
    actual = ":tar22",
    expected = [],
)

#############
# Example 23: compute_unused_inputs with file-level cross-TreeArtifact symlinks.
#
# cross_linking_tree produces a binary whose runfiles contain:
#   - *_whl_install: a real TreeArtifact with module.py
#   - *_venv: a TreeArtifact containing lib/module.py as a file-level symlink into whl_install
#
# The mtree content= paths reference files under *_venv/ (e.g. venv/lib/module.py).
# The *_whl_install artifact path (whl_install/module.py) never appears in any mtree
# content=, so the join marks whl_install files as unused.  At runtime bsdtar
# dereferences venv/lib/module.py → whl_install/module.py and fails if whl_install
# has been pruned from the sandbox.
#
# This test is expected to FAIL until the pruner is fixed.

whl_install(name = "e23_whl_install")

venv_binary(
    name = "e23_venv_binary",
    whl_install = ":e23_whl_install",
)

# mtree is derived only from e23_venv_binary's runfiles.  The venv contains
# file-level symlinks into e23_whl_install, so the mtree content= paths are
# e23_venv_binary_venv/lib/module.py (the symlink path), never the backing
# e23_whl_install/module.py path.  The pruner therefore marks e23_whl_install
# files as unused even though bsdtar must dereference the symlinks at
# archive-creation time.

mtree_spec(
    name = "mtree23",
    srcs = [":e23_venv_binary"],
)

tar(
    name = "tar23",
    srcs = [
        ":e23_venv_binary",
        ":e23_whl_install",  # needed by bsdtar via symlink dereference, not in mtree
    ],
    out = "23.tar",
    compute_unused_inputs = 1,
    mtree = ":mtree23",
)

# e23_whl_install files must NOT appear in unused_inputs even though no mtree
# content= directly names them: bsdtar dereferences
#   e23_venv_binary_venv/lib/module.py → e23_whl_install/module.py
# at archive-creation time and fails if e23_whl_install is absent from the sandbox.
assert_unused_listing(
    name = "test23_file_level_cross_treeartifact_not_pruned",
    actual = ":tar23",
    expected = [],
)

#############
# Unit tests for tar/private/compute_unused_inputs.awk
#
# Each test case creates real files and symlinks in $TEST_TMPDIR, writes fake
# prunable_inputs / keep_inputs / mtree files, runs the awk script, and asserts
# on its output.  Tests 4, 5, and 8 fail with the current stub and will pass
# once the symlink-following implementation is in place.

sh_test(
    name = "compute_unused_inputs_test",
    srcs = ["compute_unused_inputs_test.sh"],
    args = [
        "$(rootpath //tar/private:compute_unused_inputs.awk)",
        "$(rootpath @gawk//:gawk)",
    ],
    data = [
        "//tar/private:compute_unused_inputs.awk",
        "@gawk",
    ],
)

#############
# Theory 1 targets: kept for reference / local experimentation only.
#
# venv_binary_independent uses inputs=[] which causes Bazel to reject the
# TreeArtifact on all platforms (dangling symlink inside the declared directory).
# All targets below are tagged manual so they are excluded from wildcard builds
# and CI.  Use the theory2 targets instead for CI-compatible testing.

whl_install_from_file(
    name = "theory1_whl_install",
    srcs = ["whl_module.py"],
    tags = ["manual"],
)

# venv_binary_independent: the venv action does NOT depend on whl_install at
# the Bazel level, so changing whl_module.py leaves the venv digest unchanged.
# Only theory1_whl_install changes, which is exactly what we need: if
# whl_install is incorrectly in unused_inputs_list, the tar's reduced cache
# key is identical to the previous build and Bazel serves a stale archive.
venv_binary_independent(
    name = "theory1_venv_binary",
    tags = ["manual"],
    whl_name = "theory1_whl_install",
)

mtree_spec(
    name = "mtree_theory1",
    srcs = [":theory1_venv_binary"],
    tags = ["manual"],
)

tar(
    name = "tar_theory1",
    srcs = [
        ":theory1_venv_binary",
        ":theory1_whl_install",  # needed by bsdtar via symlink dereference, not in mtree
    ],
    out = "theory1.tar",
    compute_unused_inputs = 1,
    mtree = ":mtree_theory1",
    tags = ["manual"],
)

#############
# Theory 2 targets: CI test for cross-TreeArtifact symlink pruning.
#
# venv_binary properly declares whl_install as an action input, so the sandbox
# contains the whl TreeArtifact during the venv action and symlinks inside it
# are never dangling.  This makes the targets safe to build on all platforms.
#
# The mtree covers only venv_binary's runfiles; whl_install is an extra tar src
# needed by bsdtar to dereference the venv symlinks.  Because no mtree content=
# path names a file inside whl_install directly, the pruner incorrectly marks
# whl_install as unused even though bsdtar must read through the symlinks.
#
# CI checks the _unused_inputs_file output group and fails if theory2_whl_install
# appears there.  All targets are manual to avoid wildcard build inclusion.

whl_install_from_file(
    name = "theory2_whl_install",
    srcs = ["whl_module.py"],
    tags = ["manual"],
)

venv_binary(
    name = "theory2_venv_binary",
    tags = ["manual"],
    whl_install = ":theory2_whl_install",
)

mtree_spec(
    name = "mtree_theory2",
    srcs = [":theory2_venv_binary"],
    tags = ["manual"],
)

tar(
    name = "tar_theory2",
    srcs = [
        ":theory2_venv_binary",
        ":theory2_whl_install",  # needed by bsdtar via symlink dereference, not in mtree
    ],
    out = "theory2.tar",
    compute_unused_inputs = 1,
    mtree = ":mtree_theory2",
    tags = ["manual"],
)
