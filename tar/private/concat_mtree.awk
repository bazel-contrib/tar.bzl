# Merge several mtree specifications into one.
#
# Invoked as: AWKPATH=<dir of default.awk> gawk --file concat_mtree.awk SPEC1 SPEC2 ... > OUTPUT
#
# Every input line first goes through the default mutation pipeline with no options set, which
# acts as a pure normalizer: every directory entry is written as a "full" entry with a trailing
# slash. A slash-free directory line would otherwise "change directory" and nest the lines that
# follow it, including the first lines of the next input (see default.awk).
#
# Each line is then a self-contained entry, keyed on its path:
#   - an identical duplicate line is dropped;
#   - two directory entries for the same path keep the first (inputs typically synthesize the
#     same parent directories with slightly different keywords);
#   - any other duplicate path is a conflict and fails the action, naming both entries;
#   - otherwise lines are written in input order, so each input's parent-before-child ordering
#     is preserved.
#
# Inputs are expected to be specs produced by tar.bzl (`mtree_spec` or `mtree_mutate`): one
# entry per line with every keyword spelled out. Other mtree features (comments, `/set`,
# `/unset`, `..`) are not interpreted.

@include "default"

{
    path = $1
    sub(/\/+$/, "", path)
    is_dir = ($0 ~ /(^|[[:space:]])type=dir([[:space:]]|$)/)
    if (path in seen) {
        if (seen[path] == $0) {
            next
        }
        if (is_dir && was_dir[path]) {
            next
        }
        printf "mtree_concat: conflicting entries for %s:\n  %s (from %s)\n  %s (from %s)\n", \
            path, seen[path], origin[path], $0, FILENAME > "/dev/stderr"
        exit 1
    }
    seen[path] = $0
    was_dir[path] = is_dir
    origin[path] = FILENAME
    print
}
