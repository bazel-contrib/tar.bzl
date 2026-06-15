# Validate mtree file entries used by tar creation.
#
# Reproducible-build motivation:
# If a type=file mtree entry omits uid/gid/time/mode, bsdtar can fall back to
# metadata from the real source file on disk. That makes archive output depend
# on machine/user/time and breaks hermetic/reproducible builds.
#
# This validator enforces explicit metadata for type=file entries so tar output
# remains deterministic.
BEGIN { bad = 0 }
{
    # Skip comments and empty lines.
    if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) next

    # Split one mtree line into whitespace-delimited fields.
    n = split($0, fields, /[[:space:]]+/)
    is_file = 0
    has_uid = 0
    has_gid = 0
    has_time = 0
    has_mode = 0

    # Scan fields once and note what we found.
    for (i = 1; i <= n; i++) {
        if (fields[i] == "type=file") is_file = 1
        if (fields[i] ~ /^uid=/) has_uid = 1
        if (fields[i] ~ /^gid=/) has_gid = 1
        if (fields[i] ~ /^time=/) has_time = 1
        if (fields[i] ~ /^mode=/) has_mode = 1
    }

    # For file entries, require all metadata keys used for deterministic output.
    if (is_file && (!has_uid || !has_gid || !has_time || !has_mode)) {
        print "ERROR: invalid mtree entry: type=file entries must include uid=, gid=, time=, and mode=." > "/dev/stderr"
        print "ERROR: to bypass this validation temporarily, build with --norun_validations." > "/dev/stderr"
        print "ERROR: offending line: " $0 > "/dev/stderr"
        bad = 1
    }
}

# Non-zero exit causes the Bazel validation action to fail.
END { exit bad }
