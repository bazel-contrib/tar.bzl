load("@bazel_lib//lib:diff_test.bzl", "diff_test")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("@tar.bzl", "mtree_concat")

package(default_testonly = True)

# Merge semantics of mtree_concat, checked on hand-written specs. The inputs are
# normalized by the default mtree_mutate pipeline first, so every directory
# (including the bare `opt`) is written with a trailing slash. Then identical
# duplicate lines are dropped, duplicate directories keep the first occurrence,
# and input order is preserved.
mtree_concat(
    name = "merged",
    srcs = [
        "first.mtree",
        "second.mtree",
    ],
)

diff_test(
    name = "merged_test",
    file1 = "expected.mtree",
    file2 = ":merged",
)

# More than two inputs: the third repeats parents and a file already seen in the
# first two, and adds a new subtree, which is appended in input order.
mtree_concat(
    name = "merged3",
    srcs = [
        "first.mtree",
        "second.mtree",
        "third.mtree",
    ],
)

diff_test(
    name = "merged3_test",
    file1 = "expected3.mtree",
    file2 = ":merged3",
)

# Conflicts: a path that appears twice and is not an identical line or a pair of
# directory entries fails the merge. Each case merges first.mtree with one fixture
# that collides with an entry in it and asserts the failure names the path.
[
    sh_test(
        name = "{}_test".format(name),
        srcs = ["concat_fails_test.sh"],
        args = [
            "$(rootpath @gawk)",
            "$(rootpath //tar/private:concat_mtree.awk)",
            "'conflicting entries for {}'".format(path),
            "$(rootpath first.mtree)",
            "$(rootpath {})".format(fixture),
        ],
        data = [
            fixture,
            "first.mtree",
            "//tar/private:concat_mtree.awk",
            "//tar/private:default.awk",
            "@gawk",
        ],
    )
    for name, fixture, path in [
        # same file, different mode and content
        ("conflict", "conflict.mtree", "opt/app/a/x"),
        # same file and content, only the mode differs
        ("mode_conflict", "mode_conflict.mtree", "opt/app/a/x"),
        # first input has a file at this path, second declares a directory
        ("file_as_dir", "file_as_dir.mtree", "opt/app/a/x"),
        # first input has a directory at this path, second declares a file
        ("dir_as_file", "dir_as_file.mtree", "opt/app/a"),
    ]
]
