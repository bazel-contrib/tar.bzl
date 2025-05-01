"""re-export to allow syntax sugar: load("@tar.bzl", "tar")"""

load("//tar:mtree.bzl", _mtree_spec = "mtree_spec")
load("//tar:tar.bzl", _tar = "tar")

mtree_spec = _mtree_spec
tar = _tar
