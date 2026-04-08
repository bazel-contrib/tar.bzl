"""
Fixtures that model the py_console_script_binary / venv→whl_install pattern.

Two rules are exported:

  whl_install  — a standalone TreeArtifact containing real files.

  venv_binary  — an executable whose runfiles contain a *_venv TreeArtifact with
                 file-level RELATIVE symlinks into the whl_install TreeArtifact.
                 Critically, whl_install is NOT placed in venv_binary's runfiles;
                 it is only needed by the binary's action so the symlinks are valid.

Usage in tests:

    whl_install(name = "my_whl")
    venv_binary(name = "my_venv_bin", whl_install = ":my_whl")

    # whl_install must be a separate tar src so it is available to bsdtar
    # (venv symlinks into it), but it is not covered by the mtree because the
    # mtree is derived only from venv_binary's runfiles.  The pruner therefore
    # marks whl_install files as unused even though bsdtar needs them to
    # dereference the symlinks inside venv.
    tar(
        name = "my_tar",
        srcs = [":my_venv_bin", ":my_whl"],
        mtree = mtree_spec([":my_venv_bin"]),
        compute_unused_inputs = 1,
    )
"""

def _whl_install_impl(ctx):
    tree = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(
        outputs = [tree],
        command = "echo 'module' > {d}/module.py".format(d = tree.path),
    )
    return [DefaultInfo(files = depset([tree]))]

whl_install = rule(implementation = _whl_install_impl)

def _whl_install_from_file_impl(ctx):
    """Like whl_install but copies content from a source file.

    Allows CI to change the whl content between builds (same TreeArtifact
    structure, different file content) to verify cache-invalidation behaviour.
    """
    tree = ctx.actions.declare_directory(ctx.label.name)
    src = ctx.files.srcs[0]
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [tree],
        command = "cp {src} {d}/module.py".format(src = src.path, d = tree.path),
    )
    return [DefaultInfo(files = depset([tree]))]

whl_install_from_file = rule(
    implementation = _whl_install_from_file_impl,
    attrs = {"srcs": attr.label_list(allow_files = True, mandatory = True)},
)

def _venv_binary_impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(executable, "#!/bin/bash\necho hello", is_executable = True)

    whl = ctx.file.whl_install

    # Build a relative symlink path from inside venv/lib/ up to the whl_install
    # sibling directory.  The two TreeArtifacts sit side-by-side in the output
    # tree, so ../../<whl_basename>/module.py resolves correctly.
    whl_basename = whl.path.split("/")[-1]
    venv = ctx.actions.declare_directory(ctx.label.name + "_venv")
    ctx.actions.run_shell(
        inputs = [whl],
        outputs = [venv],
        command = "mkdir -p {v}/lib && ln -s ../../{whl}/module.py {v}/lib/module.py".format(
            v = venv.path,
            whl = whl_basename,
        ),
    )

    # Only venv goes into runfiles — whl_install is intentionally omitted so
    # that the mtree (derived from this binary's runfiles) does not contain any
    # content= path that names a whl_install file directly.
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [venv]),
    )]

venv_binary = rule(
    implementation = _venv_binary_impl,
    attrs = {
        "whl_install": attr.label(allow_single_file = True),
    },
    executable = True,
)

def _venv_binary_independent_impl(ctx):
    """Like venv_binary but the venv action does NOT depend on whl_install.

    The venv receives the whl_install NAME as a string attribute so the action
    command is fully determined at analysis time without any file input.  This
    means that when whl_install content changes, the venv action's cache key
    (command + empty inputs) is unchanged, so the venv stays cached and its
    digest is unchanged.  Only the tar action's whl_install input changes,
    which is exactly the condition needed to demonstrate the stale disk-cache
    entry: if whl_install is incorrectly in unused_inputs_list, the tar's
    reduced cache key (excluding whl_install) matches the previous entry and
    Bazel serves a stale archive even though the whl content changed.
    """
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(executable, "#!/bin/bash\necho hello", is_executable = True)

    venv = ctx.actions.declare_directory(ctx.label.name + "_venv")
    ctx.actions.run_shell(
        # No inputs declared — the venv action must stay cached when whl changes.
        inputs = [],
        outputs = [venv],
        command = "mkdir -p {v}/lib && ln -sf ../../{whl}/module.py {v}/lib/module.py".format(
            v = venv.path,
            whl = ctx.attr.whl_name,
        ),
    )

    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = [venv]),
    )]

venv_binary_independent = rule(
    implementation = _venv_binary_independent_impl,
    # whl_name is just the directory basename string so the action has no file
    # dependency on whl_install and its cache key remains stable across whl changes.
    attrs = {"whl_name": attr.string(mandatory = True)},
    executable = True,
)
