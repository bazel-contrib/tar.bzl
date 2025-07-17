"""
Creates a directory with a prescribed structure.
"""

def _impl(ctx):
    dir = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(
        outputs = [dir],
        command = "\n".join([
            "mkdir -p $(dirname {dir}/{relative}) && echo -n {content} > {dir}/{relative}".format(
                content = "content of {}".format(f),
                dir = dir.path,
                relative = f,
            )
            for f in ctx.attr.files
        ]),
    )

    return [
        DefaultInfo(
            files = depset([dir]),
        ),
    ]

directory = rule(
    implementation = _impl,
    attrs = {
        "files": attr.string_list(),
    },
)
