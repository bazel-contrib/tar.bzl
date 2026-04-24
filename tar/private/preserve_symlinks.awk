# Preserve-symlinks extension for the mtree mutation pipeline.
# Automatically included by mtree_mutate when preserve_symlinks = True.
# Reusable via: @include "preserve_symlinks"
#
# By default Bazel reports symlinks as regular file/dir therefore mtree_spec has no way of knowing
# that a file is a symlink. This is a problem when we want to preserve symlinks especially for
# symlink-sensitive applications such as nodejs with pnpm. To work around this we determine if a
# file is a symlink and, if so, where it points to by calling readlink.
#
# Unlike Bazel's own symlinks (which point out of the sandbox), symlinks created by
# ctx.actions.symlink stay within the Bazel sandbox and can be detected here.
#
# See https://github.com/bazelbuild/rules_pkg/pull/609

function common_sections(path1, path2, i, segments1, segments2, min_length, common_path) {
    # Normalize paths (remove leading/trailing slashes)
    gsub(/^\/|\/$/, "", path1)
    gsub(/^\/|\/$/, "", path2)

    # Split paths into arrays
    split(path1, segments1, "/")
    split(path2, segments2, "/")

    # Determine the shortest path length
    min_length = (length(segments1) < length(segments2)) ? length(segments1) : length(segments2)

    # Find common sections
    common_path = ""
    for (i = 1; i <= min_length; i++) {
        if (segments1[i] != segments2[i]) {
            break
        }
        common_path = (common_path == "" ? segments1[i] : common_path "/" segments1[i])
    }

    return common_path
}

function make_relative_link(path1, path2, i, common, target, relative_path, back_steps) {
    # A similar starlark implementation
    # https://github.com/bazelbuild/bazel-skylib/blob/7209de9148e98dc20425cf83747613f23d40827b/lib/paths.bzl#L217

    # Find the common path
    common = common_sections(path1, path2)

    # Remove common prefix from both paths
    target = substr(path1, length(common) + 2)  # "+2" to remove trailing "/"
    relative_path = substr(path2, length(common) + 2)

    # Count directories to go up from path2
    back_steps = "../"
    split(relative_path, path2_segments, "/")
    for (i = 1; i < length(path2_segments); i++) {
        back_steps = back_steps "../"
    }

    # Construct the relative symlink
    return back_steps target
}

{
    if (preserve_symlinks != "") {
        symlink = ""
        symlink_content = ""
        if ($0 ~ /type=file/ && $0 ~ /content=/) {
            match($0, /content=[^ ]+/)
            content_field = substr($0, RSTART, RLENGTH)
            split(content_field, parts, "=")
            path = parts[2]
            # Store paths for look up
            symlink_map[path] = $1
            # Resolve the symlink if it exists.
            #
            # We call plain `readlink` first and keep its result only if it
            # returned a RELATIVE string. That's specifically for
            # `declare_symlink` outputs whose `target_path` is an authored
            # relative string (e.g. `../foo/bar` or `sibling-name`) that we
            # want to preserve verbatim in the archive — `readlink -f`
            # would canonicalise these through and lose the intent.
            #
            # For anything else (plain returns absolute, or nothing),
            # `readlink -f` walks the full chain. That handles:
            #   * absolute Bazel-produced symlinks (`ctx.actions.symlink`
            #     with `target_file`).
            #   * sandboxed-action execution, where plain `readlink` on a
            #     relative input path returns the sandbox→main-execroot
            #     mapping (`/.../execroot/_main/<path>`) — uninformative
            #     for classification; canonical resolution is what we want.
            raw_readlink = ""
            cmd = "readlink \"" path "\""
            cmd | getline raw_readlink
            close(cmd)
            resolved_path = ""
            if (raw_readlink != "" && raw_readlink !~ /^\//) {
                resolved_path = raw_readlink
            } else {
                cmd = "readlink -f \"" path "\""
                cmd | getline resolved_path
                close(cmd)
            }

            if (resolved_path) {
                # Accept any of:
                #  * absolute paths under `/.../bazel-out/<any-cfg>/bin/...`
                #    (declare_file / declare_directory outputs). We don't
                #    require <cfg> to equal the mtree_mutate action's own
                #    `ctx.bin_dir.path` — downstream targets frequently sit
                #    under transitioned configs (`-ST-<hash>` / `-opt-exec-ST-<hash>`
                #    / platform_transition variants), and we want their
                #    symlinks classified too.
                #  * absolute paths under `/.../external/<repo>/...`, which
                #    is where Bazel puts files for external repos that don't
                #    go through `bazel-out` (e.g. python-build-standalone's
                #    interpreter tree in rules_python).
                #  * relative paths (e.g. `../foo`) — declare_symlink outputs
                #    whose target_path was authored as a relative string.
                #
                # In each case, normalise `resolved_path` to the execroot-
                # relative form that the mtree's `content=` fields use so
                # `symlink_map` lookups can match.
                if (resolved_path ~ /\/bazel-out\/[^\/]+\/bin\// || \
                    resolved_path ~ /\/external\// || \
                    resolved_path ~ /\.\.\//) {
                    sub(/^.*\/bazel-out\//, "bazel-out/", resolved_path)
                    sub(/^.*\/external\//, "external/", resolved_path)
                    # If the resolved path is different from the original path,
                    # or if it's a relative path
                    if (path != resolved_path || resolved_path ~ /\.\.\//) {
                        symlink = resolved_path
                        symlink_content = path
                    }
                }
            }
        }
        if (symlink != "") {
            # Store the original line with the resolved path
            line_array[NR] = $0 SUBSEP $1 SUBSEP resolved_path
        } else {
            line_array[NR] = $0  # Store other lines too, with an empty path
        }
        next;  # Skip the final { print; } rule appended by the rule impl
    }
}

END {
    if (preserve_symlinks != "") {
        # Process symlinks if needed
        for (i = 1; i <= NR; i++) {
            line = line_array[i]
            if (index(line, SUBSEP) > 0) {  # Check if this path was a symlink
                split(line, fields, SUBSEP)
                original_line = fields[1]
                field0 = fields[2]
                resolved_path = fields[3]
                if (resolved_path in symlink_map) {
                   mapped_link = symlink_map[resolved_path]

                   linked_to = make_relative_link(mapped_link, field0)
                }
                else {
                  # Already a relative path
                   linked_to = resolved_path
                }
                # Adjust the line for symlink using the map we created
                sub(/type=[^ ]+/, "type=link", original_line)
                sub(/content=[^ ]+/, "link=" linked_to, original_line)
                print original_line

            } else {
                # Print the original line if no symlink adjustment was needed
                print line
            }
        }
    }
}
