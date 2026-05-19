"""Test fixture: a symlink action whose target is a file from another repository.

Used to exercise preserve_symlinks against `external/<repo>/...` paths.
"""

def _impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "_link")
    ctx.actions.symlink(output = out, target_file = ctx.file.target)
    return [DefaultInfo(files = depset([out, ctx.file.target]))]

cross_repo_symlink = rule(
    implementation = _impl,
    attrs = {
        "target": attr.label(allow_single_file = True, mandatory = True),
    },
)
