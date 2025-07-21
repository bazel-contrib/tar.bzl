"""
Creates an executable target with prescribed runfiles symlinks structure.
"""

def _impl(ctx):
    executable = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(executable, "executable", is_executable = True)

    runfiles = ctx.runfiles(
        symlinks = {
            v: k[DefaultInfo].files.to_list()[0]
            for k, v in ctx.attr.symlinks.items()
        },
        root_symlinks = {
            v: k[DefaultInfo].files.to_list()[0]
            for k, v in ctx.attr.root_symlinks.items()
        },
    )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = runfiles,
        ),
    ]

runfiles_symlinks = rule(
    implementation = _impl,
    attrs = {
        "symlinks": attr.label_keyed_string_dict(allow_files = True),
        "root_symlinks": attr.label_keyed_string_dict(allow_files = True),
    },
    executable = True,
)
