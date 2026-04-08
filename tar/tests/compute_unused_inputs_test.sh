#!/usr/bin/env bash
# Unit tests for tar/private/compute_unused_inputs.awk
#
# The script is invoked as:
#   KEEP_INPUTS=<file> MTREE=<file> gawk -f compute_unused_inputs.awk <prunable_inputs>
#
# prunable_inputs.txt format (two space-separated columns):
#   <vis-encoded-path> <raw-path>
# For these tests all paths are ASCII with no spaces, so vis-encoded == raw.
#
# keep_inputs.txt format: one vis-encoded path per line.
#
# Output: raw paths that are unused (not in mtree content= and not in keep_inputs),
#         one per line, sorted.

set -euo pipefail

AWK_SCRIPT="$1"   # path to compute_unused_inputs.awk, supplied by the test runner
GAWK="$2"         # path to gawk binary, supplied by the test runner

###############################################################################
# Helpers
###############################################################################

PASS=0
FAIL=0

check() {
    local name="$1" actual="$2" expected="$3"
    if [ "$actual" = "$expected" ]; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        printf '  expected: |%s|\n' "$expected"
        printf '  actual:   |%s|\n' "$actual"
        FAIL=$((FAIL + 1))
    fi
}

# Run the awk script.  Callers set T, PRUNABLE, KEEP, MTREE before calling.
run_script() {
    KEEP_INPUTS="$KEEP" MTREE="$MTREE" "$GAWK" -f "$AWK_SCRIPT" "$PRUNABLE" | sort
}

# Write a prunable_inputs.txt line (vis == raw for ASCII-only paths).
prunable_line() { printf '%s %s\n' "$1" "$1"; }

###############################################################################
# Test 1 — file not referenced anywhere → must appear in unused_inputs
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

touch "$T/a.py" "$T/b.py"

printf '%s\n' "$(prunable_line "$T/a.py")" \
              "$(prunable_line "$T/b.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
printf '#mtree\n./a.py type=file content=%s\n' "$T/a.py" > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "content=_keeps_file__other_is_unused" "$(run_script)" "$T/b.py"

###############################################################################
# Test 2 — both files referenced via content= → neither should be unused
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

touch "$T/a.py" "$T/b.py"

printf '%s\n' "$(prunable_line "$T/a.py")" \
              "$(prunable_line "$T/b.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
printf '#mtree\n./a.py type=file content=%s\n./b.py type=file content=%s\n' \
    "$T/a.py" "$T/b.py" > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "both_in_mtree__nothing_unused" "$(run_script)" ""

###############################################################################
# Test 3 — keep_inputs.txt is respected regardless of mtree
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

touch "$T/a.py"

prunable_line "$T/a.py" > "$T/prunable.txt"
printf '%s\n' "$T/a.py" > "$T/keep.txt"   # a.py in keep, not in mtree
printf '#mtree\n' > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "keep_inputs_respected" "$(run_script)" ""

###############################################################################
# Test 4 — THE BUG CASE
# venv/lib/module.py is a relative symlink pointing to whl/module.py.
# The mtree only mentions the venv symlink via content=; whl/module.py never
# appears in any content= line.  The correct behaviour is that whl/module.py
# is NOT unused because bsdtar must dereference the symlink to read its bytes.
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

mkdir -p "$T/whl" "$T/venv/lib"
echo "module content" > "$T/whl/module.py"
# Relative symlink: from inside venv/lib/, go ../../whl/module.py
ln -s "../../whl/module.py" "$T/venv/lib/module.py"

printf '%s\n' "$(prunable_line "$T/venv/lib/module.py")" \
              "$(prunable_line "$T/whl/module.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
# mtree only lists the venv symlink — whl file never appears here
printf '#mtree\n./venv/lib/module.py type=file content=%s\n' \
    "$T/venv/lib/module.py" > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "symlink_target_not_unused" "$(run_script)" ""

###############################################################################
# Test 5 — symlink chain a→b→c; mtree only references a
# b and c must also be kept because they are reachable via the chain
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

echo "real content" > "$T/c.py"
ln -s "c.py"        "$T/b.py"
ln -s "b.py"        "$T/a.py"

printf '%s\n' "$(prunable_line "$T/a.py")" \
              "$(prunable_line "$T/b.py")" \
              "$(prunable_line "$T/c.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
printf '#mtree\n./a.py type=file content=%s\n' "$T/a.py" > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "symlink_chain_all_kept" "$(run_script)" ""

###############################################################################
# Test 6 — dangling symlink: content= references a symlink whose target does
# not exist.  The script must not crash and the symlink itself stays kept
# (it's in the mtree).  Unrelated files are still pruned normally.
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

touch "$T/unrelated.py"
ln -s "nowhere.py" "$T/dangling.py"   # dangling — target doesn't exist

printf '%s\n' "$(prunable_line "$T/dangling.py")" \
              "$(prunable_line "$T/unrelated.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
printf '#mtree\n./dangling.py type=file content=%s\n' "$T/dangling.py" > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "dangling_symlink_no_crash" "$(run_script)" "$T/unrelated.py"

###############################################################################
# Test 7 — symlink whose target is NOT in prunable_inputs.
# The target is outside the tar srcs entirely; the symlink itself is in mtree
# so it's kept; the unrelated prunable file is still pruned.
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

touch "$T/external.py" "$T/unrelated.py"
ln -s "external.py" "$T/link.py"  # link.py → external.py (external not in prunable)

printf '%s\n' "$(prunable_line "$T/link.py")" \
              "$(prunable_line "$T/unrelated.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
printf '#mtree\n./link.py type=file content=%s\n' "$T/link.py" > "$T/mtree.txt"
# external.py is not in prunable at all, so it won't appear in output either way

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "symlink_target_not_in_prunable" "$(run_script)" "$T/unrelated.py"

###############################################################################
# Test 8 — contents= keyword (alternative spelling accepted by libarchive)
###############################################################################
T=$(mktemp -d); trap "rm -rf $T" EXIT

echo "content" > "$T/whl.py"
ln -s "whl.py" "$T/link.py"

printf '%s\n' "$(prunable_line "$T/link.py")" \
              "$(prunable_line "$T/whl.py")" > "$T/prunable.txt"
: > "$T/keep.txt"
printf '#mtree\n./link.py type=file contents=%s\n' "$T/link.py" > "$T/mtree.txt"

PRUNABLE="$T/prunable.txt" KEEP="$T/keep.txt" MTREE="$T/mtree.txt"
check "contents=_spelling_also_followed" "$(run_script)" ""

###############################################################################
# Summary
###############################################################################
echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
