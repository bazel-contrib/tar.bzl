def _impl(ctx):
    dangling_symlink = ctx.actions.declare_symlink("dangling_symlink")
    ctx.actions.symlink(output = dangling_symlink, target_path = "../non_existent_target")
    return DefaultInfo(files = depset([dangling_symlink]))

dangling_symlink = rule(implementation = _impl)
