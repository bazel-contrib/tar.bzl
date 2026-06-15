# Validate mtree file entries used by tar creation.
#
# Reproducible-build motivation:
# If a type=file mtree entry omits uid/gid/time/mode, bsdtar can fall back to
# metadata from the real source file on disk. That makes archive output depend
# on machine/user/time and breaks hermetic/reproducible builds.
#
# This validator enforces explicit metadata for type=file entries so tar output
# remains deterministic.
#
# mtree semantics note:
# /set key=value defines defaults for following entries; /unset removes them.
# For validation we must check the *effective* values (entry overrides + active
# defaults), not just tokens present on the current line.
BEGIN { bad = 0 }
{
    # Skip comments and empty lines.
    if ($0 ~ /^[[:space:]]*#/ || $0 ~ /^[[:space:]]*$/) next

    # Handle mtree special commands that update default keyword state.
    if ($0 ~ /^[[:space:]]*\/set([[:space:]]|$)/) {
        n = split($0, fields, /[[:space:]]+/)
        for (i = 2; i <= n; i++) {
            if (fields[i] ~ /^[^=]+=/) {
                split(fields[i], kv, "=")
                defaults[kv[1]] = 1
            }
        }
        next
    }

    if ($0 ~ /^[[:space:]]*\/unset([[:space:]]|$)/) {
        n = split($0, fields, /[[:space:]]+/)
        for (i = 2; i <= n; i++) {
            if (fields[i] == "all") {
                delete defaults
            } else {
                delete defaults[fields[i]]
            }
        }
        next
    }

    # ".." is a control line for relative path traversal, not a file entry.
    if ($0 ~ /^[[:space:]]*\.\.[[:space:]]*$/) next

    # Split one mtree line into whitespace-delimited fields.
    n = split($0, fields, /[[:space:]]+/)
    has_type_file = 0
    has_type_other = 0
    has_uid = 0
    has_gid = 0
    has_time = 0
    has_mode = 0

    # Scan fields once and note what we found.
    for (i = 1; i <= n; i++) {
        if (fields[i] == "type=file") has_type_file = 1
        if (fields[i] ~ /^type=/ && fields[i] != "type=file") has_type_other = 1
        if (fields[i] ~ /^uid=/) has_uid = 1
        if (fields[i] ~ /^gid=/) has_gid = 1
        if (fields[i] ~ /^time=/) has_time = 1
        if (fields[i] ~ /^mode=/) has_mode = 1
    }

    # Determine effective type=file after combining entry and /set defaults.
    is_file = has_type_file || (!has_type_other && defaults["type"] == 1)

    # For required attrs, entry-level values override defaults.
    effective_uid = has_uid || defaults["uid"] == 1
    effective_gid = has_gid || defaults["gid"] == 1
    effective_time = has_time || defaults["time"] == 1
    effective_mode = has_mode || defaults["mode"] == 1

    # For file entries, require all metadata keys used for deterministic output.
    if (is_file && (!effective_uid || !effective_gid || !effective_time || !effective_mode)) {
        print "ERROR: invalid mtree entry: type=file entries must include uid=, gid=, time=, and mode=." > "/dev/stderr"
        print "ERROR: to bypass this validation temporarily, build with --norun_validations." > "/dev/stderr"
        print "ERROR: offending line: " $0 > "/dev/stderr"
        bad = 1
    }
}

# Non-zero exit causes the Bazel validation action to fail.
END {
    if (bad) {
        exit 1
    }
    print "ok" > validated
    close(validated)
    exit 0
}
