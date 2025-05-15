"""re-export to allow syntax sugar: load("@tar.bzl", "tar")"""

load("//tar:mtree.bzl", _mtree_mutate = "mtree_mutate", _mtree_spec = "mtree_spec", _mutate = "mutate")
load("//tar:tar.bzl", _tar = "tar")

mutate = _mutate
mtree_mutate = _mtree_mutate
mtree_spec = _mtree_spec
tar = _tar
