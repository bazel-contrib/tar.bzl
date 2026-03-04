# Default mtree mutation pipeline. Reusable via: @include "default"

{
    if (strip_prefix != "") {
        if ($1 == strip_prefix) {
            # this line declares the directory which is now the root. It may be discarded.
            next;
        } else if (index($1, strip_prefix) == 1) {
            # this line starts with the strip_prefix
            sub("^" strip_prefix "/", "");

            # NOTE: The mtree format treats file paths without slashes as "relative" entries.
            #       If a relative entry is a directory, then it will "change directory" to that
            #       directory, and any subsequent "relative" entries will be created inside that
            #       directory. This causes issues when there is a top-level directory that is
            #       followed by a top-level file, as the file will be created inside the directory.
            #       To avoid this, we append a slash to the directory path to make it a "full" entry.
            components = split($1, _, "/");
            if ($0 ~ /type=dir/ && components == 1) {
                if ($0 !~ /^ /) {
                    $1 = $1 "/";
                }
                else {
                    # this line is the root directory and only contains orphaned keywords, which will be discarded
                    next;
                }
            }
        } else {
            # this line declares some path under a parent directory, which will be discarded
            next;
        }
    }

    # Chosen to match rules_pkg
    default_time = 946699200
    if (mtime != "") {
        sub(/time=[0-9\.]+/, "time=" mtime);
        default_time = mtime
    }

    if (owner != "") {
        sub(/uid=[0-9\.]+/, "uid=" owner)
    }

    if (ownername != "") {
        sub(/uname=[^ ]+/, "uname=" ownername)
    }

    if (group != "") {
        sub(/gid=[0-9\.]+/, "gid=" group)
    }

    if (groupname != "") {
        sub(/gname=[^ ]+/, "gname=" groupname)
    }

    if (package_dir != "") {
        # First ensure parent directories exist
        if (!($0 ~ /type=dir/)) {
            split(package_dir, dirs, "/")
            path = ""
            for (i = 1; i <= length(dirs); i++) {
                if (path == "") {
                    path = dirs[i]
                } else {
                    path = path "/" dirs[i]
                }
                # Only print if we haven't seen this directory before
                if (!(path in seen_dirs)) {
                    print path " type=dir mode=0755 time=" default_time
                    seen_dirs[path] = 1
                }
            }
        }
        sub(/^/, package_dir "/")
    }

}
