# Default mtree mutation pipeline. Reusable via: @include "default"

{
    if (strip_prefix != "") {
        if ($1 == strip_prefix) {
            # this line declares the directory which is now the root. It may be discarded.
            next;
        } else if (index($1, strip_prefix) == 1) {
            # this line starts with the strip_prefix
            sub("^" strip_prefix "/", "");
            if ($0 ~ /^ /) {
                # this line was the root directory, written with a trailing slash, and now only
                # contains orphaned keywords. It will be discarded.
                next;
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
        # Compose ownership keywords that should also apply to synthesized parent
        # directories, so they don't override pre-existing ownership when this tar
        # is flattened/extracted alongside layers that already declare those dirs.
        # See https://github.com/bazel-contrib/tar.bzl/issues/91.
        ownership_attrs = ""
        if (owner != "")     ownership_attrs = ownership_attrs " uid=" owner
        if (group != "")     ownership_attrs = ownership_attrs " gid=" group
        if (ownername != "") ownership_attrs = ownership_attrs " uname=" ownername
        if (groupname != "") ownership_attrs = ownership_attrs " gname=" groupname

        # First ensure parent directories exist. They are written with a trailing slash, see the
        # NOTE on directory entries below.
        if (!package_dir_dirs_emitted) {
            split(package_dir, dirs, "/")
            path = ""
            for (i = 1; i <= length(dirs); i++) {
                if (path == "") {
                    path = dirs[i]
                } else {
                    path = path "/" dirs[i]
                }
                print path "/ type=dir mode=0755 time=" default_time ownership_attrs
            }
            package_dir_dirs_emitted = 1
        }
        sub(/^/, package_dir "/")
    }

    # NOTE: The mtree format treats paths without slashes as "relative" entries. A relative entry
    #       that is a directory "changes directory", and every later relative entry is created
    #       inside it. So a top-level directory followed by a top-level file puts the file inside
    #       the directory, and a directory line repeated by a second spec appended to this one
    #       nests as `opt/opt`. To avoid this, every directory entry is written with a trailing
    #       slash, which makes it a "full" entry, as mtree_spec already does.
    #       Lines starting with `/` are mtree "special" commands and are left alone.
    if ($0 ~ /(^|[[:space:]])type=dir([[:space:]]|$)/ && $1 !~ /\/$/ && $1 !~ /^\//) {
        $1 = $1 "/";
    }
}
