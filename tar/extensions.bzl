"Support calls from MODULE.bazel to setup the toolchains"

load("//tar/toolchain:platforms.bzl", "BSDTAR_PLATFORMS", "bsdtar_binary_repo")
load("//tar/toolchain:toolchain.bzl", "tar_toolchains_repo")

def _toolchains_extension(mctx):
    tar_toolchains_repo(name = "bsd_tar_toolchains", user_repository_name = "bsd_tar_toolchains")
    for platform in BSDTAR_PLATFORMS.keys():
        bsdtar_binary_repo(name = "{}_{}".format("bsd_tar_toolchains", platform), platform = platform)
    return mctx.extension_metadata(reproducible = True)

toolchains = module_extension(
    implementation = _toolchains_extension,
)
