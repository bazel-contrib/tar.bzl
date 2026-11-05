#!/bin/sh
# Usage: concat_fails_test.sh AWK SCRIPT EXPECTED_STDERR_SUBSTRING INPUT...
# Asserts that merging INPUT... fails and that stderr mentions EXPECTED_STDERR_SUBSTRING.
# SCRIPT @include-s "default", which must sit in the same directory.
set -eu
awk="$1"
script="$2"
expected="$3"
shift 3
out="${TEST_TMPDIR:-/tmp}/out.mtree"
stderr="${TEST_TMPDIR:-/tmp}/stderr"
if AWKPATH="$(dirname "$script")" "$awk" --file "$script" "$@" > "$out" 2> "$stderr"; then
  echo "FAIL: merge unexpectedly succeeded" >&2
  cat "$out" >&2
  exit 1
fi
if ! grep -F -q -- "$expected" "$stderr"; then
  echo "FAIL: stderr does not mention '$expected':" >&2
  cat "$stderr" >&2
  exit 1
fi
