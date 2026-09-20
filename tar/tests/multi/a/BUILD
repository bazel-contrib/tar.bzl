load("@tar.bzl", "mtree_mutate", "mtree_spec")

package(
    default_testonly = True,
    default_visibility = ["//tar/tests:__subpackages__"],
)

exports_files(["x.txt"])

# Each package describes its own files, stripped of its own path and
# relocated under the shared destination directory.
mtree_spec(
    name = "spec",
    srcs = ["x.txt"],
)

mtree_mutate(
    name = "mtree",
    mtree = ":spec",
    package_dir = "opt/sdk",
    strip_prefix = package_name(),
)
