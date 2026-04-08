# compute_unused_inputs.awk
#
# Compute the unused_inputs_list for a tar action.
#
# A prunable input is considered "used" if:
#   1. its vis-encoded path appears in a content= or contents= keyword in MTREE, OR
#   2. its vis-encoded path appears in KEEP_INPUTS (always-keep set: mtree file, bsdtar binary, etc.), OR
#   3. it is the target of a symlink whose path satisfies (1) or (2).
#
# (3) is the fix for the cross-TreeArtifact symlink bug: if a file in the mtree is a
# symlink, every file reachable by following the symlink chain is also "used" because
# bsdtar must dereference those symlinks when building the archive.
#
# Inputs (environment variables):
#   KEEP_INPUTS  — path to keep_inputs.txt (one vis-encoded path per line)
#   MTREE        — path to the mtree spec file
#
# Input (positional / piped):
#   prunable_inputs.txt — two space-separated fields per line:
#       field 1: vis-encoded path   (used for set membership tests)
#       field 2: raw path           (written to output)
#
# Output: raw paths that are unused, one per line (unsorted).
#
# Requires: GNU awk (gawk), readlink available on PATH.

# Collapse /./  and  /foo/../  segments without calling realpath.
# Preserves whether the path was absolute (leading /) or relative (no leading /).
function normalize_path(p,    parts, n, out, i, seg) {
    n = split(p, parts, "/")
    out = ""
    for (i = 1; i <= n; i++) {
        seg = parts[i]
        if (seg == "" || seg == ".") continue
        if (seg == "..") { sub(/\/[^\/]+$/, "", out); continue }
        out = out "/" seg
    }
    # strip the leading slash added by the accumulator when the input was relative
    if (out != "" && substr(p, 1, 1) != "/" && substr(out, 1, 1) == "/")
        out = substr(out, 2)
    return out
}

# Safe single-quote wrapping for shell arguments.
function shell_quote(s) { gsub(/'/, "'\\''", s); return "'" s "'" }

# Decode vis(1) space encoding back to raw path (\040 -> space).
function unvis(s) { gsub(/\\040/, " ", s); return s }

# Encode a raw path to vis-encoded form (space -> \040).
function vis_encode(s) { gsub(/ /, "\\040", s); return s }

# Follow a symlink chain rooted at vis_p; add every hop target to keep[].
# Uses readlink for each hop; stops when target is not a symlink or after 40 hops.
#
# Handles darwin-sandbox symlink indirection: the sandbox materializes input files
# as symlinks from the sandbox execroot to the real execroot. So readlink on a
# relative sandbox path returns an absolute real-execroot path with the same
# relative suffix. We detect this pattern, record the EXECROOT_PREFIX, and strip
# it so that all paths in keep[] stay in the same relative form as prunable_inputs.
function resolve_symlinks(vis_p,    raw_p, target, dir, cmd, hop, abs_target, n_abs, n_rel) {
    raw_p = unvis(vis_p)
    for (hop = 0; hop < 40; hop++) {
        cmd = "readlink -- " shell_quote(raw_p)
        if ((cmd | getline target) <= 0 || target == "") { close(cmd); break }
        close(cmd)
        abs_target = ""
        if (substr(target, 1, 1) != "/") {
            dir = raw_p; sub(/\/[^\/]+$/, "", dir)
            target = normalize_path(dir "/" target)
        }
        if (substr(target, 1, 1) == "/") {
            abs_target = target
            # Detect sandbox execroot prefix on the first relative→absolute hop:
            # readlink("rel/path") == "/prefix/rel/path"  →  prefix = "/prefix/"
            if (EXECROOT_PREFIX == "" && substr(raw_p, 1, 1) != "/") {
                n_abs = length(target); n_rel = length(raw_p)
                if (n_abs > n_rel && substr(target, n_abs - n_rel + 1) == raw_p)
                    EXECROOT_PREFIX = substr(target, 1, n_abs - n_rel)
            }
            # Strip prefix so paths match the relative entries in prunable_inputs.
            if (EXECROOT_PREFIX != "" && substr(target, 1, length(EXECROOT_PREFIX)) == EXECROOT_PREFIX)
                target = substr(target, length(EXECROOT_PREFIX) + 1)
        }
        keep[vis_encode(target)] = 1
        # When stripping the sandbox prefix gives back the same relative path we
        # started with, we must advance via the absolute real-execroot path to
        # break through the sandbox indirection layer.
        if (target == raw_p && abs_target != "")
            raw_p = abs_target
        else
            raw_p = target
    }
}

BEGIN {
    EXECROOT_PREFIX = ""  # set lazily on first sandbox symlink detection

    # Rule 2: load always-keep set from KEEP_INPUTS (vis-encoded, one per line).
    while ((getline line < ENVIRON["KEEP_INPUTS"]) > 0)
        keep[line] = 1

    # Rule 1: extract every content= / contents= value from MTREE.
    # Rule 3: follow symlinks from those paths and keep all targets too.
    while ((getline line < ENVIRON["MTREE"]) > 0) {
        tmp = line
        while (match(tmp, /contents?=[^[:space:]]+/)) {
            field  = substr(tmp, RSTART, RLENGTH)
            path   = substr(field, index(field, "=") + 1)
            keep[path] = 1
            resolve_symlinks(path)
            tmp = substr(tmp, RSTART + RLENGTH)
        }
    }
}

# For each prunable input: if its vis-encoded path (field 1) is not in the keep
# set, emit its raw path (field 2) as unused.  Field 2 may contain spaces
# (paths with spaces are vis-encoded in field 1 but raw in field 2), so we
# print everything after the first space rather than just $2.
{
    if (!($1 in keep)) print substr($0, length($1) + 2)
}
